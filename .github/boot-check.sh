#!/bin/sh
# Boot a built image as a machine and check that it comes up: systemd reaches "running"
# with no failed unit, and the machine answers on its D-Bus, which nspawn shell needs.
# Runs as root, on the OCI layout mkosi wrote:
#
#   sudo .github/boot-check.sh mkosi.output/fedora_20260922_x86-64
#
# The machine is connected as nspawn connects one to its bridge: a veth, and a
# host0.network with a fixed address bound into /run/systemd/network, so that
# systemd-networkd brings host0 up and a service that waits for network-online.target
# (nginx, for one) does not time out. It reaches nothing beyond the host's end of the
# veth: the check is the boot, not the network.
set -eu

layout=$1
machine=boot-check
veth=ve-$machine

fail() {
	echo "boot check failed: $*" >&2
	exit 1
}

work=$(mktemp -d /var/tmp/boot-check.XXXXXX)
cleanup() {
	systemctl stop "$machine.service" 2>/dev/null || true
	rm -rf "$work"
}
trap cleanup EXIT

# The single layer of the image, a zstd tar of the whole tree.
layer=$(python3 - "$layout" <<'EOF'
import json, sys
layout = sys.argv[1]
manifest = json.load(open(layout + "/index.json"))["manifests"][0]["digest"].split(":")[1]
print(json.load(open(f"{layout}/blobs/sha256/{manifest}"))["layers"][0]["digest"].split(":")[1])
EOF
)
mkdir "$work/root"
zstd -dc "$layout/blobs/sha256/$layer" |
	tar -x --numeric-owner --xattrs --xattrs-include='*' -C "$work/root"

# Every machine made from the image has to get its own ID on its first boot.
id=$(cat "$work/root/etc/machine-id" 2>/dev/null || true)
case $id in
'' | uninitialized) ;;
*) fail "the image ships a machine ID ($id)" ;;
esac

cat >"$work/host0.network" <<'EOF'
[Match]
Name=host0

[Network]
Address=10.99.0.2/24
Gateway=10.99.0.1
LLMNR=yes
LinkLocalAddressing=no
IPv6AcceptRA=no
EOF

# The console goes to the unit's journal, which is printed if the machine never answers.
systemd-run --quiet --collect --unit="$machine" \
	systemd-nspawn --quiet --directory="$work/root" --machine="$machine" --boot \
	--network-veth --bind-ro="$work/host0.network:/run/systemd/network/10-host0.network"

# The host's end of the veth exists once systemd-nspawn has set the machine up, and
# host0 only gets a carrier when it is up.
i=0
until ip link show "$veth" >/dev/null 2>&1; do
	i=$((i + 1))
	[ "$i" -le 30 ] || fail "systemd-nspawn made no $veth"
	sleep 1
done
ip link set "$veth" up
ip address replace 10.99.0.1/24 dev "$veth"

# The machine's bus comes up a moment after its systemd does; until then systemctl -M
# answers nothing.
i=0
until [ -n "$(systemctl -M "$machine" is-system-running 2>/dev/null || true)" ]; do
	i=$((i + 1))
	if [ "$i" -gt 60 ]; then
		journalctl -u "$machine.service" --no-pager -n 100 || true
		fail "the machine's D-Bus never answered"
	fi
	sleep 1
done

state=$(timeout 300 systemctl -M "$machine" is-system-running --wait 2>/dev/null || true)
echo "$machine: ${state:-no answer}"
if [ "$state" != running ]; then
	systemctl -M "$machine" list-jobs --no-pager || true
	for unit in $(systemctl -M "$machine" list-units --failed --plain --no-legend | cut -d' ' -f1); do
		systemctl -M "$machine" status "$unit" --no-pager --full --lines=30 || true
	done
	fail "systemd is ${state:-not answering}, not running"
fi

# What nspawn shell asks of a machine: machined reaches its systemd, which runs a
# command for it.
systemd-run -M "$machine" --quiet --wait /usr/bin/true || fail "the machine runs no command"
echo "$machine: boots, and runs commands"
