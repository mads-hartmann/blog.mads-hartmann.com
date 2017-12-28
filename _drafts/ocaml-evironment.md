A blog post about the tools you need to know in order to code
reason/ocaml?

- opam
- jbuild

## opam

It's a bit confusing to me how some opam packages seems to install many modules?
cohttp installs more stuff if you also have lwt or aync? Something about it
installing many findlib subpackages? so `opam install async cohttp` will
provide a package `cohttp.async`. but that won't be installed unless you also install
async? It's a bit confusing.

Nice:: `opam depext <PACKAGE>` gives you install commands for missing external packages 🎉
