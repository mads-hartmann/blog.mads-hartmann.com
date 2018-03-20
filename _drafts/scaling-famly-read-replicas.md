---
layout: post
title: "Scaling Famly: Adding MySQL read replicas"
date:   2017-08-06 10:00:00
colors: pinkred
---

This is blog post series about the various ways we've had to scale
Famly over time. Given we're a small team with a fairly young
code-base the goal of these stories is to show some of the usual
things you might be going through. The purpose is to provide some
counter weight to the stories you'd read from large companies. Their
scaling issues might not be relevant to your needs. Also to point out
that it's totally fine to start simple and then slowing scale the
various aspects of your infrastructure once the need arises.

This post describes how we moved from a single master database to the usual
setup of having a master database for writing and having multiple read replicas
for reading.



