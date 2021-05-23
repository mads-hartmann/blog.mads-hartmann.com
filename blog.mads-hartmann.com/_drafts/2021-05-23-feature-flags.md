---
layout: post-no-separate-excerpt
title: "Feature flags"
date: 2021-05-23 10:00:00
categories: SRE
colors: pinkred
---

Idea for post: Write about feature flags, with a focus on using them to experiment with changes in production. Focus on how it ties into telemetry (what good are feature flags if you can't observe the effect of enable/disable them).

Some random notes:

- Look at my tech spec from Glitch for inspiration for things to put in the post (tl;dr: "We want to make it easy to use feature-flags to deploy a change-set to a subset of servers. This gives us a tool that we can use to reduce the blast-radius when deploying changes that we deem to be potentially breaking. The end goal is that we can deploy more often and with greater confidence.")

- Reference back to my quote in the o11y posts about using feature flags and how it was enabled by o11y

- Talk about the two kinds of feature flags we used (operational / experimental)

- Talk about different "audiences", e.g. do you enable it for a % of users or a % of instances of a service. Talk about when you'd need which of the two.

- Talk about the challenges of tale feature flags and ways to mitigate it (reference the recent Github post, they had a very cool approach)

- Have an example app to show / perhaps even do a small recording of a demo. Should use Honeycomb / Launch Darkly of course.

- Mention that feature flags is one mechanism of decoupling deploys form release
	- You can split your work into multiple smaller PRs and merge into main without having written the whole thing first

- Faster and safer “rollback” than rollbacks