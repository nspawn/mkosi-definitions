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

Services, each a profile on the Debian image, tagged with the version of the package
Debian ships (`nginx:1.26.3`, `nginx:1.26`, `nginx:latest`):

| Image | Package | Serves | Definition |
| --- | --- | --- | --- |
| `nginx` | `nginx` | port 80, `/var/www/html`, `/etc/nginx` | `mkosi.profiles/nginx/` |
| `apache` | `apache2` | port 80, `/var/www/html`, `/etc/apache2` | `mkosi.profiles/apache/` |
| `caddy` | `caddy` | port 80, `/usr/share/caddy`, `/etc/caddy` | `mkosi.profiles/caddy/` |
| `postgresql` | `postgresql` (17) | port 5432, `/var/lib/postgresql`, `/etc/postgresql` | `mkosi.profiles/postgresql/` |
| `mariadb` | `mariadb-server` | port 3306, `/var/lib/mysql`, `/etc/mysql` | `mkosi.profiles/mariadb/` |
| `valkey` | `valkey-server` | port 6379, `/var/lib/valkey`, `/etc/valkey` | `mkosi.profiles/valkey/` |
| `memcached` | `memcached` | port 11211, `/etc/memcached.conf` | `mkosi.profiles/memcached/` |
| `rabbitmq` | `rabbitmq-server` | ports 5672 and 15672 (management), `/var/lib/rabbitmq`, `/etc/rabbitmq` | `mkosi.profiles/rabbitmq/` |
| `mosquitto` | `mosquitto` | port 1883, `/etc/mosquitto` | `mkosi.profiles/mosquitto/` |
| `haproxy` | `haproxy` | whatever `/etc/haproxy/haproxy.cfg` says | `mkosi.profiles/haproxy/` |
| `unbound` | `unbound` | port 53, `/etc/unbound/unbound.conf.d` | `mkosi.profiles/unbound/` |
| `dnsmasq` | `dnsmasq` | port 53, `/etc/dnsmasq.d` | `mkosi.profiles/dnsmasq/` |
| `bind9` | `bind9` | port 53, `/etc/bind` | `mkosi.profiles/bind9/` |
| `samba` | `samba` | port 445, share `data` on `/srv/samba/data`, `/etc/samba/smb.conf` | `mkosi.profiles/samba/` |
| `openssh` | `openssh-server` | port 22, `/root/.ssh/authorized_keys` | `mkosi.profiles/openssh/` |
| `prometheus` | `prometheus` | port 9090, `/var/lib/prometheus`, `/etc/prometheus` | `mkosi.profiles/prometheus/` |
| `node-exporter` | `prometheus-node-exporter` | port 9100 | `mkosi.profiles/node-exporter/` |
| `grafana` | `grafana` (Grafana Labs' repository) | port 3000, `/var/lib/grafana`, `/etc/grafana` | `mkosi.profiles/grafana/` |

They are full Debian machines with the service installed and enabled: `nspawn shell`
gets a root shell, `systemctl status nginx` inside says what it is doing, the paths above
are what to mount with `-v` to keep data and configuration on the host, and `-p` publishes
the port. Security updates come from Debian; the weekly rebuild picks them up.

Where Debian's default is to listen on localhost only, the images listen on every address
of the machine instead, as container images do: the machine is the boundary, and nothing
reaches it unless a port is published. Authentication stays as Debian ships it, so set a
password before publishing a port to the outside: PostgreSQL takes password logins from
the network once `ALTER USER postgres PASSWORD '...'` has run, MariaDB's root logs in
through the socket and network users are created from there, Valkey has no password until
`requirepass` is set, Mosquitto allows anonymous clients until a password file is added,
RabbitMQ's guest account works from localhost only, Grafana starts with admin/admin, Samba's
`data` share is open to guests, and the OpenSSH image only lets root in with a key (mount
your `authorized_keys` at `/root/.ssh/authorized_keys`) and makes its host keys on the first
boot, so machines do not share them. The DNS images (unbound, dnsmasq, bind9) turn off
systemd-resolved's stub listener so that they own port 53.

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
mkosi.profiles/<service>/  a service on the Debian image: its packages, its units, its text
mkosi.repart/              partitions of the disk variant
mkosi.bump                 the image version: the build date
.github/workflows/mkosi.yml   the matrix, one job per image
```

## Changing an image

Edit the packages or the `mkosi.postinst.chroot` of the distribution and open a pull
request: the workflow builds every image of the matrix and keeps the package manifest of
each as an artifact, without pushing anything. Once merged to `master` the same workflow
builds again and pushes to the hub; it also runs every Sunday to pick up package updates.

To add a service, add a profile under `mkosi.profiles/` (packages, a `mkosi.postinst.chroot`
that enables the units, the image id and the text) and a matrix entry with the package
whose version becomes the tag.

To add a distribution or release, add its directory under `mkosi.conf.d/` (and a kernel
entry under `mkosi.profiles/disk/mkosi.conf.d/` if it should have a disk variant) and an
entry in the matrix of the workflow with the tags the hub should show.
