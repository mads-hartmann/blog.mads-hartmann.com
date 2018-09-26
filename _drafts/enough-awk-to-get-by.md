---
layout: post
title: "Enough Awk to get by"
colors: yellowblue
excerpt_separator: <!--more-->
---

I've been using Awk for ages to pick out specific columns in lines of
text, usually as a part of a larger set of programs that are "piped"
together. However, I recently wrote an Awk program that looked so
obscure to me that it tickled the part of me that loves esoteric
programming languages so I decided to sit down and read up on Awk; to
my delight it turns out to be a cooler language than I expected. In
this post is to cover just enough of it for you to comfortably use it
as part of pipes to manipulate lines of text to your pleasing

<!--more-->

The Awk program I recently wrote[^1] is the following. It prints the
strings in the first column after having passed it through a regex
replacement.

```sh
grep -R TRIGGER . | awk '{gsub(/:.*/," ")}1'
```

This program looks really obscure to me. What does the `{...}1` mean.
How does `gsub` know what to match against?

Turns out that Awk[^2] is quite a large language. The goals of this
post is to cover just enough of it for you to be comfortably using it
as part of pipes to manipulate lines of text to your pleasing. If you
just want to know how the example above works you can jump directly to
the [Explaining the example](#explaining-the-example) section.

**tl;dr** Awk runs actions against streams of textual data. The stream
is split into records according to a specified _record separator_ and
each record is split into fields according to the _field spearator_.
.. each record is run against each ...

## Table of contents
{: .no_toc }
* TOC
{:toc}

## Invoking Awk

Awk can .... but I'll focus on using in a pipeline as that's the only
case I've had any use for it.

You can control which character is used for separating the fields.

## Key concepts

> The Awk language is a data-driven scripting language consisting of a
> set of actions to be taken against streams of textual data[^3]

There are X key concepts

**Records** are _lines_ ... The input is split according to the
_record separator_. By default this is set to be newlines but you
can change it by setting the `RS` variable.

```sh
# The following prints b d f separated by newlines
echo "a b,c d,e f" | awk -v RS=, '{print $2}'
```

**Fields** Each record is split into fields according to the _field
separator_ which can be though the `FS` variable or by using the `-F`
option

```sh
echo "a,b,c" | awk -F, '{print $2}'` # prints b
echo "a,b,c" | awk -v FS=, '{print $2}' # prints b
```

can read more about it [here](ftp://ftp.gnu.org/old-gnu/Manuals/gawk-3.0.3/html_chapter/gawk_6.html#SEC38)

## Program structure

_Awk_ programs have the following structure:

```awk
condition { action }
condition { action }
```

Here's an example that prints the last line of the input.

```sh
echo "how\nare\nyou" | awk '{}'
```

Cover special patterns.

## Built in variables

You can find the full list of built-in variables as of version 3.0.3
[here][built-in-variables].

## Explaining the example

Alright, so let's look at it again

```awk
{gsub(/:.*/," ")}1
```

## Further reading

[The GNU Awk User’s Guide][manual]

For more in-depth coverage I suggest having a look [Awk - A Tutorial
and Introduction][tutorial]

The Wikipedia page on [Awk][awk-wikipedia] is quite good as well.

[^1]: Or well, wrote a bit and Googled my way to the rest.
[^2]: There are several flavour of Awk. I'll focus on GNU Awk
[^3]: Taken from [Wikipedia][awk-wikipedia]

[manual]: https://www.gnu.org/software/gawk/manual/gawk.html
[built-in-variables]: ftp://ftp.gnu.org/old-gnu/Manuals/gawk-3.0.3/html_chapter/gawk_11.html
[tutorial]: http://www.grymoire.com/Unix/Awk.html
[awk-wikipedia]: https://en.wikipedia.org/wiki/AWK
