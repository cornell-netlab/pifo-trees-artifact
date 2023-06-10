from scapy.all import Ether, IP, wrpcap
import pandas as pd

a = '10:10:10:10:10:10'
b = '20:20:20:20:20:20'
c = '30:30:30:30:30:30'
dummy = '1:1:1:1:1:1'


def get_src(port):
    if (port == 5001):
        return a
    elif (port == 5002 or port == 5004):
        return b
    elif (port == 5003 or port == 5005):
        return c
    else:
        print("Warning: did not have a valid port for ", port)
        return dummy


def gen_pcap(df, name):
    df = df.sort_values("pushed")

    packets = []
    first_pushed = int(df.iloc[0]["pushed"], base=16)

    for index, row in df.iterrows():
        packets += Ether(src=get_src(row["udp.dstport"]),
                         dst=dummy) / IP(src='1.1.1.1', dst='1.1.1.1')
    for i, p in enumerate(packets):
        p.time = i / 10
    wrpcap(f'{name}_generated.pcap', packets)


def main():

    for name in ["fcfs", "rr", "strict", "wfq"]:
        df = pd.read_csv(f"{name}.csv")

        df['enq'], df['delta'], df['pushed'], df['popped'], df['junk'] = map(
            df['data'].str.slice, [0, 8, 16, 28, 40], [8, 16, 28, 40, 48])
        # chunking up the data column into a number of coumns.
        # the first list [0,8,16...] gives the beginning of each chunk.
        # the second list [8,16,28...] gives the end of each chunk.
        # the last chunk is junk

        gen_pcap(df, name)


if __name__ == '__main__':
    main()
