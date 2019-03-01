---
layout: post
title: "My first outage"
colors: blueish
date: 2019-03-01 12:00:00
excerpt_separator: <!--more-->
---

If you follow along [on Twitter](https://twitter.com/Mads_Hartmann/status/1100122391156527105), you might know that a couple of days ago I took down glitch.com for about half an hour. This is the first time I’ve ever taken down production - and I was just three days shy of having been at Glitch for three months 😅

<!--more-->

I was about two thirds into the process of rolling out a new fleet of docker workers - the machines that run all the apps on glitch.com - when alarms started firing. I could feel my heart rate increase as it slowly dawned on me that something was off with the new fleet.

My heart was pounding pretty badly as I prepared to write on Slack that I had broken production and would be investigating what went wrong. To my relief everyone at Glitch was amazingly supportive; this made what could’ve been an extremely stressful situation manageable.

Having had the guilt nullified by my supportive co-workers we could instead focus on identifying the problems that caused the outage. We have an internal book club that’s currently reading through the [SRE book](https://landing.google.com/sre/books/) so this was a great opportunity to put some of the theory into practice.

The whole episode turned into a great learning experience and I feel grateful for having such amazing co-workers ❤

---

I love reading incident reports; it’s hard not to bite your nails when you go through the [October 21 incident analysis by Github](https://github.blog/2018-10-30-oct21-post-incident-analysis/). When you’re reading blog posts or watching conference talks it’s easy to get the impression that everyone but you is building these beautifully architected, extremely resilient, solutions. Reading a couple of incident reports is a great way to get some grounding: We’re all just trying to build the best systems we can with the time available, and sometimes things break in spectacular ways, and when they do the most important thing is to figure out how to improve the system and surrounding processing to reduce the chance of having it break the same way again.

So in the spirit of sharing the messy parts of building systems, here’s a slightly modified version of the report we wrote for this incident.

---

# Incident retrospective 25/02/2019

## Summary

While manually rolling out a new fleet we drained a large number of hosts simultaneously. This caused a lot of apps to be migrated to the remaining hosts. On some hosts the surge of new apps put the system under too much pressure which resulted in some apps being started with a corrupted node_modules folder. Our best guess is that the component that takes care of allocating node_modules couldn't handle the load. One of the apps that had problems was the community site (glitch.com).

## Impact
We don't have a clear picture of how many apps were affected. From the support forums and Twitter it seems to have been just a handful.

Any app being started on a stressed host in the roughly 1.5 hour window could have been affected.

It was possible to fix the problem manually by running a command in the terminal of an affected app - any other affected app would recover once they were restarted as we do periodically.

The community site was unavailable for roughly 30 minutes while we were figuring out the root cause of the problem and how to fix it.

## Root causes

A surge of new apps on a single host can put the system under pressure in such a way that some apps can end up with a corrupted node_modules folder. Our best guess is that it's caused by the component that takes care of allocating node_modules folders to apps.

## Trigger

We were rolling out a new fleet manually in preparation for the new auto-rollout fleets. That entailed shutting down all the existing hosts and starting new ones. The decrease of the old fleets capacity was done at a rate that the system couldn't handle.

## Resolution

We stopped draining hosts for a while to give the system time to recover.
Affected apps could be manually fixed by running a command in the terminal of the app. The remaining affected apps would be automatically fixed on the next reboot.

## Detection

Our monitors for glitch.com, glitch.com/about and other glitch owned projects triggered.

## Timeline

- 18:45: We created the new spot fleet. We started scaling it up and scaling down the old one in large chunks (roughly 30 machines at a time) periodically.

- 19:45: We got a page from Pingdom stating that the community site and other of our glitch apps were down. We started investigating the problem.

- 20:15 Glitch.com was up again and we had a solution for our other affected apps.

## Lessons learned

### What went well

- We were able to locate the problem relatively quickly and provide a fix for the apps that had been affected.

### What went wrong

- The docker_worker_avg_pct_full cloud-watch metric was used to figure out if we could scale down the old fleet further. However, this metric doesn't say anything about the health of the projects, only the available capacity of our fleets.

- We forgot to look at datadog. Had we looked we would have seen an elevated rate of warnings that might have stopped us from scaling down the feet further before investigating.

- The 'Disk usage is getting tight' monitor was triggered many times and completely flooded our Slack channel and stress-tested the on-call persons voicemail.

- Once we were aware of the problem datadog was of little use as it was flooded with warnings and errors, with no way to tell if they were relevant or not.

- We got rate-limited by AWS as we query Route53 when booting new machines. It slowed down the rollout of the new machine but wasn't a problem as such. It did make it harder to find the root cause of the problem as we had to investigate if the rate-limit was causing any issues.

### Where we got lucky

- The community site (glitch.com) was one of the apps that had problems. That triggered our alarms so we noticed the problem. Otherwise it might have gone unnoticed for longer as we don't have any metrics that say anything about the health of the projects.

## Action items

- Make the component that allocates node_modules more resilient.

- Set and upper-limit for the number of hosts to drain automatically when the fleet is running with too much excess capacity.

- Fix our datadog setup so we aggregate similar events properly.

- Avoid querying Route53 when booting new machines to avoid being rate-limited when booting a lot of new machines.

- Fix the ‘Disk usage is getting tight’ monitor so it doesn’t trigger when everything is fine.

- Collect and display metrics for the overall health of the apps running on a specific fleet.
