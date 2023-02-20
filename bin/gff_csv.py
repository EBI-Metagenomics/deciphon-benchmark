#!/usr/bin/env python

import sys

std_cols = ["seqid", "source", "type", "start", "end", "score", "strand", "phase"]


class Item:
    def __init__(self, line: str):
        x = line.split("\t", 8)
        assert len(x) == 9
        self._seqid = x[0]
        self._source = x[1]
        self._type = x[2]
        self._start = x[3]
        self._end = x[4]
        self._score = x[5]
        self._strand = x[6]
        self._phase = x[7]

        self._attributes = {}
        for i in x[8].split(";"):
            k, v = i.split("=", 1)
            self._attributes[k] = v

    @property
    def attribute_names(self):
        return self._attributes.keys()

    def get(self, name: str):
        if name in std_cols:
            return getattr(self, f"_{name}")
        return self._attributes.get(name, "")


def gff_items(file):
    lines = (line for line in file)
    while True:
        try:
            line = next(lines).strip()
            if not line.startswith("#"):
                yield Item(line)
        except StopIteration:
            return


if __name__ == "__main__":
    gff_file = sys.argv[1]
    tsv_file = sys.argv[2]

    with open(gff_file, "r") as gff:
        x = set(k for x in gff_items(gff) for k in x.attribute_names)
        ext_cols = list(sorted(x))

    with open(gff_file, "r") as gff:
        with open(tsv_file, "w") as tsv:
            tsv.write("\t".join(std_cols + ext_cols))
            tsv.write("\n")
            for x in gff_items(gff):
                tsv.write("\t".join(x.get(col) for col in std_cols + ext_cols))
                tsv.write("\n")
