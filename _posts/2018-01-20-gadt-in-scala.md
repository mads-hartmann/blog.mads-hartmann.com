---
layout: post
title: "GADTs in Scala"
date: 2018-01-20 12:00:00
categories: scala
colors: yellowblue
excerpt_separator: <!--more-->
---

Three years ago I wrote a blog post about how to detect use-cases for
GADTs. The examples were written in OCaml as that was the language I
was working in at the time.

Today I'm mostly working in Scala so I thought it would be fun to
translate the examples to Scala.

**note**: I Had to rename some of the classes as they're reserved in
Scala (For example `Int` is already taken ;)

<!--more-->

## Table of contents
{: .no_toc }
* TOC
{:toc}

## ADT

```scala
sealed trait Value
final case class VBool(value: Boolean) extends Value
final case class VInt(value: Int) extends Value

sealed trait Expression
final case class Val(value: Value) extends Expression
final case class If(condition: Expression, thn: Expression, els: Expression) extends Expression
final case class Eq(left: Expression, right: Expression) extends Expression
final case class Lt(left: Expression, right: Expression) extends Expression
```

blah blah

```scala

def eval(expression: Expression): Value = expression match {
    case Val(v) => v
    case If(condition, left, right) => eval(condition) match {
        case VBool(true) => eval(left)
        case VBool(false) => eval(right)
        case VInt(_) => throw new Exception("Invalid AST")
    }
    case Lt(left, right) => (eval(left), eval(right)) match {
        case (VInt(x), VInt(y)) => VBool(x < y)
        case (VBool(x), VBool(y)) => VBool(x < y)
        case (VInt(_), VBool(_)) | (VBool(_), VInt(_))  => throw new Exception("Invalid AST")
    }
    case Eq(left, right) => (eval(left), eval(right)) match {
        case (VInt(x), VInt(y)) => VBool(x == y)
        case (VBool(x), VBool(y)) => VBool(x == y)
        case (VInt(_), VBool(_)) | (VBool(_), VInt(_))  => throw new Exception("Invalid AST")
    }
}

```

blah blah

```scala
eval(
    If(
        condition=Lt(
            left=Val(VInt(2)),
            right=Val(VInt(4))
        ),
        thn=Val(VInt(42)),
        els=Val(VInt(0))
    )
)
```
```
res: Value = VInt(42)
```

blah blah

```scala
eval(
    Eq(
        left=Val(VInt(42)),
        right=Val(VBool(false))
    )
)
```
```
java.lang.Exception: Invalid AST
```

blah blah 

```scala
def evalInt(value: Value): Int = value match {
    case VInt(x) => x
    case VBool(b) => throw new Exception("Got bool expected int")
}

def evalBool(value: Value): Boolean = value match {
    case VBool(b) => b
    case VInt(x) => throw new Exception("Got int expected bool")
}
```

## GADT

```scala
sealed trait Value[A]
final case class VBool(value: Boolean) extends Value[Boolean]
final case class VInt(value: Int) extends Value[Int]

sealed trait Expression[A]
final case class Val[A](value: Value[A]) extends Expression[A]
final case class If[A](condition: Expression[Boolean], thn: Expression[A], els: Expression[A]) extends Expression[A]
final case class Eq[A](left: Expression[A], right: Expression[A]) extends Expression[Boolean]
final case class Lt[A : Ordering](left: Expression[A], right: Expression[A]) extends Expression[Boolean]
```

blah blah

```scala
def eval[A](expression: Expression[A]): A = expression match {
    case Val(VBool(b)) => b
    case Val(VInt(x)) => x
    case Eq(left, right) => eval(left) == eval(right)
    case Lt(left, right) => {
        val l: A = eval(left).asInstanceOf[A] // WHAT!
        val r: A = eval(right).asInstanceOf[A]
        implicitly[Ordering[A]].lt(l, r)
    }
    case If(condition, left, right) => 
        if (eval(condition)) eval(left)
        else eval(right)
}

```

blah .. Okay I think it has something to do with type erasure :O

<div class="sidenote">
Type erasure is .. blah blah
</div>


```scala
eval(
    If(
        condition=Eq(
            left=Val(VInt(2)),
            right=Val(VInt(2))
        ),
        thn=Val(VInt(42)),
        els=Val(VInt(0))
    )
)
```

Now if we give an invalid example as try, let's see what happens

```scala
eval(
    If(
        condition=Val(42),
        thn=Val(VInt(42)),
        els=Val(VInt(0))
    )
)
```
```
type mismatch;
 found   : Int(42)
 required: Value[Boolean]
```

But OMG, that's with the cast!

this blog post https://medium.com/@sinisalouc/overcoming-type-erasure-in-scala-8f2422070d20 
has some hints as to how to overcome type erasure but it doesn't seem
like it helps this case.

### GADT the Scala way

The blog post here is not a solution. (Do I want to keep it for as a reference?)

.. So that solution doesn't work either as it doesn't have a `Lt`
construct. The `Eq` construct is cheating a bit as Scala defines `==`
for `Any` so you don't see the problem (the same is true for my
original OCaml example.).

I was a bit puzzled to be honest. I found the solution in this
[post](http://lambdalog.seanseefried.com/posts/2011-11-22-gadts-in-scala.html) from 2011
