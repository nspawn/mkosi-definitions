#!/usr/bin/env python3

import subprocess
import json

matrix = {
    "debian": ["bookwork", "sid"],
    "ubuntu": ["jammy", "lunar", "mantic"],
    "fedora": ["37", "38", "39"],
    "arch": ["rolling"],
    "opensuse": ["leap", "tumbleweed"],
    "centos": ["9"],
    "alma": ["9"],
    "rocky": ["9"],
}

output_dirs = set()

# TODO maybe use SplitArtifacts=tar instead of building twice

for distro, releases in matrix.items():
    for release in releases:
        print(f"Building {distro} {release}")
        # Call mkosi with the appropriate arguments
        # For demonstration, we will just print ensure the config is valid
        proc = subprocess.run(
            ["mkosi", "-d", distro, "-r", release, "--json", "summary"],
            check=True,
            capture_output=True,
        )
        assert proc.stderr == b"", f"Please fix mkosi config for {distro} {release}"
        summary = json.loads(proc.stdout)
        [image] = summary["Images"]
        output_dir = image["OutputDirectory"]
        assert (
            output_dir not in output_dirs
        ), f"Duplicate output directory: {output_dir}"
        output_dirs.add(output_dir)

print(json.dumps(list(output_dirs), indent=2))
