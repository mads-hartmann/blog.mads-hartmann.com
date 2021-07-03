---
layout: post
title: "Exporting org from Make"
date: 2016-07-03 07:00:00
---

Recently I've been quite obsessed with
[Make](https://www.gnu.org/software/make/). I think it might be the
perfect tool to deal with complex software projects that consist of many
different systems that are build using various languages (my team at
[issuu](https://issuu.com/about) uses it to the build, test, & deploy
our frontend, backend and various internal tools). However, I'll save
that rant for another blog post but given my fascination with Make I
recently set out to write a `Makefile` for this blog.

This blog is currently written in an awkward mix of
[org-mode](http://orgmode.org/) and [jekyll](https://jekyllrb.com/).
Previously my work-flow has been to manually start `jekyll serve -w` and
then export `org-mode` files from within `emacs`. This is a bit tedious
and it diverges from the work-flow I've come to expect from my other
projects where saving a file automatically triggers a rebuild.

In this blog post I'll explain how I was able to export my `org-mode`
files from a `Makefile`. You can find the entire solution on Github at
[mads-hartmann/mads-hartmann.github.com](http://github.com/mads-hartmann/mads-hartmann.github.com).

## Publishing from the shell

The first step was to figure out how to publish a single `org-mode` file
from the shell. Turns out that this could be achieved fairly easily by
using some of the command-line arguments that emacs provide.

```bash
emacs \
    --quick \
    --directory <path-to-org-mode> \
    --script init.el \
    --eval "(org-publish-file \"<path-to-org-file>\" nil nil)"
```

Lets look at each of the options:

-   **`--quick`** is used to reduce the boot time of emacs. It's
    equivalent to using all of `--no-init-file`, `--no-site-file`,
    `--no-site-lisp` and `--no-splash`, that is, it will start a
    bare-bones version of emacs that doesn't use any of your personal
    configuration or packages.
-   **`--directory`** adds a directory to the emacs load path. In this
    case I use it to add `org-mode` to the load path.
-   **`--script`** tells `emacs` to run a file as an Emacs Lisp script.
    In this case I use it to run a script, `init.el`, that configures
    `org-mode` so it knows how to publish my project. Using `--script`
    also has the convenient effect that `emacs` doesn't start an
    interactive display; it simply executes the script and exits.
    Together with `--eval` this means you can use `emacs` just as an
    interpreter for Emacs Lisp which is exactly what we need in this
    case.
-   **`--eval`** tells emacs to evaluate an Emacs Lisp expression. The
    expression that I'm using publishes an `org-mode` file.

This is all there is to it. Writing a `Makefile` that runs this command
for each `.org` file and watches for changes to perform a rebuild is
fairly simple (if you know Make, if not I strongly recommend the first
couple of chapters [Managing Projects with GNU
Make](http://www.oreilly.com/openbook/make3/book/index.csp), it's
awesome.).

---

**Random thought** It's quite fun to play around with using `emacs` just
for its ability to interpret Emacs Lisp. You can play around with it
like this

```bash
emacs --batch --eval "(message \"hi there\")"
```

---

You could stop here and you would have a nice way to export `.org` files
from Make. However, I got curious and explored another way to do it. In
the next section I'll show a way to speed up the build-time a bit – it's
really not necessary but it is quite fun and it requires a couple of
tricks that might be useful in other scenarios.

## Speeding up the build using `emacsclient` and `emacs --daemon`

`emacs` has the capability of starting an `emacs` server that you can
connect to using `emacsclient`. There are various use-cases for this but
in this case we'll use it to avoid having to start a fresh `emacs`
instance whenever we want to export an `org-mode` file.
n
Keeping the original goal in mind, that `make watch` should rebuild the
necessary things whenever a file is saved, here's what we want to have
running during `make watch`:

-   `Jekyll` running in server mode so I can see my blog locally and
    have it rebuild whenever a `.html` file changes.
-   A loop that calls `make build` every second. This is the simplest
    solution to re-export my `.org` files when they are changed.

Instead of having `make build` starting a fresh `emacs` every time a
file needs to be build (as we did in the previous section) let us
instead start an `emacs` server and connect to it using `emacsclient`.
This means our `make watch` target should have an extra process running:

-   An `emacs` server that can export `.org` files.

In order to achieved this we need to use a couple of tricks. I'll go
through each of them now.

### A target that runs other targets in parallel

In order to run these three `make` targets we'll introduce the first
trick. Using `xargs -P` to start processes. Here's a `Makefile` function
(or well, it's a [multi-line
variable](https://www.gnu.org/software/make/manual/html_node/Multi_002dLine.html)
that supposed to be used with
[call](https://www.gnu.org/software/make/manual/html_node/Call-Function.html#Call-Function),
but I like to think of it as a function) that will run all the `make`
targets you give it in separate processes

```
# $(call make-parallel, targets)
#   Runs (sub) make targets, with each target running in a separate process
define make-parallel
	$(call print-rule,$0,$1 - [$(words $1) targets])
	$(QUIET)echo $1 | xargs -n 1 -P $(words $1) \
		$(MAKE) --no-print-directory -f $(firstword $(MAKEFILE_LIST))
endef
```

I then use it like this to run three targets in parallel

```makefile
watch_targets := \
	_watch-continous-make \
	_watch-jekyll-server \
	_watch-emacs-server

watch:
	$(call make-parallel, $(watch_targets))
```

With this `make watch` will result in three invocations of `make`
running in parallel, namely `make _watch-emacs-server`, `make
_watch-jekyll-server` and `make _watch-emacs-server`. When I hit `^C`
(control-c) all of the processes are killed (as long as the targets
are running in the foreground).

### Starting and stopping an `emacs` daemon

Now to the next piece of the puzzle, namely how to start, communicate
with, and stop and `emacs` daemon.

#### Starting & stopping the server

By using the emacs command-line option `--daemon=<daemon-name>` you can
start an emacs server and give it a specific name. We explicitly give
the daemon a name so we can refer to it later. Here's how the emacs
daemon is started.

```bash
emacs \
  --quick \
  --directory <path-to-org-mode> \
  --script init.el \
  --daemon=<daemon-name>
```

Besides configuring `org-mode` I've added an extra important thing to
the `init.el` file that is required in order to start many daemons and
have `emacsclient` communicate with a specific one:

```elisp
;; If non-nil, use TCP sockets instead of local sockets.
(setq server-use-tcp t)
```

Alright, so that's how to get the `emacs` server up and running but
there's one problem. When using the `--daemon` option `emacs` will run
in the background. That's a problem as my `make-parallel` function
requires that all the targets run in the foreground in order to be
able to shut them down once I hit `^C`. In order to fix this I came up
with this little hack.

```bash
#! /bin/sh

trap "emacsclient --server-file=$1 --eval '(kill-emacs)'; exit" SIGINT SIGHUP SIGKILL
tail -f /dev/null
```

It's a shell script that will run forever (this is achieved by
`tail -f /dev/null`. However it also registers a `trap` for `SIGINT`,
`SIGHUP` and `SIGKILL` events. The `trap` kills the server by using
`emacsclient` to send `(kill-emacs)` to the server.

So the final `_watch-emacs-server` target looks like this

```makefile
# Starts emacs in server-mode, blocks until SIGINT/SIGHUP/SIGKILL is
# sent and then shuts down the emacs server instance.
_watch-emacs-server:
	$(QUIET)emacs \
		--quick \
		--directory $(abspath $(setup.dir)/org-$(org_version)/lisp) \
		--script init.el \
		--daemon=$(strip $(emacs_daemon_name)) $(if $(QUIET),&> /dev/null,)
	$(QUIET)sh wait-and-shutdown.sh $(emacs_daemon_name)
```

#### Communicating with the server

Once the daemon is running you can start an `emacsclient` and use it to
export an `.org` file like this.

```bash
emacsclient \
  --server-file=$(strip $(emacs_daemon_name)) \
  --eval "(org-publish-file \"<path-to-org-file>\" nil nil)"
```

### Continuous `make build`

The last trick is to create a make target that simply calls `make build`
every second.

```makefile
# Calls `make build` every second.
_watch-continous-make:
	$(QUIET)while true; do \
		sleep 1; \
		$(MAKE) \
			-f $(firstword $(MAKEFILE_LIST)) \
			-no-print-directory \
			uild WATCH_MODE=1 \
		| grep -v "Nothing to be done for" ; \
	done
```

That's it. I hope you learned a few `Make` or `emacs` tricks.

