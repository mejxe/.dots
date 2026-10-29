;;; headerize.el --- Turn a source file into a header file, or sync an existing one  -*- lexical-binding: t; -*-

;;; Commentary:

;; `my/headerize' generates foo.h from foo.c.  When foo.h already exists it is
;; synced instead of overwritten: prototypes and extern declarations missing
;; from it are appended, changed ones are rewritten in place, and everything
;; else (types, macros, includes, comments) is left alone.  Declarations that
;; the header has but the source does not are only reported, since they may be
;; implemented in another file.

;;; Code:
(require 'cl-lib)
(require 'subr-x)
(require 'treesit)

(defconst my/headerize--conditional-types
  '("preproc_if" "preproc_ifdef" "preproc_else" "preproc_elif" "preproc_elifdef")
  "Tree-sitter node types of preprocessor conditionals.")

;;
;;; Generating a header body from C source

(defun my/headerize--storage-p (node storage)
  "Non-nil if NODE has the STORAGE class specifier (e.g. \"static\")."
  (cl-some (lambda (c)
             (and (equal (treesit-node-type c) "storage_class_specifier")
                  (equal (treesit-node-text c) storage)))
           (treesit-node-children node)))

(defun my/headerize--function-declarator-p (decl)
  "Non-nil if declarator DECL declares a function (possibly returning a pointer)."
  (while (and decl (member (treesit-node-type decl)
                           '("pointer_declarator" "parenthesized_declarator")))
    (setq decl (or (treesit-node-child-by-field-name decl "declarator")
                   (treesit-node-child decl 0 t))))
  (equal (treesit-node-type decl) "function_declarator"))

(defun my/headerize--edits (node header-name)
  "Return edits (START END REPLACEMENT) turning NODE's children into header content.
HEADER-NAME is the file name of the header being generated."
  (let (edits)
    (dolist (child (treesit-node-children node t))
      (let ((type (treesit-node-type child))
            (start (treesit-node-start child))
            (end (treesit-node-end child)))
        (cond
         ;; #include "self.h"
         ((equal type "preproc_include")
          (when (equal (file-name-nondirectory
                        (string-trim (treesit-node-text
                                      (treesit-node-child-by-field-name child "path"))
                                     "[\"<]" "[\">]"))
                       header-name)
            (push (list start end "") edits)))
         ;; #if/#ifdef/#else...: look inside
         ((member type my/headerize--conditional-types)
          (setq edits (nconc (my/headerize--edits child header-name) edits)))
         ;; functions: prototype, or nothing when static
         ((equal type "function_definition")
          (if (my/headerize--storage-p child "static")
              (push (list start end "") edits)
            (push (list (treesit-node-end
                         (treesit-node-child-by-field-name child "declarator"))
                        end ";")
                  edits)))
         ;; globals: extern declaration, or nothing when static
         ((equal type "declaration")
          (let ((decl (treesit-node-child-by-field-name child "declarator")))
            (cond
             ((my/headerize--storage-p child "static")
              (push (list start end "") edits))
             ((or (null decl) (my/headerize--function-declarator-p decl)
                  (my/headerize--storage-p child "extern"))
              nil)  ; type definitions, prototypes, existing externs stay as is
             ((equal (treesit-node-type decl) "init_declarator")
              (let ((d (treesit-node-child-by-field-name decl "declarator")))
                (push (list (treesit-node-end d) end ";") edits)
                (push (list start start "extern ") edits)))
             (t (push (list start start "extern ") edits))))))))
    edits))

(defun my/headerize--drop-orphan-comments (node edits)
  "Extend deletions in EDITS to the comment directly above them in NODE."
  (let ((children (treesit-node-children node t)))
    (cl-loop for (prev next) on children
             when (and next (equal (treesit-node-type prev) "comment")
                       (<= (- (line-number-at-pos (treesit-node-start next))
                              (line-number-at-pos (treesit-node-end prev)))
                           1)
                       (cl-find-if (lambda (e) (and (= (nth 0 e) (treesit-node-start next))
                                                    (string-empty-p (nth 2 e))))
                                   edits))
             do (push (list (treesit-node-start prev) (treesit-node-end prev) "") edits))
    edits))

(defun my/headerize--apply-edits (edits)
  "Apply EDITS, a list of (START END REPLACEMENT), to the current buffer.
They are applied back to front so earlier positions stay valid."
  (atomic-change-group
    (dolist (e (sort (copy-sequence edits)
                     (lambda (a b) (or (> (car a) (car b))
                                       (and (= (car a) (car b)) (> (cadr a) (cadr b)))))))
      (goto-char (nth 0 e))
      (delete-region (nth 0 e) (nth 1 e))
      (insert (nth 2 e)))))

(defun my/headerize--transform (source header-name)
  "Return the body of a header generated from C SOURCE text."
  (with-temp-buffer
    (insert source)
    (treesit-parser-create 'c)
    (let* ((root (treesit-buffer-root-node 'c))
           (edits (my/headerize--drop-orphan-comments
                   root (my/headerize--edits root header-name))))
      (my/headerize--apply-edits edits)
      (goto-char (point-min))
      (while (re-search-forward "\n\\{3,\\}" nil t) (replace-match "\n\n"))
      (string-trim (buffer-string)))))

;;
;;; Syncing an existing header

(defun my/headerize--decl-name (declarator)
  "Return the identifier declared by DECLARATOR."
  (let ((n declarator))
    (while (and n (not (member (treesit-node-type n) '("identifier" "field_identifier"))))
      (setq n (or (treesit-node-child-by-field-name n "declarator")
                  (treesit-node-child n 0 t))))
    (and n (treesit-node-text n))))

(defun my/headerize--make-decl (node prev conds)
  "Describe declaration NODE as a plist.
PREV is the preceding sibling, kept as doc comment when it hugs NODE.
CONDS are the enclosing preprocessor conditionals, innermost first."
  (let* ((text (treesit-node-text node))
         (comment (and prev
                       (equal (treesit-node-type prev) "comment")
                       (<= (- (line-number-at-pos (treesit-node-start node))
                              (line-number-at-pos (treesit-node-end prev)))
                           1)
                       (treesit-node-text prev))))
    (list :name (my/headerize--decl-name
                 (treesit-node-child-by-field-name node "declarator"))
          :text text
          :norm (string-join (split-string text) " ")
          :start (treesit-node-start node)
          :end (treesit-node-end node)
          :comment comment
          ;; only plain #if/#ifdef branches can be re-created around a new
          ;; declaration, #else/#elif branches need a human
          :manual (cl-some (lambda (c)
                             (not (member (treesit-node-type c) '("preproc_if" "preproc_ifdef"))))
                           conds)
          :wrap (mapcar (lambda (c) (car (split-string (treesit-node-text c) "\n")))
                        (reverse conds)))))

(defun my/headerize--collect (source)
  "Return the prototypes and extern declarations in C SOURCE, as plists.
Looks inside preprocessor conditionals, so it works on header guards too."
  (with-temp-buffer
    (insert source)
    (treesit-parser-create 'c)
    (let (result)
      (cl-labels
          ((walk (node conds)
             (let (prev)
               (dolist (child (treesit-node-children node t))
                 (let ((type (treesit-node-type child)))
                   (cond
                    ((member type my/headerize--conditional-types)
                     (walk child (cons child conds)))
                    ((equal type "declaration")
                     (let ((decl (treesit-node-child-by-field-name child "declarator")))
                       (when (and decl
                                  (or (my/headerize--function-declarator-p decl)
                                      (my/headerize--storage-p child "extern")))
                         (push (my/headerize--make-decl child prev conds) result))))))
                 (setq prev child)))))
        (walk (treesit-buffer-root-node 'c) nil))
      (nreverse result))))

(defun my/headerize--insertion-point (text)
  "Return the buffer position in header TEXT where new declarations should go.
That is just before the closing #endif of the include guard, else the end."
  (with-temp-buffer
    (insert text)
    (treesit-parser-create 'c)
    (let* ((nodes (cl-remove "comment" (treesit-node-children (treesit-buffer-root-node 'c) t)
                             :key #'treesit-node-type :test #'equal))
           (last-node (car (last nodes)))
           (endif (and last-node
                       (member (treesit-node-type last-node) '("preproc_if" "preproc_ifdef"))
                       (treesit-node-child last-node -1))))
      (if (and endif (equal (treesit-node-text endif) "#endif"))
          (treesit-node-start endif)
        (point-max)))))

(defun my/headerize--decl-block (decl)
  "Return the text to append to a header for the new declaration DECL."
  (let ((body (concat (and (plist-get decl :comment) (concat (plist-get decl :comment) "\n"))
                      (plist-get decl :text)))
        (wrap (plist-get decl :wrap)))
    (if wrap
        (concat (string-join wrap "\n") "\n" body "\n"
                (string-join (make-list (length wrap) "#endif") "\n"))
      body)))

(defun my/headerize--sync (header-text new-body)
  "Compare declarations of HEADER-TEXT with those of the generated NEW-BODY.
Return (EDITS ADDED CHANGED MISSING MANUAL): EDITS to apply to HEADER-TEXT, and
lists of names that were added, rewritten, only in the header, or that could
not be placed automatically."
  (let ((old-by-name (make-hash-table :test #'equal))
        (seen (make-hash-table :test #'equal))
        (old (my/headerize--collect header-text))
        edits added changed missing manual blocks)
    (dolist (o old)
      (unless (gethash (plist-get o :name) old-by-name)
        (puthash (plist-get o :name) o old-by-name)))
    (dolist (n (my/headerize--collect new-body))
      (let* ((name (plist-get n :name))
             (o (gethash name old-by-name)))
        (unless (gethash name seen)
          (puthash name t seen)
          (cond
           (o (unless (equal (plist-get o :norm) (plist-get n :norm))
                (push (list (plist-get o :start) (plist-get o :end) (plist-get n :text)) edits)
                (push name changed)))
           ((plist-get n :manual) (push name manual))
           (t (push (my/headerize--decl-block n) blocks)
              (push name added))))))
    (dolist (o old)
      (unless (gethash (plist-get o :name) seen)
        (push (plist-get o :name) missing)))
    (when blocks
      (let ((pos (my/headerize--insertion-point header-text)))
        (push (list pos pos
                    (concat (if (string-suffix-p "\n\n" (substring header-text 0 (1- pos))) "" "\n")
                            (string-join (nreverse blocks) "\n\n")
                            "\n\n"))
              edits)))
    (list edits (nreverse added) (nreverse changed) (nreverse missing) (nreverse manual))))

(defun my/headerize--sync-buffer (header body)
  "Open HEADER and sync it with the generated header BODY, leaving it unsaved."
  (find-file header)
  (save-restriction
    (widen)
    (pcase-let* ((text (buffer-substring-no-properties (point-min) (point-max)))
                 (`(,edits ,added ,changed ,missing ,manual) (my/headerize--sync text body)))
      (when edits
        (save-excursion (my/headerize--apply-edits edits)))
      (message "headerize: %s"
               (if (not (or added changed missing manual))
                   (format "%s is up to date" (file-name-nondirectory header))
                 (string-join
                  (delq nil
                        (list (and added (format "added %s" (string-join added ", ")))
                              (and changed (format "updated %s" (string-join changed ", ")))
                              (and missing (format "only in header (left alone): %s"
                                                   (string-join missing ", ")))
                              (and manual (format "needs manual placement (#else/#elif): %s"
                                                  (string-join manual ", ")))))
                  "; "))))))

