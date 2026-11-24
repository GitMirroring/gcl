;; Copyright  William F. Schelter.   1994
;; Licensed by GNU public license.

;; You should copy isp-complete.el to the emacs/lisp directory.

;; Some commands and macros for dealing with lisp
;; M-X run : run gcl or another lisp
;; m-c-x ; evaluate defun in the other window or in the last lisp which you were using.
;; m-c-x ; with a numeric arg : compile the current defun in the other window
;; m-c-d ; disassemble in other window.
;; M-x macroexpand-next : macro expand the next sexp in other window.
;; C-h d Find documentation on symbol where the cursor is.
;; C-h / Find documentation on all strings containing a given string.
;; M-p complete the current input by looking back through the buffer to see what was last typed
;;        using this prompt and this beginning.   Useful in shell, in lisp, in gdb,...


(require 'shell)
(require 'gud)
(require 'gdb-mi)
(require 'cl-lib)
(require 'inf-lisp)

(defgroup gcl nil
  "Customization group for GNU Common Lisp (GCL) development environment."
  :group 'lisp
  :prefix "gcl-")

(defcustom gcl-dirs nil
  "List of directories searched to locate the GCL executable files.
Each directory string should include the trailing slash."
  :type '(repeat directory)
  :group 'gcl)

;;;###autoload
(define-derived-mode gcl-mode lisp-mode "GCL Source"
  "Major mode for editing GNU Common Lisp source files."
  (setq-local lisp-package nil)
  (setq-local lisp-mode-hook nil)

  (local-set-key (kbd "C-M-x")   'gcl-eval-defun)
  (local-set-key (kbd "C-c C-r") 'gcl-eval-region)
  (local-set-key (kbd "C-c C-l") 'gcl-load-file)
  (local-set-key (kbd "C-c C-b") 'gcl-break))

(defun gcl-make-overlay-mode-map nil
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "SPC") 'gcl-step)  ; Space bar steps into forms
    (define-key map (kbd "n")   'gcl-next)  ; 'n' skips functions
    (define-key map (kbd "e")   'lisp-eval-last-sexp)
    (define-key map (kbd "v")   'gcl-env)
    (define-key map (kbd "m")   'gcl-form)
    (define-key map (kbd "f")   'gcl-finish)
    (define-key map (kbd "c")   'gcl-r)
    (define-key map (kbd "t")   'gcl-bt)
    (define-key map (kbd "l")   'gcl-bl)
    (define-key map (kbd "u")   'gcl-up)
    (define-key map (kbd "d")   'gcl-down)
    (define-key map (kbd "r")   'gcl-refresh-layout)
    (define-key map (kbd "q")   'gcl-source-overlay-mode-quit) ; Turn off overlays
    map))

(defvar gcl-source-overlay-mode-map
  (gcl-make-overlay-mode-map)
  "Keymap active when the GCL debugger has focus inside a source buffer file.")

(define-minor-mode gcl-source-overlay-mode
  "Minor mode overlaying single-stroke GCL debugging keys in source buffers."
  :init-value nil
  :lighter " GCL-Debug"
  :keymap gcl-source-overlay-mode-map
  (read-only-mode (if gcl-source-overlay-mode 1 -1)))

;; Local functions

(defun gcl-substitute-% (command n)
  (let* (result	(file-line (gcl-find-line)))
    (while (and command (string-match "\\([^%]*\\)%\\([adeflp]\\)" command))
      (setq result (concat result
			   (substring command (match-beginning 1) (match-end 1))
			   (cl-case (string-to-char (substring command (match-beginning 2)))
				 (?p (if n (int-to-string n) ""))
				 (?f (or (car file-line) "unknown-file"))
				 (?l (if (cadr file-line) (int-to-string (cadr file-line)) "unknown-line")))))
      (setq command (substring command (match-end 2))))
    (concat result command)))

(defun gcl-call (command &optional numeric)
  "Invoke gcl COMMAND displaying source in inferior-lisp-buffer."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (process-send-string (get-buffer-process inferior-lisp-buffer)
			 (concat (gcl-substitute-% command numeric) "\n"))))

(defmacro def-gcl (name &optional doc def)
  (let ((fun (intern (format "gcl-%s" (cadr (split-string (car (split-string name " ")) ":")))))
	(argp (string-match-p "%" name)))
    `(defun ,fun (,@(when argp `(&optional arg)))
       ,(or doc "")
       (interactive ,@(when argp `("P")))
       (apply 'gcl-call ,name
	      ,(when argp
		  `(when (or arg ,def)
		      (list (if arg (prefix-numeric-value arg) ,def))))))))

(def-gcl ":finish %p" "Finish current function")
(def-gcl ":next %p"   "Step one source line (skip functions)")
(def-gcl ":step %p"   "Step one source line with display")
(def-gcl ":up %p"     "Step one source line with display")
(def-gcl ":down %p"   "Step one source line with display")
(def-gcl ":bt %p"     "Stack trace")
(def-gcl ":bl"        "Locals")
(def-gcl ":r"         "Continue")
(def-gcl ":env"       "Environment")
(def-gcl ":form %p"   "Invoking form for frame")
(def-gcl ":q"         "Quit")

(defun gcl-get-buffer-package ()
  "Returns what it thinks is the lisp package for the current buffer.
It caches this information in the local variable `lisp-package'.  It
obtains the information from searching for the first in-package from
the beginning of the file.  Since in common lisp, there is only
supposed to be one such statement, it should be able to determine
this.  By setting lisp-package to t, you may disable its search.  This
will also disable the automatic inclusion of an in-package statement
in the tmp-lisp-file, used for sending forms to the current
lisp-process."

  (cond ((eq lisp-package t) nil)
	((save-excursion
	   (cond ((re-search-backward "^[ \t]*(in-package "  nil t)
		  (goto-char (match-end 0))
		  (setq lisp-package (read (current-buffer)))))))
	(lisp-package lisp-package)))


(defun gcl-get-buffer-clear (name)
  (let ((cb (current-buffer))
	(buf (get-buffer-create name)))
    (set-buffer buf)
    (erase-buffer)
    (set-buffer cb)
    buf))

(defun gcl-my-send-region (proc beg end &optional arg)
  (if (string-match "telnet" (process-name proc))
      (send-region proc beg end)
    (let* ((package (gcl-get-buffer-package))
	   (src-buf (current-buffer))
	   (src-name (let ((na (buffer-file-name src-buf)))
                       (if na (expand-file-name na) (buffer-name src-buf))))
	   (src-line (- (count-lines (point-min) (+ beg 5)) 1))
	   (tmp-file (make-temp-file "gcl-" nil ".lsp")))
      (with-current-buffer (gcl-get-buffer-clear "*tmp-gcl*")
	(when package
	  (unless (eq package t)
	    (prin1 (list 'in-package package) (current-buffer))))
	(insert (format ";!(:line %S %d)\n" src-name src-line))
	(insert-buffer-substring src-buf beg end)
	(insert "\n")
	(write-region (point-min) (point-max) tmp-file nil 'nomsg))
      (message "sending ..")
      (let ((str (concat "(lisp::let ((*load-verbose* nil)) ("
			 (if arg "#+sdebug si::nload #-sdebug " "")
			 "load \""
			 tmp-file
			 "\")(values))\n  ")))
	(process-send-string proc str))
      (message (format "PACKAGE: %s ..done" (if (unless (eq package t) package) package "none"))))))

(defun gcl-eval-defun (&optional arg &aux proc)
  "Evaluate the current top-level form.
Plain execution evaluates the form natively.
Passing a universal prefix argument (C-u) routes execution through
`si::nload' to arm the line-tracking debugger."
  (interactive "P")
  (if (when (and (boundp 'inferior-lisp-buffer) inferior-lisp-buffer)
	  (setq proc (get-buffer-process inferior-lisp-buffer))
	  (and proc (eq (process-status proc) 'run)))
      (let ((beg (save-excursion (beginning-of-defun) (point)))
            (end (save-excursion (end-of-defun) (point))))
        (gcl-my-send-region proc beg end arg))
    (message "No active GCL process available for evaluation.")))

(defun gcl-eval-region (start end &optional arg &aux proc)
  "Evaluate the current region.
Plain execution evaluates the form natively.
Passing a universal prefix argument (C-u) routes execution through
`si::nload' to arm the line-tracking debugger."
 (interactive "r\nP")
  (if (when (and (boundp 'inferior-lisp-buffer) inferior-lisp-buffer)
	  (setq proc (get-buffer-process inferior-lisp-buffer))
	  (and proc (eq (process-status proc) 'run)))
      (gcl-my-send-region proc start end arg)
    (message "No active GCL process available for evaluation.")))

(defun gcl-load-file (file &optional instrument)
  "Load Lisp FILE into the active inferior Lisp process.
Plain execution (C-c C-l) loads the file normally.
Passing a universal prefix argument (C-u C-c C-l) overrides the load string
dynamically to channel the entire file through `si::nload' for line-tracking."
  (interactive
   (list (let ((def (buffer-file-name)))
	   (read-file-name (format "Load Lisp file (%s): " def) nil def t))
         current-prefix-arg))

  (let ((inferior-lisp-load-command
         (if instrument
             "(let ((*load-verbose* nil)) (#+sdebug si::nload #-sdebug load \"%s\")(values))\n"
           "(load \"%s\")\n")))

    (message (if instrument
                 "GCL: Loading file with line-tracking enabled..."
               "GCL: Loading file normally..."))
    (save-window-excursion
      (lisp-load-file file))))

(defun gcl-refresh-layout ()
  "Restore the modern GDB multi-window layout frame layout if distorted."
  (interactive)
  (let ((buffer (current-buffer)))
    (with-current-buffer inferior-lisp-buffer
      (when gcl-gdb-p
	  (gdb-restore-windows)
	  (let ((sw (cl-find-if (lambda (x)
				  (string-match-p "main\\.c" (buffer-name (window-buffer x))))
				(window-list))))
	    (when sw
	      (with-selected-window sw
		(switch-to-buffer (buffer-name buffer) nil t))))
	  (setq gcl-last-frame-displayed-p nil))
      (gcl-display-frame))))

(defun gcl-break nil
  "Set GCL breakpoint at this source line."
  (interactive)
  (save-excursion
    (end-of-line)
    (let (name at (where (point)))
      (beginning-of-defun)
      (search-forward "(def")
      (forward-sexp 2)
      (setq at (point))
      (forward-sexp -1)
      (setq name (buffer-substring (point) at))
      (beginning-of-line)
      (let ((name (format "(si::break-function '%s %s t)"  name (count-lines 1 where))))
	(message "%s" name)
	(process-send-string (get-buffer-process inferior-lisp-buffer) (concat name "\n"))))))

(defun gcl-source-overlay-mode-quit ()
  "Safely drop out of the read-only debugger map back to active editing."
  (interactive)
  (gcl-source-overlay-mode -1)
  (when (markerp overlay-arrow-position)
    (set-marker overlay-arrow-position nil))
  (gcl-q)
  (message "Debugger keys detached. Editing restored."))

;; Inferior lisp buffer

(defun gcl-find-line ()
  "If the current buffer has a process, then look first for a file-line
property, and if none, then search for a regexp.
If a non process buffer, just return current file and line number.
"
  (interactive)
  (save-excursion
    (end-of-line)
    (cond ((get-buffer-process (current-buffer))
	   (cond
	    ((progn
	       (beginning-of-line)
	       (get-text-property (point) 'file-line)))
	    ((progn (end-of-line) (re-search-backward "\(\\([^ ]+\\) +line +\\([0-9]+\\)\)" 300 nil))
	     (let* ((file (buffer-substring (match-beginning 1) (match-end 1)))
		    (line (buffer-substring (match-beginning 2) (match-end 2)))
		    (line (read line)))
	     (and (integerp line) file (list file line))))))
	  (t (list (buffer-file-name)
		   (+ 1 (if (featurep 'xemacs) (line-number) (line-number-at-pos))))))))

(defun gcl-find-and-display-line nil
  (interactive)
  (let ((res (gcl-find-line)))
    (when res
      (apply 'gcl-display-line res))))

(defun gcl-find-file (file)
  (cond ((file-exists-p file)
	 (find-file-noselect file))
	((get-buffer file))
	(t (find-file-noselect file))))

(defvar gcl-last-frame nil)
(defvar gcl-last-frame-displayed-p t)
(defvar gcl-iob-init nil)
(defvar gcl-gdb-p nil)

(defun gcl-setup-iob nil

  (let* ((buf (current-buffer))
	 (gdb-com (when (boundp 'gud-comint-buffer) gud-comint-buffer))
	 (gdb-io (when gdb-com (gdb-get-buffer 'gdb-inferior-io)))
	 (buf (if (eq buf gdb-com) gdb-io buf))
	 (gdb-p (eq buf gdb-io)))
    (with-current-buffer buf

      (setq inferior-lisp-buffer (current-buffer))
      (setq-local gcl-last-frame nil)
      (setq-local gcl-last-frame-displayed-p t)
      (setq-local gcl-iob-init t)
      (setq-local gcl-gdb-p gdb-p)

      (local-set-key (kbd "C-c l") 'gcl-find-and-display-line)
      (message "GCL environment bound cleanly to %s" (buffer-name)))))

;; Filter

(defun gcl-display-line (true-file line)
  (let* ((buffer (gcl-find-file true-file))
	 (window (progn
		   (pop-to-buffer buffer '(display-buffer-reuse-window display-buffer-pop-up-window))
		   (get-buffer-window buffer)))
 	 pos)
    (save-excursion
      (set-buffer buffer)
      (save-restriction
	(widen)
	(goto-line line)
	(setq pos (point))
	(setq overlay-arrow-string "=>")
	(unless overlay-arrow-position
	  (setq overlay-arrow-position (make-marker)))
	(set-marker overlay-arrow-position (point) (current-buffer)))
      (unless (<= (point-min) pos (point-max))
	(widen)
	(goto-char pos))
      (gcl-source-overlay-mode 1))
    (set-window-point window overlay-arrow-position)))

(defun gcl-display-frame (&optional nodisplay noauto)
  "Find, obey and delete the last filename-and-line marker from GCL.
The marker looks like \\032\\032FILENAME:LINE:CHARPOS\\n.
Obeying it means displaying in another window the specified file and line."
  (interactive)
  (with-current-buffer inferior-lisp-buffer
    (when gcl-last-frame
      (unless nodisplay
	(unless (and gcl-last-frame-displayed-p noauto)
	  (gcl-display-line (car gcl-last-frame) (cdr gcl-last-frame))
	  (setq gcl-last-frame-displayed-p t))))))

(defun gcl-filter (string)
  (let ((filtered-string string))
    (unless gcl-iob-init
      (when (string-match-p "^GCL (GNU Common Lisp)" string)
	(gcl-setup-iob)))
    (when gcl-iob-init
      (when (string-match "^[^:]*:?\032\032\\([A-Za-z]?:?[^:]*\\):\\([0-9]*\\):[^\n]+\n" string)
	(let ((file (match-string 1 string))
              (line (string-to-number (match-string 2 string))))
	  (setq filtered-string (replace-match "" t t string))
          (unless (equal line 0)
            (setq gcl-last-frame (cons file line))
            (setq gcl-last-frame-displayed-p nil)
            (gcl-display-frame)))))
    filtered-string))


;; COMINT mode

(defun gcl-comint-filter (proc string)
  (let ((inhibit-quit t))
    (with-current-buffer (process-buffer proc)
      (comint-output-filter proc (gcl-filter string)))))

(defun gcl-process-sentinel (proc msg)
  "Manage process state changes for GCL/GDB, cleaning up debugging hooks on exit."
  (let* ((p-buf (process-buffer proc))
	 (killed (or (null p-buf) (null (buffer-name p-buf)))))

    (when (or killed (memq (process-status proc) '(signal exit)))

      (message "GCL: Process stream terminated (%s). Cleaning up environment..." (string-trim msg))

      (when (markerp overlay-arrow-position)
        (set-marker overlay-arrow-position nil))

      (dolist (buf (buffer-list))
        (with-current-buffer buf
          (when (bound-and-true-p gcl-source-overlay-mode)
            (gcl-source-overlay-mode -1)
            (message "Restored editing configuration to %s" (buffer-name buf)))))

      (unless killed
	(let ((obuf (current-buffer)))
          (unwind-protect
              (with-current-buffer p-buf
		(setq mode-line-process (format ": %s" (symbol-name (process-status proc))))
		(set-buffer-modified-p (buffer-modified-p))
		(save-excursion
                  (goto-char (point-max))
                  (insert (format "\nProcess %s %s" (process-name proc) msg)))
		(unless gcl-gdb-p
		  (delete-process proc)))
            (when (buffer-live-p obuf)
              (set-buffer obuf))))))))

;;GDB mode

(defun gcl-gdb-inferior-io-filter-advice (orig-filter proc string)
  "Intercept GCL source-tracking traces in the GDB I/O channel before rendering."
  (with-current-buffer (process-buffer proc)
    (funcall orig-filter proc (gcl-filter string))))
(advice-add 'gdb-inferior-filter :around 'gcl-gdb-inferior-io-filter-advice)

(defun gcl-gdb-cleanup-advice (&rest _args)
  "Hook into gdb-mi's native reset routine to tear down custom Lisp overlays safely."

  (message "GCL: GDB session ended. Cleaning up environment overlays...")

  (when (markerp overlay-arrow-position)
    (set-marker overlay-arrow-position nil))

  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (bound-and-true-p gcl-source-overlay-mode)
        (gcl-source-overlay-mode -1)
        (message "Restored editing configuration to %s" (buffer-name buf))))))
(advice-add 'gdb-reset :after 'gcl-gdb-cleanup-advice)

;;;###autoload
(defun gcl (&optional debug)
  (interactive "P")
  (let* ((fn (or (locate-file "saved_ansi_gcl" gcl-dirs nil 'executable)
		 (shell-command-to-string "gcl27 -batch -eval '(print (si::kcl-self))'")))
	 (dir (file-name-directory
	       (directory-file-name
		(file-name-directory fn)))))
    (cond
     (debug
      (setq gdb-many-windows t)
      (gdb (format "gdb -i=mi -cd=%s -d=%s --args %s -nocinit" dir dir fn)))
     (t (let ((buf (make-comint "gcl" fn nil "-nocinit")))
	  (set-process-filter (get-buffer-process buf) 'gcl-comint-filter)
	  (set-process-sentinel (get-buffer-process buf) 'gcl-process-sentinel)
	  (pop-to-buffer buf '(display-buffer-pop-up-window)))))))

(provide 'gcl)
