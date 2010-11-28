;; Wart transformer lets us override lisp keywords.

(defun wrepl()
  (loop
    (unless *batch-mode*
      (format t "wart> ")(finish-output))
    (format t "~a~%" (wt-eval (read)))))

(unless (boundp '*batch-mode*)
  (setf *batch-mode* nil))

; To override a lisp keyword, write it as a macro with a different name, then
; register the macro with the right name.

; In return for being able to override keywords you can't use keywords anywhere
; in the program. Not even inside quoted expressions. Otherwise we can't
; handle backquoted expressions.

; intentionally ugly name; minimize its use
(defmacro defover(name new-name)
  `(progn
     (setf (gethash ',name *wart-special-form-handlers*)
           (lambda(_)
             (cons ',new-name (cdr _))))
     (setf (gethash ',name *wart-special-form-quoted-handlers*)
           ',new-name)))

(defun wload(file)
  (with-open-file (f (merge-pathnames file))
    (loop with form = (read f)
          and eof = (gensym)
      do
        (wt-eval form)
        (setq form (read f nil eof))
      until (is form eof))))



;; Internals

(defun wt-eval(sexp)
  (eval (wt-transform sexp)))

(defun wt-transform(sexp)
  (apply-to-all #'wt-transform-1 sexp))

(defun wt-transform-1(sexp)
  (cond
    ((no sexp)                        sexp)
    ((ssyntaxp sexp)                  (expand-ssyntax sexp))
    ((atom sexp)                      sexp)
    ((and (is 'quote (car sexp))
          (no (caddr sexp)))
                                      (list 'quote (lookup-quoted-handler (cadr sexp))))
    ((lookup-unquoted-handler sexp)   (call (lookup-unquoted-handler sexp) sexp))
    (t sexp)))

(defun lookup-unquoted-handler(sexp)
  (or (gethash (car sexp) *wart-special-form-handlers*)
      (gethash (type-of (car sexp)) *wart-type-handlers*)))

(defun lookup-quoted-handler(name)
  (or (gethash name *wart-special-form-quoted-handlers*)
      (gethash (type-of name) *wart-type-quoted-handlers*)
      name))

; handlers are functions of the input s-expr
(defvar *wart-special-form-handlers* (make-hash-table))
(defvar *wart-type-handlers* (make-hash-table))
; quoted handlers are names of the handlers; all handlers must be named
(defvar *wart-special-form-quoted-handlers* (make-hash-table))
(defvar *wart-type-quoted-handlers* (make-hash-table))

(defun apply-to-all(f sexp)
  (cond
    ((no sexp)  nil)
    ((atom sexp)  (call f sexp))
    (t   (call f
               (cons (apply-to-all f (car sexp))
                     (apply-to-all f (cdr sexp)))))))
