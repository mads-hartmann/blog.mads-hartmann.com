---
layout: post
title: "Complete Words Based on the Active Dictionary in Emacs"
date: 2014-03-03 20:19:00
categories: Emacs
---

<a href="/images/dictionary-completion.png" target="_blank">
  <img src="/images/dictionary-completion.png" />
</a>

I have an ever-growing document where I keep track of all the small (and
sometimes major) changes I want to make to Emacs. Today I picked a random item
and had a go at it.

I'm a lousy speller and often misspell words in my comments and git commit
messages. I do have [fly-spell][fly-spell] enabled to catch my mistakes but I
would prefer not to make them in the first place. For functions, variable names
etc. I have [dabbrev-expand][dabbrev-expand] and my own home-grown solution
based on [ctags][ctags] but nothing similar for words in the English
dictionary, so I spent 15 minutes implementing a simple solution.

The picture above shows the command in action trying to complete the word
`"dino"`. I invoked `ido-complete-word-ispell` and typed in `"sa"`; the list
shows the three remaining completions. I use
[ido-vertical-mode][ido-vertical-mode] to get the vertical representation of
the completions.

The code for command is shown below. It depends on [ido-mode][ido-mode].

```elisp
(defun ido-complete-word-ispell ()
  "Completes the symbol at point based on entries in the
dictionary"
  (interactive)
  (let* ((word (thing-at-point 'symbol t))
         (boundaries (bounds-of-thing-at-point 'symbol))
         (start (car boundaries))
         (end (cdr boundaries))
         (words (ispell-lookup-words word)))
    (let ((selection (ido-completing-read "Words: " words)))
      (if selection
          (progn
            (delete-region start end)
            (insert selection))))))
```

To add a key-binding for any of the following:

```elisp
;; To enable it in a specific mode
(define-key markdown-mode-map "\M-?" 'ido-complete-word-ispell)
;; To enable it in all modes
(global-set-key (kbd "M-?") 'ido-complete-word-ispell)
```

Simple as that. Now I just need to figure out how to bind the command to a
specific key whenever the cursor is inside of a comment or a doc-string.

[fly-spell]: http://www.emacswiki.org/emacs/FlySpell
[dabbrev-expand]: http://www.emacswiki.org/emacs/DynamicAbbreviations
[ctags]: http://ctags.sourceforge.net/
[ido-mode]: http://www.emacswiki.org/emacs/InteractivelyDoThings
[ido-vertical-mode]: https://github.com/gempesaw/ido-vertical-mode.el
