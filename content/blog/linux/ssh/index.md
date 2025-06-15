---
title: "How to use SSH from Scratch"
description: "Learn how to use and configure SSh to connect to your servers."
categories: ["linux"]
tags: ["ssh", "privacy"]
---

## Overview
SSH (Secure SHell) is a protocol designed to securely communicate with a remote computer.
It validates the identity of user and encrypts all the data is send between the devices. It's
widely used to run commands on a server over the internet and transfer files in a secure way. In
this guide, I'll show you how to install SSH, configure it, and how you can use it to connect to your servers.

## Basic Syntax
The basic syntax for using the SSH command is as follows:

```shell
ssh [username]@[ip-address]
```

Where we replace `username` with your remote server username, and `ip-address` with the server's IP address.

## Setup

### Installation
Depending if we're on our server, or on our local machine, we have to install the `openssh-server` and `openssh-client` packages respectively.

In the case of Debian/Ubuntu-based system, we open the terminal and run:
```shell
sudo apt install openssh-server
sudo apt install openssh-client
```

Or if we are using RHEL or a derivative, we run instead:
```shell
sudo dnf install openssh-server
sudo dnf install openssh-clients
```

Then we should start the SSH service on our server. We do so running the following commands:

```shell
sudo systemctl enable ssh # Enables the service, starting at system boot.
sudo systemctl start ssh # Manually starts the service.
```

If we have a firewall enabled, we should also open the port 22, so
we can reach our SSH server. For example, if we're using `ufw`, we can open the port running this command:

```shell
# UFW will translate SSH to port 22
sudo ufw allow ssh
```

### Server Configuration
Now that we have installed SSH, it's time to tweak its config file.
We can find it at `/etc/ssh/sshd_config`. It provides a large number of
options which we can find in the manual running `man sshd_config`. Here
I show you an example configuration, which modifies the most commonly used options:

```sshd_config
# Which port SSH should use. It's highly recommended to keep it
# at 22, since it could break your setup.
Port 22

# Prevents the clients from login as root. Keep this at false,
# and use sudo instead when needed.
PermitRootLogin no

# Enables Public Key Autentication, making it posible to login 
# using a SSH key instead of using a password.
PubkeyAutentication yes

# You'll only be able to auth to your server using SSH keys.
# Make sure you add your keys before disabling this.
PasswordAuthentication no

# Users the clients are allowed to login as.
# Other users will be disabled.
AllowUsers myssh-user another_user
AllowGroups ssh_users

# Users the clients shouldn't be able to login as.
# Other users will be enabled.
DenyUsers root
DenyGroups important_users
```

After editing the file, we should restart the SSH service running `sudo systemctl restart ssh`.

## Remote Access
Now that our server is configured, we can connect to it using the `ssh` command. In this example, I access a Debian virtual machine:

```shell
[matteo@nixos:~]$ ssh myssh-user@192.160.122.230
myssh-user@192.160.122.230's password: 
Linux deb-homelab 6.1.0-37-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.140-1 (2025-05-22) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sat May 31 15:56:13 2025 from 192.160.122.13
myssh-user@deb-homelab:~$
```

Add your username in place of `myssh-user` and add your server's IP in place of `192.160.122.230`, and enter the password of the user you specified.

If it's the first time you're connecting to the server, you'll be prompted
to verify the server's authenticity, seeing a message like this:

