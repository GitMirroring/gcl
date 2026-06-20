;; Copyright (C) 2024 Camm Maguire
(in-package :si)

(export '(mdlsym mdl lib-name))

(defvar *lib-package-syms* nil);FIXME accelerator for do-symbols
(defvar *dladdr-mods* nil)
(defconstant +dl-suffix+ #+darwin ".dylib" #+cygwin ".dll" #-(or darwin cygwin) ".so")

(defun esubseq (s &optional (b 0) (e (length s)) &aux (s (string s)));avoid mdl/memmove call in subseq
  (make-vector 'character (- e b) nil nil s b nil nil))

(defun name-lib (n &aux (n (string n)))
  (when (>= (string-match (load-time-value (compile-regexp "\([^/]*\)$")) n) 0)
    (setq n (esubseq n (match-beginning 1) (match-end 1))))
  (when (>= (string-match (load-time-value (compile-regexp "(\.(so|dylib|dll))$")) n) 0)
    (setq n (esubseq n 0 (match-beginning 1))))
  #+darwin(when (>= (string-match (load-time-value (compile-regexp "^libsystem")) n) 0)
	    (setq n "libSystem"))
  n)

(defun lib-name (p &aux (p (name-lib p)))
  (if (member p '("" "libc" "libm") :test #'string=)
      "" ; FIXME
      (string-concatenate p +dl-suffix+)))

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

(defun dladdr-mod (p n &aux (p (name-lib p))(n (name-lib n)))
  (cond ((cdr (assoc p *dladdr-mods* :test 'string=)))
	((unless (string= p n) (plusp (length n)))
	 (cdar (push (cons p n) *dladdr-mods*)))
	(p)))

(defun reg-psym (psym)
  (car (or (member psym *lib-package-syms*)
	   (push psym *lib-package-syms*))))

(defun mdlsym (str &optional (n "")
	       &aux (n (lib-name n))
		 (pk (load-time-value (or (find-package "LIB") (make-package "LIB")))))
  (or
   (fdlsym str n pk);FIXME repeated dlsym unreliable on non-Linux
   (let* ((k (dlopen n))
	  (ad (dlsym k str))
	  (p (or (dladdr ad t) ""));FIXME work around dladdr here, not posix
	  (p (dladdr-mod p n))
	  (psym (reg-psym (intern p pk)))
	  (npk (or (find-package psym) (make-package psym :use '(:cl))))
	  (sym (and (shadow str npk) (intern str npk))))
     (export (list psym) pk)
     (export sym npk)
     (set psym k)(set sym ad)
     sym)))

(defun mdl (n p vad)
  (let* ((sym (mdlsym n p))
	 (ad (symbol-value sym))
	 (adp (aref %init vad)))
    (dladdr-set adp ad)
    (dllist-push %memory sym adp)))
