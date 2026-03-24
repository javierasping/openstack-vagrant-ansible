#!/usr/bin/env bash
set -euo pipefail

virsh net-info mgmt-net >/dev/null 2>&1 || virsh net-define mgmt-net.xml || true
virsh net-info provider >/dev/null 2>&1 || virsh net-define provider.xml || true

for net in mgmt-net provider; do
  virsh net-start "$net" >/dev/null 2>&1 || true
  virsh net-autostart "$net" >/dev/null 2>&1 || true
done
