---
layout: post
title: "Effects"
date: 2017-12-28 12:00:00
colors: pinkred
---

I'd like to write a blog post outlining the landscape of possible
solutions you have at your disposal when you want to abstract over
effects.

- Monads & Monad Transforms
- Free(r) Monads (might also be known as extensible effects, effect
  handlers)
- Algebraic Effects
  (About effects and their equations (Comment by Joy))

The following topics might be related but I'm not sure they're
necessarily needed to describe the above.

- [Tagless Final Interpreters](http://okmij.org/ftp/tagless-final/index.html) (alternative to Free Monad?)
- co-, free-, laxABC where ABC is a category
- Indexed Monads

Suggestions by Cem

- ReactiveX (continuation monad + extra), FS2

## Resources

- Replies to [my tweet](https://twitter.com/Mads_Hartmann/status/946452171930918914)
- Joy's [gist](https://gist.github.com/cyberglot/07f0e6c1fec0ebdc06282895f84aa5a5)
- [Jonathan Brachthäuser - Effekt: Extensible Algebraic Effects in Scala | Scala Symposium 2017](https://www.youtube.com/watch?v=79CXOlIevVU)
  Uses implicit function types (from dotty) to write a library in
  Scala for Extensible Algebraic effect. The library can be found on [Github](https://github.com/b-studios/scala-effekt).
  There's a very brief reference to other techniques (tagless final,
  etc.) so it might be worth watching this again at a later date (once
  I know more about the other topics).
