from pathlib import Path
from typing import List

import hmm


def hmmiter(file: Path):
    state = 0
    metas: List[hmm.Meta] = []
    meta = hmm.Meta()
    staged: List[str] = []
    for row in open(file, "r"):
        staged.append(row)
        if row.startswith("NAME "):
            meta.name = row.split(" ", 1)[-1].strip()
            state += 1

        if row.startswith("ACC "):
            meta.acc = row.split(" ", 1)[-1].strip()
            state += 1

        if row.startswith("LENG "):
            meta.leng = int(row.split(" ", 1)[-1].strip())
            state += 1

        if row.startswith("ALPH "):
            meta.alph = row.split(" ", 1)[-1].strip()
            state += 1

        if state == 4:
            metas.append(meta)

        if row.strip() == "//":
            state = 0
            yield hmm.HMM(meta, "".join(staged))
            staged = []
