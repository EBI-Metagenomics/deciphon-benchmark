#!/usr/bin/env python

from __future__ import annotations

import sys
import re
from pathlib import Path

from clan import ClanDB
from hmmfile import hmmiter


def main(input: str, clan_file: str, output: str, clan_regex: str):
    regex = re.compile(clan_regex)
    clans = ClanDB(Path(clan_file))
    with open(Path(output), "w") as fout:
        for hmm in hmmiter(Path(input)):
            clan_id = clans.get_clan_id(hmm.meta.acc)
            if not clan_id:
                continue
            if re.match(regex, clan_id):
                fout.write(hmm.data)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
