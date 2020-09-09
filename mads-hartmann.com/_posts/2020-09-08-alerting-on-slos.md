---
layout: post-no-separate-excerpt
title: "Alerting on SLOs"
date: 2020-09-08 10:00:00
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

SLOs are useful for a lot of things. As you'll see below, we're hoping that by implementing SLOs - and alerting on them - we'll be able to improve communication during incidents, reduce the toil on on-callers, and help improve our reliability in a way that's meaningful to our users.

This post is based on two internal documents I wrote at Glitch. The first is the tech spec that we used to discuss if this was the right approach for us, the second is a presentation I gave to the Platform team to introduce SLO-based alerting - thanks to our VP of Engineering [Victoria Kirst](https://twitter.com/bictolia) for allowing me to use excerpts of these documents in this post. We're currently looking for a [Staff Software Engineer](https://glitch.bamboohr.com/jobs/) so if want to help us make Glitch even better and more reliable in the future, you should have a look at the posting!

<!--more-->

{: .no_toc }
## Outline
* TOC
{:toc}

## Why we're adopting SLO-based alerting

The motivation for adopting SLO-based alerting is best described by pulling out a few sections of the "SLO-based alerting" tech spec I wrote at Glitch - the spec was used to discuss if this was the right approach for us.

Each tech spec at Glitch is based on a common template, in this post I've extracted the **TL;DR**, **Background**, and **Goals** sections as those nicely cover where we're coming from, and what we're hoping to achieve. The tech spec is from 2020-07-01 - I have fixed a few typos, but otherwise the content is left unaltered.

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
  - Sometimes we never manage to establish what the user-facing impact was for an incident, which means that after 3 hours of stressful incident response you're left doubting if we even had an incident at all.

While this might be manageable if you have a handful of alerts, it really doesn't scale. Right now we have 49 alerts based on metrics in Prometheus, 10 uptime checks in Pingdom, 6 system checks in StatusPage, 12 triggers in Honeycomb. Having to remember the user-facing impact for each of these at 3am is hard.

#### How did we get to this state?

As with so many things, the road to *alert fatigue* is paved with good intentions of improving reliability.

All of these alerts were created for a reason. Most likely each of them came into existence like this. We had a terrible incident. Some part of Glitch was down and a lot of users were affected. During the incident retrospective the team talks through action items for how we can avoid having a terrible incident like this again, and we all agree that if we had been alerted about X in time we could have stopped the issue from escalating into an incident. So we create an alert for X.

The problem is that once the alert is created, the user-facing impact that the alert was supposed to warn about is quickly forgotten. Even if how to deal with the alert is documented in a runbook it might not be clear what impact the alert has on our users. **This might be solvable with strict guidelines for alerts, but this spec suggests another approach - to switch to SLO based alerting.**

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

3. Inherent in those SLOs is an error budget; how often the SLI is allowed to fall below the threshold in a given period before the system is considered to be operating at an unacceptable level. Finally you **configure an alert based on how fast your system is burning through its error budget**, e.g. you might decide that if the system burned through 10% of the error budget in the last hour, that signals a significant event, and you should page the on-caller.

That's it, provided you've based your SLOs on the end-user experience, **you now have highly contextual alerts that only trigger when the end-user experience is sufficiently affected**. Now let's take a step back and look at some of the details I skimmed over.

### Important terminology

All of these concepts build upon each other, so it's easiest to go through them one by one. Once the terminology is in place we'll look at how you can alert on them in the [alerting on SLOs](#alerting-on-slos) section.

#### SLIs

First on the list is Service Level Indicator (SLI). The most succinct description I've seen is from the [SRE Book chapter 4 - Service Level Objectives, Indicators](https://landing.google.com/sre/sre-book/chapters/service-level-objectives#indicators-o8seIAcZ)

>An SLI is a service level indicator — a carefully defined quantitative measure of some aspect of the level of service that is provided.
>
> Most services consider request latency—how long it takes to return a response to a request—as a key SLI. Other common SLIs include the error rate, often expressed as a fraction of all requests received, and system throughput, typically measured in requests per second. The measurements are often aggregated: i.e., raw data is collected over a measurement window and then turned into a rate, average, or percentile.

So, to implement an SLI you have to ensure your system produces appropriate telemetry about how it is performing. That could be aggregated metrics, log lines, or tracing data. SLIs are telemetry-agnostic - what telemetry to use depends on your use case and what tools you have available at your disposal. For example, if you use [Prometheus](https://prometheus.io) you'll be using aggregated metrics, if you're using [Honeycomb](https://www.honeycomb.io) you'll be using tracing data - I'm not aware of a system that uses log lines, but with sufficient post-processing I don't see why you couldn't use logs lines.

What the telemetry should be measuring depends on what kind og service you're dealing with. If it's a web API you generally care about availability, latency, and throughput. For storage systems it might be latency, availability, and durability. If you want to dive deeper, I recommend reading [SRE Book chapter 4 - Service Level Objectives](https://landing.google.com/sre/sre-book/chapters/service-level-objectives), it really is very good.

One of the SLIs we picked for our "Project Hosting" system is a latency SLI: How long it takes to start a Glitch project. We'll be using this SLI throughout the next couple of sections whenever a concrete example is needed.

#### SLOs

Next on the list is Service Level Objective (SLO). Again, a good description can be found in [SRE Book chapter 4 - Service Level Objectives, Objectives](https://landing.google.com/sre/sre-book/chapters/service-level-objectives#objectives-g0s1tdcz).

> An SLO is a service level objective: a target value or range of values for a service level that is measured by an SLI. A natural structure for SLOs is thus SLI ≤ target, or lower bound ≤ SLI ≤ upper bound. For example, we might decide that we will return Shakespeare search results "quickly," adopting an SLO that our average search request latency should be less than 100 milliseconds.

In other words, once you decided what signals to use for measuring the performance of your system (SLI), you define what should be considered "acceptable" performance by selecting a target value for the SLI.

Based on the SLI from the previous section, how long it takes to start a Glitch project, we can define an SLO:

> __99%__ of projects should start in __under 15 seconds__

The above SLO sets a target value of 99% with a threshold on the latency of 15s. Figuring out the exact value for the thresholds is rarely obvious - often the discussions around what values to pick are useful in themselves! For a few tips & tricks I suggest reading [SRE Book chapter 4 - Service Level Objectives, Objectives in Practice](https://landing.google.com/sre/sre-book/chapters/service-level-objectives#objectives-in-practice-o8squl).

Again, how exactly to implement an SLO like this depends on your tool. If you're using metrics you could implement the SLI using a histogram and then compute the SLO from that (see the [Prometheus docs](https://prometheus.io/docs/practices/histograms/#histograms-and-summaries) for examples). If you're using tracing you could implement the SLI as a span with the appropriate attributes (see the [Honeycomb docs](https://docs.honeycomb.io/working-with-your-data/slos/) for an example of how they've implemented SLOs based on tracing data).

To see how an SLO like this is useful, we have to introduce a few more concepts.

#### SLO Window

In order to measure if a system is complying to the SLO, e.g. did 99% of projects actually start in under 15 seconds, we have to select a measurement window. In case of SLOs that measurement window is called the SLO window.

A popular choice is 28 days. While this is helpful to tell if the system has performed acceptably in the last 28 days, it doesn't contain any information about how it performed at specific times in those 28 days.

So while a 28 day SLO window can be useful, you often also want to calculate the SLO using a sliding window recorded at intervals. For example, you might record the SLO every minute using a sliding window of one hour. **This is, in my opinion, where SLOs become really powerful, they show both the current and historic performance of your systems expressed in terms that align with your users' experience.**

This is in itself great, and it's how we hope to achieve the following item from the [goals](#goals) section:

> Provide a better understanding of what our reliability is in terms of affected user-experience so we can improve it in a way that's meaningful to our users.

If you want to alert on the SLOs, however, there are two more concepts to grasp.

#### Error budget

Inherent in all SLOs is an error budget. When you set the SLO target to 99% you're stating that failing 1% of the time is okay - that's your error budget. Between the SLO and SLI you've also defined when something should be considered a failure or success. In other words, the error budget is then the total number of failures that are allowed while still staying within the SLO.

Using our running example, we have chosen to use the "Project start time" SLI and defined an SLO that states that _"99% of projects should in under 15 seconds"_. This means that if a project takes more than 15 seconds to start we consider it a failure. The SLO target of 99% means that our error budget is 1%.

One thing that, to me, makes it a bit hard to explain error budgets is that they're usually used to talk about the future, but defined in percentages. We can't know ahead of time how many requests our system will receive, e.g. we don't know how many projects we're going to start over the next 28 days, so how do we calculate the error budget? The answer is we cheat and make a bunch of assumptions, but that will become more clear in the [Alerting on SLOs](#alerting-on-slos) section below.

We're almost there, there's just one more concept to cover.

#### Burn rates

From the [SRE Workbook Chapter 5 - Alerting on SLOs, Alert on Burn Rate](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/#4-alert-on-burn-rate)

> Burn rate is how fast, relative to the SLO, the service consumes the error budget.

Concretely, if the SLO window is 28 days and the burn rate is 1 we'll have consumed the error budget 28 days from now. If the burn rate is 2 we'll have consumed it in 14 days. If it is 4 we will have consumed it in 7 days, and so on.

To compute the burn rate you need to be able to compute the error rate of the SLI in relation to the thresholds set by your SLO. E.g. in our case, the error rate is how many of the total projects we started that took longer than 15 seconds. Finally you need to select a measurement window, once you have that you can compute the burn rate like so:

```
burn rate = error rate the last <window> / (100 - <slo target>)
```

If 5 out of 50 projects were slower than 15 seconds to start, that's an error rate of 10%. With an SLO target of 99% that then becomes a burn rate of 10. If we had an SLO target of 85% it would've been a burn rate of 0.6:

```
burn rate = 10 / (100 - 99) = 10
burn rate = 10 / (100 - 85) = 0.6
```

That it, in the next section we'll tie all of these concepts together.

### Alerting on SLOs

_There are a few different approaches to this, if you want a detailed walk-through of each you should read [SRE Workbook Chapter 5 - Alerting on SLOs](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/). We have adopted the "Multiple Burn Rate Alerts" approach, which I'll cover in this section._

Remember that from the ["Goals"](#goals) section that we're hoping to achieve the following by alerting on SLOs:

1. Reducing the cognitive overhead of responding to high-urgency alerts as it will be clear what user-facing impact the alert has.
2. Only paging the on-caller when the end-user experience is affected.

By basing our SLOs on the end-user experience - e.g. how long it takes to start a Glitch project - we've taken care of (1). In order to fix (2) we have to decide how bad things have to be before we alert on them, that is, we have to find a way to detect a "significant event" in terms of reduced performance as measured by our SLOs.

A convenient way to phrase this is how much of the error budget was consumed in some alerting window, for example:

> We should page the on-caller if we spent 10% of the error budget in the last hour

In order to alert on this we'll have to translate that phrase into a concrete burn rate. To do that we have to make a few assumptions:

1. We assume all minutes are equal in terms of "traffic"
2. We only look at performance in the alert window, and extrapolate from there. That is, we ignore any errors outside of the alerting window.

Given those assumptions, we can calculate the targeted burn rate:

1. We have selected an SLO window of 28 days - there are 40,320 minutes in 28 days.
2. We have selected an alerting window of 1 hour - there are 60 minutes in an hour.
3. To spend 10% of 40,320 minutes in an hour, we need a burn rate of 67,2: `(10% of 40320) / 60 = 67,2`

Now that we have a threshold for the burn rate, we can simply configure an alert to trigger if the burn rate ever surpasses 67.2 looking at data for the last hour.

As mentioned previously, we have adopted the "Multiple Burn Rate Alerts" approach as outlined in [SRE Workbook Chapter 5 - Alerting on SLOs - Multiple Burn Rate Alerts](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/#5-multiple-burn-rate-alerts). Concretely we've pciked:

1. A burn rate of 2 is a **low-urgency alert**. They are meant to represent degraded performance at a level we don't need to urgently investigate; these alerts are meant to be investigated by the on-caller during work hours.

2. A burn rate of 67,2 is a **high-urgency alert**. These alerts represent a signification event in terms of degraded performance and warrant a full incident response.

So far these burn rates seems to be working fairly well, but we're still iterating. As mentioned, it's a bit too early to tell if this has been a success or not, but it's already triggered some interesting discussions, and we have seen some early positive results 🤞

