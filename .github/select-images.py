#!/usr/bin/env python3
"""Which images of images.json a set of changed files affects.

Reads the paths on standard input, one per line, and writes the matrix as JSON.
Anything outside mkosi.conf.d/ and mkosi.profiles/ (the shared configuration, the
bump script, this script, the workflow, images.json itself) means every image, except
for the files under IGNORED, which no image is built from.
A change under mkosi.conf.d/ affects the distributions its [Match] Distribution=
lines name, and a change under mkosi.profiles/ the images built with that profile.
"""

import json
import re
import sys
from pathlib import Path

IMAGES = Path("images.json")
CONF_D = Path("mkosi.conf.d")
PROFILES = Path("mkosi.profiles")
# Files no image is built from: prose, and the partitions of the disk variant, which the
# hub does not publish.
IGNORED = {Path("README.md"), Path("LICENSE"), Path(".gitignore"), Path(".github/CODEOWNERS")}
IGNORED_DIRS = (Path("mkosi.repart"),)


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


def main() -> int:
    images = json.loads(IMAGES.read_text())
    changed = [Path(line.strip()) for line in sys.stdin if line.strip()]

    distributions: set[str] = set()
    profiles: set[str] = set()
    for path in changed:
        if path in IGNORED or any(d in path.parents for d in IGNORED_DIRS):
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
        if image["distro"] in distributions or image.get("profile") in profiles
    ]
    json.dump(selected, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