```shell
The authenticity of host '192.160.122.230 (192.160.122.230)' can't be established.
ECDSA key fingerprint is SHA256:ontibF1aG+nkeuyXhEO4zKJFfcWgJoX9TVUUdzdENk.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

We have to type `yes` and press Enter, then the server will be added to our list of known hosts.

## SSH Keys
SSH keys are a more powerful method to authenticate to your servers,
making your connection more secure and allowing to login without being
asked for the password. To use SSH keys we first have to generate a
public-private key pair. To do so we use the `ssh-keygen` command.
We'll be prompted to enter the path where we want to save the key pair.
I'll save mine at `~/.ssh/` and call it `myserver`.

```shell
[matteo@nixos:~]$ ssh-keygen 
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/matteo/.ssh/id_ed25519): /home/matteo/.ssh/myserver
Enter passphrase for "/home/matteo/.ssh/myserver" (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/matteo/.ssh/myserver
Your public key has been saved in /home/matteo/.ssh/myserver.pub
The key fingerprint is:
SHA256:lNjTQHE+ojhhdlI9BwoGJKgpt/AjQPNJEtgIUmkI9sQ matteo@nixos
The key's randomart image is:
+--[ED25519 256]--+
|XO*+o .o=o.      |
|B=*E o +o*.      |
|oo=.* + *o+      |
|* .= = o o .     |
|o+ .o . S        |
|. +  .           |
| . .             |
|                 |
|                 |
+----[SHA256]-----+

[matteo@nixos:~]$
```

If we want, we can enter a passphrase for our private key, enhancing the 
security of the connection. Otherwise leave it empty. Now it's time to
add our keys to our server using the `ssh-copy-id` command.

```shell
[matteo@nixos:~]$ ssh-copy-id -i ~/.ssh/myserver myssh-user@192.160.122.230
/run/current-system/sw/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/matteo/.ssh/myserver.pub"
/run/current-system/sw/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/run/current-system/sw/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
myssh-user@192.160.122.230's password: 

Number of key(s) added: 1

Now try logging into the machine, with: "ssh -i /home/matteo/.ssh/myserver 'myssh-user@192.160.122.230'"
and check to make sure that only the key(s) you wanted were added.

[matteo@nixos:~]$
```

We enter the password for the last time, and then it'll print in the screen
that our keys were successfully added. Now we can connect to our server using the `-i` flag, followed by the path to the key.

```shell
[matteo@nixos:~]$ ssh -i ~/.ssh/myserver myssh-user@192.160.122.230 
Linux deb-homelab 6.1.0-37-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.140-1 (2025-05-22) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sun Jun  1 18:39:37 2025
myssh-user@deb-homelab:~$ 
```

And *voila*! We wasn't prompted for entering the password! 

## File Transfer
SSH allows us to access the filesystem of our remote server in a safe way,
encrypting the files, ensuring no one without permissions can read the contents.
We'll use the `scp` and `sftp` commands to take advantage of SSH's features to
work with our server's files.

### SCP
STP stands for Secure Copy and, as the name suggests, `scp` is an extended version of the
`cp` command which can be used to copy files from our server. The syntax of `scp` is the
same as the `cp` command:

```shell
scp [from] [to]
```

Where both `from` and `to` can be in an extended form of SSH's target syntax,
which uses a `:` to specify the path:

```shell
[username]@[ip-address]:/path/to/file
```

For example, if we want to copy a shell script to our server, we'll
do something like this:

```shell
[matteo@nixos:~]$ scp ./bash-script.sh \
myssh-user@192.160.122.230:/home/myssh-user/scripts/ \
-i /home/matteo/.ssh/myserver
bash-script.sh                             100%   83    26.7KB/s   00:00 

[matteo@nixos:~]$
```

Since we're using an SSH key to connect to the server, we weren't prompted to
enter the password. We can also copy entire directories using the `-r` flag.
For example, if we want to copy all the logs from the server to our computer,
we do the following:

```shell
[matteo@nixos:~]$ scp -r myssh-user@192.160.122.230:/var/log/ ./logs \
-i /home/matteo/.ssh/myserver

[matteo@nixos:~]$ ls log/
alternatives.log       dpkg.log       fontconfig.log  private
alternatives.log.1     dpkg.log.1     installer       README
alternatives.log.2.gz  dpkg.log.2.gz  journal         runit
apt                    faillog        lastlog         wtmp

[matteo@nixos:~]$
```

### SFTP 
SFTP stands for Secure File Transfer Protocol. It's an improved version of the FTP
protocol to use SSH to encrypt the communication, and it allows us to interactively
access the remote filesystem providing commands like `ls`, `cd`, `mkdir`, `rm`, amoung
others. To use it we have to run `sftp` and pass our server as the argument:

```shell
[matteo@nixos:~]$ sftp myssh-user@192.168.122.160 \
-i /home/matteo/.ssh/myserver
Connected to 192.168.122.160.
sftp> 
```

By default, `sftp` will put us in the user's home directory. We can verify so
typing `pwd` in the new shell:

```shell
sftp> pwd
Remote working directory: /home/myssh-user
sftp> 
```

I have some Markdown files that I want to copy to the server. To do so we
can use the `put` command, followed by the name of the files. Some commands
related to the FS can be executed locally prefixing them with the letter `l`,
such as `ls`, `cd`, `mkdir`, `pwd` and `umask`.

```shell
sftp> lls
nixos-hardware.md  ssh-tutorial.md
sftp> put nixos-hardware.md 
Uploading nixos-hardware.md to /home/ami/nixos-hardware.md
nixos-hardware.              100%    0     0.0KB/s   00:00    
sftp> put ssh-tutorial.md 
Uploading ssh-tutorial.md to /home/ami/ssh-tutorial.md
ssh-tutorial.            100%    0     0.0KB/s   00:00    
sftp> ls
nixos-hardware.md   ssh-tutorial.md     
sftp> 
```

Now if for some reason I've lost those files, I can copy them back with
the `get` command.

```shell
sftp> lls
sftp> get nixos-hardware.md 
Fetching /home/ami/nixos-hardware.md to nixos-hardware.md
sftp> get ssh-tutorial.md 
Fetching /home/ami/ssh-tutorial.md to ssh-tutorial.md
sftp> lls
nixos-hardware.md  ssh-tutorial.md
sftp> 
```

To see all the available commands in `sftp` we can type `help`
and press enter.

## Client Configuration
We may face some situations where we are constantly accessing to the same
server, and it becomes repetitive to write the same username and IP address
over and over again. To those cases, SSH allows up to create a config file
under ~/.ssh/config to declare our servers so we can use an alias instead
of running the entire command. These declarations uses the following syntax:

```ssh_config
Host <alias>
    Hostname <ip-address>
    User <username>
    IdentityFile <path>
    ...

Host <alias>
    Hostname <ip-address>
    User <username>
    IdentityFile <path>
    ...
```

In our example, we could declare the server and call it `myserver`, setting the
IP address, the username and the path to the SSH key respectively:

```ssh_config
Host myserver
    Hostname 192.160.122.230
    User myssh-user
    IdentityFile /home/matteo/.ssh/myserver
```

So now we can simply pass `myserver` as the argument to `ssh` and it will
automatically translate the alias to the real target and will use our
key.

```shell
[matteo@nixos:~]$ ssh myserver 
Linux deb-homelab 6.1.0-37-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.140-1 (2025-05-22) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Fri Jun  6 18:17:48 2025
myssh-user@deb-homelab:~$
```

## Conclusion
In this article I've showed all you need to known to start using SSH to connect
to your servers. It covers how to connect to your servers, install and configure
a SSH server, how to use use SSH keys to authenticate and how to transfer files
from one machine to another. If you find this article useful, feel free to share
it to someone else or recommend my page. Have a nice day!
