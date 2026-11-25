;;Copyright William F. Schelter 1990, All Rights Reserved 
;;Copyright 2024 Camm Maguire


(In-package :SYSTEM)
(import 'sloop::sloop)

(eval-when (compile eval)
  (defmacro f (op &rest args)
    `(the fixnum (,op ,@ (mapcar #'(lambda (x) `(the fixnum ,x)) args) )))

  (defmacro fb (op &rest args)
    `(,op ,@ (mapcar #'(lambda (x) `(the fixnum ,x)) args))))


;;; Some debugging features:
;;; Search-stack :
;;; (:s "cal") or (:s 'cal) searches the stack for a frame whose function or 
;;; special form has a name containing "cal", moves there to display the local
;;; data.
;;;
;;; Break-locals :
;;; :bl displays the args and locals of the current function.
;;; (:bl 4) does this for 4 functions.
;;;
;;; (si:loc i)  accesses the local(i): slot.
;;; the *print-level* and *print-depth* are bound to *debug-print-level*

;;; Note you must have space < 3  in your optimize proclamation, in order for
;;; the local variable names to be saved by the compiler.

;;; With BSD You may also use the function write-debug-symbols to
;;; obtain an object file with the correct symbol information for using a
;;; c debugger, on translated lisp code.  You should have used the :debug
;;; t keyword when compiling the file.

;;; To Do: add setf method for si:loc.
;;; add restart capability from various spots on the stack.

(defun show-break-variables (&optional (n 1))
  (loop
					;(break-current)
   (dolist (v (reverse(car *break-env*)))
     (format *debug-io* "~%~9a: ~s" (car v) (second v)))
   (or (fb >  (incf  n -1) 0) (return (values)))
   (break-previous)
   ))

(defun show-environment nil
  (dolist (v (reverse (car (current-env))))
    (format *debug-io* "~%~9a: ~s" (car v) (second v))))

(putprop :a 'show-break-variables 'break-command)

;;make hack in compiler to remember the local variable names for the 
;;vs variables and associate it with the function name

(defun search-stack (sym &aux string);FIXME
  (setq string (cond((symbolp sym)(symbol-name sym))
		    (t sym)))
  (sloop
     for ihs downfrom (ihs-top) above 1
     for fun = (ihs-fun ihs) with name
     do
     (setq name (ihs-fname ihs))
     when (search string (symbol-name name) :test 'equal)
     do (return (progn (break-go ihs)(terpri) (break-locals)))
     finally (format *debug-io* "~%Search for ~a failed" string)
     ))

(defvar *debug-print-level* 3)

(defun break-locals (&optional (n 1) ;FIXME
			       &aux (ihs *current-ihs*)
			       (*print-level* *debug-print-level*)
			       (*print-circle* t)
			       (*print-length* *debug-print-level*)
			       (current-ihs *current-ihs*))
  (cond ((fb > n 1)
	 (sloop for i below n
	    for ihs downfrom current-ihs above 2
	    do (let ((*current-ihs* ihs)) (break-locals) (terpri)(terpri))))
	((ihs-vs (f + 1 *current-ihs*))
	 (format *debug-io* ">> ~a():" (ihs-fname ihs))
	 (show-environment))))

(defun loc (&optional (n 0))
  (let ((base (ihs-vs *current-ihs*)))
    (unless  (and (fb >= n 0)
		  (fb < n (f - (ihs-vs
				(min (ihs-top) (f + 1 *current-ihs*)))
			     base)))
	     (error "Not in current function"))
    (vs (f + n base))))

(putprop :bl 'break-locals 'break-command)
(putprop :s 'search-stack 'break-command)

(defvar *record-line-info* (make-hash-table :test 'eq))

(defvar *at-newline* nil)

(defvar *standard-readtable* *readtable*)

(defvar *line-info-readtable* (copy-readtable))

(defvar *left-parenthesis-reader* (get-macro-character #\( ))

(defvar *quotation-reader* (get-macro-character #\" ))

(defvar *stream-alist* nil)

(defvar *break-point-vector* (make-array 10 :fill-pointer 0 :adjustable t))

(defvar *step-next* nil)

(defvar *last-dbl-break* nil)

#-gcl
(eval-when (compile eval load)

(defvar *places* '(|*mv0*| |*mv1*| |*mv2*| |*mv3*| |*mv4*| |*mv5*| |*mv6*| |*mv7*|
		     |*mv8*| |*mv9*|))

(defmacro set-mv (i val) `(setf ,(nth i *places*) ,val))

(defmacro mv-ref (i) (nth i *places*))
  )

(defmacro mv-setq (lis form)
  `(prog1 (setf ,(car lis) ,form)
     ,@ (do ((v (cdr lis) (cdr v))
	     (i 0 (1+ i))
	     (res))
	    ((null v)(nreverse res))
	  (push `(setf ,(car v) (mv-ref ,i)) res))))

(defmacro mv-values (&rest lis)
  `(prog1 ,(car lis)
     ,@ (do ((v (cdr lis) (cdr v))
	     (i 0 (1+ i))
	     (res))
	    ((null v)(nreverse res))
	  (push `(set-mv ,i ,(car v)) res))))

;;start a lisp debugger loop.   Exit it by using :step

(defun dbl ()
  (break-level nil nil))

(defun stream-name (str) (when (typep str 'pathname-designator) (namestring (pathname str))))

(defstruct instream stream (line 0 :type fixnum) stream-name)


(eval-when (eval compile)

(defstruct (bkpt (:type list)) form file file-line function)
  )

(defun cleanup ()
  (dolist (v *stream-alist*)
    (unless (open-stream-p (instream-stream v))
      (setq *stream-alist* (delete v *stream-alist*)))))

(defun get-instream (str)
  (or (dolist (v *stream-alist*)
	(cond ((eq str (instream-stream v))
	       (return v))))
      (car (setq *stream-alist*
		 (cons  (make-instream :stream str
                                     :stream-name (if (streamp str)
                                               (stream-name str))
   ) *stream-alist*)))))

(defun newline (str ch)
  (declare (ignore ch))
  (let ((in (get-instream str)))
    (setf (instream-line in) (the fixnum (f + 1 (instream-line in)))))
  ;; if the next line begins with '(', then record all cons's eg arglist )
  (setq *at-newline*  (if (eql (peek-char nil str nil) #\() :all t))
  (values))

(defun quotation-reader (str ch)
  (let ((tem (funcall *quotation-reader* str ch))
	(instr (get-instream str)))
    (incf (instream-line instr) (count #\newline tem))
    tem))

(defvar *old-semicolon-reader* (get-macro-character #\;))

(defun new-semi-colon-reader (str ch)
  (let ((in (get-instream str))
	(next (peek-char nil str nil nil)))
    (setf (instream-line in) (the fixnum (f + 1 (instream-line in))))
    (cond ((eql next #\!)
	   (read-char str)
	   (let* ((*readtable* *standard-readtable*)
		  (command (read-from-string (read-line str nil nil))))
	     (cond ((and (consp command)
			 (eq (car command) :line)
			 (stringp (second command))
			 (typep (third command) 'fixnum))
		    (setf (instream-stream-name in) (second command))
		    (setf (instream-line in) (third command))))
	     ))
	  (t    (funcall *old-semicolon-reader* str ch)))
    (setq *at-newline*  (if (eql (peek-char nil str nil) #\() :all t))
    (values)))

(defun setup-lineinfo ()
  (set-macro-character #\newline #'newline nil *line-info-readtable*)
  (set-macro-character #\; #'new-semi-colon-reader nil *line-info-readtable*)
  (set-macro-character #\( 'left-parenthesis-reader nil *line-info-readtable*)
  (set-macro-character #\" 'quotation-reader nil *line-info-readtable*)
  
  )

;;FIXME bring back clear-props in fSet
(defun record-line-info (sym fun &aux (body (fle fun))(ar *fun-array*)(old-info (get sym 'line-info)))
  (remprop sym 'line-info)
  (when (when (eq *readtable* *line-info-readtable*) (consp body))
    (setf (fill-pointer ar) 0)
    (walk-through body)
    (if (zerop (length ar))
	(iterate-over-bkpts (get sym 'break-points) :delete)
	(let* ((min (reduce 'min ar :key 'cdar :initial-value most-positive-fixnum))
	       (max (reduce 'max ar :key 'cdar :initial-value 0))
	       (new (make-array (- max min -2) :initial-element :blank-line)))
	  (setf (aref new 0) (cons (caar (aref ar 0)) min))
	  (decf min)
	  (map nil (lambda (x) (setf (aref new (- (cdar x) min)) (cdr x))) ar)
	  (setf (get sym 'line-info) new)
	  (when old-info
	    (let* ((old-begin (cdr (aref old-info 0))))
	      (mapc (lambda (x &aux (bpt (aref *break-points* x)))
		      (setf (aref *break-points* x)
			    (make-break-point (fourth bpt) new (- (third bpt) old-begin))))
		    (get sym 'break-points))))))))

(defun nload (file &rest args)
  (clrhash *record-line-info*)
  (cleanup)
  (setq file (truename file))
  (setup-lineinfo)
  (let ((*readtable* *line-info-readtable*)
	(ofsf (symbol-function 'fset)))
    (unwind-protect
	 (progn
	   (setf (symbol-function 'fset) (lambda (x y) (record-line-info x y) (funcall ofsf x y)))
	   (apply 'load file args))
      (setf (symbol-function 'fset) ofsf))))

(eval-when (compile eval)

(defmacro break-data (name line) `(cons ,name ,line)))

(defun left-parenthesis-reader (str ch &aux line(flag *at-newline*))
  (if (eq *at-newline* t) (setq *at-newline* nil))
  (when flag
    (setq flag (get-instream str))
    (setq line (instream-line flag))
    )
  (let ((tem (funcall *left-parenthesis-reader* str ch)))
    (when flag
      (setf (gethash tem *record-line-info*)
	    (break-data (instream-name flag)
			line)))
    tem))

(defvar *fun-array* (make-array 50 :fill-pointer 0 :adjustable t))

(defun walk-through (body &aux (tem (gethash body *record-line-info*)))
  (when (consp body)
    (when tem
      (vector-push-extend (cons tem body) *fun-array*))
    (flet ((repl (body key &aux (tem (gethash body *record-line-info*)))
	     (when (consp body)
	       (when tem
		 (remhash body *record-line-info*)
		 (setf (gethash (funcall key body) *record-line-info*) tem))))
	   (l (x) (when (listp x) x)))
      (case (car body)
	(cond (mapc (lambda (x) (when (consp x) (repl x 'car))) (cdr body)))
	((do do*)
	 (mapc (lambda (x) (when (consp x) (repl x 'car))) (l (cadr body)))
	 (mapc (lambda (x) (when (consp x) (repl x 'car))) (l (caddr body))))
	((case ecase ccase typecase etypecase ctypecase)
	 (mapc (lambda (x) (when (consp x) (repl x 'cadr))) (cdr body)))
	((let let*)
	 (repl (cadr body) 'car)
	 (mapc (lambda (x) (when (consp x) (repl x 'cadr))) (l (cadr body))))
	((flet labels macrolet)
	 (repl (cadr body) 'car)
	 (mapc (lambda (x) (when (consp x) (repl x 'caddr))) (l (cadr body))))
	((multiple-value-bind multiple-value-setq)
	 (repl (cadr body) (lambda (x) (declare (ignore x)) (l (caddr body)))))))
    (walk-through (car body))
    (walk-through (cdr body))))

;; (defun compiler::compiler-def-hook (name body &aux (ar *fun-array*)
;; 					 (min most-positive-fixnum)
;; 					 (max -1))
;;   (declare (fixnum min max))
;;   ;;  (cond ((and (boundp '*do-it*)
;;   ;;	      (eq (car body) 'lambda-block))
;;   ;;	 (setf (cdr body) (cdr  (walk-top body)))))
	 
;;   (cond ((atom body)
;; 	 (remprop name 'line-info))
;; 	((eq *readtable* *line-info-readtable*) 
;; 	 (setf (fill-pointer *fun-array*) 0)
;; 	 (walk-through body)
;; 	 (dotimes (i (length ar))
;; 		  (declare (fixnum i))
;; 		  (let ((n (cdar (aref ar i))))
;; 		    (declare (fixnum n))
;; 		    (if (fb > n max) (setf max n))
;; 		    (if (fb < n min) (setf min n))))
;; 	 (cond ((fb > (length *fun-array*) 0)
;; 	        (let ((new (make-array (f + (f - max min) 2)
;; 				       :initial-element :blank-line))
;; 		      (old-info (get name 'line-info)))
;; 		  (setf (aref new 0)
;; 			(cons (caar (aref ar 0)) min))
;; 		  (setq min (f - min 1))
;; 		  (dotimes (i (length ar))
;; 			   (let ((y (aref ar i)))
;; 			     (setf (aref new (f - (cdar y) min))
;; 				   (cdr y))))
;; 		  (setf (get name 'line-info) new)
;; 		  (when
;; 		      old-info
;; 		    (let ((tem (get name 'break-points))
;; 			  (old-begin (cdr (aref old-info 0))))
;; 		      (dolist (bptno tem)
;; 			(let* ((bpt (aref *break-points* bptno))
;; 			       (fun (bkpt-function bpt))
;; 			       (li (f - (bkpt-file-line bpt) old-begin)))
;; 			  (setf (aref *break-points* bptno)
;; 				(make-break-point fun  new li))))))))
;; 	       (t (let ((tem (get name 'break-points)))
;; 		    (iterate-over-bkpts tem :delete)))))))

(defun instream-name (instr)
  (or (instream-stream-name instr)
      (stream-name (instream-stream instr))))

(defun find-line-in-fun (form env fun  counter &aux tem)
  (setq tem (get fun 'line-info))
  (if tem
      (let ((ar tem))
	(declare (type (array (t)) ar))
	(when ar
	  (dotimes
	   (i (length ar))
	   (cond ((eq form (aref ar i))
		  (when counter
		    (decf (car counter))
		    (cond ((fb > (car counter) 0)
					;silent
			   (return-from find-line-in-fun :break))))
		  (break-level
		   (setq *last-dbl-break* (make-break-point fun  ar i)) env
		   )
		  (return-from find-line-in-fun :break))))))))

;; get the most recent function on the stack with step info.

(defun current-step-fun ( &optional (ihs (ihs-top)) )
  (do ((i (1- ihs) (f - i 1)))
      ((fb <=  i 0))
    (let ((na (ihs-fname i)))
      (if (get na 'line-info) (return (list na i))))))

(defun init-break-points ()
  (setf (fill-pointer *break-point-vector*) 0)
  (setf *break-points* *break-point-vector*))

(defun step-into (&optional (n 1))
;(defun step-into ()
  (declare (ignore n))
  ;;FORM is the next form about to be evaluated.
  (or *break-points* (init-break-points))
  (setq *break-step* 'break-step-into)
  :resume)

(defun step-next ( &optional (n 1))
  (let ((fun (current-step-fun)))
    (setq *step-next* (cons n fun))
    (or *break-points* (init-break-points))
    (setq *break-step* 'break-step-next)
    :resume))

(defvar *step-finish* nil)

(defun step-finish (&optional (n 1))
  (let ((fun (current-step-fun)))
    (setq *step-finish* (cons n fun))
    (or *break-points* (init-break-points))
    (setq *break-step* 'break-step-finish)
    :resume))


(defun maybe-break (form line-info fun env &aux (pos (position form line-info)))
  (when pos
    (setq *break-step* nil)
    (unless (plusp (length *break-points*))
      (setf *break-points* nil))
    (break-level (make-break-point fun line-info pos) env)
    t))

;; These following functions, when they are the value of *break-step*
;; are invoked by an inner hook in eval.   They may choose to stop
;; things.

(defvar *break-instep* nil)

(defun break-step-into (form env)
  (unless *break-instep*
    (let* ((*break-instep* t)
	   (fun (car (current-step-fun))))
      (if fun
	  (maybe-break form (get fun 'line-info) fun env)
	  (setq *break-step* nil)))))

(defun break-step-next (form env)
  (unless *break-instep*
    (let* ((*break-instep* t)
	   (fun (current-step-fun)))
      (if fun
	  (when (eql (caddr *step-next*) (cadr fun))
	    (maybe-break form (get (car fun) 'line-info) (car fun) env))
	  (setq *break-step* nil)))))

 (defun break-step-finish (form env)
  (unless *break-instep*
    (let* ((*break-instep* t)
	   (fun (current-step-fun)))
      (if fun
	  (when (< (cadr fun) (caddr *step-finish*))
	    (maybe-break form (get (car fun) 'line-info) (car fun) env))
	  (setq *break-step* nil)))))

(setf (get :next 'break-command) 'step-next)
(setf (get :step 'break-command) 'step-into)
(setf (get :loc 'break-command) 'loc)
(setf (get :fin 'break-command) 'step-finish)
(setf (get :finish 'break-command) 'step-finish)

(defun break-display (&rest r)
  (setq *step-display* (append r *step-display*)))
(setf (get :dis 'break-command) 'break-display)
(setf (get :display 'break-command) 'break-display)

(defun break-undisplay (&rest r)
  (setq *step-display* (set-difference *step-display* r :test 'equal)))
(setf (get :undis 'break-command) 'break-undisplay)
(setf (get :undisplay 'break-command) 'break-undisplay)

(defun *break-points* (form  env) 
  (let ((pos(position form *break-points* :key 'car)))
    (format t "Bkpt ~a:" pos)
    (break-level  (aref *break-points* pos) env)))


(defun dwim (fun)
  (dolist (v (list-all-packages))
    (multiple-value-bind
     (sym there)
     (intern (symbol-name fun) v)
     (cond ((get sym 'line-info)
	    (return-from dwim sym))
	   (t (or there (unintern sym))))))
  (format t "~a has no line information" fun))

(defun break-function (fun &optional (li 1)  absolute  &aux fun1)
  (let ((ar (get fun 'line-info)))
    (when (null ar) (setq fun1 (dwim fun))
	  (if fun1 (return-from break-function
				(break-function fun1 li absolute))))
    (or (arrayp ar)(progn (format t "~%No line info for ~a" fun)
			  (return-from break-function nil)))
    (let ((beg (cdr (aref ar 0))))
      (if absolute (setq li (f - li beg)))
      (or (and (fb >= li 1) (fb < li (length ar)))
	  (progn (format t "~%line out of bounds for ~a" fun))
	  (return-from break-function nil))
      (if (eql li 1)
	  (let ((tem (symbol-function fun)))
	    (cond ((and (consp tem)
			(eq (car tem) 'lambda-block)
			(third tem))
		   (setq li 2)))))
      (dotimes (i (f - (length ar) li))
	       (when (not (eq (aref ar i) :blank-line))
		 (show-break-point (insert-break-point
				    (make-break-point fun ar (f + li i))))
		 (return-from break-function (values))))
      (format t "~%Beyond code for ~a "))))

(defun insert-break-point (bpt &aux at)
  (or *break-points* (init-break-points))
  (setq at (or (position nil *break-points*)
	       (prog1 (length *break-points*)
		 (vector-push-extend  nil *break-points*)
		 )))
  (let ((fun (bkpt-function bpt)))
    (push at (get fun 'break-points)))
  (setf (aref *break-points* at) bpt)
  at)

(defun short-name (name)
  (let ((Pos (position #\/ name :from-end t)))
    (if pos (subseq name (f + 1 pos)) name)))

(defun show-break-point (n &aux disabled)
  (let ((bpt (aref *break-points* n)))
    (when bpt
      (when (eq (car bpt) nil)
	(setq disabled t)
	(setq bpt (cdr bpt)))
      (format t "Bkpt ~a:(~a line ~a)~@[(disabled)~]"
	      n (short-name (second bpt))
	      (third bpt) disabled)
      (let ((fun (fourth bpt)))
	(format t "(line ~a of ~a)"  (relative-line fun (nth 2 bpt))
		fun
		)))))

(defun iterate-over-bkpts (l action)
  (dotimes (i (length *break-points*))
	   (if (or (member i l)
		   (null l))
	       (let ((tem (aref *break-points* i)))
		 (setf (aref *break-points* i)
		       (case action
			 (:delete
			  (if tem (setf (get (bkpt-function tem) 'break-points)
					(delete i (get (bkpt-function tem) 'break-points))))
			  nil)
			 (:enable
			  (if (eq (car tem) nil) (cdr tem) nil))
			 (:disable
			  (if (and tem (not (eq (car tem) nil)))
			      (cons nil tem)
			    tem))
			 (:show
			  (when tem (show-break-point i)
				(terpri))
			  tem
			  )))))))

(setf (get :info 'break-command)
      '(lambda (type)
	 (ecase type
	   (:bkpt  (iterate-over-bkpts nil :show))
	   ((:dis :display) (format t "Displaying ~s~%" *step-display*)))))

(defun complete-prop (sym package prop &optional return-list)
  (cond ((and (symbolp sym)(get sym prop)(equal (symbol-package sym)
						 (find-package package)))
	 (return-from complete-prop sym)))
  (sloop for v in-package package 
	 when (and (get v prop)
		   (eql (string-match sym v) 0))
	 collect v into all
	 finally
       
         (cond (return-list (return-from complete-prop all))
               ((> (length all) 1)
	                (format t "~&Not unique with property ~(~a: ~{~s~^, ~}~)."
			prop all))

		       ((null all)
			(format t "~& ~a is not break command" sym))
		       (t (return-from complete-prop
				       (car all))))))

(setf (get :delete 'break-command)
      '(lambda (&rest l) (iterate-over-bkpts l :delete)(values)))
(setf (get :disable 'break-command)
      '(lambda (&rest l) (iterate-over-bkpts l :disable)(values)))
(setf (get :enable 'break-command)
      '(lambda (&rest l) (iterate-over-bkpts l :enable)(values)))
(setf (get :break 'break-command)
      '(lambda (&rest l)
	 (print l)
	 (cond (l
		(apply 'si::break-function l))
	       (*last-dbl-break*
		(let ((fun  (nth 3 *last-dbl-break*)))
		  (si::break-function fun (nth 2 *last-dbl-break*) t))))))

(setf (get :fr 'break-command)
      '(lambda (&rest l )
	 (dbl-up (or (car l) 0) *ihs-top*)
	 (values)))

(setf (get :up 'break-command)
      '(lambda (&rest l )
	 (dbl-up (or (car l) 1) *current-ihs*)
	 (values)))

(setf (get :down 'break-command)
      '(lambda (&rest l )
	 (dbl-up ( - (or (car l) 1)) *current-ihs*)
	 (values)))

;; in other common lisps this should be a string output stream.

(defvar *display-string*
  (make-array 100 :element-type 'character :fill-pointer 0 :adjustable t))

(defun display-env (n env)
  (do ((v (reverse env) (cdr v)))
      ((or (not (consp v)) (fb > (fill-pointer *display-string*) n)))
    (or (and (consp (car v))
	     (listp (cdar v)))
	(return))
    (format *display-string* "~s=~s~@[,~]" (caar v) (cadar v) (cdr v))))

(defun apply-display-fun (display-fun  n lis)  
  (let ((*print-length* *debug-print-level*)
	(*print-level* *debug-print-level*)
	(*print-pretty* nil)
	(*PRINT-CASE* :downcase)
	(*print-circle* t)
	)
    (setf (fill-pointer *display-string*) 0)
    (format *display-string* "{")
    (funcall display-fun n lis)
    (when (fb > (fill-pointer *display-string*) n)
      (setf (fill-pointer *display-string*) n)
      (format *display-string* "..."))

    (format *display-string* "}")
    )
  *display-string*
  )

(setf (get :bt 'break-command) 'dbl-backtrace)
(setf (get '*break-points* 'dbl-invisible) t)

(defun get-line-of-form (form line-info)
  (let ((pos (position form line-info)))
    (if pos (f + pos (cdr (aref line-info 0))))))

(defun get-next-visible-fun (ihs)
  (do ((j  ihs (f - j 1)))
      ((fb < j *ihs-base*)
       (mv-values nil j))
    (let
	((na  (ihs-fname j)))
      (cond ((special-operator-p na))
	    ((get na 'dbl-invisible))
	    ((fboundp na)(return (mv-values na j)))))))

(defun dbl-what-frame (ihs &aux (j *ihs-top*) (i 0) na)
  (declare (fixnum ihs j i) (ignorable na))
  (loop
   (mv-setq (na j)   (get-next-visible-fun j))
   (cond ((fb <= j ihs) (return i)))
   (setq i (f + i 1))
   (setq j (f -  j 1))))

(defun dbl-up (n ihs &aux m fun line file env )
  (setq m (dbl-what-frame ihs))
  (cond ((fb >= n 0)
	 (mv-setq (*current-ihs*  n  fun line file env)
		  (nth-stack-frame n ihs))
	 (set-env)
	 (print-stack-frame (f + m n) t *current-ihs* fun line file env))
	(t (setq n (f + m n))
	   (or (fb >= n 0) (setq n 0))
	   (dbl-up n *ihs-top*))))
	
(dolist (v '(break-level universal-error-handler terminal-interrupt
	     break-level evalhook find-line-in-fun maybe-break
	     break-step-next break-step-into))
  (setf (get v 'dbl-invisible) t))

(defun get-lower-line-info (n i &aux (f (get n 'line-info)))
  (do* ((j (+ i 2) (1- j))
	(k nil (get-line-of-form (ihs-fun j) f)))
       ((or k (<= j i)) (when k (list f k j)))))

(defun next-stack-frame (ihs &aux line-info li n i k na)
  (mv-setq (n i) (get-next-visible-fun ihs))
  (cond
    ((not n) (mv-values nil nil nil nil nil))
    ((special-operator-p n))
    (t (let* ((llf (get-lower-line-info n i))
	      (line-info (pop llf)))
	 (mv-values
	  i n (pop llf)
	  (when line-info (car (aref line-info 0)))
	  (ihs-env (or (car llf) i)))))))

(defun nth-stack-frame (n &optional (ihs *ihs-top*)
			  &aux  name line file env next)
  (or (fb >= n 0) (setq n 0))
  (dotimes (i (f + n 1))
	   (setq next (next-stack-frame ihs))
	   (cond (next
		  (mv-setq (ihs name line file env) next)
		  (setq ihs (f - next 1)))
		 (t (return (setq n (f - i 1))))))
  
  (setq ihs (f + ihs 1) name (ihs-fname ihs))
  (mv-values ihs n name line file env ))

(defun dbl-backtrace (&optional (m 1000) (ihs *ihs-top*) &aux fun  file
				line env (i 0))
  (loop
   (mv-setq  (ihs fun line file  env)  (next-stack-frame ihs))
   (or (and ihs fun) (return nil))
   (print-stack-frame i nil ihs fun line file env)
   (incf i)
   (cond ((fb >= i m) (return (values))))
   (setq ihs (f - ihs 1))
   )
  (values))

(defconstant +lsym-cdr-alist+ '((lambda . 0)(lambda-closure . 3)(lambda-block-closure . 4)(lambda-block . 1)))

(deftype lambda-syms nil '(and gsym #.`(member ,@(mapcar 'car +lsym-cdr-alist+))))

(defun ihs-fname (ihs-index &aux (fun (ihs-fun ihs-index)));FIXME
  (typecase fun
    (symbol fun)
    (compiled-function (fun-name fun))
    ((cons lambda-syms t)
     (get-blocked-body-name (nthcdr (cdr (assoc (car fun) +lsym-cdr-alist+)) fun)))
    ((cons (and symbol (or (satisfies special-operator-p) (satisfies fboundp))) t)
     (car fun))
    (t :zombi)))

  ;; When running interpreted we want a line like
  ;; (list joe jane) to get recorded in the invocation
  ;; history while joe and jane are being evaluated,
  ;; even though list has not yet been invoked.   We put
  ;; it in the history, but with the previous lexical environment.
(defun computing-args-p (ihs)
  (when (> ihs 3)
    (typecase (ihs-fun ihs)
      ((cons (not lambda-syms) t) t))))


(defun print-stack-frame (i auto-display ihs fun &optional line file env)
  (declare (ignore env))
  (when (and auto-display line)
    (format *debug-io* "~a:~a:0:beg~%" file line))
  (let  ((computing-args (computing-args-p ihs)))
    (format *debug-io* "~&#~d  ~@[~a~] ~a ~@[~a~] " i
	    (and computing-args "Computing args for ")
	    fun
	    (apply-display-fun 'display-env 80 (car (ihs-env ihs))))
    (if file (format *debug-io* "(~a line ~a)" file line))
    (format *debug-io* "[ihs=~a]"  ihs)))

(defun make-break-point (fun ar i)
  (list					;make-bkpt	;:form
   (aref ar i)
					;:file
   (car (aref ar 0))
					;:file-line
   (f + (cdr (aref  ar 0)) i)
					;:function
   fun)
  )

(defun relative-line (fun l)
  (let ((info (get fun 'line-info)))
    (if info (f - l (cdr (aref info 0)))
      0)))

(defvar *step-display* nil)

(defvar *null-io* (make-broadcast-stream))
;; should really use serror to evaluate this inside.
;; rather than just quietening it.   It prints a long stack
;; which is time consuming.

(defun safe-eval (form env &aux *break-enable*)
  (let ((*error-output* *null-io*)
	(*debug-io* *null-io*))
    (cond ((symbolp form)
	   (unless (or (boundp form)
		       (assoc form (car env)))
		   (return-from safe-eval :<error>))))
    (multiple-value-bind (er val)
			 (si::error-set
			  `(evalhook ',form nil nil ',env))
			 (if er :<error> val))))

(defvar *no-prompt* nil)

(defun break-form (&rest l &aux ihs)
  (mv-setq (ihs) (if l (nth-stack-frame (car l) *ihs-top*) *current-ihs*))
  (cons (ihs-fname ihs) (ihs-args ihs)))
(putprop :form 'break-form 'break-command)

(defun ihs-args (ihs)
  (if (ihs-not-interpreted-env ihs)
      (labels ((aa (i)
		 (when (< i (ihs-vstop ihs))
		   (cons (vs i) (aa (1+ i))))))
	(aa (ihs-vs ihs)))
      (let* ((fun (ihs-fun ihs))
	     (env (when (eq (car fun) 'lambda-closure) (cadr fun))))
	(mapcar 'cadr
		(remove-if (lambda (x) (member (car x) env :key 'car))
			   (reverse (vs (ihs-vs ihs))))))))

(defun ihs-current-step-fun nil
  (let ((nm (car (current-step-fun))))
    (labels ((s (i) (when (plusp i)
		      (if (eq nm (ihs-fname i)) i
			  (s (1- i))))))
      (s *current-ihs*))))


(defun set-back (at env &aux (i (ihs-current-step-fun)))
  (setq *no-prompt* nil)
  (setq *current-ihs* i)
  (cond (env   (setq *break-env* env))
	(t (list   (vs (ihs-vs i)))))
  
  (when (consp at)
    (format *debug-io* "~a:~a:0:beg~%" (second at) (third at))
    (format *debug-io* "(~a line ~a) "
	    (second at)  (third at))
    )
  (dolist (v *step-display*)
    (let ((res (safe-eval v env)))
      (or (eq res :<error>)
	  (format t "(~s=~s)" v res)))))


(eval-when (load eval)
  (pushnew :sdebug *features* )
					;(use-fast-links nil)
  )









