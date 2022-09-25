# Nix

I have been vaguely aware of Nix for a very long time but never really took the time to sit down and play around with it until recently. In this post I'll go over what I've picked up so far.

## What is Nix

The [official manual](https://nixos.org/manual/nix/stable) is quite good so I'd recommend reading that to get a sense of what Nix is. Below I've highlighted the passages that stand out to me and will provide a bit of context on why.

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

Now this is where things start to get exciting, and where the importance of the functional programming foundations shine through. If package has a "complete dependency specification" and "Nix expressions are deterministic" then of course, why would you ever build the same package twice?

> We provide a large set of Nix expressions containing hundreds of existing Unix packages, the Nix Packages collection (Nixpkgs).

They're really understating it here. At the time of writing this blog post it's 80.000 packages. That's a lot of packages.

At this point I'm more then a little excited. You have a package manager that's built on top of few core primitives that have allowed to them build a source/binary transparent package manager that's extremely easy to cache. On top of that, other people have already put in the work of writing Nix expressions for 80.000 packages which means that I most likely will find any dependency I need in there already.

> Nix is extremely useful for developers as it makes it easy to automatically set up the build environment for a package. Given a Nix expression that describes the dependencies of your package, the command nix-shell will build or download those dependencies if they’re not already in your Nix store, and then start a Bash shell in which all necessary environment variables (such as compiler search paths) are set.

Now I'm sold. Setting up reproducible build environment has so far been a struggle. The move to using Docker for developer environments hasn't fixed that, as `Dockerfile`s are generally not reproducible as they `apt-get update` or perform other operations that depend on what time you happened to build the image.

So let's get hands-on and see how to use Nix.

## Hands on with Nix

### Nix the language

### nix-shell

#### Version pinning

### nix-build

## Resources

Official manuals

- [Nix](https://nixos.org/manual/nix/stable/)
- [Nixpkgs](https://nixos.org/manual/nixpkgs/stable/)

3rd party resources

- [nix.dev](https://nix.dev/)
