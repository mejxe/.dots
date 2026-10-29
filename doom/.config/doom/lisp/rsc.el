;;; rsc.el --- Pytania do rsc (Claude Code) z Emacsa  -*- lexical-binding: t; -*-

;;; Commentary:
;; Wysyła pytanie (opcjonalnie z regionem lub całym buforem) do sesji `rsc'
;; działającej w vterm.  Sesję uruchamia w katalogu bieżącego projektu.

;;; Code:

(require 'vterm)
(require 'project)
(require 'markdown-mode)

(defgroup rsc nil "Integracja z rsc." :group 'tools)

(defcustom rsc-buffer-name "*rsc*"
  "Nazwa bufora vterm z sesją rsc."
  :type 'string)

(defcustom rsc-command "rsc"
  "Polecenie uruchamiające rsc."
  :type 'string)

(defcustom rsc-startup-delay 2
  "Sekundy oczekiwania na start rsc, zanim wyślemy pytanie."
  :type 'number)

(defcustom rsc-max-context-chars 40000
  "Powyżej tej liczby znaków kontekstu funkcja pyta o potwierdzenie."
  :type 'integer)

(defcustom rsc-answer-buffer-name "*rsc-answer*"
  "Nazwa bufora z odpowiedzią na pytanie zadane przez `rsc-ask'."
  :type 'string)

(defvar rsc-history nil)

(define-derived-mode rsc-answer-mode markdown-mode "rsc-answer"
  "Odpowiedź `rsc-ask': markdown, tylko do odczytu, `q' zamyka okno."
  (setq buffer-read-only t))

(define-key rsc-answer-mode-map (kbd "q") #'quit-window)

(defun rsc--project-dir ()
  "Katalog projektu bieżącego bufora albo `default-directory'."
  (if-let* ((p (project-current)))
      (project-root p)
    default-directory))

(defun rsc--live-buffer ()
  (let* ((buf (get-buffer rsc-buffer-name))
         (proc (and buf (get-buffer-process buf))))
    (and proc (process-live-p proc) buf)))

(defun rsc--ensure ()
  "Zwraca (BUFOR . ŚWIEŻY). Uruchamia rsc w katalogu projektu, jeśli sesji nie ma."
  (let ((buf (rsc--live-buffer)))
    (if buf
        (cons buf nil)
      (when (get-buffer rsc-buffer-name) (kill-buffer rsc-buffer-name))
      (let ((default-directory (rsc--project-dir)))
        (save-window-excursion (vterm rsc-buffer-name))
        (let ((new (get-buffer rsc-buffer-name)))
          (with-current-buffer new
            (vterm-send-string rsc-command)
            (vterm-send-return))
          (cons new t))))))

(defun rsc--context (whole)
  "Zwraca plist z kontekstem: całość bufora (WHOLE), aktywny region albo nil."
  (let* ((region (and (not whole) (use-region-p)))
         (beg (cond (whole (point-min)) (region (region-beginning))))
         (end (cond (whole (point-max)) (region (region-end)))))
    (when beg
      (list :text (buffer-substring-no-properties beg end)
            :file (or buffer-file-name (buffer-name))
            :from (line-number-at-pos beg)
            :to (line-number-at-pos
                 (if (and (> end beg) (eq (char-before end) ?\n)) (1- end) end))
            :lang (string-remove-suffix "-mode" (symbol-name major-mode))))))

(defun rsc--format (question ctx)
  (if (null ctx)
      question
    (format "%s\n\nKontekst: %s, linie %d-%d:\n```%s\n%s\n```"
            question
            (plist-get ctx :file) (plist-get ctx :from) (plist-get ctx :to)
            (plist-get ctx :lang)
            (string-trim-right (plist-get ctx :text)))))

(defun rsc--send (buf msg)
  "Wkleja MSG do sesji rsc jako jeden blok (bracketed paste) i zatwierdza Enterem."
  (with-current-buffer buf
    (vterm-send-string msg t)
    (run-with-timer 0.3 nil
                    (lambda (b) (when (buffer-live-p b)
                                  (with-current-buffer b (vterm-send-return))))
                    buf)))

(defun rsc--check-size (ctx)
  "Zapytaj o potwierdzenie, gdy kontekst CTX przekracza `rsc-max-context-chars'."
  (when (and ctx
             (> (length (plist-get ctx :text)) rsc-max-context-chars)
             (not (yes-or-no-p
                   (format "Kontekst ma %d znaków. Wysłać mimo to? "
                           (length (plist-get ctx :text))))))
    (user-error "Anulowano")))

(defun rsc--oneshot-sentinel (proc _event)
  "Dopisz informację o zakończeniu pytania zadanego przez `rsc-ask'."
  (when (memq (process-status proc) '(exit signal))
    (let ((buf (process-buffer proc)))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (goto-char (point-max))
            (insert (format "\n\n---\n[koniec, kod wyjścia %d]\n"
                            (process-exit-status proc))))))
      (message "rsc: odpowiedź gotowa"))))

