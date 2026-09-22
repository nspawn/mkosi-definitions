# mkosi-definitions

The [mkosi](https://github.com/systemd/mkosi) definitions of the images on
[hub.nspawn.org](https://hub.nspawn.org/), the registry that
[nspawn](https://github.com/nspawn/nspawn) pulls from. One OCI image per distribution,
built by GitHub Actions from this repository and pushed to the hub.

| Image | Tags | Definition |
| --- | --- | --- |
| `archlinux` | `rolling`, `latest` | `mkosi.conf.d/arch/` |
| `debian` | `13`, `trixie`, `latest`; `12`, `bookworm`; `sid`, `unstable` | `mkosi.conf.d/debian/` |
| `ubuntu` | `26.04`, `resolute`, `latest`; `24.04`, `noble`; `22.04`, `jammy` | `mkosi.conf.d/ubuntu/` |
| `fedora` | `44`, `latest`; `43`; `rawhide` | `mkosi.conf.d/fedora/` |
| `centos` | `10`, `latest`; `9` | `mkosi.conf.d/el/` plus `el-centos.conf` |
| `almalinux` | `10`, `latest`; `9` | `mkosi.conf.d/el/` plus `el-alma.conf` |
| `rockylinux` | `10`, `latest`; `9` | `mkosi.conf.d/el/` plus `el-rocky.conf` |
| `opensuse` | `tumbleweed`, `latest`; `16.0`, `leap` | `mkosi.conf.d/opensuse/` |
| `kali` | `rolling`, `latest` | `mkosi.conf.d/kali/` |

Every build also gets a dated tag (`fedora:44-20260922`) to go back to: the first build of
a day owns that tag, a later one the same day moves the other tags but leaves it alone, so a
dated tag always names the same image. The hub keeps the last ten per repository. The images boot
systemd, log in as `root` with password `root` on the console, and carry systemd-networkd
and systemd-resolved, which is how they get their address and DNS on the nspawn bridge.

```shell
sudo nspawn pull fedora:44
sudo nspawn start fedora-44
```

## Building locally

mkosi 27 or newer. The tools tree (`ToolsTree=default`) brings the package managers, so
the host only needs mkosi itself:

```shell
mkosi -B -d fedora -r 44       # mkosi.output/fedora_<date>_x86-64/, an OCI layout
mkosi -B -d debian -r trixie
mkosi -B --profile=disk -d fedora -r 44 vm   # a bootable disk image, booted in a VM
```

`-B` (`--auto-bump`) runs `mkosi.bump`, which sets the image version to today's date and
keeps it in `mkosi.version`; without it the output has no version in its name. Without
`-r` each distribution builds its default release (the one in its `mkosi.conf`).
`mkosi.local.conf` keeps a choice around, as in every mkosi project:

```ini
[Distribution]
Distribution=fedora
Release=44
```

Test the result with nspawn on the same machine:

```shell
skopeo copy oci:mkosi.output/fedora_20260922_x86-64 docker://localhost:5000/fedora:test
```

or push it to any registry `nspawn pull` can reach.

## Layout

```text
mkosi.conf                 output format, annotations and what every image shares
mkosi.conf.d/<distro>/     [Match] Distribution=..., default release, packages, postinst
mkosi.profiles/disk/       the bootable disk variant (kernel per distribution)
mkosi.repart/              partitions of the disk variant
mkosi.bump                 the image version: the build date
.github/workflows/mkosi.yml   the matrix, one job per image
```

## Changing an image

Edit the packages or the `mkosi.postinst.chroot` of the distribution and open a pull
request: the workflow builds every image of the matrix and keeps the package manifest of
each as an artifact, without pushing anything. Once merged to `master` the same workflow
builds again and pushes to the hub; it also runs every Sunday to pick up package updates.

To add a distribution or release, add its directory under `mkosi.conf.d/` (and a kernel
entry under `mkosi.profiles/disk/mkosi.conf.d/` if it should have a disk variant) and an
entry in the matrix of the workflow with the tags the hub should show.
