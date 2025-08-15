# 192.168.188.150 - pve

## Storage
Name             Type     Status           Total            Used       Available        %
local             dir     active        12822812         3518948         8630688   27.44%
local-lvm     lvmthin     active        11034624               0        11034624    0.00%

## Network
-   active: 1
    address: 192.168.188.150
    autostart: 1
    bridge_fd: '0'
    bridge_ports: enp0s3
    bridge_stp: 'off'
    cidr: 192.168.188.150/24
    families:
    - inet
    gateway: 192.168.188.1
    iface: vmbr0
    method: static
    method6: manual
    netmask: '24'
    priority: 4
    type: bridge
-   active: 1
    altnames:
    - enx0800275076b2
    exists: 1
    families:
    - inet
    iface: enp0s3
    method: manual
    method6: manual
    priority: 3
    type: eth


## IP addresses
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
1: lo    inet6 ::1/128 scope host noprefixroute \       valid_lft forever preferred_lft forever
3: vmbr0    inet 192.168.188.150/24 scope global vmbr0\       valid_lft forever preferred_lft forever
3: vmbr0    inet6 fe80::a00:27ff:fe50:76b2/64 scope link proto kernel_ll \       valid_lft forever preferred_lft forever

## Proxmox version
pve-manager/9.0.3/025864202ebb6109 (running kernel: 6.14.8-2-pve)

## Block devices
NAME                SIZE TYPE MOUNTPOINT
sda                29.1G disk 
├─sda1             1007K part 
├─sda2              512M part 
└─sda3             28.6G part 
  ├─pve-swap        3.5G lvm  [SWAP]
  ├─pve-root       12.5G lvm  /
  ├─pve-data_tmeta    1G lvm  
  │ └─pve-data     10.5G lvm  
  └─pve-data_tdata 10.5G lvm  
    └─pve-data     10.5G lvm  
sdb                29.5G disk 
├─vg0-tp0_tmeta      32M lvm  
│ └─vg0-tp0-tpool  29.4G lvm  
│   ├─vg0-tp0      29.4G lvm  
│   ├─vg0-thinlv1    10G lvm  
│   └─vg0-thinlv2    10G lvm  
└─vg0-tp0_tdata    29.4G lvm  
  └─vg0-tp0-tpool  29.4G lvm  
    ├─vg0-tp0      29.4G lvm  
    ├─vg0-thinlv1    10G lvm  
    └─vg0-thinlv2    10G lvm  
