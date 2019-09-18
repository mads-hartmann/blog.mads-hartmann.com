---
layout: post
title: "FamlyOps: Database migrations"
date: 2018-09-13 12:00:00
colors: pinkred
excerpt_separator: <!--more-->
---

I love database migrations. Or well, not really, but I love when they don't get
in my way. It's one of those things that a  lot of developers have to deal with
so having a good workflow around them makes everything much more enjoyable. In
this post I'll sketch out how we deal with them at Famly.

<!--more-->

There's quite a lot of things to consider when you try to figure out how you
want to perform database migrations. It should preferably be **easy** on the
developer that has to write them, the migrations should be **testable**, and
**safe** to run in production.

{: .no_toc }
* TOC
{:toc}

---

**FamlyOps** This is part of a short series I hope to write (this being the
first issue) about how we perform some of our operation tasks at Famly. Recently
I've been doing a bit more of this kind of work and I find it really
interesting. It's also changing quite rapidly so I hope that future me will find
these posts fun to look back on in the future.

**Disclaimer** We're a fairly small team and no one person is hired just to work
on these things. So our solutions are trade-offs between time and what we'd
ideally like to have.

---

## Background

Our **requirements** - or well, wish-list is probably a more succinct
description if I'm being honest, looked something like this

- The migrations should go together with the code that uses it so they can be
  reviewed together
- The migrations should be verifiable by out CI system for PR
- They should be run automatically whenever a service is deployed


We started out with core. Core is a monolith written in PHP and it
uses Doctrine as the database layer. Doctrine is an ORM where you
define your model in PHP and then use a script to generate your
database.

We slowly started writing a new service in Scala. Core still owned the datbase.
The Scala service started to need to run SQL migrations as well.

We didn't want to have two databases. The extra ops work required weren't worth it.

Problems
- Now generating an empty fully migrated databse requires multi repos
- Generating demo data requires more moving parts

## Developers

## CI

## Deployment

