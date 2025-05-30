import sys
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

def main(csv_path: str):
    # Read the first row (bin edges) and second row (counts)
    bin_edges = np.loadtxt(csv_path, delimiter=",", max_rows=1)
    counts    = np.loadtxt(csv_path, delimiter=",", skiprows=1, max_rows=1)

    # Calculate bin widths and left edges for bar chart
    widths = bin_edges[1:] - bin_edges[:-1]
    left_edges = bin_edges[:-1]

    # Plot bar chart
    plt.figure(figsize=(8, 4))
    plt.bar(left_edges, counts, width=widths, edgecolor="black", align="edge")
    plt.xlabel("Susceptible Humans at T=100")
    plt.ylabel("Frequency")
    plt.title(f"Histogram from {Path(csv_path).name}")
    plt.tight_layout()

    # Save and show
    out_png = Path(csv_path).with_suffix(".png")
    plt.savefig(out_png)
    print(f"Plot saved to {out_png}")
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 plot_counts.py <csv_file>")
        sys.exit(1)
    main(sys.argv[1])

# Display the code to the user

