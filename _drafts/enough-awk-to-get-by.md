
I recently wrote[^1] the following AWK program that prints the strings in the
first column after having passed it through a regex:

```sh
grep -R TRIGGER . | awk '{gsub(/:.*/," ")}1'
```

I thought I had an rudimentary understanding of AWK - but it turns out I didn't.
So in this short blog-post I'll try to cover enough of AWK for you to
comfortable use it in small piped shell commands.

[^1]: Or well, wrote a bit and Googled my way to the rest.
