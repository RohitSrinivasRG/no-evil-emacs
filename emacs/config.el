(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable :elpaca use-package keyword.
  (elpaca-use-package-mode)
  ;; Assume :elpaca t unless otherwise specified.
  (setq elpaca-use-package-by-default t))
;; Block until current queue processed.
(elpaca-wait)

(setq backup-directory-alist '((".*" . "~/.local/share/Trash/files")))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(set-language-environment "UTF-8")

(use-package general
  :config
  (general-create-definer rgrs-leader-keys
    :prefix "C-x")
  ;; (rgrs-leader-keys
  ;;   ;; "b" '(:ignore t :wk "buffer")
  ;;   "b" '(consult-buffer :wk "Switch buffer")
  ;;   )

  ;; GIT
  ;; (global-unset-key (kbd "C-x g"))
  ;; (rgrs-leader-keys
  ;;   "g" `(:ignore t :wk "Magit")
  ;;   "g c" `(magit-clone :wk "Magit Clone")
  ;;   "g g" `(magit-status :wk "Magit status")
  ;;   "g i" `(magit-init :wk "Magit Init repo")
    
  ;;   )
  (general-define-key
    "<f7>" `display-line-numbers-mode)
     
  )

(use-package toc-org
  :commands toc-org-enablepp
  :init (add-hook 'org-mode-hook 'toc-org-enable))

(add-hook 'org-mode-hook 'org-indent-mode)
(use-package org-superstar)
(add-hook 'org-mode-hook (lambda () (org-superstar-mode 1)))

(custom-set-faces
'(org-level-1 ((t (:inherit outline-1 :height 1.35))))
'(org-level-2 ((t (:inherit outline-2 :height 1.3))))
'(org-level-3 ((t (:inherit outline-3 :height 1.25))))
'(org-level-4 ((t (:inherit outline-4 :height 1.25))))
'(org-level-5 ((t (:inherit outline-5 :height 1.2))))
'(org-level-6 ((t (:inherit outline-5 :height 1.15))))
'(org-level-7 ((t (:inherit outline-5 :height 1.1)))))

(require `org-tempo)
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))

(electric-indent-mode -1)
(setq org-edit-src-content-indentation 0)

(use-package avy
  :config
  (general-define-key "M-s-c" `avy-goto-char)
  (general-define-key "M-s-C" `avy-goto-char-2)
  (avy-setup-default)
  (global-set-key (kbd "C-c C-j") 'avy-resume)
   )

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :config
  (setq insert-directory-program "ls" dired-use-ls-dired nil)
  (setq dired-listing-switches "-agho --group-directories-first")
  (setq dired-dwim-target t)
  )

;; A few more useful configurations...
(use-package emacs
  :ensure nil
  :custom
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Emacs 28 and newer: Hide commands in M-x which do not work in the current
  ;; mode.  Vertico commands are hidden in normal buffers. This setting is
  ;; useful beyond Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

)
(setopt use-short-answers t)

