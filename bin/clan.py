from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


class ClanDB:
    def __init__(self, file: Path):
        with open(file, "r") as f:
            it = iter(csv.reader(f))
            hdr = next(it)
            assert hdr[0] == "clan_id"
            assert hdr[1] == "clan_acc"
            assert hdr[2] == "prof_acc"
            rows = [Row(*x) for x in it]
            self._prof_to_clan = {x.prof_acc: x.clan_id for x in rows}
            self._clan_ids = set(x.clan_id for x in rows)

    def get_clan_id(self, acc: str) -> Optional[str]:
        acc = acc.partition(".")[0]
        return self._prof_to_clan.get(acc, None)

    @property
    def clan_ids(self):
        return self._clan_ids


@dataclass
class Row:
    clan_id: str
    clan_acc: str
    prof_acc: str
