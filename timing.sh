#!/bin/bash
#SBATCH --job-name=malaria_scaling
#SBATCH --nodes=2
#SBATCH --time=01:00:00
#SBATCH --account=uppmax2025-2-247
#SBATCH --partition=node
#SBATCH --output=malaria_scaling_%j.out
#SBATCH --error=malaria_scaling_%j.err

# Load required modules
module purge
module load gcc/9.3.0
module load intelmpi/20.4

# Compile the code
make clean
make

# Determine available cores per node
CPUS_PER_NODE=$(grep -c ^processor /proc/cpuinfo)
TOTAL_CORES=$(( CPUS_PER_NODE * SLURM_JOB_NUM_NODES ))

# Define scaling parameters
p_values=(1 2 4 8 16 32)
N_values=(65536 131072)

# Output file
outfile="scaling_results.csv"
echo "mode,p,N_total,n_local,time_sec" > "$outfile"

# Run scaling tests
for p in "${p_values[@]}"; do
    if (( p > TOTAL_CORES )); then
        echo "Skipping p=$p (exceeds total available cores: $TOTAL_CORES)"
        continue
    fi
    
    # Strong scaling
    for N in "${N_values[@]}"; do
        if (( N % p != 0 )); then
            echo "Skipping strong: N=$N, p=$p (not divisible)"
            continue
        fi
        n_local=$(( N / p ))
        
        echo "Running strong scaling: N=$N, p=$p, n_local=$n_local"
        output=$(mpirun -n $p ./build/main $n_local 2>&1)
        time_str=$(echo "$output" | grep -Eo '[0-9]+\.[0-9]+' | tail -n1)
        
        echo "strong,$p,$N,$n_local,$time_str" >> "$outfile"
        echo "strong,$p,$N,$n_local,$time_str"
    done
    
    # Weak scaling
    base_n=65536
    n_local=$base_n
    N=$(( p * n_local ))
    
    echo "Running weak scaling: N=$N, p=$p, n_local=$n_local"
    output=$(mpirun -n $p ./build/main $n_local 2>&1)
    time_str=$(echo "$output" | grep -Eo '[0-9]+\.[0-9]+' | tail -n1)
    
    echo "weak,$p,$N,$n_local,$time_str" >> "$outfile"
    echo "weak,$p,$N,$n_local,$time_str"
done