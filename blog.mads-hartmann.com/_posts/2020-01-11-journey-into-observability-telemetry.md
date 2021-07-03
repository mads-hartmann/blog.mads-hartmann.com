---
layout: post
title: "Journey into Observability: Telemetry"
date: 2020-01-11 12:00:00
categories: SRE
colors: pinkred
excerpt_separator: <!--more-->
---

<!-- 
Rigtig god tråd om hvorfor events er smarte i forhold til volume. Kunne være godt i min blog post om telemetry
https://twitter.com/mipsytipsy/status/1218805884681211904?s=11


En anden god tråd:
https://twitter.com/el_bhs/status/1181975708072996864?s=11
-->

At [Glitch](https://glitch.com/create) we have been investing in observability tools to help us keep the platform reliable, even as more and more people run their apps on Glitch. In the [previous post](https://blog.mads-hartmann.com/sre/2019/08/04/journey-into-observability-reading-material.html) in this series I highlighted some of the best observability resources I've come across so far. In this post I'll focus on telemetry.

<!--more-->

{::options parse_block_html="true" /}
<div class="note-box">
This is the second post in a [series of post on observability](/series/observability/index.html). If you like this post make sure to also check out the other posts in the series.
</div>


In general, I use the term _telemetry_ to refer to all the data and signals your services produce about themselves. In this case, we're interested in the kinds of telemetry that will help you make your systems observable. Here's my attempt at defining observability from the previous post:

> observability is all about being able to ask questions of your system and get answers based on the existing telemetry it produces; if you have to re-configure or modify the service to get answers to your questions you haven't achieved observability yet.

There are other use-cases for telemetry such as providing feedback to other components of your infrastructure like load-balancers, auto-scalers and so on. Likely, other kinds of telemetry - such as a health endpoint or gauge metrics - are more suitable and cost-effective for those purposes; in this post, I focus on what telemetry is best suited if you're trying to make your systems observable.

I hope to provide a quick overview of what the observability telemetry landscape looks like today, as well as highlight some of the best critiques of the status quo I've come across.

**Outline**

{: .no_toc }
* TOC
{:toc}

## Status quo: The three pillars of observability

A phrase you are very likely to come across as you research observability is the **three pillars of observability** which are: metrics, logs, and traces. Thinking about observability in terms of these three pillars might not be the best approach - which we'll look at in the next section - but given its prevalence in the industry, it's hard to ignore.

- **Metrics**: Metrics are time-series recordings of some values. The values are usually gauges, counters, and the likes. Metrics usually don't allow for high-cardinality. They're used to produce time-series data with long retention periods, but that comes at the expense of losing context. Metrics are usually collected and aggregated in the same step; this pre-aggregation is one of the primary reasons metrics don't provide a lot in terms of observability, but more on that later.

- **Logs/events**: While logs may have originated as simple lines of text, today they're most commonly thought of as discrete events - sometimes referred to as structured logs - and are usually transmitted as JSON. Structured logs usually allow for high-cardinality values; how quickly those high-cardinality values can be queried and aggregated depends on your system/vendor. Depending on what scale you operate at logs may or may not be sampled. If you add a lot of tags to your logs they are more useful for later analysis, but it also means you’re sending a lot of redundant data - you might be logging the same key/value pair multiple times as a request passes through one of your services.

- **Traces**: A distributed trace tracks the progression of a single request as it is handled by your various services. In practice that means your services have to propagate some context about the trace as they communicate as well as send the trace data somewhere so it can be assembled and queryable as a single trace. Traces are usually sampled.

With the definitions in place, let us get to the critique.

## The critique of the pillars

So far I've come across two main critiques of the pillars: That thinking about observability in terms of the three pillars negatively affects observability tooling, and that metrics and logs are problematic and inadequate when it comes to observability.

### An unfortunate mindset

One point of critique of the pillars is that it creates a superficial distinction between the data types which permeates through everything. You end up with three different libraries for instrumenting your services, three different ways to collect and aggregate the data, and possibly three different tools to query and visualize it; even if you have a single vendor that supports all three, they're likely separate products. It is perfectly reasonable that within the three pillars view you end up with distinct telemetry that is produced, collected, and processed separately.

This mindset can result in suboptimal products, but worse, it can inhibit the future development of tooling as it restrains how we *think* about observability. Rather than [focus on two data-types and a visualization](https://twitter.com/mipsytipsy/status/1044668453339172864?s=20) we should focus on what we want to accomplish and work our way back from there.

My favorite resources on this critique are:

- In ["Logs vs. metrics: a false dichotomy"](https://whiteink.com/2019/logs-vs-metrics-a-false-dichotomy/) [Nick Stenning](https://whiteink.com/about/) argues that metrics are useful for alerting - The evaluation of a metric against some threshold is almost always how you will define an alert - and logs are useful for debugging. However, pre-aggregating metrics is error-prone and unnecessary as you can derive almost all metrics of interest from a suitable log stream (*Mads: and you can derive logs from trace events*).

- [Charity Majors](https://charity.wtf) has a great [✨THERE ARE NO ✨ THREE PILLARS OF ✨ OBSERVABILITY ✨ Twitter thread](https://twitter.com/mipsytipsy/status/1044666259898593282) where she critiques the three pillars. It covers both the negative effect on tooling and points out that metrics and logs can be derived from events; and traces are just one visualization of the events.

- In [Three Pillars with Zero Answers - Towards a New Scorecard for Observability](https://lightstep.com/blog/three-pillars-zero-answers-towards-new-scorecard-observability/) [Ben Sigelman](http://bensigelman.org) argues that three pillars are "just bits" and that the rather complex task of making sense of it is "left as an exercise to the reader". We'll return to this post in the next section as well.

### The problems with logs and the inadequacy of metrics

Now, I want to re-iterate there are other use-cases for logs and metrics. such as feedback mechanisms to other components of your infrastructure like load-balancers, auto-scalers and so on. It's very likely, for example, that gauge metrics are more suitable and cost-effective for those purposes; this post focuses on what telemetry is best suited if you're trying to make your systems observable. So let's look at why logs and metrics are inadequate.

- **metrics** There a few things that make metrics unsuitable for observability, but they come all come down to lack of context; and in observability context is everything. (1) metric systems usually don't allow for high-cardinality values. This means there's a limit on how many distinct values you are allowed to have for your tags. For example, adding the `hostname` is probably fine if you just have a few hundred hosts, but adding user ids is probably not okay. Effectively this restricts how you can later slice & dice your metrics when debugging things, making metrics suitable for alerting on known problems but bad at uncovering new ones. (2) metrics are pre-aggregated, which means a lot of information is thrown away; this is information you can't recover no matter how sophisticated your tooling might be. (3) metrics often rely on averages of averages to report values. For example, a requests/second metric will be averaged on the host and then again when aggregated by your metrics system; [Averages of averages can be deceiving](http://mathforum.org/library/drmath/view/52790.html).

- **logs** If your logs are unstructured - that is, they're just lines of text - the problem is again one of lack of context. If you have structured logs, the problem becomes one of scale. To make sense of all these logs you need to have a fairly sophisticated logging infrastructure in place. I have a feeling that "Any sufficiently complicated ~~C or Fortran program~~ *logging system* contains an ad-hoc, informally-specified, bug-ridden, slow implementation of half of ~~Common Lisp~~ *distributed traces*". Having said that, I'll link to a post below that shows how to combine feature flags and diagnostic logging in a clever way, so with the right approach, you might be able to get some value out of your logs after all.

My favorite resources are

- ["Three Pillars with Zero Answers - Towards a New Scorecard for Observability"](https://lightstep.com/blog/three-pillars-zero-answers-towards-new-scorecard-observability/) does a good job of explaining specific problems with each of the pillars. Metrics don't allow for high-cardinality values. The cost of conventional logging increases proportionally with your number of microservices which can make it prohibitively expensive; to make matters worse making sense of the logs introduce an increasing cognitive overhead. Finally, traces have to be sampled, and deciding on how and when to sample isn't a simple task.

- The 1st episode of [ollycast: the observability podcast](https://twitter.com/o11ycast) goes into details on why metrics aren't enough, and introduces the concept of high cardinality. The 14th episode is about telemetry and has a lot of interesting discussions.

- [Targeted Diagnostic Logging in Production](https://tersesystems.com/blog/2019/07/22/targeted-diagnostic-logging-in-production/) by [Will Sargent](https://twitter.com/will_sargent) is a fantastic blog post that does a great job of explaining the problems of logging at debug level in production, and how you can solve it using feature flags. It also does a great job of explaining what diagnostic logging is and why it's useful.

## Looking beyond the pillars

Rather than focusing on the shape of the telemetry - as the three pillars perspective will have you do - focus on what kinds of questions you're trying to answer and let that guide your choice of telemetry.

At Glitch I'd say our primary observability telemetry is distributed traces, which we send to Honeycomb; this has been an incredible boost to our ability to debug new problems in production. But I do occasionally have to use logs to debug specific services, and metrics to investigate the health of our servers.

Here's a great post on this approach: ["Health, Availability, Debuggability"](https://medium.com/observability/health-availability-debuggability-5b0ab300b35c) rather than focusing on the shape of the data [Jaana B. Dogan](https://twitter.com/rakyll) proposes instead to focus on how the telemetry is utilized, which she classifies into three areas: health, availability, and debuggability. 

