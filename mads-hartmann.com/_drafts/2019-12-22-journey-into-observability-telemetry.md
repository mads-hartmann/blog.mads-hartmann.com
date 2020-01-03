---
layout: post
title: "Journey into Observability: Telemetry"
date: 2019-12-22 06:00:00
categories: SRE
colors: pinkred
excerpt_separator: <!--more-->
---

At [Glitch](https://glitch.com/create) we have been investing in observability tools to help us keep the platform reliable, even as more and more people run their apps on Glitch. In the [previous post](https://mads-hartmann.com/sre/2019/08/04/journey-into-observability-reading-material.html) in this series I highlighted some of the best observability resources I've come across so far. In this post I'll focus on what kinds of telemetry is best suited for observability.

<!--more-->

In general I use the term _telemetry_ to refer to all the data and signals that your services produce about themselves. In this case we're interested in the kinds of telemetry that will help you make your systems observable. Here's my attempt at defining observability from the previous post:

> observability is all about being able to ask questions of your system and get answers based on the existing telemetry it produces; if you have to re-configure or modify the service to get answers to your questions you haven't achieved observability yet.

There are other use-cases for telemetry such as feedback mechanisms to other systems such as load-balancer, auto-scalers and so on. It's very likely that other kinds of telemetry, such as a health endpoint, or a gauge metric is more suitable and cost-effective for those purposes; in this post I focus on what telemetry is best suited if you're trying to make your systems observable.

I hope to provide a quick overview of what the observability telemetry landscape looks like today, as well as highlight some of the best critiques of the status quo I've come across to help you prepare for the observability tools of tomorrow.

**Outline**

{: .no_toc }
* TOC
{:toc}

## Status quo: The three pillars of observability

A phrase you are very likely to come across as you research observability is the **three pillars of observability** which are: metrics, logs, and traces. Thinking about observability in terms of these three pillars might not be the best approach - which we'll look at in the next section - but given its prevalence in the industry it's hard to ignore.

- **Metrics**: Metrics are time-series recordings of some values. The values are usually gauges, counters, and the likes. Metrics usually don't allow for high-cardinality. They're used to produce time-series data with long retention periods, but that comes at the expense of losing context. Metrics are usually collected and aggregated in the same step; this pre-aggregation is one of the primary reasons metrics doesn't provide a lot in terms of observability, but more on that later.

- **Logs/events**: While logs may have originated as simple lines of text, today they're most commonly thought of as discrete events - sometimes refereed to as structured logs - and are usually transmitted as JSON. Structured logs usually allow for high-cardinality values; how quickly those high-cardinality values can be queried and aggregated depends on your system/vendor. Depending on what scale you operate at logs may or may not be sampled. If you add a lot of tags to your logs it’s useful for later analysis, but it also means you’re sending a lot of redundant data - you might be logging the same key/value pair multiple times during a single request.

- **Traces**: A distributed trace tracks the progression of a single request as it is handled by your various services. In practice that means your services have to propagate some context about the trace as they communicate as well as send the trace data somewhere so it can be assembled and queryable as a single trace. Traces are usually sampled.

With the definitions in place, let us get to the critique.

## The critique of the pillars

So far I've come across two main critiques of the pillars: That thinking about observability in terms of the three pillars negatively effects observability tooling, and that metrics and logs are problematic and inadequate when it comes to observability.

### An unfortunate mindset

One point of critique of the pillars is that it creates a superficial distinction between the data types which permeates through everything. You end up with three different libraries for instrumenting your services, three different ways to collect and aggregate the data, and possibly three different tools to query and visualize it; even if you have a single vendor that supports all three, they're likely separate products. It perfectly reasonable that within the three pillars view you end up with distinct telemetry that is produced, collected, and processed separately.

This mindset can result in suboptimal products, but worse, it can inhibit the future development of tooling as it restrains how we *think* about observability. Rather than [focus on two data-types and a visualization](https://twitter.com/mipsytipsy/status/1044668453339172864?s=20) we should focus on what we want to accomplish and work our way back from there.

My favorite resources on this critique are:

- In ["Logs vs. metrics: a false dichotomy"](https://whiteink.com/2019/logs-vs-metrics-a-false-dichotomy/) [Nick Stenning](https://whiteink.com/about/) argues that metrics are useful for alerting - The evaluation of a metric against some threshold is almost always how you will define an alert - and logs are useful for debugging. However, pre-aggregating metrics is error-prone and unnecessary as you can derive almost all metrics of interest from a suitable log stream.

- [Charity Majors](https://charity.wtf) has a great [✨THERE ARE NO ✨ THREE PILLARS OF ✨ OBSERVABILITY ✨ Twitter thread](https://twitter.com/mipsytipsy/status/1044666259898593282) where she critiques the three pillars. It covers both the negative effect on tooling and points out that metrics and logs can be derived from events; and traces are just a visualization of the events.

- In [Three Pillars with Zero Answers - Towards a New Scorecard for Observability](https://lightstep.com/blog/three-pillars-zero-answers-towards-new-scorecard-observability/) [Ben Sigelman](http://bensigelman.org) argues that three pillars are "just bits" and that the rather complex task of making sense of it is "left as an exercise to the reader".

### The problems with logs and the inadequacy of metrics

(Before we dive into why metrics are bad for observability I want to be clear: metrics are appropriate for a lot of other things, they're great for alerting on known edge-cases. What they aren't good at is debugging new problems in production; and if your systems are under twice the load they were a month or two ago you're more likely to be debugging new problems rather than existing ones. That is, they're bad a dealing with unknown-unknowns. Let's dive into why)

(Some information on high-cardinality. Why is it important, and why does it conflict with pre-aggregation.
)

(Explain why metrics, by itself isn't enough and what problems comes with it in terms of observability -- remember that telemetry might have other purposes than Observability, like using healthpoints used for schedulers, metrics used for auto-scaling.)

Averages of averages, pre-aggregation throwing away potentially important information. Think about a latency heatmap calculted based on traces. As it's computed on-demand you can change your query; filter by host, asg, etc.
    You can't do that if the number you're looking at is pre-aggregated. All the context is gone and you can't further drill down.
This is a case where the telemetry is important; you want all the information, but just as much is the capabilities of your query tool. But the important thing is that if you throw away the information, the most powerful tool in the world won't help you - the information is lost.

My favorite resources are

- ["Three Pillars with Zero Answers - Towards a New Scorecard for Observability"](https://lightstep.com/blog/three-pillars-zero-answers-towards-new-scorecard-observability/) does a good job of explaining specific problems with each of the pillars. Metrics don't allow for high-cardinality values. The cost of conventional logging increases proportionally with your number of microservices which can make it prohibitively expensive; to make matters worse making sense of the logs introduce an increasing cognitive overhead. Finally traces have to be sampled, and deciding on how and when to sample isn't a simple task.

## Perspectives from Linux observability (BFP)

( I want to see if I can do a quick recap of BPF and see if I can draw any interesting comparisons)

## What replaces the pillars

(In this part I want to give people some actionable advice. What telemetry should they produce, and how should they do it? -- I think OpenTelemtry is a good fit, as it provides a clean interface but allows you to export traces/metrics/logs to separate locations - a good bridge between what tools are capable of now while being ready for the future)

(Just as resillience engieering is fighting to distinct itself of reliability engieering, so is observability trying to separate itself from monitoring.)

- [Tweet by Jaana](https://twitter.com/rakyll/status/1108808736661868544)
    > No current observability tool is going to solve all your problems. There is no holistic approach yet. We are in a world companies still need to staff their database reliability teams more excessively. I don't see that this is changing in the short term.

## Conclusion

In that sense, all telemetry is the same; they in the data formats and the preprocessing steps. They vary in structure, frequency (sampling?), collection strategies (pre-aggregation), post processing.
    (Reference Jaana tweet and categorising it, I like she calls it signals)

Embracing that it's all just telemetry prepares your mental model for when the tools catch up. Until then, it's it's worth knowing what kinds/shapes of telemetry you can produce and what trade-offs there are right now.

Rather than focusing on the shape of the telemetry - as the three pillars perspective will have you do - focus on what kinds of questions you're trying to answer. ... Do you need to know exactly how many times a specific thing happened, then sampling is a problem.

One of the problems of so rigidly separating the telemetry into three .. thinking of them as distinct, lacking context between them. It's a separation caused by implementation details in tools.

## Unused resources (for now)

One distinction I've come across that I like is

- ["Health, Availability, Debuggability"](https://medium.com/observability/health-availability-debuggability-5b0ab300b35c) rather than focusing on the shape of the data [Jaana](https://twitter.com/rakyll) proposes instead to focus on how the telemetry is utilized, which she classifies into three areas: health, availability, and debuggability. Health signals such as a `/health` endpoints are critical for orchestrators such as schedulers and load balancers. Availability signals are crucial for reliability because they answer the fundamental question of whether a system is working as expected as user wants. Debuggability signals are used in troubleshooting scenarios. While some signals, such as logs, might fit into all three, it requires distinct design and planning to make them useful in these categories.

- [Observablility: Tabs vs. Spaces for Ops](https://www.linkedin.com/pulse/observablility-tabs-vs-spaces-ops-joshua-biggley/) - See my notes, figure out if I want to link to this.

- [Logging, Metrics & Distributed Tracing – These are Problems, not Solutions!](https://www.autoletics.com/posts/logging-metrics-distributed-tracing-these-are-problems-not-solutions). TODO: Figure out if this is interesting.
