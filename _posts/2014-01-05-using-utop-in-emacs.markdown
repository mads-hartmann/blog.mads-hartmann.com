---
layout: post
title:  "Using Utop in Emacs"
date:   2014-01-05 14:08:52
categories: ocaml
---

<a href="/images/ocaml-utop-session.png">
<img src="/images/ocaml-utop-session.png" width="100%"/>
</a>

> utop is an improved toplevel for OCaml. It can run in a terminal or
> in Emacs. It supports line edition, history, real-time and context
> sensitive completion, colors, and more.

I've found [utop](https://github.com/diml/utop) to be a really nice toplevel for playing around with OCaml. Espeically being able to evaluate code straight from an Emacs buffer is wonderful. However, as soon as you start using it on larger projects you will find that in a lot of cases it won't be able to evaluate the code in your buffer as it depends on various [opam](http://opam.ocamlpro.com) packages and modules you've defined in your project.

Luckily there is a way to make utop aware of the opam packages that you require and the modules you've defined in your project. This is a short blog post that explain how. I also created a very small [example project](http://github.com/mads379/ocaml-utop-emacs-example) to go along with the blog post.

## Loading the appropriate packages

If you fire up utop and invoke `#use "topfind";;` you will have a new directive named `#require` that you can use to load your opam packages into the toplevel (e.g. `#require "batteries";;`)

This is really nice and convenient when you want to play around with a specific package, but if you use a lot of modules it's still quite tedious (we use 24 in one of our OCaml projects at [Issuu](http://www.issuu.com/about).

Luckily utop provides the following command line option:

    -init <file>        Load <file> instead of default init file

So if you simply create a `toplevel.init` file which contains the appropriate `#use` and `#require` statements then you will have everything loaded and ready when utop has launched. See [this makefile](https://github.com/mads379/ocaml-utop-emacs-example/blob/master/Makefile) for an example of a Makefile target that generates such a file.

## Making utop aware of your compiled sources

It so happens that utop takes another very helpful command line argument:

    -I <dir>            Add <dir> to the list of include directories

So all you need to do is to point utop to the appropriate folder where you generate your bytecode. There are however, one caveat: `-I` will only include one directory, not any sub-directories, so you need to add an `-I` argument for each folder that contains your bytecode.

Again see [this makefile](https://github.com/mads379/ocaml-utop-emacs-example/blob/master/Makefile) for an example of how to start `utop` with the compiled binaries ready to be loaded.

## Using it from inside of Emacs

The example project contains a Makefile target that will compile your OCaml code and start a utop session with the appropriate arguments just as explained in the blog post so far.  However, to get utop set up properly as the toplevel that is recognized by Emacs we still need to do some tweaking.

Now, I assume that you have utop and configured it properly in Emacs as described in the [README](https://github.com/diml/utop) (you also have to set it as the default OCaml toplevel as described in this [section](https://github.com/diml/utop#integration-with-the-tuaregtyperex-mode), see my [Emacs config](https://github.com/mads379/.emacs.d/blob/master/languages.el#L18) if you need an example).

Now all you need to do is copy the following elisp code, save it somewhere and load it into Emacs.

{% highlight lisp %}

(require 'cl)
(require 'utop)

(defconst init-file-name "toplevel.init")

(defconst build-dir-name "_build")

(defun upward-find-file (filename &optional startdir)
  "Move up directories until we find a certain filename. If we
  manage to find it, return the containing directory. Else if we
  get to the toplevel directory and still can't find it, return
  nil. Start at startdir or . if startdir not given"

  (let ((dirname (expand-file-name
                  (if startdir startdir ".")))
        (found nil) ; found is set as a flag to leave loop if we find it
        (top nil))  ; top is set when we get
                    ; to / so that we only check it once

    ; While we've neither been at the top last time nor have we found
    ; the file.
    (while (not (or found top))
      ; If we're at / set top flag.
      (if (string= (expand-file-name dirname) "/")
          (setq top t))

      ; Check for the file
      (if (file-exists-p (expand-file-name filename dirname))
          (setq found t)
        ; If not, move up a directory
        (setq dirname (expand-file-name ".." dirname))))
    ; return statement
    (if found dirname nil)))

(defun should-include-p (file)
  "A predicate for wether a given file-path is relevant for
   setting up the `include` path of utop."
  (cond ((string= (file-name-base file) ".") nil)
        ((string= (file-name-base file) "..") nil)
        ((string-match ".*\.dSYM" file) nil)
        ((file-directory-p file) t)))

(defun ls (dir)
  "Returns directory contents. Only includes folders that
   are relevant for utop"
  (if (should-include-p dir)
      (remove-if-not 'should-include-p (directory-files dir t))
    nil))

(defun ls-r (dir)
  "Returns directory contents, decending into subfolders
   recursively. Only returns folders that are relevant for utop "
  (defun tail-rec (directories result)
    (if (> (length directories) 0)
        (let* ((folders (remove-if-not 'should-include-p directories))
               (next (mapcar 'ls folders))
               (flattened (apply #'append next)))
          (tail-rec flattened (append result folders)))
      result))
  (tail-rec (list dir) nil))

(defun utop-invocation (&optional startdir)
  "Generates an appropriately initialized utop buffer."
  (interactive)
  (let* ((dir (if startdir startdir default-directory))
         (project-root (upward-find-file init-file-name dir))
         (init-file (concat project-root "/" init-file-name))
         (build-dir (concat project-root "/" build-dir-name))
         (includes (ls-r build-dir))
         (includes-str (mapconcat (lambda (i) (concat "-I " i)) includes " "))
         (utop-command (concat "utop -emacs " "-init " init-file " " includes-str)))
    ;; The part below is mostly copied from utop.el; Look at the source for comments.
    (let ((buf (get-buffer utop-buffer-name)))
      (cond
       (buf
        (pop-to-buffer buf)
        (when (eq utop-state 'done) (utop-restart)))
       (t
        ;; This is the change. We set the command string explicitly.
        (setq utop-command utop-command)
        (setq buf (get-buffer-create utop-buffer-name))
        (pop-to-buffer buf)
        (with-current-buffer buf (utop-mode))))
      buf)))

{% endhighlight %}

This will provide a `utop-invocation` function that you can invoke using `M-x`; the function will start a properly initialized utop session.

Now that the Emacs _utop_ buffer is aware of all the packages that we're using and all of the modules we've defined, we can open any `.ml` file and start feeding it to our utop session using `C-x C-e`. This makes it refreshingly easy to play around with smaller pieces of OCaml code straight from your buffer.
