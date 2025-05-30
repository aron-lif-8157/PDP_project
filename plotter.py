import matplotlib.pyplot as plt
from pathlib import Path

files = [
    Path("histogram_1048576_p32.csv"),
    Path("histogram_2097152_p32.csv"),
    Path("histogram_4194304_p32.csv"),
]

def load_hist(path):
    edges  = []
    counts = []
    last_end = None

    with path.open() as f:
        next(f)                     # hoppa över header-raden

        for line in f:
            parts = line.strip().split(",")
            if len(parts) != 3:
                continue            # skydda mot tomma rader

            start, end, cnt = parts
            edges.append(float(start))
            counts.append(int(cnt))
            last_end = float(end)   # sparar senaste "Bin End"

    if last_end is not None:
        edges.append(last_end)      # avsluta kantlistan

    return edges, counts

for csv in files:
    edges, counts = load_hist(csv)
    if not counts:
        print(f"⚠️  Hittade inga data i {csv}")
        continue

    centers = [(edges[i] + edges[i+1]) / 2 for i in range(len(edges)-1)]

    plt.figure(figsize=(8, 4))
    plt.bar(centers, counts,
            width=centers[1] - centers[0],
            edgecolor="black", align="center")
    plt.xlabel("Susceptible humans at T=100")
    plt.ylabel("Frequency")
    plt.title(f"Histogram – {csv.stem}")
    plt.tight_layout()
    plt.show()          # byt till plt.savefig(...) om du vill spara bilden
