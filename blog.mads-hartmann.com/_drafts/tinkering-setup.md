---
layout: post
title: "Tinkering: Setup"
date: 2022-08-27 12:00:00
colors: pinkred
excerpt_separator: <!--more-->
---

Since joining Gitpod in April 2021 I haven't done **any** development locally. It's been incredibly liberating not having to install and manage fragile development environments.

It's gotten to a point where I really go to great lengths to avoid having to install anything on my Mac; I even went 6 months without installing Homebrew, and I still haven't configured my dotfiles.

However, for now, there are a few things you can't run in Gitpod. Most importantly for me, a full functionen Kubernetes "cluster". This is a short post about the setup I use for those situations.

<!--more-->

The TL;DR is that I use [Tailscale](https://tailscale.com/) to manage a private network within which I connect my Mac, my Gitpod workspaces, and a Linux box where I can run things like Kubernetes.

In general, any tools I need for development I'll install in the Gitpod workspace. Any services that I need during development that I can't run insidew of Gitpod I'll install on the Linux box. My Mac is for the most part just an overpowered - but very lovely - thin client.

1. Gitpod workspaces: See [github.com/mads-hartmann/new](https://github.com/mads-hartmann/new). The environment is based off gitpod/workspace-full ([docs](https://www.gitpod.io/docs/config-docker)) and only adds tailscale. The workspaces have been configured to connect to my tailscale network using a [Tailscale Auth Key](https://tailscale.com/kb/1085/auth-keys/) and the hostname is set to the Gitpod Workspace ID. The Auth key is Ephemeral, meaning that Tailscale will remove it from the network when it has been inactive for a while.
1. Linux server: It is running Ubuntu and also has tailscale running. This is where I'll install anything I can run in Gitpod (kubenetes clusters mainly).
1. MacBook Pro: For the most part this is pretty much just an overpowered - but very lovely - thin client. It also runs tailscale.

Now, this setup is only really needed if there are things you can't run in your Gitpod workspace for whatever reason; if I just want to `sudo apt-get` or `curl | bash` yolo-install some software to take it for a spin then I'll simply use https://gitpod.new and close the workspace when I'm done playing around.

## But isn't your Linux box just your dev box?

You're right. I'm relying on a single shared resource between many Gitpod workspaces which is undermining the ephemerality of the Gitpod workspaces, and does indeed mean that I have to manage my Linux box as you would a traditional development machine.

In my case that's okay. I run as much as possible in Gitpod and I mainly run a Kubernetes cluster and a few other things on the Linux box; besides, this is only for doing a bit of hobby development and tinkering with new tools like acorn.io.

However, if your development flow is tightly coupled with the resources you can't run in Gitpod, it's worht investing some energy into ensuring that those resoruces can share a lifecycle with Gitpod workspaces. This is what we do at Gitpod. We spin up VMs with a k3s cluster for each branch in gitpod-io/gitpod so that people have a cluster avaiable to use during development, if needed.


## Mac <> Gitpod connection test

### Mac setup

```sh
# Make the CLI available
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# List nodes
tailscale status

# SSH to a node
ssh <device ip>

# Get ip of specific node
tailscale ip <device name> 
```

### Gitpod setup

See [mads-hartmann/new](https://github.com/mads-hartmann/new).

1. `tailscale` is installed in the workspace.
2. It's configured to connect to the network on startup using the Workspace ID as the hostname. It uses an emphereal auth key I have created in keys (https://login.tailscale.com/admin/settings/keys) and added as an environment variable `TAILSCALE_AUTH_KEY`

### SSH

SSH doesn't work with Gitpod

ssh gitpod@100.97.252.131 results in Unable to change owner or mode of tty stdin: Operation not permittedConnection to 100.97.252.131 closed.

https://github.com/gitpod-io/gitpod/issues/11195

### Connecting

Testing the connection using `nc` - first with my MBP as the host:

```
# MBP
nc -l 0.0.0.0 8080

# Workspace
sudo apt-get install netcat
nc "$(tailscale ip --1 mbp)" 8080
```

And the other way around 

```
# Workspace
nc -l 0.0.0.0 8080

# MBP
nc "$(tailscale ip --1 madshartmann-new-xvq3ore8bs4)" 8080
```