;;
;;; Command

(defun my/headerize--source (c-file)
  "Return the text of C-FILE, from its buffer when it is being visited."
  (if-let* ((buf (find-buffer-visiting c-file)))
      (with-current-buffer buf
        (save-restriction (widen) (buffer-substring-no-properties (point-min) (point-max))))
    (with-temp-buffer (insert-file-contents c-file) (buffer-string))))

(defun my/headerize (c-file &optional regenerate)
  "Generate the header for C-FILE, or sync it when it already exists.
The header is opened unsaved.  Includes, macros, typedefs, structs and enums
are kept; function definitions become prototypes, globals become `extern'
declarations and static items are dropped.  An existing header only gets the
missing or changed prototypes and externs.  With a prefix argument REGENERATE,
overwrite an existing header instead."
  (interactive
   (list (read-file-name "Select .c file to headerize: " nil
                         (and buffer-file-name
                              (string-suffix-p ".c" buffer-file-name)
                              buffer-file-name)
                         t)
         current-prefix-arg))
  (setq c-file (expand-file-name c-file))
  (unless (string-suffix-p ".c" c-file)
    (user-error "Aborted: selected file must end with .c"))
  (let* ((header (concat (file-name-sans-extension c-file) ".h"))
         (guard (concat (upcase (replace-regexp-in-string
                                 "[^[:alnum:]]" "_"
                                 (file-name-base c-file)))
                        "_H"))
         (body (my/headerize--transform (my/headerize--source c-file)
                                        (file-name-nondirectory header))))
    (if (and (file-exists-p header) (not regenerate))
        (my/headerize--sync-buffer header body)
      (when (and (file-exists-p header)
                 (not (y-or-n-p (format "%s exists, overwrite? " (file-name-nondirectory header)))))
        (user-error "Aborted"))
      (find-file header)
      (erase-buffer)
      (insert (format "#ifndef %s\n#define %s\n\n%s\n\n#endif /* %s */\n"
                      guard guard body guard))
      (goto-char (point-min)))))

(provide 'headerize)
;;; headerize.el ends here
