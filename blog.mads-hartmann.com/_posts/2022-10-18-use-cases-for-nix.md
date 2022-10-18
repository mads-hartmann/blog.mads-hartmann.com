---
layout: post-no-separate-excerpt
title: "Use cases for Nix"
date: 2022-10-18 10:00:00
colors: pinkred
---

I have been vaguely aware of Nix for several years but never really took the time to sit down and play around with it until recently. I originally started writing an intro-style blog-post about Nix as a way to document my learning path but the post just kept growing and growing in scope. It got to a point where - with the limited spare time I have these days - I would never be able to finish it. So instead I thought I'd simply start by writing about why I'm interested in Nix and what problems I'm hoping that it can help me solve.

I have three primary use-cases: Declarative developer environments, building and sharing tools, and managing my personal development server.

## Declarative Developer Environments

To be fair "Developer Environments" is a rather loosely defined term, and as far as I can tell, Nix can only help with a sub-set of what I'd consider a "Developer Environment". Even so, it's an important part. I'm hoping to use Nix to install all the tools that I need, and do so in a **declarative** and **reproducible** way.

The industry seems to have standardized on using container images as a way to package developer environments and I can understand why: It's very flexible and there is a whole ecosystem of great tools and services that developers already know how to use.

However, I have two qualms about using container images:

1. The images are not necessarily reproducible as they usually use `apt-get`.
2. Updating these images is (currently) rather tedious and slow, forcing you to think about details such as layer ordering when all you want to do is just install a bunch of tools.

So far I'm experimenting with using a minimal container image which primarily contains Nix, and then use Nix itself to install all the remaining tools. This works quite well when you're using Gitpod (my employer) though there are a few things we could improve to make the experience better - see my current explorations in the README of [mads-hartmann/new](https://github.com/mads-hartmann/new).

I'm especially interested in declarative developer environments for monorepos where many teams have to co-exist and might need different tools installed as they're working on different services and perform different tasks. This is one case where the one-size-fits-all approach of container images seems to be a bit challenging, and as far as I can tell, Nix is well suited for this use-case. I haven't done any experiments in this area yet though. If you have, please reach out and I'd be happy to link to any relevant blog posts or resources on this topic below.

## Building and sharing tools

From what I understand so far, you get "publishing" for free if you're using Nix to build your tools as users simply have to point to your Git repository and the path of the relevant Nix derivation and it will take care of building the tool in their environment.

This means that I - as the author of the tool - don't have to worry about cutting releases and publishing my tools anywhere. This lowers the threshold for publishing small tools that I personally write and use.

I haven't done any prototypes in this area yet, so I don't know if this works out well in practice or not, but the use-case is appealing to me at least.

**Update 2022-10-18**: [@GeoffreyHuntley](https://twitter.com/GeoffreyHuntley) shared an interesting thread diving into the source/binary substitution approach that Nix takes and how that can impact the OSS community in a positive way [here](https://twitter.com/GeoffreyHuntley/status/1582376205260820480?s=20&t=Ygb_IVzyWp-b8LaMPwY3rw).

## Managing my personal development server

The last use-case is to manage my development server in a more declarative way. I have an old Hackintosh which I now use a development/toy server. I use it to host a private Gitpod installation which is accessible through Tailscale.

Currently this server has been installed and configured in a YOLO-manner and if it breaks I'm not sure I'd be able to get it back to its current state - so I'd like use NixOS instead.
