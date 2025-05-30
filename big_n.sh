#!/bin/bash
#SBATCH --job-name=malaria_bigN
#SBATCH --nodes=2               # 2 noder räcker för 32 kärnor på Rackham
#SBATCH --time=02:00:00         # justera vid behov
#SBATCH --account=uppmax2025-2-247
#SBATCH --partition=node
#SBATCH --output=bigN_%j.out
#SBATCH --error=bigN_%j.err


module purge
module load gcc/9.3.0
module load intelmpi/20.4        


make clean
make                            

# ------------------------------------------------------------
#  Run with the three big N
# ------------------------------------------------------------
P=32                            
BIG_N=(1048576 2097152 4194304) # 2^20, 2^21, 2^22  (>1e6)

for N in "${BIG_N[@]}"; do
    if (( N % P != 0 )); then
        echo "⚠️  Skipping N=$N – Not divisible by p=$P"
        continue
    fi

    n_local=$(( N / P ))
    echo "=== Running N=$N  p=$P  n_local=$n_local ==="
    mpirun -n $P ./build/main "$n_local"

done