;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

(setq doom-gruvbox-dark-variant "soft")
(setq doom-theme 'doom-gruvbox)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 18 :weight 'semi-bold))

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; settings
;;; --- General Settings (Ported from set.lua) ---

;; 1. Line Numbers: Relative (vim.opt.relativenumber = true)
(setq display-line-numbers-type 'relative)

;; 2. Tabs & Indentation (vim.opt.tabstop = 4, expandtab = true)
;; Note: Emacs handles this per-mode, but this sets the defaults.
(setq-default tab-width 4
              standard-indent 4
              indent-tabs-mode nil) ; expandtab (use spaces)

;; 3. Scrolling (vim.opt.scrolloff = 10)
(setq scroll-margin 10)
(setq evil-kill-on-visual-paste nil)

;; 4. Split Behavior (vim.opt.splitright = true, splitbelow = false)
(setq evil-vsplit-window-right t
      evil-split-window-below nil)

;; unlag terminal
(setq vterm-timer-delay nil)

;; nvim keybinds
;;; --- Keybindings (Ported from keymap.lua) ---
(use-package! drag-stuff
  :config
  (drag-stuff-global-mode 1))

;; fix apheleia
(after! apheleia
  (setf (alist-get 'rust-mode apheleia-mode-alist) '(lsp))
  (setf (alist-get 'rustic-mode apheleia-mode-alist) '(lsp))
  (setf (alist-get 'rust-ts-mode apheleia-mode-alist) '(lsp)))

(setq +format-with-lsp t)
;; lsp settings
(after! lsp-mode
  ;; Stop the signature popup from showing automatically
  (setq lsp-signature-auto-activate nil)
  )

;; undo tree
(map!
 :n "U" #'vundo
 )
;; vertico splits
(defun my/open-in-vsplit (file)
  (interactive "f")
  (select-window (split-window-right))
  (find-file file))

(defun my/open-in-hsplit (file)
  (interactive "f")
  (select-window (split-window-below))
  (find-file file))

(defun my/vertico-vsplit ()
  (interactive)
  (require 'embark)
  ;; 't' at the end tells Embark to quit the minibuffer immediately
  (embark--act #'my/open-in-vsplit (car (embark--targets)) t))

(defun my/vertico-hsplit ()
  (interactive)
  (require 'embark)
  (embark--act #'my/open-in-hsplit (car (embark--targets)) t))

;; 3. Bind them
(map! :after vertico
      :map vertico-map
      "C-v" #'my/vertico-vsplit
      "C-s" #'my/vertico-hsplit)
(map!
 ;; -- Normal Mode Mappings --
 :n ";" #'evil-ex                     ; Map ; to :
 :n "J" #'mz/join-lines-stay          ; J keeps cursor in place (defined below)

 ;; Centered Scrolling (C-d/C-u + zz)
 :n "C-d" (cmd! (evil-scroll-down 0) (evil-scroll-line-to-center nil))
 :n "C-u" (cmd! (evil-scroll-up 0)   (evil-scroll-line-to-center nil))
 :n "C-q" #'winner-undo
 :n "C-e" #'winner-redo


 ;; Disable Arrow Keys
 :n "<left>"  #'ignore
 :n "<right>" #'ignore
 :n "<up>"    #'ignore
 :n "<down>"  #'ignore



 ;; -- Visual Mode Mappings --

 :v "J" #'drag-stuff-down
 :v "K" #'drag-stuff-up


 ;; -- Leader Key Mappings (Prefix "SPC") --
 :leader
 :desc "Open Dired" "pv" #'dired-jump
 :desc "Seach project" "sg" #'+default/search-project
 :desc "Diagnostic List" "c q"  #'flycheck-list-errors)


;; Helper function for the "J" behavior (join without moving cursor)
(use-package! evil-goggles
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))
(defun mz/join-lines-stay ()
  "Join lines but keep cursor position."
  (interactive)
  (let ((p (point)))
    (evil-join (point) (line-beginning-position 2))
    (goto-char p)))


;; ORG MODE
(custom-set-faces!
  '(org-level-1 :inherit outline-1 :height 1.4)
  '(org-level-2 :inherit outline-2 :height 1.3)
  '(org-level-3 :inherit outline-3 :height 1.2)
  '(org-level-4 :inherit outline-4 :height 1.1)
  '(org-document-title :height 1.75 :weight bold))

;; Agenda
(setq org-agenda-custom-commands
      '(("v" "Improved view"
         (
          (agenda ""
                  ((org-agenda-span '30)
                   (org-agenda-show-all-dates 'nil)
                   (org-agenda-overriding-header "Scheduled Stuff")))
          (tags "*"
                ((org-agenda-files '("~/org/exams.org"))
                 (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                 (org-agenda-overriding-header "--- EXAMS ---")))
          (tags-todo "*"
                     ((org-agenda-files '("~/org/personal.org"))
                      (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                      (org-agenda-overriding-header "--- PERSONAL ---")))
          (tags "*"
                ((org-agenda-files '("~/org/uni.org"))
                 (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                 (org-agenda-overriding-header "--- UNI ---")))
          ))))

(defun open-custom-agenda()
  (interactive)
  (org-agenda nil "v")
  )
(map!
 :n "M-m" 'open-custom-agenda)
;;
;;Agenda templates
(after! org
  (add-to-list 'org-capture-templates
               '("c" "Code TODO" entry
                 (file+headline +org-capture-todo-file "Inbox")
                 "* TODO %?\nFrom: %a\n\n#+BEGIN_SRC %(with-current-buffer (org-capture-get :original-buffer) (replace-regexp-in-string \"-ts-mode$\\|-mode$\" \"\" (symbol-name major-mode)))\n%i\n#+END_SRC\n"
                 :prepend t
                 :kill-buffer t)))
;; DAP
(setq dape-adapter-dir "~/.config/emacs/debug-adapters/")
;; PDFS
(use-package! pdf-tools
  :config
  (add-to-list 'revert-without-query ".pdf")
  (map! :map pdf-view-mode-map
        :n "j"   #'pdf-view-next-line-or-next-page
        :n "k"   #'pdf-view-previous-line-or-previous-page
        :n "C-=" #'pdf-view-enlarge
        :n "C--" #'pdf-view-shrink))
(add-hook 'pdf-view-mode-hook #'(lambda () (interactive) (display-line-numbers-mode -1)
                                  (blink-cursor-mode -1)))
;;


;; Vim like clipboard
(setq select-enable-clipboard nil
      select-enable-primary nil)

(map! :leader
      ;; 1. YANK (Copy)
      ;; We set the register to '+' (system), then call yank.
      ;; Since yank is an "operator", it will automatically wait for your motion (iw, $, etc.)
      :desc "Yank to system" "y"
      (cmd! (evil-use-register ?+) (call-interactively #'evil-yank))

      :desc "Paste from system (Before)" "P"
      (cmd! (evil-use-register ?+) (call-interactively #'evil-paste-before)));;
(after! evil
  (map! :i "C-v" (cmd! (evil-paste-from-register ?+))))
;;java
(after! lsp-java
  ;; Tell LSP that 'java-ts-mode' uses the 'java' language server
  (add-to-list 'lsp-language-id-configuration '(java-ts-mode . "java")))

;; 3. Trigger LSP automatically when java-ts-mode activates
(add-hook 'java-ts-mode-hook #'lsp)


;; useful binds
(map!
 :n "M-p" 'duplicate-line
 :n "C-," 'doom/window-maximize-buffer)

;; Winner undo
