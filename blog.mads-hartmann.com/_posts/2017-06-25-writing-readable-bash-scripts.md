---
layout: post
title: "Writing Readable Bash Scripts"
date:   2017-06-16 12:30:00
---

Recently I've been writing quite a lot of Bash scripts. It's been a mix of
scripts for my own [.dotfiles][dotfiles], scripts that automate [our local
development here at Famly][famlyplan], and scripts that are used as part of
our CI/CD pipeline.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">I’ve been writing Bash scripts almost exclusively for a couple of days now — I feel like I’m a full-time Bash developer now 😆</p>&mdash; Mads ♥mann (@Mads_Hartmann) <a href="https://twitter.com/Mads_Hartmann/status/874892062910558210">June 14, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

You're not afforded a whole lot of abstractions to work with when you're
writing Bash scripts, but if you use them right you can still produce some
fairly readable scripts.

The following example contains most of the important aspects of what I consider
a readable script. The script is pretty useless -- it gets the current time in
[epoch][epoch] and prints whether it's odd or even. I'll go though each part of
the script in the following sections.

```bash
#!/bin/bash

set -u
set -e
set -o pipefail

function is-even {
    if [[ $(($1 % 2)) -gt 0 ]]
    then return 1
    else return 0
    fi
}

function epoch {
    date +"%s"
}

if is-even $(epoch)
then echo "Even epoch"
else echo "Odd epoch"
fi
```

## The Header Ceremony

Unless you have a good reason not to you should start your scripts with the
following bit of code.

```bash
#!/bin/bash

set -u
set -e
set -o pipefail
```

It sets a couple of Bash flags. I'll go through them briefly but you can read
more about the various flags if you run `help set` in a Bash session.

- `set -u` will cause the script to fail if you're trying to reference a
  variable that hasn't been set. The default behavior will just evaluate the
  variable to the empty string.

- `set -e` will cause the script to exit immediately if a command fails. The
  default behavior is to simply continue executing the remaining commands in the
  script.

- `set -o pipefail` will cause a pipeline to fail if any of the commands in the
  pipeline failed. The default behavior is to only use the exit status of the
  last command.

All of these flags makes it much more likely that you'll catch errors in your
Bash script early on and thus makes it much easier to debug.

## Functions

Most of the Bash scripts I've seen tend to lack any kind of structure. They're
simply a set of command that are executed top to bottom. This is a natural
first step as you're usually just taking a set of commands that you were typing
in your shell and putting them in a script in order to automate a small task.

However, if scripts are allowed to grow in this way they quickly become very
hard to understand as nothing is named and everything relies on global
variables.

To avoid this you should split your script into named chunks with clear
boundaries using functions; I know we do this every day when we're writing
software but Bash scripts are sometimes not given the same amount of love.

There are [two ways][bash-functions] of writing functions in Bash. One is POSIX
compliant and the other is Bash specific. I prefer to use the Bash specific one
as I usually don't care about POSIX compliance -- I'm writing scripts that will
always be executed by Bash.

```bash
function my-function {
    local message=$1
    echo "Hello ${message}"
}

my-function "World"
```

Arguments are positional and are accessed through `$1, $2 ... $n`. Functions are
invoked by name and arguments are separated by spaces. If you want to capture the
output of a function in a variable you should execute it in a subshell like this

```bash
message=$(my-function "World")
echo ${message}
```

The use of `local` means that the variable is restricted to the scope of the
function; this helps reduce the global state of the script. One thing to keep in
mind though is that `local foobar=$(myprogram abc)` can potentially swallow errors.
If `myprogram abc` exists with an error code it wont propagate to your script as
it's caught by the local assignment. In these cases you unfortunately have to spit
your declaration and assignment into two separate commands.

```bash
function my-function {
    local number
    number=$(command-that-might-fail)
    echo "Number is ${number}"
}
```

## Readable if expressions

The control flow of a script is usually the part that gets hard to read first.
To mitigate this I like to separate the boolean expressions into their own
functions that use `return` to explicitly set the exit status (`help return`
for more info).

```bash
function branch-name {
    git rev-parse --abbrev-ref HEAD
}

function is-on-master {
    if [[ "$(branch-name)" == "master" ]]
    then return 0
    else return 1
    fi
}

function is-on-staging {
    if [[ "$(branch-name)" == "staging" ]]
    then return 0
    else return 1
    fi
}

if is-on-staging || is-on-master
then echo "Deploy"
else echo "Skipping deploy"
fi
```

This does tend generate a few more lines of code but it's worth it in my
opinion. The only thing to keep in mind is that `0` means `true` and 1 and
above means `false`. This is because an exit code of `0` means a program exited
successfully and anything else means the program failed and the error code is
used to give some context as to why the program failed.

<div style="border: 2px solid red; padding: 10px;">
<strong>Note</strong>: After writing this blog post I discovered that there are
two built-in convenience commands that you can use to avoid the confusion.
They're called, as you might have guessed, <code>true</code> and
<code>false</code>. <code>true</code> has an exit code of 0 whereas
<code>false</code> has an exit code of one (try <code>false ; echo $?</code>).
So you can replace <code>return 0</code> with <code>true</code> and
<code>return 1</code> with <code>false</code> to make the code more readable
</div>

Another thing that can be a bit confusing is the difference between `[` and `[[`.
`[` is an alias for `test` (see `man test` for more information) whereas `[[` is part
of the Bash syntax (use `help [[` for more information).

That it. Two simple tips that should help you keep your scripts readable. If
you have any other tips please leave a comment below or reach out to me on
[Twitter][twitter]

[dotfiles]: https://github.com/mads-hartmann/dotfiles
[famlyplan]: http://blog.mads-hartmann.com/2017/01/15/automating-developer-environments.html
[epoch]: https://en.wikipedia.org/wiki/Unix_time
[bash-functions]: https://stackoverflow.com/a/7917086/119357
[twitter]: https://twitter.com/mads_hartmann
