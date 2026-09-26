"""Collects validation findings. Errors block import; warnings route to human review."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class Issue:
    level: str  # "error" | "warning"
    where: str  # file path and/or question id
    message: str

    def __str__(self) -> str:
        return f"{self.level.upper():7} {self.where}: {self.message}"


@dataclass
class Issues:
    items: list[Issue] = field(default_factory=list)

    def error(self, where: str, message: str) -> None:
        self.items.append(Issue("error", where, message))

    def warn(self, where: str, message: str) -> None:
        self.items.append(Issue("warning", where, message))

    @property
    def errors(self) -> list[Issue]:
        return [i for i in self.items if i.level == "error"]

    @property
    def warnings(self) -> list[Issue]:
        return [i for i in self.items if i.level == "warning"]

    def extend(self, other: "Issues") -> None:
        self.items.extend(other.items)


def check_keys(obj: dict, where: str, issues: Issues, *, required: set[str], optional: set[str] = frozenset()) -> None:
    """Report missing and unknown keys. Unknown keys usually mean a typo or a
    YAML flow-mapping split by an unquoted comma, so they are errors."""
    for key in sorted(required - obj.keys()):
        issues.error(where, f"missing field '{key}'")
    for key in sorted(obj.keys() - required - optional):
        issues.error(where, f"unknown field '{key}'")
