import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import Patch

c1 = "red"
c2 = "skyblue"
c3 = "forestgreen"
c4 = "lightsalmon"
c5 = "dodgerblue"
c6 = "darkseagreen"
c7 = "orchid"


def getColor(src):
    prefix = str(src)[0:2]
    if prefix == "17":
        return c1
    elif prefix == "35":
        return c2
    elif prefix == "52":
        return c3
    elif prefix == "70":
        return c4
    elif prefix == "88":
        return c5
    elif prefix == "10":
        return c6
    elif prefix == "12":
        return c7
    else:
        return "white"


legend_elements_basic = [
    Patch(color=c1, label="A"),
    Patch(color=c2, label="B"),
    Patch(color=c3, label="C"),
]

legend_elements_five = legend_elements_basic + [Patch(color=c5, label="E")]

legend_elements_seven = legend_elements_five + [
    Patch(color=c6, label="F"),
    Patch(color=c7, label="G"),
]


def flesh_out_plot(f, df):
    # Setting Y-axis limits, ticks
    f.set_ylim(0, len(df))
    f.axes.yaxis.set_visible(False)

    # Setting labels and the legend
    # f.set_xlabel('seconds since start')

    for index, row in df.iterrows():
        # Declaring a bar in schedule
        # [(start, stride)] in x-axis
        # (start, stride) in y-axis
        treetime = row["popped"] - row["pushed"]
        color = getColor(row["src"])
        f.broken_barh([(row["pushed"], treetime)], (index, 1), facecolors=color)
    f.invert_yaxis()


def make_plot(df, subplt, name):
    fig, f1 = subplt.subplots(1, 1)
    fig.set_size_inches(10, 5, forward=True)
    df1 = df.sort_values("pushed")
    df1 = df1.reset_index()
    flesh_out_plot(f1, df1)
    subplt.savefig(name, bbox_inches="tight")


def plot():
    for i in [
        "fcfs",
        "fcfs_bin",
        "strict",
        "strict_bin",
        "rr",
        "rr_bin",
        "wfq",
        "wfq_bin",
        "hpfq",
        "twopol",
        "twopol_bin",
        "threepol",
        "threepol_bin",
    ]:
        df = pd.read_csv(f"_build/output{i}.csv")
        make_plot(df, plt, i)


def plot_extension():
    for i in ["extension", "extension_ternary"]:
        df = pd.read_csv(f"_build/output{i}.csv")
        make_plot(df, plt, i)


if __name__ == "__main__":
    # plot()
    plot_extension()
