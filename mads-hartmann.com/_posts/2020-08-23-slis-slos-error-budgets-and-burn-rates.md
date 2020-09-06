---
layout: post-no-separate-excerpt
title: "SLIs, SLOs, error budgets, and burn rates"
date: 2020-08-23 10:00:00
categories: SRE
colors: pinkred
excerpt_separator: <!--more-->
---

At Glitch we've recently completed a project to migrate to SLO-based alerts. It's too early to tell if this has been a success or not, but in this post I'll write about our motivation for going down this route, and give an introduction to all the concepts you need to know, should you want to give it a go as well.

This post is based on two internal documents I wrote at Glitch. The first is a tech spec that we used to discuss if this was the right approach for us, the second is based off a presentation I gave to the Platform team to introduce SLO-based alerting - thanks to our VP of Engineering [Victoria Kirst](https://twitter.com/bictolia) for allowing me to use excerpts of these documents in this post.

<!--more-->

**Outline**

{: .no_toc }
* TOC
{:toc}

## Why we're switching to SLO-based alerting

The reasoning for switching to error budget burn-rate based alerts is best described by pulling out sections of the internal tech spec i wrote at Glitch before starting the work. Each tech spec follows a template, in this post I've extracted the **TL;DR**, **Background**, and **Goals** sections - the tech spec is from 2020-07-01.

### TL;DR

Currently most of our alerts are based on symptoms such as high system load, low available disk space, etc. This means that when an on-caller is alerted they have to figure out what the user-facing impact is and make a judgement call to figure out if a page warrants an incident or not.

We want to turn this around so we're alerting on the end-user experience directly  based on SLOs, error budgets, and burn rates. **We're hoping this will improve communication during incidents, reduce the toil on on-callers, and help improve our reliability in a  way that's meaningful to our users.**

### Background

**Example of what a page might look like today**. The on-caller gets alerted on high-system load on the apiproxies (let's say it's 10 and the alert threshold is 4) at 3am. The on-caller investigates and sees that the system load is indeed high and doesn't seem to go down again. An incident channel is created. The on-caller pages support but it's not clear what the impact of the high system load is so it's hard to come up with a good status update at this time. Based on prior experience the on-caller spends 15 minutes checking a few different signals to gauge the impact of the incident and it seems like requests to Glitch apps are slower than usual - the information is passed on to support who update StatusPage accordingly. The on-caller eventually resolves the system load issue and tells support who closes the incident.

There are a few problems with this:

- The on-caller gets paged at 3am for something that might turn out to not be urgent at all.
- Figuring out what impact the incident has on our users (if any at all) is slow and depends on the experience of the on-caller. This delays our StatusPage updates.
  - Sometimes we never manage to establish what the user-facing impact is for an incident, which means that after 3 hours of stressful incident response you're left doubting if we even had an incident at all.

While this might be manageable if you have a handful of alerts, it really doesn't scale. Right now we have 49 alerts based on metrics in Grafana, 10 uptime checks in Pingdom, 6 system checks in StatusPage, 12 triggers in Honeycomb. Having to remember the user-facing impact for each of these at 3am is hard.

{::options parse_block_html="true" /}
<div class="note-box">
**📜 How did we get to this state**

As with so many things, the road to *alert fatigue* is paved with good intentions of improving reliability.

All of these alerts were created for a reason. Mostly likely each of them came into existence like this. We had a terrible incident. Some part of Glitch was down and a lot of users were affected. During the incident retrospective the team talks through action items for how we can avoid having a terrible incident like this again, and we all agree that if we had been alerted about X in time we could have stopped the issue from escalating into an incident. So we create an alert for X.

The problem is that once the alert is created, the user-facing impact that the alert was supposed to warn about is quickly forgotten. Even if how to deal with the alert is documented in a runbook it might not be clear what impact the alert has on our users. This might be solvable with strict guidelines for alerts, but this product spec suggests another approach - to switch to SLO based alerting.
</div>

### Goals

The overall goals are

* Provide a better understanding of what our reliability is in terms of affected user-experience so we can improve it in a way that's meaningful to our users.
* Make on-call more sustainable by 
  * Reducing the cognitive overhead of responding to high-urgency alerts as it will be clear what user-facing impact the alert has.
  * Only paging the on-caller when the end-user experience is affected. 
  * Make it clear when we're having an incident and when they're resolved.
* Make it easier (and faster) to provide support with the information they need to make user-relevant updates on statuspage.io for our incidents.

## Introduction to SLO-based alerting

With the motivation in place, let us look at the relevant concepts and how they relate to each other. I used Google SRE books to study these concepts, I especially recommend [Chapter 5 - Alerting on SLOs](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/) of the Google [SRE Workbook](https://landing.google.com/sre/workbook/toc/) as it contains a lot of details if you want to dive deeper.

The concepts are SLIs, SLOs, error budgets, and burn rates (and SLO windows and alert windows). As these concepts build upon each other, we can start with a simple use-case and add layers.

{::options parse_block_html="false" /}
<div class="boxes">
<div class="box">
<div class="box__header">
Some section
</div>
<div class="box__content">
* How are our systems doing right now?
* Useful seeing reliability trends; are we doing better or worse? Do we need to invest more in reliability?
</div>
</div>
<div class="box">
<div class="box__header">
Some other section
</div>
<div class="box__content">
* Can use recent performance to extrapolate future SLO compliance and alert us ahead of time. This gives us highly contextual alerts.
</div>
</div>
</div>

### SLIs, SLOs, and SLO windows

#### SLIs

TODO: Add concrete examples: 
* how do you instrument an SLI (metric if that's what you use, event (span) if you use something like Honeycomb)
* List the different kinds of SLI categories (availaiblity, latency, durability, etc). -> Show how you might instrument a latency SLI.

TODO: Change the quote below  so it's from the google book, I don't have to re-invent descriptions, I'll just add longer descriptions and clarify things.

> Service level indicator (SLI) - quantitative measure of some aspect of the level of service that is provided. Common examples are latency (how long it took to provide a response to the user) and Availability (what percentage of requests succeeded with a 200 status code)


#### SLOs and SLO windwos

Let's start with SLIs and SLOs

* Service level objective - a target value or range of values for a service level that is measured by an SLI. E.g. Based on the latency and availability SLIs above we might define three SLOs:
  * availability should be 97%
  * latency should be < 450ms for 90% of requests
* SLO Window - ...

Let us make it concrete. Our SLI is how fast we're able to start Glitch projects. Based on that SLI would could define an SLO:

> __99%__ of projects should start in __under 15 seconds__

Assuming we've instrumented our code that's responsible for starting Glitch projects, we can then use these measurements to tell us:

* How are our systems doing right now? Okay, maybe not *right now*, but a minute ago.
* Useful seeing reliability trends; are we doing better or worse? Do we need to invest more in reliability?

### Error budgets, burn-rates, and alert windows

While all SLOs have an error budget (it's the derived from the SLO target, that is), I have  found that it's mainly relevant in the context of alerting.

* Can use recent performance to extrapolate future SLO compliance and alert us ahead of time. This gives us highly contextual alerts.

Concepts: Error budget, alert window, burn rate.
