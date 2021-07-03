---
layout: post
title: "ocamldebug"
date: 2014-11-15 21:00:00
categories: ocaml
---

When I first read about the time-travel feature of the ocaml debugger I
was very intrigued but never got around to trying it out in practice at
work. This weekend I decided to give it a go.

I wanted to try it out on a simple but non-trivial program (in terms of
setup, i.e. a program that requires opam packages to compile) so I used
the [hello world
example](https://github.com/mirage/ocaml-cohttp/blob/master/examples/async/hello_world.ml)
of the [ocaml-cohttp](https://github.com/mirage/ocaml-cohttp) library.

## Configuration

Before the `ocamldebugger` can work with your programs they need to be
compiled with the `-g` flag enabled. This is also required for any
libraries that you use. You can configure the `ocamlc` parameters that
opam uses by setting `OCAMLPARAM`; in this case you want to set it to
`_,g`. You will want to run `opam reinstall` on any package you have
previously installed to make sure they get recompiled.

The second thing you need to do is tell `ocamldebug` where to look for
your compiled files. Unfortunately this is not as easy as it is with
utop. Luckily I came across this stack overflow
[thread](http://stackoverflow.com/questions/6218990/how-can-ocamldebug-be-used-with-a-batteries-included-project)
which explains how to do it. I ended up using a slightly different
approach as you can't pass arguments to `ocamldebug` when running it
from within Emacs (at least I couldn't get it to work). I decided to
write the results of
`ocamlfind query -recursive core async cohttp cohttp.async` into a file
named `.ocamldebug` and prefix each line with `directory`. After
starting the debugger in Emacs you then need to run `source <PATH>` to
configure it.

## Using the debugger

Starting the debugger from within Emacs is just a matter of running
`M-x ocamldebug` and point it to the executable you want to debug.

You start the program by writing `run` in the `ocamldebug` buffer. You
set break-points in your code using `C-x C-a C-b` and step through the
code use `C-c C-s`. You can inspect values using `C-x C-a C-p`. For more
information read this
[chapter](http://caml.inria.fr/pub/docs/manual-ocaml/debugger.html) of
the OCaml Users Guide.

## Shortcomings

Unfortunately I found a couple of shortcomings when I played around with
the debugger for a bit.

### No support for `-pack`'ed compilation units

Once you start setting some breakpoints and step through the code you're
very likely to get an error like the following.


    (ocd) step
    Time: 1084742 - pc: 4416712 - module Cohttp.Request
    No source file for Cohttp.Request.

This error had me puzzled for a bit as I thought I had already told
`ocamldebug` where to look for my opam packages. I joined the `#ocaml`
IRC channel and `whitequark` was able to come up with a potential
explanation. It seems that `ocamldebug` doesn't support compilation
units that contain submodules that have been added using `-pack` and
`-for-pack`. Search for `-pack` in this
[section](http://caml.inria.fr/pub/docs/manual-ocaml/comp.html) for the
OCaml Users Guide for more information.

### No arbitrary OCaml code execution

Once you hit a breakpoint it's possible to inspect the values of the
variables in the current scope. This is great, but it would have been
even better if you could execute arbitrary OCaml code in the current
scope. This doesn't seem to be possible. To be fair this might be better
classified as an **awesome feature** rather than a shortcoming.
