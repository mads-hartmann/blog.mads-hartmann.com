---
layout: post
title: "Writing ZSH completion scripts"
date:   2017-07-20 12:30:00
---

I've had to write a couple of completion scripts for [ZSH][zsh] over the last couple
of months. I write them rarely enough that I seem to have forgotten how to do
it every time I set out to write a new one. So this time I decided to write
down a few notes so I don't have to look through the documentation too much
next time.

Imagine you have a program with an interface like the following

{% highlight zsh %}
hello -h | --help
hello quietly [--silent] <message>
hello loudly [--repeat=<number>] <message>
{% endhighlight %}

This imaginary program has two command `quietly` and `loudly` that each have
distinct arguments you can pass to them -- ideally we'd like the completion
script to complete `-h`, `--help`, `quietly`, and `loudly` when no commands are
supplied, and once either `quietly` or `loudly` has been entered it should give
context specific completions for those.

I found it useful to follow the following outline. 


{% highlight zsh %}
#compdef hello
#description Modifies the input and echo it.

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
{% endhighlight %}

There are three things worth going into here. The `_arguments` function, the
use of `typeset` and the local variables.

`typeset` is used to define variables and 

 re-defines opt_args in the scope of the function.

The part that's a bit cryptic are the XYZZ strings -- you really don't have
much in the way of abstraction so everything that's a bit complex is encoded
inside of strings leaving you to learn these small sub-languages. I'll give a
bit of info into this specific one here as this is the part where I usually
have to look up the documentation.

## Enabling completions in ZSH

fpath=(path/to/folder/with/scripts $fpath)

rm -f ~/.zcompdump; compinit

## Resources

The [ZSH documentation][zsh-completion-system] has all the information you
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
