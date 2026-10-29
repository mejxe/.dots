;;; config.el --- generated from config.org -*- lexical-binding: t; -*-

(setq doom-theme 'doom-gruvbox
      doom-gruvbox-dark-variant "soft"
      doom-gruvbox-dark-brighter-comments t
      doom-gruvbox-dark-brighter-modeline t
      doom-gruvbox-light-brighter-comments nil
      doom-gruvbox-light-brighter-modeline t)

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 18 :weight 'semi-bold))

(setq fancy-splash-image (concat doom-user-dir "splash.png"))

(add-hook 'org-mode-hook #'org-superstar-mode)

;; Must be set before org loads!
(setq org-directory "~/org/")

(add-load-path! "lisp")

;; Relative (vim.opt.relativenumber = true)
(setq display-line-numbers-type 'relative)

;; (vim.opt.tabstop = 4, expandtab = true)
;; Note: Emacs handles this per-mode, but this sets the defaults.
(setq-default tab-width 4
              standard-indent 4
              indent-tabs-mode nil) ; expandtab (use spaces)

;; (vim.opt.scrolloff = 10)
(setq scroll-margin 10)
(setq evil-kill-on-visual-paste nil)

;; (vim.opt.splitright = true, splitbelow = false)
(setq evil-vsplit-window-right t
      evil-split-window-below nil)

(use-package! drag-stuff
  :config
  (drag-stuff-global-mode 1))

(use-package! evil-goggles
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))

(map!
 :n "U" #'vundo
 )

;; Helper function for the "J" behavior (join without moving cursor)
(defun my/join-lines-stay ()
  "Join lines but keep cursor position."
  (interactive)
  (let ((p (point)))
    (evil-join (point) (line-beginning-position 2))
    (goto-char p)))

