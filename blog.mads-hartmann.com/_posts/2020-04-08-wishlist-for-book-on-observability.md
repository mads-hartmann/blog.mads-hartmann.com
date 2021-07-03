---
layout: post
title: "My wishlist for a book on observability"
date: 2020-04-08 10:00:00
categories: SRE
colors: pinkred
excerpt_separator: <!--more-->
---

<!--more-->

Recently Charity Majors asked a few hypothetical questions ([tweet](https://twitter.com/mipsytipsy/status/1247212789086609410)) around what you'd want out of a book on observability. I saw this as excellent opportunity to throw a bunch of questions I've been struggling with at an observability expert - so here are my questions ☺️

> if you picked up a book on observability, what would you be looking to learn from it?

There seems to be two camps in the observability space. While they have the same goal - to be able to ask arbitrary questions of your systems without modifying them - they're focusing on different things and seem to be approaching the problem differently:

- *Linux Observability* focuses on individual hosts and relies on existing instrumentation of the Linux kernel (uprobes, kprobes) to understand what programs are doing through BPF.

- *Distributed systems observability* focuses on the services that make up a distributed system and relies on developers instrumenting their services uniformly so context can be propagated correctly. This makes it possible to understand where errors and latencies are introduced as requests flow through the system.

What can these two groups learn from each other? Is it possible to have the book cater to both groups? If not, why not?

> what questions would you be hoping for a deeper dive into?

One of the challenges of observability is it generates a lot of data. There are various ways to deal with this: There are different sampling strategies and they can be performed at various points in the telemetry pipeline. Another approach might be to only produce the telemetry on-demand for ad-hoc analysis. What are the various ways to deal with this and what are the trade-offs?

> which examples would you be wanting

Usually the primary focus for observability is how you can use it to better understand your services. I would love various inspirational examples of how observability can help you in other regards:

- From my experience so far observability seems to sneak into every aspect of your software engineering practices: how you deal with incidents, how you release software, how to prioritize what to work on etc. A few concrete examples on how observability can improve your engineering practices would be great.

- What other systems could benefit from observability? E.g. I've heard examples of people instrumenting their tests suites, CI pipelines etc.

Examples like these might help people who already have some observability in place get even more value out of it.

> what sections would you completely skim past?

I'd skip any section that focused on a specific library for instrumentation your services or tool for querying the telemetry. I'd love for this book to focus on principles rather than specific technologies.

---

As a general wish for the book, I'd love for it to approach observability from first-principles rather than explain what observability is in relation to existing things that aren't observability (the three pillars, for example). This might make the book more approachable to people who don't have experience with traditional monitoring and ops tools and their deficiencies.
