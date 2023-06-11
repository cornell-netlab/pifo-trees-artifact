# from termios import CS5
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import Patch

c1 = 'red'
c2 = 'skyblue'
c3 = 'forestgreen'
c4 = 'lightsalmon'
c5 = 'dodgerblue'
c6 = 'darkseagreen'
c7 = 'orchid'


def getColor(src):
    prefix = str(src)[0:2]
    if (prefix == "17"):
        return c1
    elif (prefix == "35"):
        return c2
    elif (prefix == "52"):
        return c3
    elif (prefix == "70"):
        return c4
    elif (prefix == "88"):
        return c5
    elif (prefix == "10"):
        return c6
    elif (prefix == "12"):
        return c7
    else:
        return 'white'


legend_elements_basic = [Patch(color=c1, label='A'),
                         Patch(color=c2, label='B'),
                         Patch(color=c3, label='C')]

legend_elements_five = legend_elements_basic + [Patch(color=c5, label='E')]

legend_elements_seven = legend_elements_five + [Patch(color=c6, label='F'),
                                                Patch(color=c7, label='G')]


def flesh_out_plot(f, df):

    # Setting Y-axis limits, ticks
    f.set_ylim(0, len(df))
    f.axes.yaxis.set_visible(False)

    # f.set_yticks(range(0, len(df), len(df)//10))

    # Setting labels and the legend
    # f.set_xlabel('seconds since start')

    for index, row in df.iterrows():
        # Declaring a bar in schedule
        # [(start, stride)] in x-axis
        # (start, stride) in y-axis
        # gnt.broken_barh([(40, 50)], (30, 1), facecolors=('tab:orange'))
        treetime = row["popped"] - row["pushed"]
        color = getColor(row["src"])

        f.broken_barh([(row["pushed"], treetime)],
                      (index, 1), facecolors=color)

    f.invert_yaxis()


def make_plot(df, subplt, name):

    # print(f"Algorithm {name} had length {len(df)}")

    fig, f1 = subplt.subplots(1, 1)
    fig.set_size_inches(10, 5, forward=True)

    df1 = df.sort_values("pushed")
    df1 = df1.reset_index()

    flesh_out_plot(f1, df1)

    # subplt.show()
    subplt.savefig(name, bbox_inches='tight')


def plot():
    for i in ["hpfq"]:
        #   "fcfs", "strict", "rr", "wfq", "hpfq"]:
        #   "fcfs_bin", "strict_bin", "rr_bin", "fair_bin", "mrg_bin"]:
        # for j in range(1, 3):
        df = pd.read_csv(f"_build/output{i}.csv")
        make_plot(df, plt, i)
    # for i in ["fair2tier", "fair2tier'", "fair3tier", "fairstrict2tier",
    #           "fair2tier_bin", "fair2tier'_bin", "fair3tier_bin",
    #           "fairstrict2tier_bin"]:
    #     name = f"{i}"
    #     df = pd.read_csv(f"_build/output{name}.csv")
    #     make_plot(df, plt, name)
    # for i in ["fcfs", "rr", "strict"]:
    #     name = f"flow_accurate_{i}"
    #     df = pd.read_csv(f"_build/{name}.csv")
    #     make_plot(df, plt, name)


if __name__ == '__main__':
    plot()
