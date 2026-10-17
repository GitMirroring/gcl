;; Copyright (C) 2024 Camm Maguire
;; -*-Lisp-*-
(in-package :si)

#+c99
(progn

(eval-when
    (compile eval)
  (defmacro deflibmfun (x)
    `(progn
       (defdlfun (:float    ,(strcat x "f")     ) :float)
       (defdlfun (:double   ,x                  ) :double)
       (defdlfun (:fcomplex ,(strcat "c" x "f") ) :fcomplex)
       (defdlfun (:dcomplex ,(strcat "c" x)     ) :dcomplex)))
  
  (defmacro defrlibmfun (x &optional y)
    `(progn
       (defdlfun (:float    ,(strcat x "f")     ) :float :float)
       (defdlfun (:double   ,x                  ) :double :double)
       ,@(when y
	   `((defdlfun (:fcomplex   ,(strcat "c" x "f")     ) :fcomplex :fcomplex)
  	     (defdlfun (:dcomplex   ,(strcat "c" x)         ) :dcomplex :dcomplex)))))

  (defmacro defrlibmfun1 (x)
    `(progn
       (defdlfun (:float    ,(strcat x "f")     ) :float)
       (defdlfun (:double   ,x                  ) :double)))

  (defmacro defalibmfun (x)
    `(progn
       (defdlfun (:float    ,(strcat "f" x "f") ) :float)
       (defdlfun (:double   ,(strcat "f" x)     ) :double)
       (defdlfun (:fixnum   ,(strcat "l" x)     ) :fixnum)
       (defdlfun (:float    ,(strcat "c" x "f") ) :fcomplex)
       (defdlfun (:double   ,(strcat "c" x)     ) :dcomplex))))

(defalibmfun "abs")

(deflibmfun "exp")
(defrlibmfun "pow" t)
(deflibmfun "log")
(deflibmfun "sqrt")

(deflibmfun "sin")
(deflibmfun "cos")
(deflibmfun "tan")
(deflibmfun "sinh")
(deflibmfun "cosh")
(deflibmfun "tanh")
(deflibmfun "asin")
(deflibmfun "acos")
(deflibmfun "atan")
(defrlibmfun "atan2")
(deflibmfun "asinh")
(deflibmfun "acosh")
(deflibmfun "atanh")

(defrlibmfun1 "erf")
(defrlibmfun1 "erfc")
(defrlibmfun1 "trunc")
(defrlibmfun1 "ceil")

(defrlibmfun1 "lgamma")
(defrlibmfun1 "tgamma")

(defdlfun (:float    "cargf"     ) :fcomplex)
(defdlfun (:double    "carg"     ) :dcomplex)

(defdlfun (:float "ldexpf") :float :int)
(defdlfun (:double "ldexp") :double :int)

(defun bsqrt (x);this is an instruction, or a jump to main body
  (check-type x long-float)
  (lit :double "sqrt(" (:double x) ")"))
(setf (get 'bsqrt 'compiler::cmp-inline) t)

(defun bsqrtf (x);this is an instruction, or a jump to main body
  (check-type x short-float)
  (lit :float "sqrtf(" (:float x) ")"))
(setf (get 'bsqrtf 'compiler::cmp-inline) t)

(eval-when 
 (compile eval)
 

 (defmacro defmfun (x &optional n protect-real sqrtp)
   (let* ((b (if sqrtp 'bsqrt (mdlsym x)))
	  (f (if sqrtp 'bsqrtf (mdlsym (string-concatenate x "f"))))
	  (c (mdlsym (string-concatenate "c" x)))
	  (cf (mdlsym (string-concatenate "c" x "f")))
	  (ts (intern (string-upcase x)))
	  (tp (get ts 'compiler::type-propagator))
	  (body `(typecase x
		   (long-float  (,b x))
		   (short-float (,f x))
                   ,@(when sqrtp `((bignum (max (,b (float x 0.0)) (float (isqrt x) 0.0)))))
		   (rational    (,b (float x 0.0)))
		   (dcomplex    (,c x))
		   (fcomplex    (,cf x))
		   (otherwise   (,c (complex (float (realpart x) 0.0) (float (imagpart x) 0.0)))))))
     `(progn
	(mdlsym ,x)
	(mdlsym (string-concatenate ,x "f"))
	(mdlsym (string-concatenate "c" ,x))
	(mdlsym (string-concatenate "c" ,x "f"))
	(setf (get ',b 'compiler::type-propagator)  ',tp)
	(setf (get ',f 'compiler::type-propagator)  ',tp)
	(setf (get ',c 'compiler::type-propagator)  ',tp)
	(setf (get ',cf 'compiler::type-propagator) ',tp)
	(defun ,(or n (intern (string-upcase x))) (x)
	  ,@(unless (and n (not (string= (string-upcase n) (string-upcase x))))
	      `((declare (optimize (safety 2)))
		(check-type x number)))
	  ,(if protect-real
	       `(if (and (realp x) ,protect-real)
		    ,body
		  (let ((x (cond ((not (realp x)) x) 
				 ((floatp x) (complex x (float 0.0 x)))
				 ((complex (float x 0.0) 0.0)))))
		    ,body))
	       body)))))

  (defmacro defmlog (x &optional n)
   (let* ((b (mdlsym x))
	  (f (mdlsym (string-concatenate x "f")))
	  (c (mdlsym (string-concatenate "c" x)))
	  (cf (mdlsym (string-concatenate "c" x "f")))
	  (ts (intern (string-upcase x)))
	  (tp (get ts 'compiler::type-propagator)))
     `(progn
	(mdlsym ,x)
	(mdlsym (string-concatenate ,x "f"))
	(mdlsym (string-concatenate "c" ,x))
	(mdlsym (string-concatenate "c" ,x "f"))
	(setf (get ',b 'compiler::type-propagator)  ',tp)
	(setf (get ',f 'compiler::type-propagator)  ',tp)
	(setf (get ',c 'compiler::type-propagator)  ',tp)
	(setf (get ',cf 'compiler::type-propagator) ',tp)
	(defun ,(or n (intern (string-upcase x))) (x)
	  ,@(unless (and n (not (string= (string-upcase n) (string-upcase x))))
	      `((declare (optimize (safety 2)))
		(check-type x number)))
	  (etypecase x
	    (fixnum (,b (float x 0.0)))
	    (integer (ilog x))
	    (rational (- (ilog (numerator x)) (ilog (denominator x))))
	    (short-float (,f x))
	    (long-float (,b x))
	    (fcomplex (,cf x))
	    (dcomplex (,c x))
	    (complex (,c (complex (float (realpart x) 0.0) (float (imagpart x) 0.0)))))))))

 (defmacro defmabs (x &optional n)
   (let* ((i 'babs);(mdlsym (string-concatenate "l" x)))
	  (b (mdlsym (string-concatenate "f" x)))
	  (f (mdlsym (string-concatenate "f" x "f")))
	  (c (mdlsym (string-concatenate "c" x)))
	  (cf (mdlsym (string-concatenate "c" x "f")))
	  (ts (intern (string-upcase x)))
	  (tp (get ts 'compiler::type-propagator)))
     `(progn
	(mdlsym ,x)
	(mdlsym (string-concatenate "f" ,x))
	(mdlsym (string-concatenate "c" ,x))
	(setf (get ',i 'compiler::type-propagator)  ',tp)
	(setf (get ',b 'compiler::type-propagator)  ',tp)
	(setf (get ',f 'compiler::type-propagator)  ',tp)
	(setf (get ',c 'compiler::type-propagator)  ',tp)
	(setf (get ',cf 'compiler::type-propagator)  ',tp)
	(defun ,(or n (intern (string-upcase x))) (x)
	  ,@(unless n `((declare (optimize (safety 2)))
			(check-type x number)))
	  (typecase x
			 (long-float  (,b x))
			 (short-float (,f x))
			 (fixnum      (if (= x most-negative-fixnum) (- most-negative-fixnum) (,i x)))
			 (rational    (if (minusp x) (- x) x))
			 (dcomplex    (,c x))
			 (fcomplex    (,cf x))
			 (otherwise   (,c (complex (float (realpart x) 0.0) (float (imagpart x) 0.0)))))))))

 (defmacro defrmfun (x &optional n)
   (let ((b (mdlsym x))
	 (f (mdlsym (string-concatenate x "f")))
	 (tp (get 'atan 'compiler::type-propagator)));FIXME
     `(progn
	(mdlsym ,x)
	(mdlsym (string-concatenate ,x "f"))
	(setf (get ',b 'compiler::type-propagator)  ',tp)
	(setf (get ',f 'compiler::type-propagator)  ',tp)
	(defun ,(or n (intern (string-upcase x))) (x z)
	  ,(unless n `((declare (optimize (safety 2)))
		       (check-type x real)
		       (check-type z real)))
	  (typecase 
	   z
	   (long-float (typecase 
			x
			(long-float  (,b x z))
			(short-float (,b (float x z) z))
			(fixnum      (,b (float x z) z))
			(rational    (,b (float x z) z))))
	   (short-float (typecase 
			 x
			 (long-float  (,b x (float z x)))
			 (short-float (,f x z))
			 (fixnum      (,f (float x z) z))
			 (rational    (,f (float x z) z))))
	   (fixnum (typecase 
		    x
		    (long-float  (,b x (float z x)))
		    (short-float (,f x (float z x)))
		    (fixnum      (,b (float x 0.0) (float z 0.0)))
		    (rational    (,b (float x 0.0) (float z 0.0)))))
	   (rational (typecase 
		      x
		      (long-float  (,b x (float z x)))
		      (short-float (,f x (float z x)))
		      (fixnum      (,b (float x 0.0) (float z 0.0)))
		      (rational    (,b (float x 0.0) (float z 0.0)))))))))))


(defun babs (x) (declare (fixnum x)) (lit :fixnum "labs(" (:fixnum x) ")"));this is a builtin in recent gcc
(setf (get 'babs 'compiler::cmp-inline) t)
 
(defmabs "abs")

(defmfun "sin")	
(defmfun "cos")	
(defmfun "tan")
(defmfun "asinh")
(defmfun "sinh")
(defmfun "cosh")
(defmfun "tanh")

(defmfun "exp" rawexp)
(defun exp (x)
  (declare (inline rawexp))
  (check-type x number)
  (rawexp x))

;(defrmfun "pow" expt)

(defrmfun "atan2"  rawatan2)
(defmfun "atan" rawatan)
(defun atan (x &optional (z 0.0 zp))
  (declare (optimize (safety 2)) (inline rawatan2 rawatan))
  (check-type x number)
  (check-type z real)
  (cond (zp 
	 (check-type x real)
	 (rawatan2 x z))
	((rawatan x))))

(defun ilog (n &aux (l (integer-length n)))
  (+ (plog (float (/ n (ash 1 l)))) (* (plog 2.0) l)))
(declaim (inline ilog))

(defmlog "log" plog)
(declaim (inline plog))

(defun rawlog (x)
  (cond
    ((complexp x) (let* ((z (max (abs (realpart x)) (abs (imagpart x)))))
		    (+ (plog z) (plog (complex (/ (realpart x) z) (/ (imagpart x) z))))))
    ((minusp x) (+ (plog (- x)) (plog (complex -1 (if (floatp x) (float 0.0 x) 0.0)))))
    ((plog x))))

(defun log (x &optional b)
  (declare (optimize (safety 2)) (inline rawlog))
  (check-type x number)
  (check-type b (or null number))
  (if b 
      (/ (log x) (log b))
    (rawlog x)))
  
(defmfun "acosh" acosh (>= x 1))
(defmfun "atanh" atanh (and (>= x -1) (<= x 1)))
(defmfun "acos"  acos (and (>= x -1) (<= x 1)))
(defmfun "asin"  asin (and (>= x -1) (<= x 1)))
(defmfun "sqrt"  sqrt (>= x 0) t)

(defun isfinite (x)
  (typecase
   x
   (short-float (lit :boolean "__builtin_isfinite(" (:float x) ")"))
   (long-float (lit :boolean "__builtin_isfinite(" (:double x) ")"))))
(setf (get 'isfinite 'compiler::cmp-inline) t)

(defun isnormal (x)
  (typecase
   x
   (short-float (lit :boolean "__builtin_isnormal(" (:float x) ")"))
   (long-float (lit :boolean "__builtin_isnormal(" (:double x) ")"))))
(setf (get 'isnormal 'compiler::cmp-inline) t)

(defun scale-float (x y)
  (declare (optimize (safety 1)))
  (check-type x float)
  (check-type y integer)
  (let ((y (max -4096 (min 4096 y))))
    (typecase x
      (short-float (#.(mdlsym "ldexpf") x y))
      (float (#.(mdlsym "ldexp") x y)))))

(dolist (l (mapcar 'mdlsym '("ldexpf" "ldexp")))
  (setf (get l 'compiler::type-propagator) (get 'scale-float 'compiler::type-propagator)))

(declaim (inline l2imul))
(defun l2imul (x y &optional (z 1))
  (if (plusp y)
      (l2imul (* x x) (ash y -1) (if (oddp y) (* z x) z))
      z))

(declaim (inline float-integer-p))
(defun float-integer-p (x)
  (typecase x
    (short-float (eql (#.(mdlsym "truncf") x) x))
    (long-float (eql (#.(mdlsym "trunc") x) x))
    (integer t)))

(defun expt (b e)

  (declare (optimize (safety 1)))
  (check-type b number)
  (check-type e number)

  (typecase b
    (integer
     (typecase e
       ((and fixnum (integer 0)) (mpz_pow_ui b e))
       (fixnum (/ 1 (expt b (- e))))
       (integer
	(case b
	  ((0 1) (if (minusp e) (/ 1 b) b))
	  (-1 (if (oddp e) -1 1))
	  (otherwise (error 'storage-exhausted))))
       (rational (expt (float b 0.0) (float e 0.0)))
       (float (expt (float b e) e))
       (fcomplex (expt (coerce b '(complex short-float)) e))
       (t (expt (coerce b '(complex long-float)) e))))
    (ratio (/ (expt (numerator b) e) (expt (denominator b) e)))
    (short-float
     (typecase e
       ((or rational short-float)
	(if (unless (float-integer-p e) (minusp b))
	    (expt (complex b 0.0s0) e)
	    (#.(mdlsym "powf") b (float e b))))
       (long-float
	(if (unless (float-integer-p e) (minusp b))
	    (expt (complex b 0.0) e)
	    (#.(mdlsym "pow") (float b e) e)))
       ((complex short-float) (expt (complex b 0.0s0) e))
       (t (expt (complex b 0.0) e))))
    (long-float
     (typecase e
       ((or rational float)
	(if (unless (float-integer-p e) (minusp b))
	    (expt (complex b 0.0) e)
	    (#.(mdlsym "pow") b (float e b))))
       (t (expt (complex b 0.0) e))))
    ((complex rational)
     (typecase e
       (integer (if (zerop e) 1 (l2imul (if (minusp e) (/ 1 b) b) (abs e))))
       ((or rational short-float (complex (or rational short-float)))
	(expt (coerce b '(complex short-float)) e))
       (t (expt (coerce b '(complex long-float)) e))))
    ((complex short-float)
     (typecase e
       ((or rational short-float (complex (or rational short-float)))
	(#.(mdlsym "cpowf") b (coerce e '(complex short-float))))
       (t (expt (coerce b '(complex long-float)) e))))
    (t (#.(mdlsym "cpow") b (coerce e '(complex long-float))))))

(dolist (l (cons 'mpz_pow_ui (mapcar 'mdlsym '("pow" "powf" "cpow" "cpowf"))))
  (setf (get l 'compiler::type-propagator) (get 'expt 'compiler::type-propagator)))



)

#-c99
(defun abs (z)
  (declare (optimize (safety 2)))
  (check-type z number)
  (cond ((complexp z)
	 ;; Compute (sqrt (+ (* x x) (* y y))) carefully to prevent
	 ;; overflow!
	 (let* ((x (abs (realpart z)))
		(y (abs (imagpart z))))
	   (if (< x y)
	       (rotatef x y))
	   (if (zerop x)
	       x
	     (let ((r (/ y x)))
	       (* x (sqrt (+ 1 (* r r))))))))
	((minusp z) (- z))
	(z)))


;; (defdlfun (:fixnum "__gmpz_cmp") :fixnum :fixnum)
;; #.(let ((x (truncate fixnum-length char-length)))
;;     `(defun mpz_cmp (x y) (|libgmp|:|__gmpz_cmp| (+ ,x (address x)) (+ ,x (address y)))));FIXME
;; (setf (get 'mpz_cmp 'compiler::cmp-inline) t)


(defdlfun (:fixnum "memcpy") :fixnum :fixnum :fixnum)
#.`(defun memcpy (a b c)
     (declare (fixnum a b c))
     (lit :fixnum "{fixnum f=1;f;}");(side-effects)
     (,(mdlsym "memcpy") a b c))
(declaim (inline memcpy))

(defdlfun (:fixnum "memmove") :fixnum :fixnum :fixnum)
#.`(defun memmove (a b c)
     (declare (fixnum a b c))
     (lit :fixnum "{fixnum f=1;f;}");(side-effects)
     (,(mdlsym "memmove") a b c))
(declaim (inline memmove))
