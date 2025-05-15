#!/usr/bin/env python3

import subprocess
import json

matrix = {
    "debian": ["bookworm", "sid"],
    "ubuntu": ["noble", "plucky"],
    "fedora": ["41", "42", "rawhide"],
    "arch": ["rolling"],
    "opensuse": ["leap", "tumbleweed"],
    "centos": ["9", "10"],
    "alma": ["9"],
    "rocky": ["9"],
}

# TODO maybe use SplitArtifacts=tar instead of building twice

for distro, releases in matrix.items():
    if distro == "opensuse":
        # Failes due to outdated signing key?
        continue

    for release in releases:
        print(f"Building {distro} {release}")
        # Call mkosi with the appropriate arguments
        # For demonstration, we will just print ensure the config is valid
        proc = subprocess.run(
            ["mkosi", "-d", distro, "-r", release],
            check=True,
        )
