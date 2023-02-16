from __future__ import annotations

import gzip
import io
import sys
from collections import defaultdict
from dataclasses import dataclass
from typing import Dict, List


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


def compute_clans(input_filepath: str, output_filepath: str):
    """
    Compute clans. Save to CSV.
    """
    filter_fields = set(["ID", "AC", "MB"])
    csv = CSV([])
    state = "UNK"
    fields: Dict[str, List[str]] = defaultdict(list)

    print("Reading input file... ", end="")
    with gzip.open(input_filepath, "rb") as f:
        file_content = f.read()
    print("done.")

    for row in io.StringIO(file_content.decode("Windows-1252")):
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
    with open(output_filepath, "w") as file:
        file.write("clan_id,clan_acc,prof_acc\n")
        for row in csv.rows:
            file.write(f"{row.ID},{row.AC},{row.MB}\n")


def fields_to_csv(fields):
    IDs = fields["ID"] * len(fields["MB"])
    ACs = fields["AC"] * len(fields["MB"])
    MBs = fields["MB"]
    return CSV([Row(*i) for i in zip(IDs, ACs, MBs)])


if __name__ == "__main__":
    compute_clans(sys.argv[1], sys.argv[2])
