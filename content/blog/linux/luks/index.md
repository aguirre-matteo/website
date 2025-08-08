---
title: "Protecting your files with LUKS"
description: "Explore how to use LUKS to fully encrypt your sensitive data."
categories: ["linux"]
tags: ["luks", "encryption", "privacy", "cryptsetup", "crypttab"]
---

## Overview
Securing our private data from a bare-metal attack is
extremely important if we want to ensure privacy. This
is especially the case on laptops, since they're in 
constant exposure to the external world, and on enterprise
and governmental computers, where a leak of information
could compromise the personal data of a large number
of persons. LUKS is currently the most powerful and widely
adopted solution for disk encryption on Linux. In this guide
I'll show you how to use LUKS to encrypt your disks, how to
configure it to automatically mount on boot, and how to manage
different passphrases to unlock the partition.

## Requirements
Before continuing with the guide, we should first install
the `cryptsetup` package, which provides the utilities for
managing LUKS. 

If we are using Debian/Ubuntu we must run:
```shell
sudo apt install cryptsetup
```

Or in the case we're using a Fedora/RHEL derivative:
```shell
sudo dnf install cryptsetup-luks
```

We'll also be using `parted` for partitioning the disk, so 
make sure you have it installed, or use your prefered
tool.
```shell
sudo apt install parted # Debian/Ubuntu
sudo dnf install parted # Fedora/RHEL
```

## Creating an encrypted partition
Open the terminal and find which disk/partition you want to encrypt.
In my case, I have two virtual disks, `vda` and `vdb`, and I'll use
the last to store my sensitive data.
```shell
[root@nixos:~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
vda    253:0    0   20G  0 disk 
├─vda1 253:1    0  1.9G  0 part 
└─vda2 253:2    0 18.1G  0 part 
vdb    253:16   0   20G  0 disk 
```

The first step is to format the disk/partition as a LUKS device. To 
do so we have to run `cryptsetup luksFormat /dev/disk` and set the 
passphrase we want to use to protect the data.
```shell
[root@nixos:~]$ cryptsetup luksFormat /dev/vdb

WARNING!
========
This will overwrite data on /dev/vdb irrevocably.

Are you sure? (Type 'yes' in capital letters): YES
Enter passphrase for /dev/vdb: 
Verify passphrase: 

[root@nixos:~]$ 
```

This completely wiped the disk, so all the data that was there now
is lost. To start working with it, we have to unlock the device
using the `cryptsetup open` command.
```shell
[root@nixos:~]$ cryptsetup open /dev/vdb encrypted-disk
Enter passphrase for /dev/vdb: 

[root@nixos:~]$ 
```

I'll call it `encrypted-disk` so it's more easy to recognize it. Now
the device is available under `/dev/mapper/encrypted-disk`. Replace
the last part with the name you gave. I'll format it as a BTRFS 
filesystem and mount it at `/mnt`
```shell
[root@nixos:~]$ mkfs.btrfs /dev/mapper/encrypted-disk 
btrfs-progs v6.11
See https://btrfs.readthedocs.io for more information.

NOTE: several default settings have changed in version 5.15, please make sure
      this does not affect your deployments:
      - DUP for metadata (-m dup)
      - enabled no-holes (-O no-holes)
      - enabled free-space-tree (-R free-space-tree)

Label:              (null)
UUID:               35cf0855-f5d6-4fe8-b773-808bbefb8493
Node size:          16384
Sector size:        4096	(CPU page size: 4096)
Filesystem size:    19.98GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP             256.00MiB
  System:           DUP               8.00MiB
SSD detected:       no
Zoned device:       no
Features:           extref, skinny-metadata, no-holes, free-space-tree
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH                      
    1    19.98GiB  /dev/mapper/encrypted-disk


[root@nixos:~]$ mount /dev/mapper/encrypted-disk /mnt/

[root@nixos:~]$ 
```

And if we want to umount it, we should run `umount` and
`cryptsetup close`.
```shell
[root@nixos:~]$ umount /mnt 

[root@nixos:~]$ cryptsetup close encrypted-disk 

[root@nixos:~]$ 
```

## Mounting on boot
Cryptsetup has it own `fstab`-like config file where we can declare
all the encrypted devices we want to unlock during the boot. We 
can find it at `/etc/crypttab` and the syntax of each line is like
it follows:
```crypttab
volume-name device key-file options
```

In our example, I should configure it like this, using the UUID of 
the disk to identify it. We can get the UUID running `cryptsetup luksUUID`.

```shell
[root@nixos:~]$ cryptsetup luksUUID /dev/vdb 
283c80cf-04ee-42f4-afe8-4b51bc124498
```

On `/etc/crypttab`:
```crypttab
encrypted-disk UUID=283c80cf-04ee-42f4-afe8-4b51bc124498 none luks
```

Now we add an entry to `/etc/fstab` to mount it automatically on boot:
```shell
/dev/mapper/encrypted-disk /mnt btrfs defaults 0 2
```

And the last step is to update the initram so the changes are applied:
```shell
update-initramfs -u -k all
```

## Managing passphrases
LUKS permits us to set multiple keys to unlock the encrypted disk,
allowing for more flexibility. Cryptsetup provides commands for both
adding and removing passphrases from the disk.

### Add key
To add a new passphrase to our setup, we can use the `cryptsetup luksAddKey` command, followed by the device we want to modify.

```shell
[root@nixos:~]$ cryptsetup luksAddKey /dev/vda 
Enter any existing passphrase: 
Enter new passphrase for key slot: 
Verify passphrase: 

[root@nixos:~]$ 
```

It will prompt us to enter the already existent passphrase we've set up, and the new passphrases we want to add.

### Remove key
To remove a passphrase from the LUKS device, we use `cryptsetup luksRemoveKey` and pass the device as the argument.

```shell
[root@nixos:~]$ cryptsetup luksRemoveKey /dev/vda 
Enter passphrase to be deleted: 

[root@nixos:~]$ 
```

It will ask us for the passphrase we want to remove and it will delete it from the list.

## Conclusion
In this article I've showed you all the commands related to
LUKS you need to know to encrypt a disk to protect sensitive
data. If you find this guide useful, feel free to share it to
other people or recommend the page. Have a nice day!
