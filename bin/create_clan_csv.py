#!/usr/bin/env python

from __future__ import annotations

import sys
from collections import defaultdict
from dataclasses import dataclass
from typing import Dict, List


def main(input: str, output: str):
    filter_fields = set(["ID", "AC", "MB"])
    csv = CSV([])
    state = "UNK"
    fields: Dict[str, List[str]] = defaultdict(list)

    for row in open(input, "r", encoding="Windows-1252"):
        if row.startswith("# STOCKHOLM"):
            state = "BEGIN"
            continue

        if state == "BODY" and row.startswith("//"):
            state = "END"
            fields["MB"] = list(set(fields["MB"]))
            csv.rows += fields_to_csv(fields).rows
            fields = defaultdict(list)
            continue

        if state == "BEGIN" and not row.startswith("//"):
            state = "BODY"

        if state == "BODY":
            assert "#=GF " == row[:5]
            key = row[5:7]
            if key in filter_fields:
                val = row[10:].strip().rstrip(";")
                fields[key].append(val)
            continue

    csv.sort()
    with open(output, "w") as file:
        file.write("clan_id,clan_acc,prof_acc\n")
        for row in csv.rows:
            file.write(f"{row.ID},{row.AC},{row.MB}\n")


@dataclass
class Row:
    ID: str
    AC: str
    MB: str

    def __lt__(self, you: Row):
        x = self.ID < you.ID
        x = x or self.ID == you.ID and self.AC < you.AC
        x = x or self.ID == you.ID and self.AC == you.AC and self.MB < you.MB
        return x

    def __gt__(self, you: Row):
        x = self.ID > you.ID
        x = x or self.ID == you.ID and self.AC > you.AC
        x = x or self.ID == you.ID and self.AC == you.AC and self.MB > you.MB
        return x


@dataclass
class CSV:
    rows: List[Row]

    def sort(self):
        self.rows = list(sorted(self.rows))


def fields_to_csv(fields):
    IDs = fields["ID"] * len(fields["MB"])
    ACs = fields["AC"] * len(fields["MB"])
    MBs = fields["MB"]
    return CSV([Row(*i) for i in zip(IDs, ACs, MBs)])


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
