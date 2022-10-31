---
layout: post-no-separate-excerpt
title: "Sharing Bash Scripts with Nix"
date: 2022-10-21 03:00:00
colors: pinkred
---

In my [previous post](https://blog.mads-hartmann.com/2022/10/18/use-cases-for-nix.html) I mentioned that one of the use cases I had in mind for Nix was using it to build and share tools more easily:

> From what I understand so far, you get “publishing” for free if you’re using Nix to build your tools as users simply have to point to your Git repository and the path of the relevant Nix derivation and it will take care of building the tool in their environment

I spent some time figuring out how this would work for a simple bash script and thought I'd share the details in this post.

There are three components to this: The actual Bash script, the Nix derivation to "package" it, and a nix derivation that shows how to use the package.

## The Bash script

I wanted the Bash script to be as simple as possible, yet still depend on at least one or two executables being installed on the system. I decided to write a tiny one that `curl`s the Wikipedia REST API and uses `jq` to pretty-print the result - that is, the script depends on `curl` and `jq` to be available on the system that executes it.

```sh
#!/usr/bin/env bash
set -euo pipefail

url="https://en.wikipedia.org/w/rest.php/v1/search/page?q=${1}&limit=1"
curl "${url}" --silent | jq '.'
```

That's it for the script. Let's move on to the Nix package declaration.

## The Nix derivation

To package this script using Nix we'll have to write a Nix derivation for it.

```nix
with import <nixpkgs> {};
let 
  script = rec {
    name = "wiki-search";
    src = builtins.readFile ./wiki-search.sh;
    runtimeInputs = [ pkgs.jq pkgs.curl ];
    bin = (pkgs.writeScriptBin name src).overrideAttrs(old: {
      buildCommand = "${old.buildCommand}\n patchShebangs $out";
    });
  };
in pkgs.symlinkJoin {
  name = script.name;
  paths = [ script.bin ] ++ script.runtimeInputs;
  buildInputs = [ makeWrapper ];
  postBuild = "wrapProgram $out/bin/${script.name} --prefix PATH : $out/bin";
}
```

While this is only 16 lines of Nix code, there is quite a lot to unpack. I have highlighted the details that I find interesting below.

`builtins.readFile path` ([docs](https://nixos.org/manual/nix/stable/language/builtins.html#builtins-readFile)) returns the contents of the file path as a string.

`pkgs.writeScriptBin my-file contents` ([docs](https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeText)) Writes the `conents` to `my-file` at `/nix/store/<store path>/bin/my-file` and makes it executable. It returns a derivation which we then invoke `overrideAttrs` on. `overrideAttrs` ([docs](https://nixos.org/manual/nixpkgs/stable/#sec-pkg-overrideAttrs)) is a function that is available on all derivations produced by `stdenv.mkDerivation` which is what  `writeScriptBin` uses. It makes it possible to override attributes in the derivation, in this case it's used to extend the `buildCommand` so that it also calls `patchShebangs` on the script produced by `writeScriptBin`. `patchShebangs $out` ([docs](https://nixos.org/manual/nixpkgs/stable/#patch-shebangs.sh), [source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/patch-shebangs.sh)) patches the script so that `#!/usr/bin/env bash` instead points to bash managed by Nix - I believe you'll get whatever version of bash is defined in the revision of [nixpkgs](https://github.com/NixOS/nixpkgs) you're using, but there's almost certainly a way to override that.

`pkgs.symlinkJoin` ([docs](https://nixos.org/manual/nixpkgs/stable/#trivial-builder-symlinkJoin)) is used to "join" all the paths into a new derivation.

TODO: Can I point to any docs/source for makeWrapper?

`wrapProgram` ([docs](https://nixos.org/manual/nixpkgs/stable/#fun-wrapProgram), [source](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh)) creates a wrapper script which configures the environment variable PATH to include the `bin` folder of our packages - this is how we make the runtime dependencies available to the bash script - this will become more clear in a moment when we inspect the files that Nix produces when we build the package.

TODO: Might make sense to have this in a "details" toggle showing how to use `nix repl` to play around there.
TODO: Some notes on how to best find docs/functions - or maybe just a note that I found it hard. E.g. how do I find the derivation that produced `makeWrapper`? How do I look up the docs for a derivation like `pkgs.writeScriptBin`? Does the REPL have any commands to do so like other REPLs? Maybe some notes about tooling too? Are there any LSP implementations that allow me to jump to derivations?

```sh
nix repl '<nixpkgs>'
nix-repl> pkgs.writeScriptBin "filename" "echo hello"
«derivation /nix/store/2yndq2svmg0kb5nws4d0vkkvar9j0g32-filename.drv»
```

```sh
cat /nix/store/2yndq2svmg0kb5nws4d0vkkvar9j0g32-filename.drv
```

## Using the package in a Nix shell

Now, if I want to use this in a nix-shell environment, I can simply load it from Git as following:

```nix
let
  nixpkgs = import <nixpkgs> {};
  repo = builtins.fetchGit {
    url="https://github.com/mads-hartmann/random.git";
    rev="74f52ea4ec592cfacc09fed7d205bcf1567a1bae";
    shallow = true;
  };
  wiki-search = import "${repo}/nix/nix-build/wiki-search/wiki-search.nix";
in
nixpkgs.mkShell {
  nativeBuildInputs = [
    wiki-search
  ];
  shellHook = '';
}
```
