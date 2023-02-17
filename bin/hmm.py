from __future__ import annotations

from dataclasses import dataclass


@dataclass
class Meta:
    name: str = ""
    acc: str = ""
    leng: int = 0
    alph: str = ""


@dataclass
class HMM:
    meta: Meta
    data: str
