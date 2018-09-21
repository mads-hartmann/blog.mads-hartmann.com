
Mostly I use _awk_ to pick out columns in lines of text. Something like the
following

```sh
echo 'a b c' | awk '{print $2}'
```

which prints `b`. However, I recently wrote[^1] the following AWK program that
prints the strings in the first column after having passed it through a regex
replacement:

```sh
grep -R TRIGGER . | awk '{gsub(/:.*/," ")}1'
```

This program looks really obscure to me. What does the `{...}1` mean. How does
`gsub` know what to match against? That got the part of me that loves esoteric
programming languages interested. So I decided it might be time to read up on
how to write _awk_ programs. This blog post contains my learnings.

_awk_ programs have the following structure:

```awk
condition { action }
condition { action }
```


[^1]: Or well, wrote a bit and Googled my way to the rest.
