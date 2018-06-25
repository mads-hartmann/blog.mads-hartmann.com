---
layout: post
title: "GADTs and the expression problem"
date: 2018-06-25 08:43:58
categories: scala
colors: yellowblue
excerpt_separator: <!--more-->
---

Recently I've been attempting to port [ocaml-graphql-server](https://github.com/andreas/ocaml-graphql-server) to Scala.
The design of the library in OCaml uses GADTs quite heavily so this
was a chance for me to revisit how to use GADTs in Scala.

<!--more-->

> The Expression Problem is a new name for an old problem. The goal is
> to define a datatype by cases, where one can add new cases to the
> atatype and new functions over the datatype, without recompiling
> existing code, and while retaining static type safety (e.g., no
> casts) - Philip Wadler, 1998. [Link](http://homepages.inf.ed.ac.uk/wadler/papers/expression/expression.txt)

## Resources

- [Haskell GADTs in Scala](http://lambdalog.seanseefried.com/posts/2011-11-22-gadts-in-scala.html)
  Even though this post is from 2011 it strikes at the heart of the
  problem. The Scala compiler can't seem to use the various
  constructors of your GADT properly when type-checking.

- [The Expression Problem solved, finally!](https://www.slideshare.net/etorreborre/the-expression-problem-solved-finally) by [Eric Torreborre](https://twitter.com/etorreborre)
  **TODO**: Haven't read this yet. How object algebras, or
  "fold-algebras" can be used to represent data and how its encoding
  as typeclasses or interfaces help with the Expression Problem.

- [Gist that might be useful](https://gist.github.com/calincru/cea751f050883581730093e93eaf2723).
  **TODO** Is this useful?

- [Types in Object-Oriented Languages The Expression Problem in Scala](https://www.scala-lang.org/docu/files/TheExpressionProblem.pdf)
  **PDF**. **TODO** Might be useful.