(use-package multiple-cursors
  :config
  (general-define-key "C-S-c C-S-c" 'mc/edit-lines)
  (general-define-key "C->" 'mc/mark-next-like-this-word)
  (general-define-key "C-<" 'mc/mark-previous-like-this-word)
  (general-define-key (kbd "C-S-<mouse-1>") 'mc/add-cursor-on-click)
  )

(use-package rainbow-delimiters
:config
(add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package rainbow-mode
:hook org-mode prog-mode)

(use-package vterm
:config
(setq shell-file-name "/usr/bin/bash")
(add-to-list 'vterm-tramp-shells '("ssh" "/bin/bash"))
(add-to-list 'vterm-tramp-shells '("sudo" "/bin/bash"))
)


(use-package vterm-toggle
  :after vterm
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (setq vterm-toggle-scope 'project)
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                     (let ((buffer (get-buffer buffer-or-name)))
                       (with-current-buffer buffer
                         (or (equal major-mode 'vterm-mode)
                             (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                  (display-buffer-reuse-window display-buffer-at-bottom)
                  ;;(display-buffer-reuse-window display-buffer-in-direction)
                  ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                  ;;(direction . bottom)
                  ;;(dedicated . t) ;dedicated is supported in emacs27
                  (reusable-frames . visible)
                  (window-height . 0.3))))

(use-package multi-vterm 
  :after vterm    
  :ensure t
  :bind 
  (
   ("C-c t t" . multi-vterm-dedicated-toggle)
   ("C-c t n" . multi-vterm)
   ("C-c t p" . multi-vterm-project)
   )
  :config
  (setq multi-vterm-dedicated-window-height-percent 30)
  
)

(use-package smartparens
:config
(smartparens-global-mode))

(use-package corfu
  ;; Optional customizations
  :custom
  ;; (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-separator ?_)          ;; Orderless field separator
  (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin

  ;; Enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))

  ;; Recommended: Enable Corfu globally.  This is recommended since Dabbrev can
  ;; be used globally (M-/).  See also the customization variable
  ;; `global-corfu-modes' to exclude certain modes.
  ;; :init
  ;; (global-corfu-mode)
  )

(add-hook 'elpaca-after-init-hook 'global-corfu-mode)
;; Enable Corfu completion UI
;; See the Corfu README for more configuration tips.
;; Add extensions

(use-package cape
  ;; Bind dedicated completion commands
  ;; Alternative prefix keys: C-c p, M-p, M-+, ...
  :bind (("C-c p p" . completion-at-point) ;; capf
         ("C-c p t" . complete-tag)        ;; etags
         ("C-c p d" . cape-dabbrev)        ;; or dabbrev-completion
         ("C-c p h" . cape-history)
         ("C-c p f" . cape-file)
         ("C-c p k" . cape-keyword)
         ("C-c p s" . cape-elisp-symbol)
         ("C-c p e" . cape-elisp-block)
         ("C-c p a" . cape-abbrev)
         ("C-c p l" . cape-line)
         ("C-c p w" . cape-dict)
         ("C-c p :" . cape-emoji)
         ("C-c p \\" . cape-tex)
         ("C-c p _" . cape-tex)
         ("C-c p ^" . cape-tex)
         ("C-c p &" . cape-sgml)
         ("C-c p r" . cape-rfc1345))
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  ;;(add-hook 'completion-at-point-functions #'cape-history)
  ;;(add-hook 'completion-at-point-functions #'cape-keyword)
  ;;(add-hook 'completion-at-point-functions #'cape-tex)
  ;;(add-hook 'completion-at-point-functions #'cape-sgml)
  ;;(add-hook 'completion-at-point-functions #'cape-rfc1345)
  ;;(add-hook 'completion-at-point-functions #'cape-abbrev)
  ;;(add-hook 'completion-at-point-functions #'cape-dict)
  ;;(add-hook 'completion-at-point-functions #'cape-elisp-symbol)
  ;;(add-hook 'completion-at-point-functions #'cape-line)
)

;; (use-package kind-icon
;;   :ensure t
;;   :after corfu
;;   ;:custom
;;   ; (kind-icon-blend-background t)
;;   ; (kind-icon-default-face 'corfu-default) ; only needed with blend-background
;;   :config
;;   (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package magit
  :config
  (global-unset-key (kbd "C-x g"))
  (rgrs-leader-keys
    "g" `(:ignore t :wk "Magit")
    "g c" `(magit-clone :wk "Magit Clone")
    "g g" `(magit-status :wk "Magit status")
    "g i" `(magit-init :wk "Magit Init repo")
    )

)
(use-package transient)

(use-package anzu
:config
(global-anzu-mode 1)
(general-define-key [remap query-replace] 'anzu-query-replace)
(general-define-key [remap query-replace-regexp] 'anzu-query-replace-regexp))

(add-to-list 'custom-theme-load-path "~/.config/emacs/themes/")

(use-package doom-themes
:ensure t
:config
(setq doom-themes-enabled-bold t
      doom-themes-enable-italic t))

(setq custom-safe-themes t)
(add-hook 'elpaca-after-init-hook (lambda() (load-theme 'doom-gruvbox)))

(use-package doom-modeline
  :ensure t
  :init
  ;; (setq doom-modeline-support-imenu t) 
  (doom-modeline-mode 1)
  :config
  (setq doom-modeline-project-detection 'auto)

  ;; Specification of \"percentage offset\" of window through buffer.
  (setq doom-modeline-percent-position '(-3 "%p"))

  ;; ;; Format used to display line numbers in the mode line. Also used to display column for some reason
  (setq doom-modeline-position-line-format '("%l:%c"))
  (setq doom-modeline-buffer-state-icon t)
  (setq doom-modeline-enable-word-count nil)
  (setq doom-modeline-time-icon t)
  (setq doom-modeline-time-live-icon t)
  (setq doom-modeline-time-analogue-clock t)

  )

(use-package nerd-icons)

(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)
)


;; Optionally:
;; (setq nerd-icons-corfu-mapping
;;       '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
;;         (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
;;         ;; ...
;;         (t :style "cod" :icon "code" :face font-lock-warning-face)))
;; Remember to add an entry for `t', the library uses that as default.

;; The Custom interface is also supported for tuning the variable above.

(use-package dimmer
:config
(dimmer-configure-which-key)
(dimmer-mode t))

(winner-mode 1)

(use-package winum
:config
(winum-mode))

(global-set-key (kbd "C-0") 'winum-select-window-0)
(global-set-key (kbd "C-1") 'winum-select-window-1)
(global-set-key (kbd "C-2") 'winum-select-window-2)
(global-set-key (kbd "C-3") 'winum-select-window-3)
(global-set-key (kbd "C-4") 'winum-select-window-4)
(global-set-key (kbd "C-5") 'winum-select-window-5)
(global-set-key (kbd "C-6") 'winum-select-window-6)
(global-set-key (kbd "C-7") 'winum-select-window-7)
(global-set-key (kbd "C-8") 'winum-select-window-8)

(use-package orderless
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package consult
  :bind (
	 ("C-x b" . consult-buffer)
	 ("M-g i" . consult-imenu)
	 ("C-x r b" . consult-bookmark)
	 ("M-s l" . consult-line)
	 ("M-s g" . consult-grep)
	 ("M-s r" . consult-ripgrep)
	 ("M-g g" . consult-goto-line) 
	 ("M-g M-g" . consult-goto-line)
	 ("C-x p b" . consult-project-buffer)
	 ;; M-s bindings in `search-map'
	 ("M-s d" . consult-find) 
	 ("M-s k" . consult-keep-lines)
	 ("M-s u" . consult-focus-lines)
	 )
)

(use-package vertico
  :init
  (vertico-mode))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode))

(setq enable-recursive-minibuffers t)

;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))

(use-package which-key
  :init
  (which-key-mode 1)
  :config
  (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.8
        which-key-max-description-length 25
        which-key-allow-imprecise-window-fit nil
        which-key-separator " → " ))

(use-package indent-bars
  :ensure (:host github :repo "jdtsmith/indent-bars")
  :hook ((prog-mode) . indent-bars-mode)
  )

(use-package isearch
  :ensure nil
  :bind
  ("C-*" . 'isearch-forward-symbol-at-point)
  )

(use-package magit-todos
  :after magit
  :config (magit-todos-mode 1))

(use-package consult-project-extra
  :bind
  (("C-c p f" . consult-project-extra-find)
   ("C-c p o" . consult-project-extra-find-other-window)))

(use-package drag-stuff
  :config
  (drag-stuff-global-mode 1)
  (drag-stuff-define-keys)
  )

(use-package good-scroll
  :config
  (good-scroll-mode 1)
  (global-set-key [next] #'good-scroll-up-full-screen)
  (global-set-key [prior] #'good-scroll-down-full-screen)
)

(use-package git-gutter
  :config
  (global-git-gutter-mode 1)
)

(use-package beacon
  :config
  (beacon-mode 1)
)

(use-package solaire-mode
  :config
  (solaire-global-mode +1)
)

(use-package kbd-mode 
  :ensure (:host github :repo "kmonad/kbd-mode")
  ;;(kbd-mode-kill-kmonad "pkill -9 kmonad")
  ;;(kbd-mode-start-kmonad "kmonad ~/path/to/config.kbd")
)

(add-to-list 'load-path "~/.config/emacs/languages/bsv/")
(add-to-list 'load-path "~/.config/emacs/languages/bsv/emacs20-extras.el")
(add-to-list 'load-path "~/.config/emacs/languages/bsv/mark.el")

(autoload 'bsv-mode "bsv-mode" "BSV mode" t )
(setq auto-mode-alist (cons  '("\\.bsv\\'" . bsv-mode) auto-mode-alist))
(setq auto-mode-alist (cons  '("\\.defines\\'" . bsv-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.defs\\'" . bsv-mode) auto-mode-alist))
(setq bsv-indent-level 2)
(setq bsv-indent-level-module 2)
(setq bsv-indent-level-declaration 2)
(setq bsv-indent-level-directive 2)
(setq bsv-indent-level-behavioral 2)
(setq bsv-cexp-indent 2)
(setq bsv-tab-always-indent nil)

(setq auto-mode-alist (cons '("\\.sdc\\'" . tcl-mode) auto-mode-alist))

(use-package anaconda-mode
:config
(add-hook 'python-mode-hook 'anaconda-mode))

(use-package yaml-mode
:config
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
(add-hook 'yaml-mode-hook
    '(lambda ()
    (define-key yaml-mode-map "\C-m" 'newline-and-indent)))

)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown"))

(defun rgrs/spc_4_indent ()
 "Updates the indent tabs mode to nil"
(interactive)
(setq indent-tabs-mode nil))

(defun rgrs/test_print ()
 "Updates the indent tabs mode to nil"
(interactive)
(message "Mode loaded;LMAO bsv-mode-hook working"))
(add-hook 'bsv-mode-hook #'rgrs/spc_4_indent)
(add-hook 'bsv-mode-hook 'rgrs/test_print)
(add-hook 'prog-hook #'rgrs/spc_4_indent)
