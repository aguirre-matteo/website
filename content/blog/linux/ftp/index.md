---
title: "Sharing files across the network with FTP"
description: "Learn how to setup your own FTP server to remotely accessing your files"
categories: ["linux"]
tags: ["ftp", "network", "server", "vsftpd", "file sharing"]
---

## Overview
FTP (File Transfer Protocol) is an Internet protocol used to transfer files
between different machines over a network. It follows the client-server model
where a client installs an FTP client app to connect to a remote FTP server. In this guide, you'll learn how to setup your own FTP
server and access it through different clients.

## Security concerns
The FTP protocol is in disuse due to some major security issues,
like the lack of encryption, vulnerable to brute-force attacks since
it doesn't have stronger authentication mechanism than usernames and passwords,
and being susceptible to DDoS attacks. In most cases it's highly recommended 
to use more secure alternatives like SFTP or FTPS, so take this post just as 
an educational piece of information, and don't follow the steps if you are
setting up a sever in production.

## Setup

### Installation
The first thing we should do is to install the `vsftpd` package,
which we can do running:

In Debian/Ubuntu distributions:
```shell
sudo apt install vsftpd
```

Or on RedHat-based systems:
```shell
sudo dnf install vsftpd
```

The server should start automatically, but if that's not the case
we can start it manually doing:

```shell
sudo systemctl enable vsftpd
sudo systemctl start vsftpd
```

And of course, if we have previously configured a firewall, we have
to open ports `20` and `21`:

```shell
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
```

### Configuration
In my case, I'll configure the server to allow accessing both with
a username and a password, and anonymously. First, let's create 
the users we want to expose through the server. I'll call them
`teachers` and `lab-students`:

```shell
sudo useradd -m teachers
sudo useradd -m lab-students
sudo passwd teachers
sudo passwd lab-students
```

And setup the directories we'll serve:

```shell
mkdir -p /srv/ftp/public
chmod 555 /srv/ftp/public
chown ftp:ftp /srv/ftp/public

mkdir -p /home/{lab-students,teachers}/ftp
chmod 755 /home/{lab-students,teachers}/ftp
chown lab-students:lab-students /home/lab-students/ftp
chown teachers:teachers /home/teachers/ftp
```

Now, let's open `/etc/vsftpd.conf` and write the following lines
to the file:

```vsftpd.conf
# Enable anonymous access
anonymous_enable=YES
no_anon_password=YES

# Setup the public directory as read-only
anon_root=/srv/ftp/public
anon_upload_enable=NO
anon_mkdir_write_enable=NO
anon_other_write_enable=NO

# Vsftpd will replace this token with the respective username
user_sub_token=$USER

# The directory the daemon must serve
local_root=/home/$USER/ftp

# This allows logging in as local users
local_enable=YES

# Gives clients write permissions
write_enable=YES

# Makes sure users don't access each others files
chroot_local_user=YES

# Configures the list of users we'll allow logging in as
userlist_enable=YES

# Deny accessing as any other users
userlist_deny=NO
```

And in `/etc/vsftpd.user_list` we write the usernames:

```vsftpd.userlist
teachers
lab-students
```

And finally restart the service so it reloads the configuration:

```shell
sudo systemctl restart vsftpd
```

## Connecting to the server
Now, to connect to our FTP server we must use an FTP client software.
There are GUI frontends out there, like Filezilla and WinSCP, but I'll 
use a CLI client called `lftp`, which we can install running:

```shell
sudo apt install lftp # Debian/Ubuntu
sudo dnf install lftp # Fedora/RHEL
```

We run `lftp` followed by the IP address of our remote server and we'll 
be connected to it.

```shell
[matteo@nixos:~]$ lftp 192.168.122.2
lftp 192.168.122.2:~> 
```

By default, we'll login anonymously, so if try to list the contents of
the current directory, it will show the public available files:

```shell
lftp 192.168.122.2:~> ls
-rw-r--r--    1 0        0              31 Aug 23 14:24 my.txt
-rw-r--r--    1 0        0              26 Aug 23 14:24 public.txt
-rw-r--r--    1 0        0              26 Aug 23 14:24 files.txt
lftp 192.168.122.2:~> 
```

Now to login as a specific user we type `login` followed by the username.
We'll be prompted to enter it's respective password.

```shell
lftp 192.168.122.2:~> login teachers
Password: 
lftp teachers@192.168.122.2:~>
```

The FTP shell provides commands such as `mkdir`, `rmdir`, `put`
and `get` which we can use to perform those respective operations
in the filesystem.

```shell
lftp teachers@192.168.122.2:~> ls
-rw-r--r--    1 0        0              31 Aug 23 14:24 another.txt
-rw-r--r--    1 0        0              26 Aug 23 14:24 message.txt
lftp teachers@192.168.122.2:~> mkdir a b c
mkdir ok, 3 directories created
lftp teachers@192.168.122.2:~> get message.txt 
26 bytes transferred
lftp teachers@192.168.122.2:~> put ./local.txt 
7048 bytes transferred
lftp teachers@192.168.122.2:~> ls
drwx------    2 1001     1001         4096 Aug 23 14:25 a
-rw-r--r--    1 0        0              31 Aug 23 14:24 another.txt
drwx------    2 1001     1001         4096 Aug 23 14:25 b
drwx------    2 1001     1001         4096 Aug 23 14:25 c
-rw-------    1 1001     1001            0 Aug 23 14:26 local.txt
-rw-r--r--    1 0        0              26 Aug 23 14:24 message.txt
lftp teachers@192.168.122.2:~> exit 

[matteo@nixos:~]$ cat ./message.txt 
Hello from my FTP server!

[matteo@nixos:~]$
```

All the available commands can be found running `help` in the FTP shell.

## Conclusion
This guides briefly shows how to setup a simple FTP server
from scratch, covering how to configurate different users
and how to connect to the server via a CLI FTP client.
If you find this guide useful, feel free to share it to 
somebody else or recommend the page. Have a nice day!
