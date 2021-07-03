---
layout: post
title: "OCaml Briefly"
date:   2014-11-13 14:00:00
categories: ocaml
---

This document gives you a brief tour of [OCaml](https://ocaml.org/). It covers
a rather small selection of features; the selection has been based on what
features I personally think represent OCaml the best.

This document does very little to explain use-cases for the selected features
but rather focuses on syntax. For a more in-depth coverage of all of these
features I recommend reading the [OCaml Document and User's
Manual](http://caml.inria.fr/pub/docs/manual-ocaml/) and [Real World
OCaml](https://realworldocaml.org/).

For each feature there is a small explanation of the syntax, some examples, and
links for further reading. As such this document is ideal for someone who wants
to get a taste of the features of OCaml or who want to learn more about a
specific feature.

If you have any comments please reach out to me at <mads379@gmail.com>
or [@mads\_hartmann](http://www.twitter.com/mads_hartmann) on twitter.

If you want to play around with the code I recommend using
[this](http://ocsigen.org/js_of_ocaml/2.5/files/toplevel/index.html)
online REPL.

**Note**: This is still a work in progress. I haven't yet covered the
following: pattern matching, modules, functors, Abstract Data Types, and much
more.

_You can find a Japanese translation of this post [here](https://postd.cc/ocaml-briefly/)_

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Lists, Arrays, and Tuples](#lists-arrays-and-tuples)
- [Let-bindings](#let-bindings)
- [Functions](#functions)
  - [Defining functions](#defining-functions)
    - [Labeled arguments](#labeled-arguments)
    - [Optional arguments](#optional-arguments)
    - [Default arguments](#default-arguments)
- [Records](#records)
- [Variants](#variants)
  - [Polymorphic Variants](#polymorphic-variants)
  - [Extensible Variants](#extensible-variants)
- [Exceptions](#exceptions)
- [Generalized Algebraic Datatypes](#generalized-algebraic-datatypes)

## Lists, Arrays, and Tuples

A `List` is constructed using square brackets where the elements are separated
by semi-colons:

```ocaml
[ 1 ; 2; 3 ];;
```

An `Array` is constructed using square brackets with bars where the elements
are separated by semi-colons:

```ocaml
[| 1 ; 2; 3 |];;
```

`Tuples` are constructed using parens and the elements are separated using
commas:

```ocaml
( "foo", "bar", "foobar" )
```
```ocaml
- : string * string * string = ("foo", "bar", "foobar")
```

## Let-bindings

A let-binding associates an identifier with a value. It is introduced using the
following syntax `let <identifier> = <expression> in <expression>`.

```ocaml
let hi = "hi " in
let there = "there!" in
hi ^ there;;
```
```
hi there!
```

The `^` is a function that concatenates two strings. The `^` function is used
as an infix operator in the example above but it could just as easily have been
invoked in a prefix manner as shown below.

```ocaml
(^) "Hi " "there";;
```
```
Hi there
```

Let-bindings are also used to declare functions. More on that in the next
section.

## Functions

As was shown in the previous section you invoke a function by adding the
arguments after the function name separated by whitespace.

```ocaml
min 42 10;;
```
```ocaml
10
```

It might take some time to get used to separating function arguments with
whitespace rather than commas as you do in other programming languages. In
another language the above example might look like this:

```ocaml
min(10,24);;
```
```ocaml
- : int * int -> int * int = <fun>
```

However, in OCaml this will [partially
apply](http://en.wikipedia.org/wiki/Partial_application) the function `min`
with one argument, the tuple `(10, 24)`. Partial application is another nice
feature of OCaml that allows you to supply `N` arguments to a function of arity
`X` and get a function of arity `X-N` in return. This is possible as all
functions in OCaml are [curried](http://en.wikipedia.org/wiki/Currying).

```ocaml
let at_least_42 = max 42 in
at_least_42 22;;
```
```
42
```

### Defining functions

A function is defined using the following syntax
`let <name> <arg1> <arg2> = <expression> in <expression>`, that is, the
function name followed by it's arguments separated by whitespace.

The following is a function that takes one argument `x` (which is inferred to
be an integer) and returns the square value of that integer.

```ocaml
let square x = x * x;;
```
```ocaml
val square : int -> int = <fun>
```

You can use the `fun` keyword to introduce a lambda, it has the following
syntax `fun <arg1> <arg2> -> <expression>`. So the example above is equivalent
to this:

```ocaml
let square = fun x -> x * x;;
```
```ocaml
val square : int -> int = <fun>
```

As mentioned earlier some functions can be used as infix operators. A
function can be used as in infix operator if one of the following names
are used `! $ % & * + - . / : < = > ? @ ^ | ~`. Read more about infix
and prefix functions in [this
section](https://realworldocaml.org/v1/en/html/variables-and-functions.html#prefix-and-infix-operators)
of Real World OCaml.

If your function only takes one argument and you want to pattern match
on it you can use the `function` keyword (please ignore this horribly
inefficient implementation I'm about to show you):

```ocaml
let rec sum = function
  | x :: xs -> x + (sum xs)
  | [] -> 0
in sum [1;2;3;4;5;1;2];;
```
```ocaml
18
```

More on pattern matching
[later](http://mads-hartmann.github.io/ocaml/2014/11/13/ocaml-briefly.html#sec-3-1).
The previous example also shows that if you want to define a [recursive
function](http://en.wikipedia.org/wiki/Recursion_(computer_science)) in
OCaml you have to use the `rec` keyword.

#### Labeled arguments

By prefixing an argument with `~` you can give it a label which makes
the code easier to read and makes the order of the arguments irrelevant.

```ocaml
let welcome ~greeting ~name = Printf.printf "%s %s\n" greeting name in
welcome ~name:"reader" ~greeting:"Hi"
```
```ocaml
Hi reader
- : unit = ()
```

Shayne Fletcher has written [an excellent blog
post](http://blog.shaynefletcher.org/2015/03/labeled-and-optional-arguments.html)
that goes into both labeled and optional arguments (described below) in
more detail.

#### Optional arguments

By prefixing an argument with `?` you can make it optional. The value of
optional arguments are represented using the [`Option`
type](https://realworldocaml.org/v1/en/html/a-guided-tour.html#options).

```ocaml
let welcome ?greeting_opt name =
  let greeting = match greeting_opt with
    | Some greeting -> greeting
    | None -> "Hi"
  in
  Printf.printf "%s %s\n" greeting name
in
welcome ~greeting_opt:"Hey" "reader" ;
welcome ?greeting_opt:None "reader"
```
```ocaml
Hey reader
Hi reader
- : unit = ()
```

#### Default arguments

For optional arguments you can provide a default value. Thus the previous
example could also have been written as such:

```ocaml
let welcome ?(greeting="Hi") name =
  Printf.printf "%s %s\n" greeting name
in
welcome ~greeting:"Hey" "reader" ;
welcome "reader"
```
```ocaml
Hey reader
Hi reader
- : unit = ()
```

## Records

Records are used to store a collection of values together as a single
value. The example below defines a record named `person` with two
components.

```ocaml
type person = {
  name: string;
  age: int;
} ;;
let p = { name = "Mads" ; age = 25 } in
Printf.printf "%s is %d years old" p.name p.age
```
```ocaml
Mads is 25 years old- : unit = ()
```

Records can be parameterized using a polymorphic type.

```ocaml
type 'a ranked = {
  item: 'a;
  rank: int;
};;
let item = { item = Some 42 ; rank = 1 }
```
```ocaml
val item : int option ranked = {item = Some 42; rank = 1}
```

There is a lot more to be said of records. See this [this
section](https://realworldocaml.org/v1/en/html/records.html) of Real
World OCaml and [this
section](http://caml.inria.fr/pub/docs/manual-ocaml/coreexamples.html#sec11)
of the OCaml Users Guide.

## Variants

Variants, also known as [algebraic data
types](http://en.wikipedia.org/wiki/Algebraic_data_type), are commonly
used to define recursive data structures. Just like records they can be
parameterized using a polymorphic type as shown in the example below
where a variant is used to represent a binary tree.

```ocaml
type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a * 'a tree;;
Node ((Leaf "foo"), "bar", (Leaf "foobar"));;
```
```ocaml
- : string tree = Node (Leaf "foo", "bar", Leaf "foobar")
```

The type `tree` has two constructors: `Leaf` and `Node`. The example
below shows one way to compute the height of such a tree:

```ocaml
let rec depth = function
  | Leaf _ -> 1
  | Node (left, _ ,right) -> 1 + max (depth left) (depth right)
in
let tree =
  Node ((Leaf 1), 2, (Node ((Leaf 3), 4, (Node ((Leaf 5), 6, (Leaf 6))))))
in
depth tree;;
```
```ocaml
4
```

The example above uses the `function` keyword to define a function that
takes a single argument that is pattern matched on.

Variants are one of the most useful features of OCaml so it's well worth
spending some more time studying them. See [this
section](https://realworldocaml.org/v1/en/html/variants.html) of Real
World OCaml for information on use-cases and best-practices.

### Polymorphic Variants

OCaml also has another type of variants that they call polymorphic
variants. When using polymorphic variants you do not need to define the
constructors prior to using them - you can think of them as an ad-hoc
version of the regular variants.

```ocaml
let length_of_title book_title =
  match String.length book_title with
  | length when length <= 5  -> `Short
  | length when length <= 10 -> `Medium
  | _  -> `Long
in
length_of_title "The Hitchhiker's Guide to the Galaxy"
```
```ocaml
- : [> `Long | `Medium | `Short ] = `Long
```

Once again this feature is thoroughly covered in [this
section](https://realworldocaml.org/v1/en/html/variants.html#polymorphic-variants)
of Real World OCaml.

### Extensible Variants

As the name suggests extensible variants are variants that can be
extended with new constructors.

This is a new feature that was introduced in OCaml 4.02 and as such I
haven't yet used these in my own code so I will stick to the examples
shown in the OCaml Users Manual.

```ocaml
type attr = .. ;;
type attr += Str of string ;;
type attr +=
  | Int of int
  | Float of float ;;
```
```ocaml
type attr += Int of int | Float of float
```

For more information read this
[section](http://caml.inria.fr/pub/docs/manual-ocaml/extn.html#sec246)
of the OCaml Users Manual. This features was released after Real World
Ocaml and as such it isn't covered in the book unfortunately. I look
forward to then next revision.

## Exceptions

OCaml gives you the posibility of using exceptions for signaling and
handling exceptional conditions in your programs.

Exceptions are not checked, meaning that the OCaml compiler does not
enforce that you catch exceptions.

You can define your own exceptions in a way similar to variants.

```ocaml
exception BadRequest of int * string
```

You signal an exception using the `raise` keyword.

```ocaml
raise (BadRequest (500, "Oh noes, the service broke"))
```

You catch exceptions using the following syntax

```ocaml
try int_of_string "foo" with
| Failure msg -> -1
```
```ocaml
-1
```

Since OCaml 4.02 you can [catch exceptions in pattern
matches](http://caml.inria.fr/pub/docs/manual-ocaml/extn.html#sec245).

```ocaml
match int_of_string "foo" with
| n -> Printf.printf "Got an integer %d" n
| exception Failure msg -> Printf.printf "Caught exception with message %s" msg
```
```ocaml
Caught exception with message int_of_string- : unit = ()
```

As always, for more information read the
[section](http://caml.inria.fr/pub/docs/manual-ocaml/coreexamples.html#sec13)
in the OCaml Users Manual.

## Generalized Algebraic Datatypes

Generalized Algebraic Datatypes (GADTs) are an extension of the normal
variants (algebraic datatypes). They can be used to allow the OCaml
compiler to perform more sophisticated type checking or to control the
memory representation of your data. I wrote a [blog
post](http://blog.mads-hartmann.com/ocaml/2015/01/05/gadt-ocaml.html) about
the former and Janestreet has written a great [blog
post](https://blogs.janestreet.com/why-gadts-matter-for-performance/?utm_source=rss&utm_medium=rss&utm_campaign=why-gadts-matter-for-performance)
on the latter.

The following is an example from my [blog
post](http://blog.mads-hartmann.com/ocaml/2015/01/05/gadt-ocaml.html). I
include it here as an example of the syntax you use to define GADTs.

```ocaml
type _ value' =
  | GBool : bool -> bool value'
  | GInt : int -> int value'

type _ expr' =
  | GValue : 'a value' -> 'a expr'
  | GIf : bool expr' * 'a expr' * 'a expr' -> 'a expr'
  | GEq : 'a expr' * 'a expr' -> bool expr'
  | GLt : int expr' * int expr' -> bool expr'
```

GADTs were introduced in OCaml 4.00. The following
[section](http://caml.inria.fr/pub/docs/manual-ocaml/extn.html#sec238)
in the OCaml Users Manual describe the syntax and contains a few
examples.
