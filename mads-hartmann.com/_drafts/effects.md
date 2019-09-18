---
layout: post
title: "Effects"
date: 2018-06-18 12:00:00
colors: pinkred
---

Some time ago I started reading up on various ways to abstract over
effects. Turns out there's an pretty overwhelming amount of approaches
and techniques available. In this blog-post I'll try to cover some of
the most popular ones.

As far as I can tell there are the following different approaches to
dealing with effects - they might overlap in some areas.

- Monads
- Algebraic Effects
- Extensible Effects
- Effect Handlers
- Effect Systems

And then there's a bunch of concrete instantiations of these concepts.

- Monad Transformers
- The Eff monad
- Free(r) Monads
- Tagless Final

I was familiar with Monads and Monad Transformers though the latter
was mainly from a Haskell course I took back at Univeristy.

This is going to be in the context of Scala where applicable.

## Effects

When it comes to functional programming the word effect is
unfortunately both prevalent and vague. One gets the feeling that it's
synonymous with Monads. Or perhaps it's just the word *side-effects*
where the writer couldn't be bothers to write out the `side-` part of
it. It's not quite any of the two.

The best long-form version of *effect* is probably **effectful
computation**.

Monads model effects that can have data-dependency between them[^1].
Applicatives model *static* effect flows.

So what are effects? Take the following Scala example

```scala
type F[A] = ???
def xyz(x: X): F[Z]
```

I'd say that this function computes the a value of type `Z` using some
effect `F`. Or more concisely, as expressed by Rob Norris:

> an effect is what distinguishes `F[A]` from `A`.

So an effect is not in an on itself super exciting. What's interesting
is how your languages deals with them and how you can compose them.

## Extensible Effects

## Algebraic Effects

About effects and their equations (Comment by Joy)

## Thanks

Many of the papers that you'll find in the list below were suggested
to me by [Joy](https://twitter.com/cyberglot) in this [Gist](https://gist.github.com/cyberglot/07f0e6c1fec0ebdc06282895f84aa5a5). Also thanks to [@cem](https://twitter.com/cem2ran) and [@keleshev](https://twitter.com/keleshev) for
replying to my [original tweet](https://twitter.com/Mads_Hartmann/status/946452171930918914) **many** months ago when I started
researching the material for this blog post.

## Resources

### Ideas

- Functional programming with effects, use case: tracing. Each effect can be
  traced meaningfully - db, network, filesystem, etc

### Talks

- **[Functional Programming with Effects](https://www.youtube.com/watch?v=po3wmq4S15A) by Rob Norris**.
  This is one of the best and gentlest introductions to Monads that
  I've seen. Even if you can recite the Monad laws in your sleep this
  is still worth a watch as it might give you a new approach to
  teaching Monads to other developers.

- [Effekt: Extensible Algebraic Effects in Scala | Scala Symposium 2017](https://www.youtube.com/watch?v=79CXOlIevVU) by Jonathan Brachthäuser
  Uses implicit function types (from dotty) to write a library in
  Scala for Extensible Algebraic effect. The library can be found on
  [Github](https://github.com/b-studios/scala-effekt). There's a very brief reference to other techniques (tagless
  final, etc.) so it might be worth watching this again at a later
  date (once I know more about the other topics). They also did a
  [short paper](http://files.b-studios.de/effekt.pdf) about it.

### Papers

### Blog Posts

- [Deferring commitments: Tagless Final](https://medium.com/@calvin.l.fer/deferring-commitments-tagless-final-704d768f15cb) by Calvin F
  **TODO**: Haven't read this yet.

- [Typed final (tagless-final) style](http://okmij.org/ftp/tagless-final/index.html) by Oleg Kiselyov
  Has a nice short description of tagless final. It's main an index
  over all the work Oleg has done that's related to tagless final.

- [Free and tagless compared - how not to commit to a monad too early](https://softwaremill.com/free-tagless-compared-how-not-to-commit-to-monad-too-early/) by Adam Warski
  Quick introduction to both Free and Tagless Final. Then compares the
  two encoding through a couple of examples: combining languages,
  compiling to a low-level instruction set. It has a very name
  comparison table in the end.

- [Writing a simple Telegram bot with tagless final, http4s and fs2](http://pavkin.ru/writing-a-simple-telegram-bot-with-tagless-final-http4s-and-fs2/) by Vladimir Pavkin
  A concrete example showing how to build a small application using
  Tagless Final.

### Might be relevant

- [A roadtrip with monads: from MTL, through tagless, to BIO - Paweł Szulc](https://www.youtube.com/watch?list=PLdefG8qcBW3bIA7p0sT785UkOryzLRg2Z&v=QM86Ab3lL20)
- [Comment on Reddit about IO](https://www.reddit.com/r/scala/comments/8ygjcq/can_someone_explain_to_me_the_benefits_of_io/e2jfrg8/)

[^1]: Lovely quote from Rob Norris' [Talk](https://www.youtube.com/watch?v=po3wmq4S15A).
