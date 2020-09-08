---
layout: post-no-separate-excerpt
title: "SLIs, SLOs, error budgets, and burn rates"
date: 2020-08-23 10:00:00
categories: SRE
colors: pinkred
excerpt_separator: <!--more-->
---

<style>
  .document {
    padding: 1em;

    background: #f9f9f9;
    border: 2px solid #ccc;

    font-size: 0.85em;
  }
</style>

At Glitch we've recently completed a project to migrate to SLO-based alerts. It's too early to tell if this has been a success or not, but in this post I'll write about our motivation for going down this route, and give an introduction to all the concepts you need to know, should you want to give it a go as well.

SLOs are useful for a lot of things; this post focuses on using SLOs to
improve communication during incidents, reduce the toil on on-callers, and help improve our reliability in a way that's meaningful to our users.

This post is based on two internal documents I wrote at Glitch. The first is the tech spec that we used to discuss if this was the right approach for us, the second is a presentation I gave to the Platform team to introduce SLO-based alerting - thanks to our VP of Engineering [Victoria Kirst](https://twitter.com/bictolia) for allowing me to use excerpts of these documents in this post.

<!--more-->

{: .no_toc }
## Outline
* TOC
{:toc}

## Why we're adopting SLO-based alerting

The motivation for adopting SLO-based alerting is best described by pulling out a few sections of the "SLO-based alerting" tech spec I wrote at Glitch - the spec was used to discuss if this was the right approach for us.

Each tech spec at Glitch is based off a common template, in this post I've extracted the **TL;DR**, **Background**, and **Goals** sections as those nicely cover where we're coming from and what we're hoping to achieve. The tech spec is from 2020-07-01 - I have fixed a few typos, but otherwise the content is left unaltered.

----

{::options parse_block_html="true" /}
<div class="document">

### TL;DR

Currently most of our alerts are based on symptoms such as high system load, low available disk space, etc. This means that when an on-caller is alerted they have to figure out what the user-facing impact is and make a judgement call to figure out if a page warrants an incident or not.

We want to turn this around so we're alerting on the end-user experience directly based on SLOs, error budgets, and burn rates. **We're hoping this will improve communication during incidents, reduce the toil on on-callers, and help improve our reliability in a way that's meaningful to our users.**

### Background

**Example of what a page might look like today**. The on-caller gets alerted on high-system load on the apiproxies (let's say it's 10 and the alert threshold is 4) at 3am. The on-caller investigates and sees that the system load is indeed high and doesn't seem to go down again. An incident channel is created. The on-caller pages support but it's not clear what the impact of the high system load is so it's hard to come up with a good status update at this time. Based on prior experience the on-caller spends 15 minutes checking a few different signals to gauge the impact of the incident and it seems like requests to Glitch apps are slower than usual - the information is passed on to support who update StatusPage accordingly. The on-caller eventually resolves the system load issue and tells support, who then closes the incident.

There are a few problems with this:

- The on-caller gets paged at 3am for something that might turn out to not be urgent at all.
- Figuring out what impact the incident has on our users (if any at all) is slow and depends on the experience of the on-caller. This delays our StatusPage updates.
  - Sometimes we never manage to establish what the user-facing impact is for an incident, which means that after 3 hours of stressful incident response you're left doubting if we even had an incident at all.

While this might be manageable if you have a handful of alerts, it really doesn't scale. Right now we have 49 alerts based on metrics in Grafana, 10 uptime checks in Pingdom, 6 system checks in StatusPage, 12 triggers in Honeycomb. Having to remember the user-facing impact for each of these at 3am is hard.

#### How did we get to this state?

As with so many things, the road to *alert fatigue* is paved with good intentions of improving reliability.

All of these alerts were created for a reason. Most likely each of them came into existence like this. We had a terrible incident. Some part of Glitch was down and a lot of users were affected. During the incident retrospective the team talks through action items for how we can avoid having a terrible incident like this again, and we all agree that if we had been alerted about X in time we could have stopped the issue from escalating into an incident. So we create an alert for X.

The problem is that once the alert is created, the user-facing impact that the alert was supposed to warn about is quickly forgotten. Even if how to deal with the alert is documented in a runbook it might not be clear what impact the alert has on our users. This might be solvable with strict guidelines for alerts, but this spec suggests another approach - to switch to SLO based alerting.

### Goals

The overall goals are

* Provide a better understanding of what our reliability is in terms of affected user-experience so we can improve it in a way that's meaningful to our users.
* Make on-call more sustainable by 
  * Reducing the cognitive overhead of responding to high-urgency alerts as it will be clear what user-facing impact the alert has.
  * Only paging the on-caller when the end-user experience is affected. 
  * Make it clear when we're having an incident and when they're resolved.
* Make it easier (and faster) to provide support with the information they need to make user-relevant updates on statuspage.io for our incidents.

</div>

----

Hopefully this sets the scene; what our previous alerting looked like, and what we were hoping to achieve by adoption SLO-based alerting. Below I've written a getting started guide of sorts that hopefully works as a good introduction to SLO-based alerting, should you want to go down that route as well.

## Introduction to alerting using SLOs and error budgets

Whole chapters (["Service Level Objectives"](https://landing.google.com/sre/sre-book/chapters/service-level-objectives/),["Implementing SLOs"](https://landing.google.com/sre/workbook/chapters/implementing-slos/), ["Alerting on SLOs"](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/)) and a book (["Implementing Service Level Objectives"](https://www.oreilly.com/library/view/implementing-service-level/9781492076803/)) have been written on SLOs, error budgets, and burn rates, but I'll do my best to keep it short.

Here is a _very short_ introduction. It's probably too short, and it uses terminology that I won't define until later, but I personally find it useful to see how the pieces fit together before diving into the details:

1. First you **ensure your system is producing appropriate telemetry** that can be used to measure how certain aspects of your system is performing. That is, you define and implement your SLIs.

2. Then you **pick thresholds for the SLIs to indicate if the system is operating at an acceptable level**, that is, you define your SLOs.

3. Inherent in those SLOs is an error budget; how often the SLI is allowed to fall below the threshold in a given period before the system is considered to be operating at an unacceptable level. Finally you **configure an alert based on how fast your system is burning through its error budget**, e.g. you might decide that if the system burned through 5% of the error budget in the last hour, that signals a significant event, and you should page the on-caller.

That's it, you now have highly contextual alerts that are based on the affected user experience. Now let's take a step back and look at some of the details I skimmed over.

### Important terminology

Before we can talk about alerting on SLOs we'll have to cover the key terminology.

#### SLIs

The most succinct description I've seen is from the [SRE Book chapter 4 - Service Level Objectives, Indicators](https://landing.google.com/sre/sre-book/chapters/service-level-objectives#indicators-o8seIAcZ)

>An SLI is a service level indicator—a carefully defined quantitative measure of some aspect of the level of service that is provided.
>
> Most services consider request latency—how long it takes to return a response to a request—as a key SLI. Other common SLIs include the error rate, often expressed as a fraction of all requests received, and system throughput, typically measured in requests per second. The measurements are often aggregated: i.e., raw data is collected over a measurement window and then turned into a rate, average, or percentile.

So, to implement an SLI you have to ensure your system produces some appropriate telemetry about how it is performing. That could be aggregated metrics, log lines, or tracing data. SLIs are telemetry-agnostic - what telemetry to use depends on your use case and what tools you have available at your disposal.

What the telemetry should be measuring depends on what kind og service you're dealing with. If it's a web API you generally care about availability, latency, and throughput. For storage systems it might be latency, availability, and durability. If you want to dive deeper, I recommend reading [SRE Book chapter 4 - Service Level Objectives](https://landing.google.com/sre/sre-book/chapters/service-level-objectives), it really is very good.

One of the SLIs we picked for our "Project Hosting" system was a latency SLI: How long it takes to start a Glitch project.

#### SLOs

Again, a good description can be found in [SRE Book chapter 4 - Service Level Objectives, Objectives](https://landing.google.com/sre/sre-book/chapters/service-level-objectives#objectives-g0s1tdcz).

> An SLO is a service level objective: a target value or range of values for a service level that is measured by an SLI. A natural structure for SLOs is thus SLI ≤ target, or lower bound ≤ SLI ≤ upper bound. For example, we might decide that we will return Shakespeare search results "quickly," adopting an SLO that our average search request latency should be less than 100 milliseconds.

In other words, once you decided what signals to use for measuring the performance of your system (SLIs), you can define what should be considered "acceptable" performance by selecting a target value for the SLI.

Let us make it concrete. Based on the SLI from the previous section, how long it takes to start a Glitch project, we can define an SLO:

> __99%__ of projects should start in __under 15 seconds__

The above SLO sets a target value of 99% with a threshold on the latency of 15s. Figuring out the exact value for the thresholds is rarely obvious - often the discussions around what values to pick are useful in themselves! For a few tips & tricks I suggest reading [SRE Book chapter 4 - Service Level Objectives, Objectives in Practice](https://landing.google.com/sre/sre-book/chapters/service-level-objectives#objectives-in-practice-o8squl).

To see how an SLO like this is useful, we have to introduce a few more concepts.

#### SLO Window

In order to measure if a service is complying to the SLO, e.g. did 99% of projects actually start in under 15 seconds, we have to select a measurement window. In case of SLOs that measurement window is called the SLO window.

A popular choice is 28 days, as it contains "the same number of weekends". While this is helpful to tell if the service has performed acceptably the last 28 days, it doesn't contain any information how it performed at specific times in those 28 days.

So while a 28 day SLO window can be useful, you often also want to calculate the SLO using a sliding window of 1 hour and record it at intervals (e.g. every minute); **This is, in my opinion, where SLOs become really powerful, they show both the current and historic performance of your systems expressed in terms that align with your users' experience.**

If you want to alert on the SLOs though, there are two more concepts to grasp.

#### Error budget

Once you have defined an SLO and an SLO window you have also implicitly defined an error budget. Between the SLO and the SLI you have defined when an 'event' should be considered a failure or a success. The error budget is then the total number of failures that are allowed while still staying within the SLO.

Concretely, we have chosen to use the "Project start time" SLI and defined an SLO that states that "99% of projects should in under 15 seconds". This means that if a project takes more than 15 seconds to start we consider it a failure. The SLO target of 99% means that our error budget is 1%.

One thing, that to me, makes it a bit hard to describe error budgets is that SLO targets are defined in percentages, but we can't know ahead of time how many requests our services will receive. E.g. we don't know how many projects we are going to attempt to start up over the next 28 days, so how do we calculate the error budget? The answer is we cheat and make a bunch of assumptions, but that will become more clear in the [Alerting on SLOs](#alerting-on-slos) section below.

We're almost there, there's just one more concept to cover..

#### Burn rates

From the [SRE Workbook Chapter 5 - Alerting on SLOs, Alert on Burn Rate](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/#4-alert-on-burn-rate)

> Burn rate is how fast, relative to the SLO, the service consumes the error budget.

Concretely, if the SLO window is 28 days and the burn rate is 1 we'll have consumed the error budget 28 days from now. If the burn rate is 2 we'll have consumed it in 14 days. If it is 4 we will have consumed it in 7 days, and so on.

To compute the burn rate you need to be able to compute the error rate of the SLI in relation to the thresholds set by your SLO. E.g. in our case, the error rate is how many of the total projects we started that took longer than 15 seconds. Once you have that, computing the burn rate is quite simple:

```
burn rate = error rate the last hour / (100 - <slo target>)
```

If 5 out of 50 projects were slower than 15 seconds to start, that's an error rate of 10%. With an SLO target of 99% that then becomes a burn rate of 10. If we had an SLO target of 85% it would've been a burn rate of 0.6:

```
burn rate = 10 / (100 - 99) = 10
burn rate = 10 / (100 - 85) = 0.6
```

That it, in the next section we'll tie all of these concepts together.

### Alerting on SLOs

**TODO**: Why would you want to alert on SLOs?

Once you've defined an SLO, you have agreed upon an error budget; that is, some number of failure is acceptable and expected. The challenge of alerting then becomes to figure out a numerical way to express that the service is not performing at an acceptable level.

A nice way to express a significant event is in terms of how much of the error budget was consumed in some alerting window. For example:

> We should page someone if we spent 10% of the error budget in the last hour

In order to alert on this we'll have to translate that phrase into a concrete burn rate. To do that we have to make a few assumptions:

1. We assume all minutes are equal
2. We only look at performance in the alert window, and extrapolate from there. That is, we ignore any errors outside of the alerting window.

Given those assumptions, we can calculate the targeted burn rate:

1. SLO window of 28 days - there are 40,320 minutes in 28 days
2. Alerting window of 1 hour - there are 60 minutes in an hour
3. To spend 10% of 40,320 minutes in an hour, we need a burn rate of 67,2

Here's the calculations

```
28*24*60 = 40,320
40320 * 0.1 = 4,032
4,032 / 60 = 33,6
```

If you want to dive even deeper into the various approaches and trade-off when it comes to alerting on SLOs you should head over to [SRE Workbook Chapter 5 - Alerting on SLOs](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/).

We have adopted the "Multiple Burn Rate Alerts" approach and are currently using the following rules:

1. A burn rate of 2 is a low-urgency alert. They are meant to represent degraded performance at a level we don't need to urgently investigate; these alerts are meant to be investigated by the on-caller during work hours.

2. A burn rate of ? is a high-urgency alert. These alerts represent a signification event in terms of degraded performance and warrant a full incident response

So far that seems to be working fairly well, but we're still iterating.

## A side-note: SLO-based alerting & observability

TODO:

- Are they related? Sort of, SLO based alerts are less concrete in terms of telling you how something is broken.
- Check if they mention this in the o11y chapter of the new SLO book.
