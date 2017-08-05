---
layout: post
title: "Writing zsh completion scripts"
date:   2017-07-20 12:30:00
colors: blueish
---

I've had to write a couple of completion scripts for [zsh][zsh] over the last
couple of months. I write such scripts rarely enough that I seem to have
forgotten how to do it every time I set out to write a new one. So this time I
decided to write down a few notes so I don't have to look through the
documentation too much next time.

This post contains a short introduction to the zsh completion system, a full
example that can be used as a starting point for new scripts, and some
explanation of some of the more interesting parts of writing completion
scripts.

## Table of contents
{: .no_toc }
* TOC
{:toc}

## Basics of zsh's completion system

The zsh completion system (`compsys`) is the part of zsh that takes care of
providing the nice tab-completions you're used to when typing in commands in
your shell. You can find the full documentation [here][zsh-completion-system]
or you can have a look at the [source code][main-complete-function], the most
interesting bit being the `_main_complete` function, however, it's all a bit of
a mouthful so I'll provide the basic information here.

{::options parse_block_html="true" /}
<div class="sidenote">
The completion system needs to be activated. If you're using something like
[oh-my-zsh][ohmyzsh] then this is already taken care of, otherwise you'll need
to add the following to your `~/.zshrc`

```zsh
autoload -U compinit
compinit
```
</div>

When you type `foobar <tab>` into your shell zsh will invoke the completion
function that has been registered for `foobar`. The completion function
provides the relevant completions to zsh by invoking a set of builtin functions
that are part of `compsys` -- We'll look at one of these functions later.

Functions can be registered manually by using the `compdef` function directly
like this `compdef <function-name> <program>`. However, more commonly you'll
define the completion function in a separate file. By convention completion
functions, and the files they live in, are prefixed with an underscore and
named after the program they provide completions for. When the completion system
is being initialized through `compinit` zsh will look through all the files
accessible via the `fpath` and read the first line they contain, as such you
simply register a completion function by putting it somewhere that's on your
`fpath` and ensuring that the first line contains the `compdef` command
like this `#compdef _foobar foobar`

The `fpath` is the list of directories that zsh will look at when searching for
functions. If you're unsure what it's set to simply run `echo $fpath`. If you
want to append a directory just reassign the variable like so
`fpath = ($fpath <path-to-folder>)`
{: .sidenote}

With the basics out of the way, let's have a look at a full example.

## Example completion script

Imagine you have a program with an interface like the following

```sh
hello -h | --help
hello quietly [--silent] <message>
hello loudly [--repeat=<number>] <message>
```

This imaginary program has two command `quietly` and `loudly` that each have
distinct arguments you can pass to them -- ideally we'd like the completion
script to complete `-h`, `--help`, `quietly`, and `loudly` when no commands are
supplied, and once either `quietly` or `loudly` has been entered it should give
context specific completions for those.

The following zsh script provides completions for the program as described. In
the rest of the post I'll give an explanation of the general outline of the
script and dive into some of the more interesting parts.

```zsh
#compdef hello
#description Modifies the input and echos it.

function _hello {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        "-h[Show help information]" \
        "--h[Show help information]" \
        "1: :(quietly loudly)" \
        "*::arg:->args"

    case $line[1] in
        loudly)
            _hello_loudly
        ;;
        quietly)
            _hello_loudly
        ;;
    esac
}

function _hello_quietly {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        "--silent[Dont output anything]"
}

function _hello_loudly {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        "--repeat=[Repat the <message> any number of times]"
}

_hello
```

There are a few things worth going into here, especially the arguments passed
to `_arguments` function, the use of `typeset` and the `local` variables, but
first off let us look at the general structure of the script.

## General structure

There's nothing special about a zsh completion script. It's just a normal zsh
script that uses `#compdef <prorgram>` to register itself as a completion
script for `program`, so you're free to structure your script anyhow you see fit,
but I've found the following structure to be helpful.

Define a function named `_<program>` that provides the default completions. For
each sub-command that the program provides define a `_<program>_<sub-command>`
function that provides completions for that sub-command. In my experience this
makes the completion script pretty straight-forward to write.

## Details

### `_arguments`

The part that's a bit cryptic are the XYZZ strings -- you really don't have
much in the way of abstraction so everything that's a bit complex is encoded
inside of strings leaving you to learn these small sub-languages. I'll give a
bit of info into this specific one here as this is the part where I usually
have to look up the documentation.

### `typeset -A`

`typeset` is used to define variables and 

 re-defines opt_args in the scope of the function.

### `local`

## Resources

The [zsh documentation][zsh-completion-system] has all the information you
could possibly need, but it can be a bit overwhelming. I recommend having a
look at the [zsh-completions][zsh-completions] project. It has a ton of good
examples and their [guide][zsh-guide] on how to write completion scripts is
great.

man zshcompsys

[zsh]: http://www.zsh.org/
[ohmyzsh]: http://ohmyz.sh/
[zsh-completion-system]: http://zsh.sourceforge.net/Doc/Release/Completion-System.html#Completion-System
[zsh-completions]: https://github.com/zsh-users/zsh-completions
[zsh-guide]: https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org
[main-complete-function]: https://github.com/zsh-users/zsh/blob/master/Completion/Base/Core/_main_complete
