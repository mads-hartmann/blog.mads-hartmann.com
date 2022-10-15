---
layout: post-no-separate-excerpt
title: "Learning Nix"
colors: pinkred
---

I have been vaguely aware of Nix for a very long time but never really took the time to sit down and play around with it until recently. As I read up on the docs, watched presentations, and did a few proof-of-concepts, I wrote down a few notes to help guide my learning. I'm sharing them here in case they might be useful to someone else.

{: .no_toc }
## Table of contents
* TOC
{:toc}

## TODOs

- [Nix Pills](https://nixos.org/guides/nix-pills/) seems like a great resource! Check it out and reference it as needed.
- Is there a standard library for Nix worth mentioning?
- What about tooling? Any LSP-based tools worth trying?
- Explain what part of the language the tokens <nixpkgs> comes from, e.g. in `let pkgs = import <nixpkgs> {}; in { a = "foo"; }`
- Mention `nix repl`
- Is [NixOps](https://github.com/NixOS/nixops) relevant to me?

## Introduction to Nix

The [official manual](https://nixos.org/manual/nix/stable) is quite good, but also rather comprehensive. I do recommend giving it a read to dive deeper, but below I've highlighted the passages that stand out to me and will provide a bit of context on why.

> Nix is a purely functional package manager

This would have gotten Mads-in-his-twenties very excited as I was very much into functional programming at the time. Mads-in-his-thirties needs a bit more information to get excited.

> This means that it treats packages like values in purely functional programming languages such as Haskell — they are built by functions that don’t have side-effects, and they never change after they have been built. Nix stores packages in the Nix store, usually the directory `/nix/store`, where each package has its own unique subdirectory such as `/nix/store/b6gvzjyb2pg0kjfwrjmg1vfhh54ad73z-firefox-33.1/` where `b6gvzjyb2pg0…` is a unique identifier for the package that captures all its dependencies (it’s a cryptographic hash of the package’s build dependency graph). This enables many powerful features.

From my time being enamoured with functional programming I've seen how having immutable data and side-effect-free functions enable some interesting programming techniques, so when they say that treating packages this way "enables powerful features" I believe them.

> You can have multiple versions or variants of a package installed at the same time.

Sounds good.

> Nix helps you make sure that package dependency specifications are complete.

At first glance this isn't that big of a deal to me. The software I work on is usually built by a CI system, so if I overlook a dependency it would usually not build in CI and I'd notice. On the other hand, CI might use a slightly different version than I use on my system and that might break in subtle ways, so a "complete dependency specification" does sound nice.

> Packages are built from Nix expressions, which is a simple functional language. A Nix expression describes everything that goes into a package build action (a “derivation”): other packages, sources, the build script, environment variables for the build script, etc. Nix tries very hard to ensure that Nix expressions are deterministic: building a Nix expression twice should yield the same result.

This bit I find nice as gives a bit more information about how Nix achieves the "complete dependency specification" mentioned above.

> Nix expressions generally describe how to build a package from source [...] This is a source deployment model. For most users, building from source is not very pleasant as it takes far too long. However, Nix can automatically skip building from source and instead use a binary cache, a web server that provides pre-built binaries. For instance, when asked to build `/nix/store/b6gvzjyb2pg0…-firefox-33.1` from source, Nix would first check if the file https://cache.nixos.org/b6gvzjyb2pg0….narinfo exists, and if so, fetch the pre-built binary referenced from there; otherwise, it would fall back to building from source.

Now this is where things start to get exciting, and where the importance of the functional programming foundations shine through. If a package has a "complete dependency specification" and "Nix expressions are deterministic" then of course, why would you ever build the same package twice?

> We provide a large set of Nix expressions containing hundreds of existing Unix packages, the Nix Packages collection (Nixpkgs).

They're really understating it here. At the time of writing this blog post it's 80.000 packages. That's a lot of packages.

At this point I'm more then a little excited. You have a package manager that's built on top of few core primitives that have allowed to them build a source/binary transparent package manager that's extremely easy to cache. On top of that, other people have already put in the work of writing Nix expressions for 80.000 packages which means that I most likely will find any dependency I need in there already.

> Nix is extremely useful for developers as it makes it easy to automatically set up the build environment for a package. Given a Nix expression that describes the dependencies of your package, the command nix-shell will build or download those dependencies if they’re not already in your Nix store, and then start a Bash shell in which all necessary environment variables (such as compiler search paths) are set.

Now I'm sold. Setting up reproducible build environment has so far been a struggle. The move to using Docker for developer environments hasn't fixed that, as `Dockerfile`s are generally not reproducible as they `apt-get update` or perform other operations that depend on what time you happened to build the image.

So let's dive into Nix the language and the related tools.

## Nix the language

Again, [the manual](https://nixos.org/manual/nix/stable/language/index.html) is quite good, so give it a read to dive deeper.

An important thing to keep in mind when picking up Nix (the language) is the following:

> it only exists for the Nix package manager: to describe packages and configurations as well as their variants and compositions. It is not intended for general purpose use.

Which is great. I love a good domain specific language. But it does mean that it's going to a bit different than learning any general purpose programming language. You first have to learn a bit about the "domain" before the language makes sense.

The primary concepts are [expressions](https://nixos.org/manual/nix/stable/glossary.html#gloss-nix-expression), [derivations](https://nixos.org/manual/nix/stable/glossary.html#gloss-derivation), and the [store objects](https://nixos.org/manual/nix/stable/glossary.html#gloss-store-object)

> derivation
>
> A description of a build action. The result of a derivation is a store object. Derivations are typically specified in Nix expressions using the derivation primitive. These are translated into low-level store derivations (implicitly by nix-env and nix-build, or explicitly by nix-instantiate).

> Nix expression
>
> A high-level description of software packages and compositions thereof. Deploying software using Nix entails writing Nix expressions for your packages. Nix expressions are translated to derivations that are stored in the Nix store. These derivations can then be built.

> Store object
>
> A file that is an immediate child of the Nix store directory. These can be regular files, but also entire directory trees. Store objects can be sources (objects copied from outside of the store), derivation outputs (objects produced by running a build action), or derivations (files describing a build action).

So when programming in Nix you'll be writing expressions which are typically derivations that produce store objects.

Lets dive into how you can write and evaluate these expressions - to do so we need to look at the tools that ship with Nix.

## Nix tools

When you [install Nix](https://nixos.org/manual/nix/stable/installation/installation.html) you get a few different commands, I'll cover them below.

### nix-instantiate

> [nix-instantiate](https://nixos.org/manual/nix/stable/command-ref/nix-instantiate.html)
>
> The command nix-instantiate generates store derivations from (high-level) Nix expressions. It evaluates the Nix expressions in each of files (which defaults to ./default.nix). Each top-level expression should evaluate to a derivation, a list of derivations, or a set of derivations. The paths of the resulting store derivations are printed on standard output.

When picking up a new language I usually find it easiest if I have a playground where I can write small programs - `nix-instantiate` gives us just that.

Using the `--eval` option it's possible to write Nix expressions in a file and evaluate them even if they aren't derivations.

> --eval
>
> Just parse and evaluate the input files, and print the resulting values on standard output. No instantiation of store derivations takes place.

```sh
# From stdin
echo "2+2" | nix-instantiate --eval -

# From a file
nix-instantiate --eval <path>
```

This is really useful to play around with core parts of the language: [Data Types](https://nixos.org/manual/nix/stable/language/values.html), [Language Constructs](https://nixos.org/manual/nix/stable/language/constructs.html), [Operators](https://nixos.org/manual/nix/stable/language/operators.html)

The most interesting Data Types is [Attribute Set](https://nixos.org/manual/nix/stable/language/values.html#attribute-set) which is just a collection of name-value pairs

```nix
# in attribute-set.nix
{
    name = "Mads";
    url = "https//mads-hartmann.com";
}.name
```

```sh
nix-instantiate --eval attribute-set.nix
"Mads"
```

TODO: add any other interesting "core features" and then create the first derivation.

### nix-env

> The command nix-env is used to manipulate Nix user environments. User environments are sets of software packages available to a user at some point in time.
>
> https://nixos.org/manual/nix/stable/command-ref/nix-env.html

nix-env will look at `~/.nix-profile` by default, which means that your Nix user environment is going to be your "normal" user by default - that means you can use Nix as a way to install software for your user, and it comes with some neat features. Here's a quick introduction to how to use is.

To list installed packages

```sh
nix-env -q
```

To install a package

```sh
nix-env --install gawk
```

Here's a short command log showing what it does; it creates a symlink to the binary in the Nix store - these commands were executed from a [Gitpod Workspace](https://www.gitpod.io/) off [mads-hartmann/random](https://github.com/mads-hartmann/random)

```sh
$ which awk
/home/gitpod/.nix-profile/bin/awk

$ awk --version
GNU Awk 5.1.1, API: 3.1
... REDACTED ...

$ file /home/gitpod/.nix-profile/bin/awk
/home/gitpod/.nix-profile/bin/awk: symbolic link to /nix/store/7rd34k5jnjwhpk7i9dwjc9xd93psp4gg-gawk-5.1.1/bin/awk
```

A neat thing is that Nix keeps a "changelog" of the changes that you make to your user environment, which allows you to rollback changes.

Here's a short example:

```
$ nix-env --list-generations
   1   2022-09-06 23:29:03
   2   2022-09-06 23:29:23
   3   2022-09-06 23:29:50
   4   2022-09-29 18:59:26
   5   2022-09-29 19:05:14   (current)

$ nix-env --rollback
switching profile from version 5 to 4

$ which awk
/usr/bin/awk

$ nix-env --list-generations
   1   2022-09-06 23:29:03
   2   2022-09-06 23:29:23
   3   2022-09-06 23:29:50
   4   2022-09-29 18:59:26   (current)
   5   2022-09-29 19:05:14

$ nix-env --switch-generation 5
switching profile from version 4 to 5

$ which awk
/home/gitpod/.nix-profile/bin/awk
```

I personally find this really neat, and this on its own is a huge improvement to how I've been management software on my systems previously. However, I don't use `nix-env` directly, I use `nix-shell`.

### nix-shell

For the use-cases I'm interested in at the moment `nix-shell` is the star of the show.

> The command nix-shell will build the dependencies of the specified derivation, but not the derivation itself. It will then start an interactive shell in which all environment variables defined by the derivation path have been set to their corresponding values, and the script $stdenv/setup has been sourced. This is useful for reproducing the environment of a derivation for development.
>
> https://nixos.org/manual/nix/stable/command-ref/nix-shell.html

A minimal `shell.nix` file is

```nix
let
  nixpkgs = import <nixpkgs> {};
in
nixpkgs.mkShell {
  nativeBuildInputs = [];

  shellHook = ''
    echo "Welcome to an empty shell"
  '';
}
```

```sh
$ nix-shell empty.nix
Welcome to an empty shell

[nix-shell]$ which go
/home/gitpod/go/bin/go
```

Now using `--pure` it can't even find which

```sh
$ nix-shell --pure empty.nix
Welcome to an empty shell

[nix-shell]$ which go
bash: which: command not found
```

It doesn't even have `which` 😅

### nix-build

## Nix packages

### Version pinning

TODO: See https://nix.dev/tutorials/towards-reproducibility-pinning-nixpkgs#pinning-packages-with-urls-inside-a-nix-expression and reference it

TODO: Explain the following
- nixpkgs and what their version strategy is (e.g. ruby, ruby_3_0, ruby_3_1) - I think they only track major/minor and ignore patch.
- How would you pin a minor version of ruby to e.g. `ruby 3.1.1` or `ruby 3.1.2` - I think you have to pin your version of nixpks to the commit that happens to have the minor version you want - you can use this tool to find it https://lazamar.co.uk/nix-versions/ - but I think you are not guaranteed that a specific minor version will be available.

Tools for management dependencies more easily:

- https://github.com/nmattia/niv

## Nix ecosystem

- [Cachix](https://www.cachix.org/)

## Resources

Official manuals

- [Nix](https://nixos.org/manual/nix/stable/)
- [Nixpkgs](https://nixos.org/manual/nixpkgs/stable/)

3rd party resources

- [nix.dev](https://nix.dev/)
