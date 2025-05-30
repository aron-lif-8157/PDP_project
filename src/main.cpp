//
// Created by aron on 5/23/25.
//
#include <array>
#include <iostream>
#include <fstream>
#include <string>
#include <mpi.h>
#include <algorithm>
#include <iomanip>
#include <vector>

#include "ssa.hpp"
#include "stoichiometry.hpp"
// #include "output_file_logic.hpp"

std::array<int, 7> x0 = {900, 900, 30, 330, 50, 270, 20}; // starting values for the state vector
const double T = 100.0;                                   // Total time for the simulation
int TIME_RUNS = 100;                                      // Number of runs for timing tests is multiplied by given processes

int main(int argc, char *argv[])
{
    MPI_Init(&argc, &argv); // Initialize MPI environment
    int rank, world_size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);       // Get the rank of the process
    MPI_Comm_size(MPI_COMM_WORLD, &world_size); // Get the total number of processes
                                                // Parse args: expect at least runs, plus optional "--time"

    /* check for enough arguments*/
    if (argc < 2 && rank == 0)
    {
        std::cerr << "Usage: " << argv[0] << " <times_to_run>";
        MPI_Abort(MPI_COMM_WORLD, 1); // Exit code 1
        return 1;                     // Exit if not enough arguments are provided
    }

    int local_runs = std::stoi(argv[1]);
    int total_runs = local_runs * world_size;

    /*check that total runs is divisible by the number of processes*/
    if (rank == 0 && total_runs % world_size != 0)
    {
        std::cerr << "Error: total_runs must be divisible by the number of processes (" << world_size << ").\n";
        MPI_Abort(MPI_COMM_WORLD, 1); // Exit code 1
        return 1;                     // Exit if not enough arguments are provided
    }

    std::random_device rd; // Random number generator
    //! changing of seed is done here
    std::mt19937_64 rand_seed(rd() + rank); // Mersenne Twister engine for random number generation

    double t0 = MPI_Wtime(); // Start timing
    //?run simulations
    std::vector<int> local_results(local_runs);

    for (int i = 0; i < local_runs; ++i)
    {
        std::array<int, 7> tmp_result = malaria_simulation_sequential(T, x0, rand_seed);
        local_results[i] = tmp_result[0]; // Store the result in the local results array
    }

    //? gather the results
    std::vector<int> all_results;
    if (rank == 0)
    {
        all_results.resize(total_runs);
    }

    MPI_Gather(
        local_results.data(),                     /*sendbuf*/
        local_runs,                               /*sendcount*/
        MPI_INT,                                  /*sendtype*/
        rank == 0 ? all_results.data() : nullptr, /*recvbuf*/
        local_runs,                               /*recvcounts*/
        MPI_INT,                                  /*recvtype*/
        0,                                        /*root*/
        MPI_COMM_WORLD                            /*comm*/
    );

    if (rank == 0)
    {
        //? calculcate global min and max
        int global_min = *std::min_element(all_results.begin(), all_results.end());
        int global_max = *std::max_element(all_results.begin(), all_results.end());

        //? calculate bin edges for histogram
        int bins = 20;
        double width = double(global_max - global_min) / bins; // Assuming 20 bins
        std::vector<double> bin_edges(bins + 1);
        for (int i = 0; i <= bins; ++i)
        {
            bin_edges[i] = global_min + i * width;
        }

        //? calculate bin results
        std::vector<int> bin_values(bins, 0); // Create a vector of vectors to hold values for each bin

        for (int value : all_results)
        {
            int index = int((value - global_min) / width); // Determine the bin index
            if (index == bins)
                index = bins - 1; // Ensure the index does not exceed the last bin
            bin_values[index]++;  // Increment the count for the corresponding bin
        }
        double t1 = MPI_Wtime(); // End timing
        double time = t1 - t0;   // Calculate elapsed time

        // Generate filename
        std::string filename = "histogram_" +
                               std::to_string(total_runs) + "_p" +
                               std::to_string(world_size) + ".csv";

        // Open file in current directory
        std::ofstream outfile(filename);
        if (!outfile)
        {
            std::cerr << "Error opening output file: " << filename << "\n";
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        // Write bin edges (header)
        outfile << "Bin Start,Bin End,Count\n";

        // Write bin data
        for (size_t i = 0; i < bin_values.size(); ++i)
        {
            outfile << bin_edges[i] << ","
                    << bin_edges[i + 1] << ","
                    << bin_values[i] << "\n";
        }

        outfile.close();
        std::cout << "[timing] processes:" << world_size << " problem size:" << total_runs << ") took " << time << " s\n";
    }

    MPI_Finalize();
    return 0;
}