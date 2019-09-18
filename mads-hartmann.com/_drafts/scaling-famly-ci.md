---
layout: post
title: "Scaling Famly: Improving CI"
date:   2017-08-06 10:00:00
colors: pinkred
---

This might be a blog post about adding CI to everything and some of
the issues that we encountered.

Embracing Docker:
    Things we needed to figure out when starting to more heavily use docker
        - Somewhere to store meta-data about what images where
          produced by which branch, i.e. give me the latest image of
          `core` that's from the `staging` branch.
