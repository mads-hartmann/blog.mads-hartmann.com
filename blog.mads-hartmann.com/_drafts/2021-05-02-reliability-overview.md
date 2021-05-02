---
layout: post-no-separate-excerpt
title: "Reliability overview"
date: 2021-05-01 08:00:00
categories: SRE
colors: pinkred
---

I recently left [Glitch](https://glitch.com]) where I had been an Staff level SRE for two years, and an engineering manager for the platform team for my last six months. I'm joining [Gitpod](https://gitpod.io) as a SRE. I loved managing the platform team; .. but when joining a new company I found it much more comfortable to join as an IC. That's what i know best, that's where I feel safest. And with a small kid, not being overwhelmed by work is a high priority for me. I could definitely see myself [swinging back and forth](https://charity.wtf/2017/05/11/the-engineer-manager-pendulum/) between being a manger and an IC over the next many years.

But that's not the topic of this post.

Before joining I thought a bit about how to get a bit of situational awareness once I joined, and how to figure out how best to contribute to the reliability of the platform.

So I came up with the list you see below. I intend to update it as I realise things have been missing. When you're joining a new company as an SRE, what would you have on your list?

This is not a complete list of what I beleive are the responsibilities of a SRE.

This is not an attempt to give a company a reliability score, these are areas I'd want to know how the company doing, and to find places where I might be able to help.

## Table of contents
{: .no_toc }
* TOC
{:toc}

## Release process  

How do they release their software and at what cadence?

- Do they release whenever they merge into main, and are there any manual steps involved?
- Do they use feature flags to separate deployment and release, or to run experiments in production?

## Observability

How are they debugging their production systems?

- What kind of telemetry do they have in place and what tools do they use?
- Are there any guidelines around naming conventions and instrumentation in general?
- Do they use their tools as part of the regular feedback, or only during incidents?

## Monitoring & alerting

How are they monitoring their production systems?

- Do they experience a high false-posistive rate of alerts?
- Do they have SLOs?
- Do they have an guidelines around alerting? E.g. rules for when something should be high or low urgency.
- Do they use runbooks for their alerts?
 
## On-call

How are they dealing with on-cal, if at all.

- How do they put on the on-call rotation?

## Incident response

How do they deal with incidents in production when they happen.

- Do they have a guide - an incident playbook - for how to respond to incidents?
- How are they learning from their incidents. If they write up incident retrospectives, ask to see some of the interesting ones.