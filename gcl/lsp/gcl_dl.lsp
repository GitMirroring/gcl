;; Copyright (C) 2024 Camm Maguire
(in-package :si)

(export '(mdlsym mdl lib-name))

(defvar *lib-package-syms* nil);FIXME accelerator for do-symbols

(defun lib-name (p);FIXME
  (if (or (string= p "") (string= p "libc") (string= p "libm")) "" 
      (string-concatenate
       #+darwin "/usr/lib/system/" ;FIXME still needed?
       p
       #+darwin ".dylib" #+cygwin ".dll" #-(or darwin cygwin) ".so")))

(defun esubseq (s &optional (b 0) (e (length s)));avoid mdl/memmove call in subseq
  (let* ((l (- e b))
	 (ns (make-vector 'character l nil nil nil 0 nil nil)))
    (copy-array-portion s ns b 0 l)
    ns))

(defun name-lib (n)
  (when (>= (string-match (load-time-value (compile-regexp "\([^/]*\)$")) n) 0)
    (setq n (esubseq n (match-beginning 1) (match-end 1))))
  (when (>= (string-match (load-time-value (compile-regexp "(\.(so|dylib|dll))$")) n) 0)
    (setq n (esubseq n 0 (match-beginning 1))))
  n)

(defun find-external-symbol (str p)
  (multiple-value-bind (sym key) (find-symbol str p)
    (when (eq key :external)
      sym)))

(defun fdlsym (str n pk &aux r sym)
  (declare (dynamic-extent r))
  (let* ((n (name-lib n))
	 (psym (find-symbol n pk)))
    (mapc (lambda (x &aux (s (find-external-symbol str x)))
	    (when s
	      (when (if sym (<= (symbol-value s) (symbol-value sym)) t)
		(setq sym s))))
	  (if psym
	      (push psym r)
	      (when (zerop (length n))
		*lib-package-syms*)))
    sym))

(defun mdlsym (str &optional (n "" np)
		     &aux (pk (load-time-value (or (find-package "LIB") (make-package "LIB")))))
  (or
   (fdlsym str n pk);FIXME repeated dlsym unreliable on non-Linux
   (let* ((k  (if np (dlopen n) 0))
	  (ad (dlsym k str))
	  (p (or (dladdr ad t) ""));FIXME work around dladdr here, not posix
	  (psym (car (pushnew (intern p pk) *lib-package-syms*)))
	  (npk (or (find-package psym) (make-package psym :use '(:cl))))
	  (sym (and (shadow str npk) (intern str npk))))
     (export (list psym) pk)
     (export sym npk)
     (set psym k)(set sym ad)
     sym)))

(defun mdl (n p vad)
  (let* ((sym (mdlsym n (lib-name p)))
	 (ad (symbol-value sym))
	 (adp (aref %init vad)))
    (dladdr-set adp ad)
    (dllist-push %memory sym adp)))
