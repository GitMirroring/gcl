;; Copyright (C) 2024 Camm Maguire
(in-package :si)

(export '(mdlsym mdl lib-name))

(defun lib-name (p)
  (if (or (string= p "") (string= p "libc") (string= p "libm")) "" 
    (string-concatenate #+darwin "/usr/lib/system/" p #+darwin ".dylib" #+cygwin ".dll" #-(or darwin cygwin) ".so")));FIXME

(defun name-lib (n)
  (when (>= (string-match #.(compile-regexp "\([^/]*\)$") n) 0)
    (setq n (subseq n (match-beginning 1) (match-end 1))))
  (when (>= (string-match #.(compile-regexp "(\.(so|dylib|dll))$") n) 0)
    (setq n (subseq n 0 (match-beginning 1))))
  n)

(defun mdl (n p vad)
  (let* ((sym (mdlsym n (lib-name p)))
	 (ad (symbol-value sym))
	 (adp (aref %init vad)))
    (dladdr-set adp ad)
    (dllist-push %memory sym adp)))

(defun fdlsym (str n pk &aux r)
  (declare (dynamic-extent r))
  (let* ((n (name-lib n))
	 (psym (find-symbol n pk))
	 (psyms (if psym (push psym r) (when (zerop (length n)) (do-symbols (s pk r) (push s r)))))
	 sym
	 (vals (mapc (lambda (x &aux (s (find-symbol str x)))
		       (when s
			 (when (if sym (<= (symbol-value s) (symbol-value sym)) t)
			   (setq sym s))))
		     psyms)))
    sym))

(defun mdlsym (str &optional (n "" np)
		     &aux (pk #.(or (find-package "LIB") (make-package "LIB"))))
  (or
   (fdlsym str n pk);FIXME repeated dlsym unreliable on non-Linux
   (let* ((k  (if np (dlopen n) 0))
	  (ad (dlsym k str))
	  (p (or (dladdr ad t) ""));FIXME work around dladdr here, not posix
	  (psym (intern p pk))
	  (npk (or (find-package psym) (make-package psym :use '(:cl))))
	  (sym (and (shadow str npk) (intern str npk))))
     (export (list psym) pk)
     (export sym npk)
     (set psym k)(set sym ad)
     sym)))

