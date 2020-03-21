---
layout: post
title: "Journey into Observability: Reading material"
date: 2019-08-04 12:00:00
categories: SRE
colors: yellowblue
excerpt_separator: <!--more-->
---

I've been reading up on observability over the last three months. In this post I have organized the material into a sort of recommended reading order. It doesn't reflect the order in which I read it, but I think this order would've made more sense.

<!--more-->

{::options parse_block_html="true" /}
<div class="note-box">
This is the first post in a [series of post on observability](/series/observability/index.html). If you like this post make sure to also check out the other posts in the series.
</div>

As [Glitch] is getting an ever-increasing amount of traffic we are sometimes struggling to keep up; what was previously considered performance edge-cases are now commonplace. A lot of *Unknown-Unknowns* are becoming *Known-Unknowns*. We are investing in observability tools now in the hopes that it will help us ensure that everyone has a snappy experience even as more and more people run their apps on Glitch.

Over the last three months, I've been reading up on observability. To be honest I found it to be a quite confusing topic to dive into. You will hear people talk about the *three pillars of observability* - metrics, logs, and traces - which seems comprehensible, but it turns out that it is not really what observability is [^1] [^2]. If you do a glance over the traditional vendors they all claim to give you everything you need to achieve observability - but they all use the same vocabulary to describe their offerings even though they are clearly selling different things. If you research which standards and tools might be relevant you'll find competing standards and a lot of vendor-specific libraries.

My take-away so far is that observability is all about being able to ask questions of your system and get answers based on the existing telemetry it produces; if you have to re-configure or modify the service to get answers to your questions you haven't achieved observability yet. Right now the telemetry usually takes the form of logs, metrics, and traces, but that's not inherent to observability, it is just the kinds of telemetry that is most common right now for distributed systems. It also means you can have all these kinds of telemetry without having observability; having distributed traces doesn't help you much if you can't query them just the way you need to answer your questions.

With this definition, it's clear that answering the question "Have we achieved observability?" isn't a yes/no question. It's a sliding scale and how much you should invest in observability tools depends on your use case. Having said that, I do like [Charity Majors](https://twitter.com/mipsytipsy) rule of thumb 

> if you can't drill down to the raw request it's not observability[^3]

---

Below I've tried to organize what I've read over the last few months into a sort of recommended reading order. It doesn't reflect the order in which I read them, but I think this order would've made more sense. Keep in mind that this is [my path through the maze](https://medium.com/@old_sound/notes-on-the-synthesis-of-labyrinths-a45457ce5ecd).

{::options parse_block_html="true" /}
<div class="emphasis_block">
**Caveat:** At a glance it is easy to conflate observability with distributed tracing, and you'd be excused to think I'm doing the same in this list. I try not to, it's just that distributed tracing seemed like a really useful observability tool and we didn't have it at Glitch before so I needed to read up on it.
</div>

The following two resources should give you the necessary background on observability and why you should care about it.

* The first episode of [ollycast: the observability podcast](https://twitter.com/o11ycast) is a great introduction and gives a lot of context. Amongst other things they define what observability is, goes into details on why metrics aren't enough, and introduces the concept of high cardinality. It's just a fantastic episode. 

* [Framework for an observability maturity model: using observability to advance your engineering & product](https://www.honeycomb.io/framework-for-an-observability-maturity-model-using-observability-to-advance-your-engineering-product/). This is a great read. It defines what observability is all about and why you should care about it.

    It defines a framework for measuring how well your company is doing in terms of observability. They define the engineering organization goals of observability as: 

    * Sustainable systems and engineer happiness
    * Meeting business needs and customer happiness. 

    To help you access how your organization is doing they list five capabilities that are directly impacted by the quality of your observability practice. It’s not an exhaustive list but is intended to represent the breadth of potential areas of the business. For each capability, the article explains why it is important, provides guidance on how to assess how well you're doing in that area, and finally how it relates to observability. The five capabilities are: 

    1. Respond to system failure with resilience 
    1. Deliver high-quality code
    1. Manage complexity and technical debt
    1. Release on a predictable cadence
    1. Understand user behavior.

Next up it's time to read up on one of the most popular - at least the most talked-about - observability tool when it comes to distributed systems:  distributed tracing.

1. Googles paper from 2010 is a great introduction to distributed tracing: [Dapper, a Large-Scale Distributed Systems Tracing Infrastructure](https://ai.google/research/pubs/pub36356). It covers the basic concepts and how they implemented it at Google at the time.

1. If you want a bit of a deeper dive into distributed tracing I recommend [Mastering Distributed Tracing by Yuri Shkuro](https://www.shkuro.com/books/2019-mastering-distributed-tracing/). If you need to know more about a specific area of distributed tracing this book probably has you covered.

1. [Distributed Tracing — we’ve been doing it wrong](https://medium.com/@copyconstruct/distributed-tracing-weve-been-doing-it-wrong-39fc92a857df). This is not so much a critique of tracing but rather a suggestion that we could be doing so much more with the data than what is currently the "state of the art" - the trace-view. One of the key points of the post is that "spans are too low level". Even though this might not be the most actionable post to read if you're just getting into distributed tracing it's still a nice thought-provoking post to keep in mind as you're becoming more comfortable with the tools.

Remember, there is more to observability than tracing.

1. [Visualizing Distributed Systems with Statemaps by Bryan Cantrill](https://www.youtube.com/watch?v=U4E0QxzswQc&feature=youtu.be). First half is about observability in general. His biggest point here is that we should keep the human in mind when building observability tools:

    > We must keep the human in mind when developing for observability - the capacity to answer arbitrary questions is only as effective as the human asking them. 
    
    The second half shows a new visualization they've been working on at Joyent called Statemaps. It is a generic and system neutral tool for visualizing system state over time. [Statemaps](https://github.com/joyent/statemap) are useful for prompting questions, but doesn't give you answers in itself - you need your other observability tools to answer the questions.

1. At some point when trying to understand a performance problem you might find yourself with a single node or process that is just not performing the way you would expect. To help you in that situation I recommend **Chapter 4 "Observability Tools" of Systems Performance by Brendan Gregg**. It focuses on the observability tools you can use to find performance bottlenecks on a single host. Most of the other resources lean towards distributed systems, so this chapter is really useful if you have used the other tools to pinpoint a problematic host, and now you need to figure out *why* this specific host is having problems. I'm still working my way through the book, but it has been a great read so far. I like his analogy for describing the difference between static and dynamic tracing:

    > analyzing kernel internals can be like venturing into a dark room, with candles (system statistics) placed where the kernel engineers thought they were needed. Dynamic tracing is like a flashlight you can point anywhere
    
    I'm eagerly awaiting his newest book [BPF Performance Tools](http://www.brendangregg.com/bpf-performance-tools-book.html).

--- 

I hope this was useful. I'll do a follow-up post on how we've been rolling out distributed tracing at [Glitch]. Right now we have instrumented about a third of our services using OpenCensus and are sending traces to [Honeycomb](https://www.honeycomb.io) through the OpenCensus Collector. It has been live in production for about a week.

[^1]: [Lightstep blog "Three Pillars with Zero Answers - Towards a New Scorecard for Observability"](https://lightstep.com/blog/three-pillars-zero-answers-towards-new-scorecard-observability/)
[^2]: [Tweet by Charity Majors](https://twitter.com/mipsytipsy/status/1044666259898593282)
[^3]: Episode 7 of [ollycast: the observability podcast](https://twitter.com/o11ycast) around 11:40.


[Glitch]: https://glitch.com
