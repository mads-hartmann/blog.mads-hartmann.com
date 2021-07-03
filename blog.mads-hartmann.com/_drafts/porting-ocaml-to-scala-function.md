---
layout: post
title: "Porting three lines of OCaml to Scala"
date: 2018-06-27 08:00:00
colors: pinkred
excerpt_separator: <!--more-->
---

Recently I've been porting ocaml-graphql-server to Scala. It's been
super fun and has forced me to re-learn a lot of Scala type-level
programming techniques.

<!--more-->

## Table of contents
{: .no_toc }
* TOC
{:toc}

## The Goal

We want to define a GraphQL object with the following API

```scala
Schema.field(
  name = "create",
  type = NonNull(User.T).
  arguments = (
    Arg.id("id"),
    Arg.string("name"),
    Arg.int("age")
  ),
  resolve = (ctx, _, id, name, age) => User(id, name, age)
)
```

The important thing here is that the `resolve` function has the
correct return type and that it takes the correct number and typed
arguments.

## High-level approach

- Convert TupleX[]
- Prepend CTX and SRC to TupleX
- Convert a FunctionX to a Function1[TupleX]

## A Detour: Prolog

Let's take a little detour into the world of logic programming. It's
sometimes easiest to understand a concept when you've seen it it's
pure form.

## The implementation


[ocaml-graphql-server]: 
