---
layout: post
title: "Tinkering: Setup"
date: 2022-08-27 12:00:00
colors: pinkred
excerpt_separator: <!--more-->
---

Since I've moved all my development to Gitpod I **really** dislike installing anything on my Mac; I even went half a year before even installing Homebrew.

However, you can't run everything in Gitpod (yet), so for the rare occacions where I need to connect to something during development that I can't run in Gitpod I have created a private tailscale network that still allows me to do most things in Gitpod.

<!--more-->

My setup consists of three components that are all connected through a private Tailscale network.

1. Gitpod workspaces: See [github.com/mads-hartmann/new](https://github.com/mads-hartmann/new). The environment is based off gitpod/workspace-full ([docs](https://www.gitpod.io/docs/config-docker)) and only adds tailscale. The workspaces have been configured to connect to my tailscale network using a [Tailscale Auth Key](https://tailscale.com/kb/1085/auth-keys/) and the hostname is set to the Gitpod Workspace ID. The Auth key is Ephemeral, meaning that Tailscale will remove it from the network when it has been inactive for a while.
1. Linux server: It is running Ubuntu and also has tailscale running. This is where I'll install anything I can run in Gitpod (kubenetes clusters mainly).
1. MacBook Pro: For the most part this is pretty much just an overpowered - but very lovely - thin client. It also runs tailscale.

Now, this setup is only really needed if there are things you can't run in your Gitpod workspace for whatever reason; if I just want to `sudo apt-get` or `curl | bash` yolo-install some software to take it for a spin then I'll simply use https://gitpod.new and close the workspace when I'm done playing around.