(map!
 ;; -- Normal Mode Mappings --
 :n ";" #'evil-ex                     ; Map ; to :
 :n "J" #'my/join-lines-stay          ; J keeps cursor in place (defined above)
 :n "M-u" #'universal-argument

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

(map!
 :n "M-p" 'duplicate-line
 :n "C-," 'doom/window-maximize-buffer)

;; dired . bind
(map! :after dired
      :map dired-mode-map
      :n "." #'dired-up-directory)

(setq select-enable-clipboard nil
      select-enable-primary nil)

(evil-define-operator my/evil-yank-clipboard (beg end type)
  "Yank to the system clipboard only, leaving the kill ring untouched.
`evil-yank' always calls `kill-new', even for the + register."
  :move-point nil
  :repeat nil
  (interactive "<R>")
  (let ((text (if (eq type 'block)
                  (string-join (extract-rectangle beg end) "\n")
                (filter-buffer-substring beg end))))
    (when (and (memq type '(line screen-line))
               (not (string-suffix-p "\n" text)))
      (setq text (concat text "\n")))
    (evil-set-selection 'CLIPBOARD text)
    (unless (memq type '(line screen-line))
      (goto-char beg))))

(evil-define-command my/evil-paste-clipboard (count)
  "Paste before point from the system clipboard, linewise if it ends in a newline."
  :suppress-operator t
  (interactive "*P")
  (let ((text (evil-get-register ?+)))
    (evil-paste-before count ?+ (and (stringp text)
                                     (string-suffix-p "\n" text)
                                     #'evil-yank-line-handler))))

(map! :leader
      :desc "Yank to system" :nv "y" #'my/evil-yank-clipboard
      :desc "Paste from system (before)" :n "P" #'my/evil-paste-clipboard)

(after! evil
  (map! :i "C-v" (cmd! (insert (shell-command-to-string "wl-paste -n")))))

(defun my/ffc ()
  "Open the file whose path is in the Wayland clipboard."
  (interactive)
  (let ((path (shell-command-to-string "wl-paste -n")))
    (find-file (string-trim path))))

;; standalone rustfmt has no idea about the crate's edition, so format via rust-analyzer
(after! apheleia
  (dolist (mode '(rust-mode rustic-mode rust-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) '(lsp))))

(defvar-local my/c-clang-format-style
  "--style={BasedOnStyle: LLVM, BreakBeforeBraces: Allman}"
  "Style argument passed to clang-format; override per project via dir-locals.")

(after! apheleia
  (setf (alist-get 'clang-format apheleia-formatters)
        '("clang-format" "-assume-filename"
          (or (apheleia-formatters-local-buffer-file-name)
              (apheleia-formatters-mode-extension) ".c")
          my/c-clang-format-style)))

(after! lsp-mode
  ;; Stop the signature popup from showing automatically
  (setq lsp-signature-auto-activate nil)
  )

(use-package! topsy
  :defer t
  :init
  (add-hook! lsp-mode
    (unless (memq major-mode '(+doom-dashboard-mode org-mode dirvish-mode))
      (topsy-mode +1))))

(setq c-default-style "bsd"
      c-ts-mode-indent-style 'bsd)

(after! lsp-clangd
  (dolist (arg '("--query-driver=/usr/bin/arm-none-eabi-*"
                 "--header-insertion=never"))
    (cl-pushnew arg lsp-clients-clangd-args :test #'equal)))

(defvar my/openocd-command
  "openocd -f interface/stlink.cfg -f target/stm32f4x.cfg"
  "Shell command that starts OpenOCD for the current board.")

(defun my/openocd-ready-p ()
  "Return non-nil if OpenOCD listens for gdb on port 3333.
Uses ss instead of connecting, since OpenOCD takes only one gdb client."
  (with-temp-buffer
    (call-process "ss" nil t nil "-ltn" "sport = :3333")
    (> (count-lines (point-min) (point-max)) 1)))

(defun my/openocd-ensure ()
  "Start OpenOCD in a vterm buffer unless its gdb port is already up."
  (unless (my/openocd-ready-p)
    (let ((buf (get-buffer-create "*openocd*")))
      (unless (get-buffer-process buf)
        (with-current-buffer buf (vterm-mode)))
      (with-current-buffer buf
        (vterm-send-string my/openocd-command)
        (vterm-send-return))
      (display-buffer buf '(display-buffer-in-side-window (side . bottom) (window-height . 0.25)))
      (let ((tries 0))
        (while (and (< tries 100) (not (my/openocd-ready-p)))
          (sleep-for 0.2)
          (cl-incf tries)))
      (unless (my/openocd-ready-p)
        (user-error "OpenOCD did not open port 3333 in 20 s, check *openocd*")))))

(defun my/openocd-stop ()
  "Kill the *openocd* vterm buffer, which also stops OpenOCD."
  (when-let* ((buf (get-buffer "*openocd*")))
    (when-let* ((proc (get-buffer-process buf)))
      (set-process-query-on-exit-flag proc nil))
    (kill-buffer buf)))

(after! dape
  ;; dape has no quit hook, so run after its final cleanup (the call without skip-process-buffers).
  (advice-add 'dape--kill-buffers :after
              (lambda (&optional skip-process-buffers)
                (unless skip-process-buffers (my/openocd-stop))))

  ;; dape expects `compilation-find-buffer' to return the build buffer, but in a buffer with
  ;; flycheck/lsp it returns the current one. Switching to the build buffer fixes it.
  (setq dape-compile-function
        (lambda (cmd)
          (set-buffer (compile cmd)))))

(defun dape-stm32 (elf-path)
  "Start OpenOCD in vterm, build, then flash ELF-PATH over localhost:3333 and debug it with dape."
  (interactive
   (list (expand-file-name
          (read-file-name "Select .elf file: "
                          (concat (project-root (project-current t)) "build/")))))

  (require 'dape)
  (require 'vterm)
  (my/openocd-ensure)
  (dape `(command ,(expand-file-name "debug-adapters/cpptools-debug/bin/OpenDebugAD7" doom-emacs-dir)
          command-cwd ,(project-root (project-current t))
          compile "make -j8"
          :type "cppdbg"
          :request "launch"
          :cwd ,(project-root (project-current t))
          :program ,elf-path
          :MIMode "gdb"
          :externalConsole :json-false
          :miDebuggerPath ,(executable-find "arm-none-eabi-gdb")
          :setupCommands [(:text "target extended-remote localhost:3333" :ignoreFailures nil)
                          (:text "monitor reset halt" :ignoreFailures nil)
                          (:text ,(concat "file " elf-path) :ignoreFailures nil)
                          (:text "load" :ignoreFailures nil)])))

(custom-set-faces!
  '(org-level-1 :inherit outline-1 :height 1.4)
  '(org-level-2 :inherit outline-2 :height 1.3)
  '(org-level-3 :inherit outline-3 :height 1.2)
  '(org-level-4 :inherit outline-4 :height 1.1)
  '(org-document-title :height 1.75 :weight bold))

(defun my/org-file (name)
  "Absolute path of NAME inside `org-directory'."
  (expand-file-name name org-directory))

(setq org-agenda-custom-commands
      '(("v" "Improved view"
         ((tags "*"
                ((org-agenda-files (list (my/org-file "this_week.org")))
                 (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                 (org-agenda-prefix-format "")
                 (org-agenda-overriding-header "--- IMPORTANT ---")))
          (agenda ""
                  ((org-agenda-span 30)       ;
                   (org-agenda-show-all-dates nil)
                   (org-agenda-overriding-header "Scheduled Stuff")))
          (tags "*"
                ((org-agenda-files (list (my/org-file "exams.org")))
                 (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                 (org-agenda-overriding-header "--- EXAMS ---")))
          (tags "*"
                ((org-agenda-files (list (my/org-file "uni.org")))
                 (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                 (org-agenda-overriding-header "--- UNI ---")))))

        ("p" "Personal todos"
         ((tags-todo "*"
                     ((org-agenda-files (list (my/org-file "personal.org")))
                      (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                      (org-agenda-prefix-format "")
                      (org-agenda-overriding-header "--- PERSONAL ---")))
          (tags-todo "*"
                     ((org-agenda-files (list (my/org-file "this_week.org")))
                      (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                      (org-agenda-prefix-format "")
                      (org-agenda-overriding-header "--- THIS WEEK ---")))
          (tags-todo "*"
                     ((org-agenda-files (list (my/org-file "projects.org")))
                      (org-agenda-sorting-strategy '(timestamp-up alpha-up))
                      (org-agenda-prefix-format "%-12:c ")
                      (org-agenda-overriding-header "--- PROJECTS ---")))))))

(defun my/open-custom-agenda ()
  "Open the custom \"v\" agenda view (important, scheduled, exams, uni)."
  (interactive)
  (org-agenda nil "v")
  )
(defun my/open-personal-todos ()
  "Open the custom \"p\" agenda view (personal, this week, projects todos)."
  (interactive)
  (org-agenda nil "p")
  )
(map!
 :n "M-m" #'my/open-custom-agenda
 :leader "np" #'my/open-personal-todos)

(after! org
  (add-to-list 'org-capture-templates
               '("c" "Code TODO" entry
                 (file+headline +org-capture-todo-file "Inbox")
                 "* TODO %?\nFrom: %a\n\n#+BEGIN_SRC %(with-current-buffer (org-capture-get :original-buffer) (replace-regexp-in-string \"-ts-mode$\\|-mode$\" \"\" (symbol-name major-mode)))\n%i\n#+END_SRC\n"
                 :prepend t
                 :kill-buffer t)))

(use-package! org-roam
  :custom
  (org-roam-node-display-template
   (concat "${title:*} " (propertize "${tags:20}" 'face 'shadow)
           " ${backlinkscount:3}"))
  :config
  (cl-defmethod org-roam-node-backlinkscount ((node org-roam-node))
    (number-to-string (length (org-roam-backlinks-get node))))
  (setq org-roam-capture-templates
        '(("d" "default" plain
           "%?\n\n* References\n- "
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n\nTagi: \n\n")
           :unnarrowed t)
          ("l" "literature" plain
           "* Źródło
- Autor: %^{Autor}
- Typ: %^{Typ|książka|artykuł|wideo|kurs|dokumentacja}
- Gdzie: %^{Link / strony}

* Główne tezy
%?

* Cytaty
-

* Moje uwagi
-

* Notatki z tego źródła
- "
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+filetags: :literature:\n\nTagi: \n\n")
           :unnarrowed t))))

(use-package! org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package! pdf-tools
  :config
  (add-to-list 'revert-without-query ".pdf")
  (map! :map pdf-view-mode-map
        :n "j"   #'pdf-view-next-line-or-next-page
        :n "k"   #'pdf-view-previous-line-or-previous-page
        :n "C-=" #'pdf-view-enlarge
        :n "C-c C-g" #'pdf-view-goto-page
        :n "C--" #'pdf-view-shrink))
(add-hook 'pdf-view-mode-hook #'(lambda () (interactive) (display-line-numbers-mode -1)
                                  (blink-cursor-mode -1)))

(use-package! saveplace-pdf-view
  :after (:any doc-view pdf-tools)
  :demand t)

(defun my/browse-books ()
  "Find a file in the ~/calibre-books library."
  (interactive)
  (doom-project-find-file "~/calibre-books")
  )

(custom-set-faces!
  '(markdown-header-delimiter-face :foreground "#616161" :height 0.9)
  '(markdown-header-face-1 :height 1.8 :foreground "#A3BE8C" :weight extra-bold :inherit markdown-header-face)
  '(markdown-header-face-2 :height 1.4 :foreground "#EBCB8B" :weight extra-bold :inherit markdown-header-face)
  '(markdown-header-face-3 :height 1.2 :foreground "#D08770" :weight extra-bold :inherit markdown-header-face)
  '(markdown-header-face-4 :height 1.15 :foreground "#BF616A" :weight bold :inherit markdown-header-face)
  '(markdown-header-face-5 :height 1.1 :foreground "#b48ead" :weight bold :inherit markdown-header-face)
  '(markdown-header-face-6 :height 1.05 :foreground "#5e81ac" :weight semi-bold :inherit markdown-header-face))

(defvar my/current-line '(0 . 0)
  "(START . END) of the line point is on, used to reveal its hidden markup.")
(make-variable-buffer-local 'my/current-line)

(defun my/unhide-current-line (limit)
  "Font-lock matcher that removes markdown concealment on the current line up to LIMIT."
  (let ((start (max (point) (car my/current-line)))
        (end (min limit (cdr my/current-line))))
    (when (< start end)
      (remove-text-properties start end
                              '(invisible t display "" composition ""))
      (goto-char limit)
      t)))

(defun my/refontify-on-linemove ()
  "Refontify around point whenever it moves to another line.\nMeant for `post-command-hook'."
  (let* ((start (line-beginning-position))
         (end (line-beginning-position 2))
         (needs-update (not (equal start (car my/current-line)))))
    (setq my/current-line (cons start end))
    (when needs-update
      (font-lock-fontify-block 3))))

(defun my/markdown-unhighlight ()
  "Hide markdown markup, revealing it only on the line point is on."
  (interactive)
  (markdown-toggle-markup-hiding 'toggle)
  (font-lock-add-keywords nil '((my/unhide-current-line)) t)
  (add-hook 'post-command-hook #'my/refontify-on-linemove nil t))
(add-hook 'markdown-mode-hook #'my/markdown-unhighlight)

(use-package! headerize)

(use-package! rsc
  :commands (rsc-ask rsc-ask-terminal rsc-switch)
  :config
  (map! :map rsc-answer-mode-map :nm "q" #'quit-window))

(map!
 (:prefix ("M-a" . "rsc")
  :desc "Ask rsc" "M-a" #'rsc-ask
  :desc "Ask rsc (terminal)" "t" #'rsc-ask-terminal
  :desc "Switch to rsc" "s" #'rsc-switch))
