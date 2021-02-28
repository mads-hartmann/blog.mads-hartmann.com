---
layout: post
title: "Writing zsh completion scripts"
date:   2017-08-06 10:00:00
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

Completion functions can be registered manually by using the `compdef` function
directly like this `compdef <function-name> <program>`. However, more commonly
you'll define the completion function in a separate file. By convention
completion functions, and the files they live in, are prefixed with an
underscore and named after the program they provide completions for. When the
completion system is being initialized through `compinit` zsh will look through
all the files accessible via the `fpath` and read the first line they contain,
as such you simply register a completion function by putting it somewhere
that's on your `fpath` and ensuring that the first line contains the `compdef`
command like this `#compdef _foobar foobar`

The `fpath` is the list of directories that zsh will look at when searching for
functions. If you're unsure what it's set to simply run `echo $fpath`. If you
want to append a directory just reassign the variable like so
`fpath=($fpath <path-to-folder>)`
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
#compdef _hello hello

function _hello {
    local line

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
            _hello_quietly
        ;;
    esac
}

function _hello_quietly {
    _arguments \
        "--silent[Dont output anything]"
}

function _hello_loudly {
    _arguments \
        "--repeat=[Repat the <message> any number of times]"
}
```

There are a few things worth going into here, especially the arguments passed
to `_arguments` function and the use of `local`, but first off let us look at
the general structure of the script.

### General structure

There's nothing special about a zsh completion script. It's just a normal zsh
script that uses `#compdef <function> <program>` to register itself as a
completion script for `program`, so you're free to structure your script anyhow
you see fit, but I've found the following structure to be helpful.

Define a function named `_<program>` that provides the default completions. For
each sub-command that the program provides define a `_<program>_<sub-command>`
function that provides completions for that sub-command. In my experience this
makes the completion script pretty straight-forward to write.

### The use of `_arguments`

By invoking the `_arguments` function the script provides the potential
completions to zsh. There are many other functions you can use to achieve this,
see section [20.6 in the documentation][zsh-completion-system].

There are two interesting parts about the use of `_arguments` in this case. The
string arguments are called `specs` and they can be a bit cryptic when you
first encounter them -- you really don't have much in the way of abstraction in
zsh so everything that's a bit complex is encoded inside of strings leaving you
to learn these small domain specific languages. In this case the `specs` can
take two forms:

* option specs: `OPT[DESCRIPTION]:MESSAGE:ACTION`
* command specs: `N:MESSAGE:ACTION`. N indicates that it is the Nth command argument.

The `ACTION` part is again it's own lille domain specific language.
[This][action-docs] is best description of this language I've found, but again,
the [documentation][zsh-completion-system] has all the details if you search
for `specs: overview`.

The `-C` flag, together with the `ACTION` specification `"*::arg:->args"` is
where it becomes interesting. Here's the description of the `-C` flag from the
documentation:

> In this form, _arguments processes the arguments and options and then returns
> control to the calling function with parameters set to indicate the state of
> processing; the calling function then makes its own arrangements for generating
> completions.

The parameters they mention are the following:

```zsh
local context state state_descr line
typeset -A opt_args
```

You can think of this as a way to have `_arguments` return multiple values --
it's modifying global variables but due to the use of `typeset -A` and `local`
it's only modified in the current call-graph. The `-A` option to `typeset`
tells zsh that the parameter is an associative array.

So the `-C` flags gives us to opportunity to inspect the completion state and
provide context specific completions based on what the user has entered. In our
case we're only using the `line` variable to switch on what sub-command the
user has entered and then invoking the relevant function to provide completions
for that command.

I hope this clarifies some of the aspects of writing completion scripts.

## Resources

The [zsh documentation][zsh-completion-system] has all the information you
could possibly need, but it can be a bit overwhelming. I recommend having a
look at the [zsh-completions][zsh-completions] project. It has a ton of good
examples and their [guide][zsh-guide] on how to write completion scripts is
great.

[zsh]: http://www.zsh.org/
[ohmyzsh]: http://ohmyz.sh/
[action-docs]: https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org#user-content-actions
[zsh-completion-system]: http://zsh.sourceforge.net/Doc/Release/Completion-System.html#Completion-System
[zsh-completions]: https://github.com/zsh-users/zsh-completions
[zsh-guide]: https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org
[main-complete-function]: https://github.com/zsh-users/zsh/blob/master/Completion/Base/Core/_main_complete
