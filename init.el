(setq server-use-tcp t)

(require 'org)
(require 'ox-publish)
(require 'ob-ocaml)
(require 'ob-sh)
(require 'ob-sql)
(require 'ob-python)
(require 'ob-js)
(require 'ob-R)

(setq org-publish-use-timestamps-flag nil)
(setq org-html-htmlize-output-type 'css)
(setq org-src-fontify-natively t)   ;trying it out
(setq org-startup-folded nil)
(setq org-confirm-babel-evaluate nil) ;; Living on the edge
(setq org-startup-indented nil)
(setq org-export-babel-evaluate nil) ;; Don't evaluate on export by default.

(setq org-publish-project-alist
      '(
        ;;
        ;; Blog
        ;;
        ("org-mads379.github.com"
         ;; Path to your org files.
         :base-directory "~/dev/mads379.github.com/_org/"
         :base-extension "org"
         ;; Path to your Jekyll project.
         :publishing-directory "~/dev/mads379.github.com/"
         :recursive t
         :publishing-function org-html-publish-to-html
         :headline-levels 4
         :html-extension "html"
         :body-only t) ;; Only export section between <body> </body>

        ("org-static-mads379.github.com"
         :base-directory "~/dev/mads379.github.com/org/"
         :base-extension "css\\|js\\|png\\|jpg\\|gif"
         :publishing-directory "~/dev/mads379.github.com/"
         :recursive t
         :publishing-function org-publish-attachment)

        ("mads379.github.com"
         :components ("org-ianbarton" "org-static-ian"))))

(setq org-babel-load-languages
      '((ocaml . t)
        (emacs-lisp . t)
        (sh . t)
        (sql . t)
        (python . t)
        (js . t)
        (r . R)))

;;; init.el ends here
