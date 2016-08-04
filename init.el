(setq server-use-tcp t)

(require 'org)
(require 'ox-publish)
(require 'ob-ocaml)
(require 'ob-sh)
(require 'ob-sql)
(require 'ob-python)
(require 'ob-js)
(require 'ob-R)
(require 'ob-makefile)

(setq auto-save-default nil) ; disable auto-save files (#foo#)
(setq backup-inhibited t)    ; disable backup files (foo~)

(setq org-publish-use-timestamps-flag nil)
(setq org-html-htmlize-output-type 'css)
(setq org-confirm-babel-evaluate nil) ;; Living on the edge
(setq org-export-babel-evaluate nil) ;; Don't evaluate on export by default.
(setq max-specpdl-size 10000)
(setq debug-on-error t)

;; This is important, otherwise I can't tangle source blocks
;; written in makefile mode.
(setq org-src-preserve-indentation t)

;; Even if sh-mode source-blocks fail I still want the output.
(setq org-babel-default-header-args:sh
      '((:prologue . "exec 2>&1") (:epilogue . ":")))

(setq org-babel-load-languages
      '((ocaml . t)
        (emacs-lisp . t)
        (sh . t)
        (makefile . t)
        (sql . t)
        (python . t)
        (js . t)
        (r . R)))

(setq org-publish-project-alist
      '(
        ("org-mads379.github.com"
         ;; Path to your org files.
         :base-directory "~/dev/mads379.github.com/_org/"
         :base-extension "org"
         :publishing-directory "~/dev/mads379.github.com"
         :publishing-function org-html-publish-to-html

         :recursive t
         :headline-levels 4
         :html-extension "html"
         :body-only t))) ;; Only export section between <body> </body>

;;; init.el ends here