;;;###autoload
(defun rsc-ask (question &optional whole-buffer)
  "Zadaj QUESTION jednorazowo przez `rsc -p'; odpowiedź trafia do osobnego bufora.
Bez prefiksu: z regionem, jeśli jest aktywny, inaczej samo pytanie.
Z prefiksem (C-u): z całym buforem.  Treść idzie do rsc przez stdin.
W tym trybie nie da się zatwierdzać edycji ani poleceń git (rsc je odrzuci)."
  (interactive (list (read-string "rsc> " nil 'rsc-history) current-prefix-arg))
  (let* ((ctx (rsc--context whole-buffer))
         (msg (rsc--format question ctx))
         (buf (get-buffer-create rsc-answer-buffer-name))
         (old (get-buffer-process buf)))
    (rsc--check-size ctx)
    (when old
      (unless (y-or-n-p "Poprzednie pytanie jeszcze trwa. Przerwać i zadać nowe? ")
        (user-error "Anulowano"))
      (set-process-sentinel old #'ignore)
      (delete-process old))
    (with-current-buffer buf
      (rsc-answer-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "## Pytanie\n\n" question "\n\n## Odpowiedź\n\n")))
    (let* ((default-directory (rsc--project-dir))
           (proc (make-process :name "rsc" :buffer buf
                               :command (list rsc-command "-p")
                               :connection-type 'pipe
                               :sentinel #'rsc--oneshot-sentinel)))
      (process-send-string proc msg)
      (process-send-eof proc))
    (display-buffer buf)
    (deactivate-mark)
    (message "rsc: pytam...")))

;;;###autoload
(defun rsc-ask-terminal (question &optional whole-buffer)
  "Wyślij QUESTION do interaktywnej sesji rsc w vterm.
Bez prefiksu: z regionem, jeśli jest aktywny, inaczej samo pytanie.
Z prefiksem (C-u): z całym buforem."
  (interactive (list (read-string "rsc> " nil 'rsc-history) current-prefix-arg))
  (let* ((ctx (rsc--context whole-buffer))
         (msg (rsc--format question ctx)))
    (rsc--check-size ctx)
    (let* ((res (rsc--ensure))
           (buf (car res)))
      (display-buffer buf)
      (deactivate-mark)
      (if (cdr res)
          (progn
            (message "rsc startuje, pytanie poleci za %ss..." rsc-startup-delay)
            (run-with-timer rsc-startup-delay nil #'rsc--send buf msg))
        (rsc--send buf msg)))))

;;;###autoload
(defun rsc-switch ()
  "Przejdź do bufora rsc (uruchom, jeśli nie działa)."
  (interactive)
  (pop-to-buffer (car (rsc--ensure))))

(provide 'rsc)
;;; rsc.el ends here
