---
layout: post
title: "Emacs & Docker - What's your setup?"
date: 2016-07-18 10:00:00
---

I'm having a lot of fun exploring what kinds of development
environments and work-flows that Docker can enable. There's one thing
that's been on my mind lately and I haven't been able to find a proper
solution to it. I'm sharing my thoughts here in the hopes that perhaps
some of you have come up with a creative solution.

Here's the scenario. Let's say you've grown very enthusiastic about
using Docker in your development environment. Everything runs inside
of your containers, be that linting, compiling your Scala code,
running your Python code, etc. Everything from your programming
language runtimes, your tools, and your libraries are inside of
containers. All you need on your host system is Docker. This is
wonderful in the sense that your whole setup is now documented and can
be replicated easily.

But there is one downside. All the work you put into making Emacs
clever is now no longer useful. In order to provide code-completion,
navigation, type-checking, etc. Emacs needs to have access to the
tools, libraries, and runtimes, which are no longer on your host
system. How do you work around that?

I was hoping to be able to run Emacs in a separate container and use
`volumes-from` to edit other containers. I've temporarily stopped this
as what I wanted to run was `emacs --daemon` in TCP mode inside of the
container and then use the OSX Emacs application as the `emacsclient`
but it turns that, to my understanding, the client/server
implementation in Emacs can't handle this case.

So my question is, how do you overcome this? Here's are various
approaches:

p-   Install everything on the host system and live with the redundancy.
    So basically give up and don't use containers for your development
    environment (this is my current setup).

-   Use TRAMP and SSH to the container and do you development
    "remotely". I haven't tried this yet but I image that not all of the
    Emacs packages I use deal with this in a nice way.

-   Create a development container with all the tools you need. Use
    `--volumes-from` to get access to the data volumes of the
    application you're working on. SSH to the development container with
    X-forwarding and use Quarts to render Emacs on your host.

