--- 
layout: post
title: "Emacs Tree View"
date: 2016-05-12 07:00:00
---

Every once in a while I find it really convenient to use a tree-like
project explorer to get an overview of the project I'm working on. For
me this is especially the case when working on new projects or during
pair-prgramming sessions. This feature has become ubiquitous in all
editors and Emacs does have quit a lot of packages that try to solve
this problem. Throughout the years I've tried a couple of them (some
examples being
[sr-speedbar](https://www.emacswiki.org/emacs/SrSpeedbar),
[project-explorer](https://github.com/sabof/project-explorer),
[emacs-neotree](https://github.com/jaypei/emacs-neotree)) but none of
them really seem to cut it for me so I sat down and did a bit of elisp.

<a href="/images/emacs-tree-viewer.png" target="_blank">
  <img src="/images/emacs-tree-viewer.png" width="100%" />
</a>

Here are a couple of the features I was looking for

-   It should be [projectile](https://github.com/bbatsov/projectile)
    project aware
-   It should be attached to a single frame. I usually have one frame
    for each project I'm working on and as such I need one for each
    frame.
-   It would be nice if it displayed folders before files
-   It should be positioned on either the right or left side of the
    frame
-   The window shouldn't be affected by `delete-other-windows` and
    similar functions.
-   The window should never be overtaken by another buffer

I believe I've accomplished this without too much hacking around; I'm
using a couple of packages and some built-in emacs features.

Lets start with the packages. I'm using
[use-package](https://github.com/jwiegley/use-package) to configure all my
emacs packages; if you aren't using it already I can really recommend it.

The first part of the solution is
[dired-subtree](http://melpa.org/#/dired-subtree). This is a very helpful
package that makes it possible to insert a subdirectory as a separate listing
in the active dired buffer thus giving you a tree-like dired buffer.

```elisp
(use-package dired-subtree
  :demand
  :bind
  (:map dired-mode-map
    ("<enter>" . mhj/dwim-toggle-or-open)
    ("<return>" . mhj/dwim-toggle-or-open)
    ("<tab>" . mhj/dwim-toggle-or-open)
    ("<down-mouse-1>" . mhj/mouse-dwim-to-toggle-or-open))
  :config
  (progn
    ;; Function to customize the line prefixes (I simply indent the lines a bit)
    (setq dired-subtree-line-prefix (lambda (depth) (make-string (* 2 depth) ?\s)))
    (setq dired-subtree-use-backgrounds nil)))
```

The functions `mhj/dwim-toggle-or-open` and `mhj/mouse-dwim-to-toggle-or-open`
are optional but I use them to either expand a folder or open a file depending
on the what is under the point when you execute it. Here's the implementation.

```elisp
(defun mhj/dwim-toggle-or-open ()
  "Toggle subtree or open the file."
  (interactive)
  (if (file-directory-p (dired-get-file-for-visit))
      (progn
    (dired-subtree-toggle)
    (revert-buffer))
    (dired-find-file)))

(defun mhj/mouse-dwim-to-toggle-or-open (event)
  "Toggle subtree or the open file on mouse-click in dired."
  (interactive "e")
  (let* ((window (posn-window (event-end event)))
     (buffer (window-buffer window))
     (pos (posn-point (event-end event))))
    (progn
      (with-current-buffer buffer
    (goto-char pos)
    (mhj/dwim-toggle-or-open)))))
```

So now we have a `dired` buffer that works as a tree-view. To have `dired` put
folders before files in its list, and to hide a couple of files I don't care
about I use the following configuration

```elisp
(use-package dired
  :ensure nil
  :config
  (progn
    (setq insert-directory-program "/usr/local/opt/coreutils/libexec/gnubin/ls")
    (setq dired-listing-switches "-lXGh --group-directories-first")
    (add-hook 'dired-mode-hook 'dired-omit-mode)
    (add-hook 'dired-mode-hook 'dired-hide-details-mode)))
```

This configuration is for OS X. Notice that I use GNU `ls` rather than
the `ls` that ships with OS X as it doesn't support the command line
options we need for this. You can get this by running
`brew install coreutils`

Now we have a dired buffer with the functionality we want. To solve the
last two requirements we use two very handy Emacs features: [Dedicated
Windows](https://www.gnu.org/software/emacs/manual/html_node/elisp/Dedicated-Windows.html#Dedicated-Windows)
and [Action Functions for
display-buffer](https://www.gnu.org/software/emacs/manual/html_node/elisp/Display-Action-Functions.html).

```elisp
(defun mhj/toggle-project-explorer ()
  "Toggle the project explorer window."
  (interactive)
  (let* ((buffer (dired-noselect (projectile-project-root)))
    (window (get-buffer-window buffer)))
    (if window
    (mhj/hide-project-explorer)
      (mhj/show-project-explorer))))

(defun mhj/show-project-explorer ()
  "Project dired buffer on the side of the frame.
Shows the projectile root folder using dired on the left side of
the frame and makes it a dedicated window for that buffer."
  (let ((buffer (dired-noselect (projectile-project-root))))
    (progn
      (display-buffer-in-side-window buffer '((side . left) (window-width . 0.2)))
      (set-window-dedicated-p (get-buffer-window buffer) t))))

(defun mhj/hide-project-explorer ()
  "Hide the project-explorer window."
  (let ((buffer (dired-noselect (projectile-project-root))))
    (progn
      (delete-window (get-buffer-window buffer))
      (kill-buffer buffer))))
```

The interesting functions here are `display-buffer-in-side-window` and
`set-window-dedicated-p`.

That's all it takes. I've been using it for a couple of weeks and so far I've
very happy with the solution. It's pretty convenient that it's using `dired` as
it gives you a lot of features for free and it plays well with other dired
packages like [dired-narrow](http://melpa.org/#/dired-narrow).
