from termios import CS5
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import Patch

c1 = "red"
c2 = "skyblue"
c3 = "forestgreen"


def getColor(port):
    if port == 5001:
        return c1
    elif port == 5002 or port == 5004:
        return c2
    elif port == 5003 or port == 5005:
        return c3
    else:
        print("Warning: gave color white to ", port)
        return "white"


def flesh_out_plot(f, df):
    # Setting Y-axis limits, ticks
    f.set_ylim(0, len(df))
    f.axes.yaxis.set_visible(False)

    # f.set_yticks(range(0, len(df), len(df)//10))

    # Setting labels and the legend
    # f.set_xlabel('seconds since start')

    first_pushed = int(df.iloc[0]["pushed"], base=16)
    # print(first_pushed)

    for index, row in df.iterrows():
        popped = int(row["popped"], base=16) - first_pushed
        pushed = int(row["pushed"], base=16) - first_pushed
        treetime = popped - pushed
        color = getColor(row["udp.dstport"])

        f.broken_barh([(pushed, treetime)], (index, 1), facecolors=color)

    f.invert_yaxis()


def make_plot(df, subplt, name):
    print(f"Algorithm {name} had length {len(df)}")

    fig, f1 = subplt.subplots(1, 1)
    fig.set_size_inches(10, 5, forward=True)

    df1 = df.sort_values("pushed")
    df1 = df1.reset_index()

    flesh_out_plot(f1, df1)

    # subplt.show()
    subplt.savefig(f"../../notes/oopsla23/gallery/{name}", bbox_inches="tight")


def plot():
    for name in ["fcfs", "rr", "strict", "wfq"]:
        name = f"tofino_{name}"
        df = pd.read_csv(f"{name}.csv")

        df["enq"], df["delta"], df["pushed"], df["popped"], df["junk"] = map(
            df["data"].str.slice, [0, 8, 16, 28, 40], [8, 16, 28, 40, 48]
        )
        # chunking up the data column into a number of coumns.
        # the first list [0,8,16...] gives the beginning of each chunk.
        # the second list [8,16,28...] gives the end of each chunk.
        # the last chunk is "junk" and has "77{color}{color}"

        make_plot(df, plt, name)


if __name__ == "__main__":
    plot()
