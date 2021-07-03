---
layout: post-no-separate-excerpt
title: "Thundering herds, noisy neighbours, and retry storms"
date: 2021-05-14 10:00:00
categories: SRE
colors: pinkred
---

Thundering herds, noisy neighbours, retry storms.

I love the names that people have come up with over the years. Some of them describe observed patterns, as [Lorin Hochstein](https://surfingcomplexity.blog/) so eloquently put it "Operators give names to recurring patterns of system behavior that they observe" ([tweet](https://twitter.com/norootcause/status/1392721477447733249)), others describe techniques used to mitigate these observed patterns.

I don't know what you'd call these names, and I haven't been able to find a dictionary or list of them anywhere, so I've wanted to create a list for a while now. 

**Update (17th May 2021)**: [Lex Neva](https://sreweekly.com/bio/) suggested calling these "operational patterns" and I love it.

So here we go, I'll add some now based on the few I can remember and notes I have on my computer, and then I can always come back and add more as a I come across them.

I'd love your help growing this list. If you know of a name that is missing from the list please send me a [tweet](https://twitter.com/Mads_Hartmann) with the name and a short description of it and I'll include it in the list with a link to your tweet 😍

{: .no_toc }
## Table of contents
* TOC
{:toc}

## Names

### Thundering herd

[[Wikipedia](https://en.wikipedia.org/wiki/Thundering_herd_problem)]

I first came across this term from a colleague at Glitch who used it to describe the situation where we had just recovered from an incident, only to have everything break once all our users tried to start their projects again 😅 The surge of projects overwhelmed the system and everything broke. It was truly a thundering herd.

Other related names are: Dogpile, Cache-stampede [[wikipedia](https://en.wikipedia.org/wiki/Cache_stampede)]

### Noisy neighbour

[[wikipedia](https://en.wikipedia.org/wiki/Cloud_computing_issues)]

I don't remember when I first came across this, but it has come up quite a lot both at Glitch and Gitpod.

### Nosy neighbour

Okay this isn't a thing, but I really think it should be ([tweet](https://twitter.com/Mads_Hartmann/status/1393257951830462468)).

### Retry storm

It's a bit like the thundering herd, but specific to retries. Still a great name.

[[Microsoft - Retry Storm antipattern](https://docs.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/)]

### Banding

[[tweet](https://twitter.com/norootcause/status/1393037129870053380)]

### Dimensions of doom

This is specific to time series databases that don't support high cardinality labels, but I still love it.

> The number of time series quickly becomes overwhelming, and impossible to store for tools that aren’t designed to handle it, much less read it back quickly enough to help you figure out where issues lie.

~~I don't know the source of the description above. I found it in a note on my computer, but I doubt I wrote it. If you know where it might be from send me a tweet and I'll link to it here.~~

This is from [How Does Honeycomb Compare to Metrics, Log Management, and APM Tools?](https://www.honeycomb.io/blog/how-does-honeycomb-compare-to-metrics-log-management-and-apm-tools/), thanks to Kevin Collas-Arundell for spotting the reference ([tweet](https://twitter.com/kcollasarundell/status/1394105640293867520?s=20))!

### Load shedding

Purposefully reducing requests to your systems to avoid them falling over. Netflix wrote a great post about it here: [Keeping Netflix Reliable Using Prioritized Load Shedding](https://netflixtechblog.com/keeping-netflix-reliable-using-prioritized-load-shedding-6cc827b02f94)

### Circuit Breaker

[[wikipedia](https://en.wikipedia.org/wiki/Circuit_breaker_design_pattern)]

### Haunted Graveyard

Submitted by [Lorin Hochstein](https://twitter.com/norootcause) in [this tweet](https://twitter.com/norootcause/status/1394085634789154820?s=20)

> I like "haunted graveyards" (learned this one from @john_p_looney), about systems that people are afraid to change.

Another related name for this is Haunted Forrest (see [tweet](https://twitter.com/jhscott/status/1394089724701151234) from [Jacob](https://twitter.com/jhscott))

### Flapping

Submitted by [James Cheng](https://twitter.com/lorax_james) in [this tweet](https://twitter.com/lorax_james/status/1394090072836689921)

> "flapping". When something repeatedly switches back and forth between "good" and "bad". Imagine a health check for something that is healthy, then gets overwhelmed, then recovers, then again gets overwhelmed.

With follow up additions by [rat rancher](https://twitter.com/__eel__) [tweet](https://twitter.com/__eel__/status/1394111889571860485)

> I've heard "flapping" mainly with regard to flapping links on network devices:

And [Lorin Hochstein](https://twitter.com/norootcause) in this [tweet](https://twitter.com/norootcause/status/1394112070140841991)

> I’ve heard of flapping alerts.

### Flaky

[Jan Keromnes](https://twitter.com/jankeromnes) calls out the similarity to Flaky in this [tweet](https://twitter.com/jankeromnes/status/1396408454722506752); I've heard them used interchangeably and think of them as synonyms:

> The definition of "flapping" makes me think of "flaky" (as in "flaky tests" -- personally I've never heard "flapping" used that way)

### Death spiral

Submitted by [Lex Neva](https://sreweekly.com/bio/):

> I'm talking about the pattern where the system reacts to a failure or degradation in certain ways that act to amplify the problem.  An example is the db struggling under load, and the auto-scaler notices the degradation and starts adding front-ends, but the front-ends have to boot up by running a few intensive queries, exacerbating the load, so the auto-scaler adds more instances...

### Verbalmatic

This was submitted by Paul de Lange who writes "I would like to contribute one that we use at Expedia. This was coined by Mike Peterson, and first appeared in an internal conversation on 18 September, 2020."

> When the answer should be automatic but it isn't, and so we rely on talking to a bunch of people to come up with the answer. This goes against the tenants of SRE because it is manual toil to answer the question each time and the reliability of the answer depends on the specific person you ask.

### Numbers from Lost

Submitted by [Mark Ellens]

> Another is 'numbers from Lost' wherein a human being has to perform a certain action (entering a series of numbers, applying a specific piece of config) on a regular basis, at a specific interval, otherwise dire consequence (island explosion, catastrophic system failure) will ensue.  Like in Lost, you see.

### turn it off and on again...and again

Submitted by [Mark Ellens]

> The scenario is that you have a message queue and one of the consumers stops processing messages and so the queue backs up. A naive fix for your immediate issue is to, predictably, turn it off and on again.  With a certain type of issue it will then start to look like it is processing normally, perhaps even long enough to make the SRE / person on call close the ticket, go back to bed, set off for the office or whatever.  At which point the actual cause (perhaps a badly formed message) would come in, cause monitoring to back up, and trigger another alert.  An optimistic / inexperienced SRE can waste a good few hours in this way.

### Chesterton Fences

Submitted by [motxilo](https://twitter.com/motxilo) in this [tweet](https://twitter.com/motxilo/status/1394371924201988114) which links to [this blog post](https://josephwoodward.co.uk/2020/04/software-the-chestertons-fence-principle):

> The sun is shining and you're walking through a wood when you happen upon quiet, desolate road. As you walk along the road you encounter an rather peculiar placed fence running from one side of the road to the other. "This fence has no use" you mutter under your breath as you remove it.
>
> Removing the fence could very well be the correct thing to do, nonetheless you have fallen victim to the principle of Chesterton's Fence. Before removing something we should first seek to understand the reasoning and rationale for why it was there in the first place.

I've definitely fallen victim to this. I can just see the PR "Removed superfluous config" and down went production 😅

## Changelog

### 2021 May 14

Initial version of the list

### 2021 May 17

Added 

- [Haunted Graveyard](#haunted-graveyard)
- [Flapping](#flapping)
- [Death spiral](#death-spiral)
- [Verbalmatic](#verbalmatic)

### 2021 May 23

Added 

- [Numbers from Lost](#numbers-from-lost)
- [turn it off and on again...and again](#turn-it-off-and-on-againand-again)
- [Chesterton Fences](#chesterton-fences)
- [Flaky](#flaky) which I believe is a synonym for [Flapping](#flapping)

<!-- Links -->
[Mark Ellens]: https://www.linkedin.com/in/mellens/