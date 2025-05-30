#!/usr/bin/env bash

make clean
make

# Output file
outfile="scaling_grid_results.csv"
echo "mode,p,N_total,n_local,time_sec"

# MPI executable
EXEC="./build/main"

# Process counts to test
p_values=(1 2 4 8 16 32)

# Workloads for strong scaling (all > 10^6)
N_values=(65536 131072) # 1048576 2097152 4194304

# ---------- Strong Scaling ----------
for N in "${N_values[@]}"; do
  for p in "${p_values[@]}"; do
    if (( N % p != 0 )); then
      echo "Skipping strong: N=$N, p=$p (not divisible)"
      continue
    fi
    n_local=$(( N / p ))
    echo "Running strong scaling: N=$N, p=$p, n_local=$n_local"
    time_str=$(
      mpirun -n "$p" "$EXEC" "$n_local" 2>&1 \
        | grep -Eo '[0-9]+\.[0-9]+' \
        | tail -n1
    )
    echo "strong,$p,$N,$n_local,$time_str"
  done
  echo "Finished strong scaling for N=$N"
  echo "-----------------------------"
done

# ---------- Weak Scaling ----------
N_values=(65536 131072) # 1048576 2097152 4194304
for p in "${p_values[@]}"; do
  for n_local in "${N_values[@]}"; do
    N=$(( p * n_local ))
    echo "Running weak scaling: N=$N, p=$p, n_local=$n_local"
    time_str=$(
      mpirun -n "$p" "$EXEC" "$n_local" 2>&1 \
        | grep -Eo '[0-9]+\.[0-9]+' \
        | tail -n1
    )
    echo "weak,$p,$N,$n_local,$time_str"
  done
done