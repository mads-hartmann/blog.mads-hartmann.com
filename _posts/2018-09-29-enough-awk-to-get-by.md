---
layout: post
title: "Enough AWK to get by"
colors: yellowblue
date: 2018-09-29 12:00:00
excerpt_separator: <!--more-->
---

I've been using AWK for ages to pick out specific columns in lines of
text. However, I recently wrote a tiny AWK program that looked so
obscure that it tickled the part of me that loves esoteric programming
languages. I decided to sit down and read up on AWK; to my delight it
turns out to be a cooler language than I expected. In this post I'll
cover just enough of the language for you to comfortably write small
AWK programs.


<!--more-->

The tiny AWK program I recently wrote[^1] is the following. It prints
each line after having passed it through a regex replacement[^2].

```sh
grep -R TRIGGER . | awk '{gsub(/:.*/," ")}1'
```

This program looks really obscure to me. What does the `{...}1` mean.
How does `gsub` know what to match against?

Turns out that AWK[^4] is quite a large language - at least if you go
by the size of the [official documentation][manual]. The goals of this
post is to cover just enough of it for you to be comfortable writing
small programs. If you just want to know how the example above works
you can jump directly to the [Explaining the
example](#explaining-the-example) section.

**tl;dr** AWK runs actions against streams of textual data. The stream
is split into records according to a specified _record separator_ and
each record is split into fields according to the _field separator_.
An AWK program is a sequence of pattern-action statements. If the
pattern holds the action is executed against the current record.

## Table of contents
{: .no_toc }
* TOC
{:toc}

## Invoking AWK

Imagine you have the following AWK program in a file named `program.awk`.

```awk
{print $4}
```

And the following text in a file named `text.txt`.

```
This is the first line
This is the second line
This is the third line
```

Then you can invoke `awk` like this

```sh
awk -f program.awk text.txt
# first
# second
# third
```

However, I almost exclusively use AWK as part of a pipe, which looks
like this

```sh
cat text.txt | awk '{print $4}'
```

## Key concepts

Before we start looking at the concrete syntax let's get an overview
of the key concepts.

**Records** The text stream is split into a sequence of records
according to the _record separator_. By default this is set to be
newlines but you can change it by setting the `RS` variable - in the
following example the `-v` flag is used to set the value of the `RS`
variable before the AWK program is executed.

```sh
# The following prints b d f separated by newlines
echo "a b,c d,e f" | awk -v RS=, '{print $2}'
```

**Fields** Each record is split into fields according to the _field
separator_ which can be changed by setting the `FS` variable or by
using the `-F` option. The default field separator is space. You can
read more about it [here][field-splitting].

```sh
echo "a,b,c" | awk -F, '{print $2}'` # prints b
echo "a,b,c" | awk -v FS=, '{print $2}' # prints b
```

**Rules** A rule consists of a **pattern** and an **action**, either
of which (but not both) may be omitted. The action is executed if the
pattern matches the current input record. An action consists of one or
more awk statements.

With the main concepts in place let's have a look at how to write an
AWK program.

## Program structure

As mentioned above an AWK program consists of a sequence of
pattern-action statements which are called rules. Concretely that
looks like this.

```awk
pattern { action }
...
pattern { action }
```

Either the pattern or the action can be omitted. If the pattern is
omitted the empty pattern is used. If the action is omitted the
default action is used which is `{print $0}`, that is, it will print
the current record.

Each record is tested against all of rules. Let's have a look at how
to define patterns.

## Patterns

There are five different kinds of [patterns][patterns]

- **[Empty pattern][empty-pattern]**: This pattern is used if you
  omitted a pattern in your rule. It matches every record.

- **[Regular expression pattern][regex-pattern]**: These allow you to
  use regular expressions to define your patterns.

- **[Expression pattern][expression-pattern]**: If the value of the
  expression is non-zero or non-null the pattern is considered a
  match.

- **[Range pattern][range-pattern]**: These patterns consists of two
  patterns separated by a comma. The first pattern denotes the start
  of the range and the second pattern denotes the end of the range.

- **[Built in special patterns][special-pattern]**. These patterns are
  built into AWK. The two most commonly used are `BEGIN` and `END`.
  They allow you to run actions before the first and after the last
  record is read. This is useful to initialize variables, perform
  cleanup, and such.

Have a look at an example of each of the patterns below.

```awk
# The empty pattern
{print "The empty pattern is always true: " $0}

# Regular expression pattern
/second/ {print "A line matched the regex: " $0 }

# An expression pattern
NR == 1 { print "The first line: " $0}

# A range pattern consisting of two expression patterns
NR == 2, NR == 3 { print "In range as NR is " NR ": " $0}

# Special patterns
BEGIN { print "Before everything else" }
END { print "After everything else" }
```

If we run that on the example input from before we get the following
output.

```
Before everything else
The empty pattern is always true: This is the first line
The empty pattern is always true: This is the second line
A line matched the regex: This is the second line
In range as NR is 2: This is the second line
The empty pattern is always true: This is the third line
In range as NR is 3: This is the third line
After everything else
```

## Actions

The purpose of an action is to tell awk what to do once a match for
the pattern is found.

An action consists of one or more AWK statements, enclosed in braces.
The statements are separated by newlines or semicolons.

There are six kinds of statements. This is where it becomes apparent that
AWK is a full-blown programming language, so I'll keep it short.

- **[Expressions][expressions]**. Calling functions and assigning values
  to variables.

- **[Control statements][control-statements]**. Your usual control-flow
  constructs like `if`, `for`, `while`, etc.

- **Compound statements**. Simply used to group statements together,
  which you'll most likely need if you use any control statements.
  It's simply a pair of braces with statements separated by newlines
  or semicolons.

- **Input statements**. These statements allow you to read input from
  stdin or files.

- [**Output statements**][output-statements]. These are used to print
  to stdout. You'll already seen the use of `print` in all of the
  examples so far.

- **Deletion statements**. These are for deleting array elements.

Here's an examples I made up to make it concrete. The program counts
the total number of words in lines that contain six or more words.
The Wikipedia page on AWK also has a few [sample programs][samples]
that might be useful.

```awk
BEGIN {
    skipped = 0
    long_lines = 0
    count = 0
}

NF <= 5 { skipped++ }
NF > 5 {
    long_lines++
    count += NF
}

END {
    print "Skipped " skipped " lines as they were too short"
    print "Found " long_lines " with a total of " count " words!"
}
```

Have a look at the manual if you want to know more about
[actions][actions].

## Useful built-in variables & functions

You can find the full list of built-in variables
[here][built-in-variables]. These are the ones that you'll most likely
need.

- `FS`: The field separator
- `RS`: The record separator
- `NF`: The number of fields in the current record
- `NR`: The number of the current record, starts at 1.

You can find the full list of built-in functions [here][built-in-functions].

- `gsub(regexp, replacement [, target])`  
  The `taget` is optional, if left out it will default to `$0`. An
  example would be `gsub(/my-regex/, "replacement", $3)`

- `length([string])`.  
  Computes the length of the input string. The argument is optional,
  it will default to `$0`


## Explaining the example

Alright, let's try to dissect the example to see if we can make any sense of it.

```awk
{gsub(/:.*/," ")}1
```

This AWK program consists of two rules. `{gsub(/:.*/," ")}` and `1`.
The first rule has omitted the pattern and as such it uses the `empty`
pattern. The second rule has omitted the action which means AWK will
use the default action. Additionally the `taget` argument to `gsub`
has been omitted which means that it will default to `$0`. Let's make
all of this explicit.

```awk
{gsub(/:.*/," ", $0)}
1 { print $0 }
```

Now that everything is explicit it's a bit more clear that AWK will
run the regular expression substitution on the current record and then
print it.

## Further reading

Everything you could possibly want to know can be found somewhere in
[The GNU AWK User’s Guide][manual].

If you want something that's smaller than the manual but contains more
information than this post I'd suggest having a look [AWK - A Tutorial
and Introduction][tutorial]

The Wikipedia page on [AWK][awk-wikipedia] is quite good as well.

[^1]: Or well, wrote a bit and Googled my way to the rest.
[^2]: I know I could've used `sed` instead like so `sed 's/:.*//g'` but what's the fun in that?
[^3]: There are several flavour of AWK. I'll focus on GNU AWK
[^4]: [The A-Z of Programming Languages: AWK](https://web.archive.org/web/20080808234125/http://www.computerworld.com.au/index.php/id%3B1726534212%3Bpp%3B2)

[manual]: https://www.gnu.org/software/gawk/manual/html_node/index.html
[built-in-variables]: https://www.gnu.org/software/gawk/manual/html_node/Built_002din-Variables.html#Built_002din-Variables
[built-in-functions]: https://www.gnu.org/software/gawk/manual/html_node/Built_002din.html#Built_002din
[tutorial]: http://www.grymoire.com/Unix/Awk.html
[awk-wikipedia]: https://en.wikipedia.org/wiki/AWK
[field-splitting]: ftp://ftp.gnu.org/old-gnu/Manuals/gawk-3.0.3/html_chapter/gawk_6.html#SEC38
[patterns]: https://www.gnu.org/software/gawk/manual/gawk.html#Pattern-Overview
[empty-pattern]: https://www.gnu.org/software/gawk/manual/gawk.html#Empty
[regex-pattern]: https://www.gnu.org/software/gawk/manual/gawk.html#Regexp-Patterns
[expression-pattern]: https://www.gnu.org/software/gawk/manual/gawk.html#Expression-Patterns
[range-pattern]: https://www.gnu.org/software/gawk/manual/gawk.html#Ranges
[special-pattern]: https://www.gnu.org/software/gawk/manual/gawk.html#BEGIN_002fEND
[actions]: https://www.gnu.org/software/gawk/manual/html_node/Action-Overview.html#Action-Overview
[expressions]: https://www.gnu.org/software/gawk/manual/html_node/Expressions.html#Expressions
[control-statements]: https://www.gnu.org/software/gawk/manual/html_node/Statements.html#Statements
[output-statements]: https://www.gnu.org/software/gawk/manual/html_node/Printing.html#Printing
[samples]: https://en.wikipedia.org/wiki/AWK#Sample_applications
