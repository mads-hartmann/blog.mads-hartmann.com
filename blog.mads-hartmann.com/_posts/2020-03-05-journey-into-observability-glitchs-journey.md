---
layout: post
title: "Journey into Observability: Glitch's journey"
date: 2020-03-05 12:00:00
categories: SRE
colors: pinkred
excerpt_separator: <!--more-->
---

As I have alluded to in the other parts of this little series of posts we've  been investing in observability tools at [Glitch](https://glitch.com/create) to help us keep the platform reliable, even as more and more people run their apps on Glitch. In this post, I'll focus on why we started investing in observability tools, where we are now and how we got there, and finally what we still haven't figured out.

<!--more-->

{::options parse_block_html="true" /}
<div class="note-box">
This is the third post in a [series of post on observability](/series/observability/index.html). If you like this post make sure to also check out the other posts in the series.
</div>

**Outline**

{: .no_toc }
* TOC
{:toc}

## Glitch 

{::options parse_block_html="true" /}
<div class="emphasis_block">
*If this your first encounter with observability I recommend reading my two previous posts on the topic before this one: [reading material](https://blog.mads-hartmann.com/sre/2019/08/04/journey-into-observability-reading-material.html), and [telemetry](https://blog.mads-hartmann.com/sre/2020/01/11/journey-into-observability-telemetry.html)*
</div>

In observability, context is everything. The same goes for experience reports like this post - otherwise, you have no way of accessing if any of our experiences are applicable to you. So, we are around ~30 developers who maintain ~5 micro-services which run on ~1000 EC2 instances that serve around 100k requests/minute[^1].

Now, in the context of observability, the exact value for these numbers isn't important - sure the request/minute is important as a sufficiently high number means you probably have to sample your telemetry - the most important thing is the change rate. In Glitch's case all but the number of micro-services has increased dramatically in the year or so I've been here.

The change rate is important as it influences how often you'll come upon unknown-unknowns during incident response; if things change all the time it's very likely you're debugging something you've never debugged before. In production. While everything is in flames. Your assumptions, hunches, and mental model might all be of little use as everything has changed since the last incident. Last week. This is where observability shines, it increases the likelihood that you can ask questions of your systems you hadn't anticipated ahead of time.

That's not to say that you only need observability to help with incident response; that's just where the lack of it hurts the most. In our experience observability has changed how we think about production to the point where it has influenced how we deploy and experiment with our code - but more on that later in the post.

<!-- (this is also true for new employees) -->

### Why we started investing in observability

In some sense, Glitch's journey into observability began way before I started working here. When I joined we had a *sort-of-if-you-squint* custom distributed tracing solution in place. We generated a `request-id` for every incoming request and propagated it throughout our system and attached it to our telemetry - this allowed us to see all logs line for a single request in Kibana, for example. We also had some timing method you could use to record the duration of a task which would result in a timing metric which was sent to our metrics provider, as well as a `timing started: <name>` and `timing ended <name> <duration>` log lines which could be viewed in Kibana. The `request-id` is analogous to a `trace-id` and the timing marks indicate a `span`. We added lots of tags to our telemetry, like `request-route`, `project-id`, etc. This allowed us to ask questions like:

- How long does it take to cold-start a Glitch project split by mean, p50, p95, p99 - but also drill down to the individual projects.

- Similarly, we could use the metrics to understand the latency profile of specific routes. If a route had a performance regression we could slice it by a few dimensions, like the EC2 host, or find individual requests to the route in Kibana and look at the timing logs to try to understand where the latency was introduced; essentially constructing a trace-view mentally by reading log lines.

So at a quick glance, this looks pretty good - it's a lot of data which can be sliced on high cardinality columns such as the Glitch project id - we have **a lot of projects** - but unfortunately we had two problems with this approach:

- While it's true that we could use our tools to look at latency profiles split by high cardinality values, it wasn't exactly an easy thing to do - the tool was mainly focused on creating static graphs for dashboards and alerting, not short-lived exploratory investigations. Similarly, we could construct a trace-view mentally, but doing so involved a significant cognitive overhead just to reconstruct a single trace. So, while the data was technically available it was very hard to actually use; to the point where almost nobody would use it. Collecting the data isn't valuable if no-one is looking at it.

- Secondly, as you might have guessed, this is an expensive way to add tracing to your systems. With no sampling, 65% of all our log lines were timing start/end lines. We were sending 5 million custom metrics monthly to our vendor (we were allowed around 30K) - which resulted in a slightly unhappy mail from our metrics provider and a threat of an astronomically high monthly fee if we didn't stop sending all those high-cardinality metrics. Thankfully we worked it out with them without paying for our overages.

All of this is to say that we were already trying to ask sophisticated questions using high-cardinality data. We just didn't have the tooling in place. The tools weren't built for these kinds of queries, which resulted in a bad user experience and unhappy vendors. And we wanted to add more high-cardinality values - we wanted to understand the latency profile not just for specific routes and projects, but also split by user id, user agent, and so on. So, we needed a new approach, one that was built with these kinds of use-cases in mind.

### Where we are now and how we got here

We introduced distributed tracing and converted all our manual timing method invocations to spans. This reduced our generated log lines by 65% and removed most of our custom application-level metrics which made our metrics vendor happy.

We instrumented our services using OpenCensus. Each service sends the trace data to a local OpenCensus collector which has been configured to perform simple head-based sampling before shipping the data off to Honeycomb. We chose OpenCensus as it's vendor-agnostic - at the time we started our journey OpenTelemetry wasn't ready. We plan to eventually migrate to that. 

We started instrumenting services that were earliest in the request path from a user's perspective and worked our way backwards. This made it possible to observe the latencies for specific requests early on; adding more services was then a matter of "filling out the blanks" in our traces. This meant that we got
a lot of value out of the traces really quickly; a little observability goes a long way.

We created a telemetry checklist for each service and methodically worked on getting each service to conform to the checklist.

## Our experience so far

At this point, we've had all our services instrumented for about six months or so. We still have a few things we haven't sorted out yet - more on that in the next section - but we have used it enough that I feel comfortable sharing some of our experiences so far.

While I don't have any exact numbers to share, I do feel that we're able to handle incidents faster and with more confidence. We're able to disprove our hypotheses more quickly, which means we usually find the problems faster. Overall there are fewer occasions where we draw up blanks during incident response. This alone has made it worth the effort, but one of the most valuable things we've gotten out of this journey is a shift in perspective. We now expect to be able to view and understand what our services are doing in production to a level we didn't before. That means we're now more comfortable carrying out small experiments, and it's starting to influence how we release our software - smaller changes, guarded by feature flags. Adding these capabilities involved work that's outside the scope of observability, but aiming for observability pushed us to do better. I'm not surprised companies that are far into their observability journey start advocating for testing in production - once you have the data and you can slice & dice it as you see fit, testing in production seems like a totally reasonable thing to do.

One thing that has surprised me is that we don't use the trace-view very much. We're mostly slicing & dicing heatmaps until the problem reveals itself. I think the reason the trace-view is so prevalent is that it very clearly, and visually, explains what traces are in a way that's easier to understand than "A trace is a tree of spans". But a single trace is rarely very interesting - it's the patterns between many of the same traces that help you understand the behavior of your systems. If all my distributed tracing tool did was show individual trace-views, but didn't give me a way to query and aggregate them on the fly, it really wouldn't be of much use.

### What we haven't figured out yet

There are still a few things we haven't quite sorted out yet:

- <span id="sampling-is-hard">Getting sampling right is hard</span>. We still rely on metrics and logs in some circumstances. The general rule-of-thumb internally right now is: If you need to know the exact number of times something happened, then use a metric or a log line alongside tracing. This is mostly for infrequent events where we worry that our aggressive sampling won't catch them. If we could move the sampling decision to the application layer and give the developer the power to choose that an event shouldn't be sampled I think all of our custom application metrics could go away. I also find the idea of using targeted feature flags to control sampling for a specific subset of services or users at runtime very alluring; essentially what [Will Sargent](https://twitter.com/will_sargent) describes in his post [Targeted Diagnostic Logging in Production](https://tersesystems.com/blog/2019/07/22/targeted-diagnostic-logging-in-production/) but for traces.

- Right now we don’t instrument our frontends. This is unfortunate as it means there’s a big part of a request’s life-cycle we can't observe. We had a problem with an elevated rate of 502 requests as experienced by our load balancer (ALB) which wasn’t reflected in our traces. If the traces had started in the browser rather than the first service to receive the request from the ALB then we would’ve noticed the problem much sooner.

### Advice

Here's a bit of advice if you're considering starting your own journey into observability.

- I highly encourage writing a Telemetry checklist. Having services produce consistent telemetry makes it easier to debug problems across services and helps build a shared vocabulary. You can also use it to communicate progress with the rest of your company as you're working on having all services conform to the checklist.

- Start instrumenting the services that are closest to your users and work your way backwards in your service hierarchy. This makes it possible to observe slow requests as experienced by your users early on - adding more services is then a matter of “filling out the blanks” in your traces. This way you'll get value out of your traces really early in your journey; a little observability goes a long way.

- Be sure to advocate for your observability tools internally - your tools are only worth the money you pay for them if people use them.

If you're still not sure how you would start rolling out observability at your company I recommend listening to the [Page It to the Limit](https://www.pageittothelimit.com) episode titled [Observability With Christine Yen](https://www.pageittothelimit.com/observability-with-christine-yen/). It's a good introduction to observability, but it also ends with succinct description of the steps involved in rolling out observability; the main theme throughout the episode is that observability isn't only for operations.

Best of luck on your observability journey.

[^1]: If you do the math that's 100 requests per minute per box. On the surface that isn't very impressive, but keep in mind we run full-stack apps for our users - most of these boxes are doing much, **much** more than just serving HTTP requests 😉
