---
layout: post
title: "Detecting use-cases for GADTs in OCaml"
date: 2015-01-05 21:00:00
categories: ocaml
colors: yellowblue
excerpt_separator: <!--more-->
---

I've been interested in GADTs<sup>1</sup> for quite some time now but I've had a
hard time finding proper use-cases for them in my day-to-day programming tasks;
this is not because GADTs aren't useful, they are, but rather that my
understanding of them has been limited.

<!--more-->

I often experience this when I'm learning more advanced features of programming
languages and I've found that I personally find it easier to grasp language
features when I have a clear understanding of what kinds of problems they're
meant to solve. One way to achieve this is start out by solving a specific
problem **without** the language feature and then show how, when you add the
feature, the solution becomes more elegant. I haven't found any posts that do
this with GADTs thus I set out to write this post. As I work through the example
I will also try to point out symptoms in your code that might mean you're better
off modeling your problem using a GADT; this will hopefully help you find
use-cases for GADTs in your own code-base.

In case you haven't stumbled upon GADTs before reading this here is a very
brief description of what they do; this is the most succinct description I've
found and it was written by [Ptival](http://www.reddit.com/user/Ptival) on
[reddit](http://www.reddit.com/r/ocaml/comments/1jmjwf/explain_me_gadts_like_im_5_or_like_im_an/).
I've modified it slightly, but it goes as follows:

> In essence GADTs makes it possible to describe a richer relation
> between your data constructors and the types they inhabit. By doing
> so you give the compiler more information about your program and
> thus it's able to type your programs more precisely.

Let that description dwell in the back of your mind as you read through
the rest of the post.

The example that we're going to use is similar to the canonical example
that you can also find in the OCaml Users Guide
[section](http://caml.inria.fr/pub/docs/manual-ocaml/extn.html#sec238)
on GADTs. I later hope to write a blog post with lots of examples of
GADTs to help solidify the concept - but that's for another time.

## The canonical example

The task is to write a small evaluator for a simple programming
language. Now I know this might be quite different from the problems
you would normally deal with at work but this is the canonical example
for a good reason so bear with me.

The language is simple and only contains `if`-expressions, two operators
(`=`, `<`) and two primitive types, `int` and `boolean`.

As I alluded to in the introduction we'll first try to model this using
a regular ADT<sup>2</sup>; Once we've seen the ADT
implementation it's easier to understand the benefits of using a GADT.

### Using ADTs

```ocaml
type value =
  | Bool of bool
  | Int of int

type expr =
  | Value of value
  | If of expr * expr * expr
  | Eq of expr * expr
  | Lt of expr * expr
```

I've chosen to represent the [abstract syntax
tree](http://en.wikipedia.org/wiki/Abstract_syntax_tree) using two
variants: `value` which models the primitive values and `expr` that
model the expressions.

Lets try and write a function that evaluates an `expr` into a `value`;
this can be achieved with a straightforward recursive implementation.

```ocaml
let rec eval: expr -> value = function
  | Value v -> v
  | Lt (x, y) -> begin match eval x, eval y with
      | Int x, Int y -> Bool (x < y)
      | Int _, Bool _
      | Bool _, Int _
      | Bool _, Bool _ -> failwith "Invalid AST"
    end
  | If (b, l, r) -> begin match eval b with
      | Bool true -> eval l
      | Bool false -> eval r
      | Int _ -> failwith "Invalid AST"
    end
  | Eq (a, b) -> begin match eval a, eval b with
      | Int  x, Int  y -> Bool (x = y)
      | Bool _, Bool _
      | Bool _, Int  _
      | Int  _, Bool _ -> failwith "Invalid AST"
    end
```

An example of how to invoke this function is shown below.

```ocaml
eval (If ((Lt ((Value (Int 2)), (Value (Int 4)))),
          (Value (Int 42)),
          (Value (Int 0))))
```
```
- : value = VInt 42
```

An here's what happens if we try to `eval` an invalid `expr`

```ocaml
eval (Eq ((Value (Int 42)), (Value (Bool false))))
```
```
Exception: Failure "Invalid AST".
```

Even though this implementation is correct (at least I hope it is) it
leaves a lot to be desired. The first thing that springs to mind is that
it's possible to construct `expr` values that we can't evaluate. This
means we still need to cover these cases in our pattern matches in order
for them to be exhaustive; we could use wildcard matches but then the
compiler won't be able to warn us about missing cases if we decide to
add new data constructs later. Exhaustiveness checking is extremely
helpful when working with larger code-bases so it shouldn't be thrown
away lightly. This gives us the first symptom you can look for when
you're considering use-cases for GADTs

{::options parse_block_html="true" /}
<div class="emphasis_block">
**symptom \#1**: When you need to to add extra cases for invalid states to make
your pattern matches exhaustive
</div>

Now lets say we wanted to write an `eval` function that returned a
proper OCaml `int` or `bool` rather than the wrapped `value` values.

To do this we would need to create a function for each primitive type, like so

```ocaml
let eval_int: value -> int = function
  | Int x -> x
  | Bool _ -> failwith "Got Bool, expected Int"

let eval_bool: value -> bool = function
  | Bool b -> b
  | Int _ -> failwith "Got Int, expected Bool"
```

Again, this solution works but it is rather unsatisfying to have
boilerplate like that. It would be preferable if we could have a single
function where its return type would depend on the input. This leads us
to symptom \#2:

{::options parse_block_html="true" /}
<div class="emphasis_block">
**symptom \#2**: You want the result of a function to depend on the data
constructor used to create the data
</div>

With these two symptoms in mind lets see what the GADT implementation
would look like.

### Using GADT

Before we dive into the GADT implementation lets do a quick review of
how to define GADTs in OCaml. Remember that we previously defined the
`value` type like this

```ocaml
type value =
  | Bool of bool
  | Int of int
```

To define a GADT we need to use a slightly different syntax. The following
syntax definition is taken from the OCaml Users Guide.

```
constr-decl ::= ...
              ∣ constr-name :  [ typexpr  { * typexpr } -> ]  typexpr
```

For the `value` type the GADT definition would look like this

```ocaml
type value =
  | Bool : bool -> value
  | Int : int -> value
```

Notice that we explicitly type the constructors. On its own this isn't
that exciting but it comes in handy when we introduce type parameters to
the GADT as you will see shortly. Now lets give the full GADT
implementation a go.

```ocaml
type _ value =
  | Bool : bool -> bool value
  | Int : int -> int value

type _ expr =
  | Value : 'a value -> 'a expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr
  | Eq : 'a expr * 'a expr -> bool expr
  | Lt : int expr * int expr -> bool expr
```

We define `value` and `expr` GADTs which are parameterized with an
anonymous type (notice the `_`) and each data constructor is explicitly
typed with a type for this parameter, e.g. the `Bool` constructor takes
a `bool` and gives you a `bool` typed `value`'.

The type parameter allows us to do two things:

-   We can associate a specific type with each data constructor, e.g.
    `Bool` is of type `bool expr`'.
-   We can restrict the input to functions using the type parameter of
    `expr`', e.g. `If` requires that the first argument needs to be of
    type `bool expr`'.

Now that we've told the compiler about these restrictions lets see how
the `eval`' function turns out.

```ocaml
let rec eval : type a. a expr -> a = function
  | Value (Bool b) -> b
  | Value (Int i) -> i
  | If (b, l, r) -> if eval b then eval l else eval r
  | Eq (a, b) -> (eval a) = (eval b)
  | Lt (a,b) -> (eval a) < (eval b)
```

This is so wonderfully concise that the previously solution now looks
horrific. Notice that this match is exhaustive __and__ the return type is
an actual ocaml primitive type. This is possible as OCaml now associates
a specific type for the type parameter of each data constructor.

Lets give the `eval` function as go with an example

```ocaml
eval (If ((Eq ((Value (Int 2)), (Value (Int 2)))),
      (Value (Int 42)),
      (Value (Int 12))))
```
```
42
```

And an example where we return a `bool` rather than `int`

```ocaml
eval (If ((Eq ((Value (Int 2)), (Value (Int 2)))),
      (Value (Bool true)),
      (Value (Bool false))))
```
```
- : bool = true
```

Now if we give an invalid example as try, let's see what happens

```ocaml
eval (If ((Value (Int 42)), (Value (Int 42)), (Value (Int 42))))
```
```
eval (If ((Value (Int 42)), (Value (Int 42)), (Value (Int 42))))
                  ^^^^^^
Error: This expression has type int value
       but an expression was expected of type bool value
       Type int is not compatible with type bool
```

Though it isn't obvious from the output this is actually a compile-time
error rather than the runtime error we got in the ADT example, that is,
it is no longer possible to construct an invalid AST.

That's it for this time. If you have any feedback catch me on twitter at
[@mads\_hartmann](http://twitter.com/mads_hartmann).

<div class="notice"> **Jan 20, 2018** Based on the feedback I've gotten
over the years I've updated the code examples to make them more clear.
Take that into consideration when you're reading the comments below ;)
</div>

## Footnotes

1. Generalized Algebraic Datatypes
2. Algebraic Datatypes
