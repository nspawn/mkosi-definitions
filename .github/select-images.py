#!/usr/bin/env python3
"""Which images of images.json a set of changed files affects.

Reads the paths on standard input, one per line, and writes the matrix as JSON.

    mkosi.conf.d/<something>      the distributions its [Match] Distribution= lines name
    mkosi.profiles/<profile>/     the images built with that profile
    images.json                   the entries that were added or changed (--base names
                                  the commit to compare against)
    anything else under mkosi.    every image (the shared configuration, mkosi.bump)
    .github/, README, LICENSE,    nothing: no image is built from them. A change to how
    mkosi.repart/                 the workflow builds (the mkosi version, for one) asks
                                  for a manual run, which builds everything.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

IMAGES = Path("images.json")
CONF_D = Path("mkosi.conf.d")
PROFILES = Path("mkosi.profiles")
# Files no image is built from: prose, and the partitions of the disk variant, which the
# hub does not publish.
IGNORED = {Path("README.md"), Path("LICENSE"), Path(".gitignore")}
IGNORED_DIRS = (Path("mkosi.repart"), Path(".github"))


def distributions_of(path: Path) -> set[str]:
    """The distributions a fragment of mkosi.conf.d/ matches, from its [Match] section.

    A directory carries its mkosi.conf; a bare file speaks for itself. A path that
    is gone (a deletion) tells us nothing, so it stands for every distribution.
    """
    files = [path] if path.is_file() else sorted(path.glob("mkosi.conf"))
    if not files:
        return set()
    found: set[str] = set()
    for file in files:
        for line in file.read_text().splitlines():
            match = re.fullmatch(r"Distribution=\|?(\S+)", line.strip())
            if match:
                found.add(match.group(1))
    return found


def entries_changed(base: str | None) -> list[dict]:
    """The entries of images.json that are new or different from `base`.

    Without a base to compare against (the file did not exist there, or none was
    given) nothing counts as changed: the entries describe images that already
    exist, and the weekly run rebuilds every one of them anyway.
    """
    images = json.loads(IMAGES.read_text())
    if not base:
        return []
    previous = subprocess.run(
        ["git", "show", f"{base}:{IMAGES}"], capture_output=True, text=True
    )
    if previous.returncode != 0:
        return []
    was = json.loads(previous.stdout)
    return [image for image in images if image not in was]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", help="commit the change is measured against")
    args = parser.parse_args()

    images = json.loads(IMAGES.read_text())
    changed = [Path(line.strip()) for line in sys.stdin if line.strip()]
    selected_by_entry: list[dict] = []

    distributions: set[str] = set()
    profiles: set[str] = set()
    for path in changed:
        if path in IGNORED or any(d in path.parents for d in IGNORED_DIRS):
            continue
        if path == IMAGES:
            selected_by_entry = entries_changed(args.base)
            continue
        if CONF_D in path.parents or path.parent == CONF_D:
            # mkosi.conf.d/debian/mkosi.conf -> debian/, mkosi.conf.d/el-alma.conf -> itself
            top = CONF_D / path.relative_to(CONF_D).parts[0]
            names = distributions_of(top)
            if not names:  # deleted, or a fragment without a [Match]: rebuild everything
                distributions.update(image["distro"] for image in images)
            distributions.update(names)
        elif PROFILES in path.parents:
            profiles.add(path.relative_to(PROFILES).parts[0])
        else:
            json.dump(images, sys.stdout)
            return 0

    selected = [
        image
        for image in images
        if image["distro"] in distributions
        or image.get("profile") in profiles
        or image in selected_by_entry
    ]
    json.dump(selected, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
