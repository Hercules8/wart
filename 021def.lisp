(setf wart-signatures* (table))

(defmacro$ def(name params &body body)
  `(progn
    (push (list (length-matcher ',params)
                (fn ,params
                  (handling-$vars ,@body)))
          (gethash ',name wart-signatures*))
    (defun$ ,name(&rest ,$args)
      (call-correct-variant (gethash ',name wart-signatures*)
                            ,$args))))

(defmacro proc(name params . body)
  `(def ,name ,params ,@body nil))

(defmacro redef(name params &body body)
  `(ignore-redef
     (setf (gethash ',name wart-signatures*) nil)
     (def ,name ,params ,@body)))



;; Internals

(defun call-correct-variant(variants args)
  (if variants
    (destructuring-bind (test func) (car variants)
      (if (or (singlep variants)
              (apply test args))
        (apply func args)
        (call-correct-variant (cdr variants) args)))))

(defun length-matcher(params)
  (fn args
    (let* ((args (remove-if [kwargp params _] args))
           (req  (required-params params))
           (rest (rest-param params))
           (opt  (map 'list 'car (optional-alist params))))
      (if rest
        (>= (length args) (length req))
        (>= (+ (length req) (length opt))
            (length args)
            (length req))))))
