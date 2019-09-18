---
layout: post
title: "Using Utop in Emacs"
date: 2014-01-05 14:08:52
categories: ocaml
---

<a href="/images/ocaml-utop-session.png" target="_blank">
    <img src="/images/ocaml-utop-session.png" width="100%" />
</a>

> utop is an improved toplevel for OCaml. It can run in a terminal or in
> Emacs. It supports line edition, history, real-time and context
> sensitive completion, colors, and more.

I've found [utop][utop] to be a really nice toplevel for playing around with
OCaml. Especially being able to evaluate code straight from an Emacs buffer is
wonderful. However, as soon as you start using it on larger projects you will
find that in a lot of cases it won't be able to evaluate the code in your
buffer as it depends on various [opam][opam] packages and modules you've
defined in your project.

Luckily there is a way to make utop aware of the opam packages that you depend
on and the modules you've defined in your project. This is a short blog post to
explain how. I've also created a very small [example project][example] to
provide concrete examples.

**Note**: This is the 2nd iteration. The setup was vastly simplified on
November 8 2014. The previous version can be found [here][previous-post].

## Loading the appropriate packages

If you fire up utop and invoke `#use "topfind";;` you will have a new directive
named `#require` that you can use to load your opam packages into the toplevel
(e.g. `#require "batteries";;`)

This is really neat and convenient when you want to play around with a specific
package, but if you use a lot of modules it's still quite tedious (we use 24 in
one of our OCaml projects at [issuu][issuu].

Fortunately utop makes it possible to put these directives (or anything else
you could type in the toplevel) in a file and have utop load it upon boot. If
there's a file named `.ocamlinit` in the folder where you invoke utop it will
load that, otherwise you can specify a file path using the `-init` option.

So if you simply create a `.ocamlinit` file which contains the appropriate
`#use` and `#require` statements then you will have everything loaded and ready
when utop has launched. See [this `.ocamlinit`][ocamlinit] for a concrete
example.

## Making utop aware of your compiled sources

The other thing to solve is figuring out how to tell utop where to look for
your bytecode. There are two ways to achieve this. You can use the `#directory`
directive in the toplevel (or your `.ocamlinit` file) or you can specify it as
command line argument when invoking utop using `-I <dir>`. Again See [this
`.ocamlinit`][ocamlinit] for a concrete example.

## Using it from inside of Emacs

The last piece of the puzzle is a bit of Emacs configuration.

You need to tell Emacs to use the `-init` option when starting the utop buffer.
You can do this through the utop-command variable so you won't have to type it
in manually every time you invoke `M-x utop`. I prefer setting it in the
[`.dir-locals`][dirlocals] file of my ocaml projects^[1](#fn.1). You can see a
concrete example [here][dirlocals-example]. An example is shown below.

```elisp
((tuareg-mode .
    ((utop-command . "utop -emacs -init ~/dev/backend-similarity/.ocamlinit"))))
```

Now you can just open an OCaml source file and hit `M-x utop` to get a
properly configured utop toplevel buffer. You can feed code to your utop
session using `C-x C-e`. This makes it refreshingly easy to play around
with smaller pieces of OCaml code straight from your buffer.

[utop]: https://github.com/diml/utop
[opam]: http://opam.ocamlpro.com
[example]: http://github.com/mads-hartmann/ocaml-utop-emacs-example
[previous-post]: https://github.com/mads-hartmann/mads-hartmann.github.com/blob/8c9e7b4c7e262d298e7e2401446ae0fa34c148cb/_posts/2014-01-05-using-utop-in-emacs.markdown
[issuu]: http://www.issuu.com/about
[ocamlinit]: https://github.com/mads-hartmann/ocaml-utop-emacs-example/blob/master/.ocamlinit
[dirlocals]: https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html
[dirlocals-example]: https://github.com/mads-hartmann/ocaml-utop-emacs-example/blob/master/.dir-locals.el

## Footnotes

^[1](#fnr.1)
Support for this is currently on master but a new release hasn't been
pushed to opam yet. See this
[PR](https://github.com/diml/utop/pull/111).
