(load "bdd.lisp")

(defun foo() 34)
(test-wc "simple defun"
  :valueof (foo)
  :should be 34)

(progn
  (defun foo0() 3)
  (defun foo1() (+ 1 (foo0))))
(test-wc "nested defuns"
  :valueof (foo1)
  :should be 4)

(progn
  (defmacro foo2(n) `(+ 1 ,n))
  (defmacro foo3(n) `(+ 1 (foo2 ,n))))
(test-wc "nested macros"
  :valueof (foo3 2)
  :should be 4)

(eval (wc '(def foo4() 34)))
(test-wc "simple def"
  :valueof (foo4)
  :should be 34)

(eval (wc '(mac foo5(n) `(+ ,n 1))))
(test-wc "simple mac"
  :valueof (foo5 32)
  :should be 33)

(eval (wc '(def foo6() (cons 3 4))))
(test-wc "def 2"
  :valueof (foo6)
  :should be (cons 3 4))

(eval (wc '(def foo7(a . b) b)))
(test-wc "dotted rest"
  :valueof (foo7 3 4)
  :should be '(4))

(test-wc "wc-destructuring-bind handles plain vars"
  :valueof (wc-destructuring-bind a 1 a)
  :should be 1)

(test-wc "wc-destructuring-bind handles nested lists"
  :valueof (wc-destructuring-bind (a) '(1) a)
  :should be 1)

(test-wc "wc-destructuring-bind handles empty lists"
  :valueof (wc-destructuring-bind (a) '() a)
  :should be nil)

(test-wc "wc-destructuring-bind handles lists"
  :valueof (wc-destructuring-bind ((a b) (c d)) '((1 2) (3 4)) c)
  :should be 3)

(test-wc "wc-destructuring-bind handles &rest"
  :valueof (wc-destructuring-bind (&rest b) '(1) b)
  :should be '(1))

(test-wc "wc-destructuring-bind handles destructured args + rest"
  :valueof (wc-destructuring-bind ((a b) (c d) &rest e) '((1 2) (3 4) 5 6 7) (cons c e))
  :should be '(3 5 6 7))

(eval (wc '(def foo8((a b)) b)))
(test-wc "destructured args"
  :valueof (foo8 '(3 4))
  :should be 4)

(eval (wc '(def foo9((a b) . c) b)))
(test-wc "destructured args + dotted rest"
  :valueof (foo9 '(3 4) 5)
  :should be 4)

(test-wc "destructured args + dotted rest for fn"
  :valueof ((fn ((a b) . c) b) '(3 4) 5)
  :should be 4)

(test-wc "alternative syntax for fn"
  :valueof ([+ _ 1] 3)
  :should be 4)

(setq foo10 (lambda() 3))
(test-wc "no need for funcall on function atoms"
  :valueof (foo10)
  :should be 3)

(test-wc "no need for funcall on function forms"
  :valueof ((lambda() 3))
  :should be 3)

(test-wc "no need for funcall on function forms with args"
  :valueof ((lambda(a) (+ a 3)) 2)
  :should be 5)

(test-wc "non-top-level calls require funcall"
  :valueof (wc-let a 1 (funcall (fn() a)))
  :should be 1)

(pending-test-wc "no need for funcall with non-top-level function forms"
  :valueof (wc-let a 1 ((fn() a)))
  :should be 1)

(test-wc "remove-if-cons works"
  :valueof (remove-if-cons #'oddp '(1 2 3 4))
  :should be '(2 4))

(test-wc "remove-if-cons works on dotted lists"
  :valueof (remove-if-cons #'oddp '(1 2 3 . 4))
  :should be '(2 . 4))

(test-wc "remove-if-cons works on dotted lists with passing rest"
  :valueof (remove-if-cons #'evenp '(1 2 3 . 4))
  :should be '(1 3))

(test-wc "remove-if-cons works on dotted lists with nil rest"
  :valueof (remove-if-cons #'evenp '(1 2 3 . nil))
  :should be '(1 3))

(test-wc "wc-complex-bind handles simple args"
  :valueof (wc-complex-bind (a b) '(1 2) b)
  :should be 2)

(test-wc "wc-complex-bind handles dotted rest args"
  :valueof (wc-complex-bind (a . b) '(1 2 3) b)
  :should be '(2 3))

(test-wc "wc-complex-bind handles destructured args"
  :valueof (wc-complex-bind ((a b)) '((1 2)) b)
  :should be 2)

(test-wc "wc-complex-bind handles destructured args + dotted rest"
  :valueof (wc-complex-bind ((a b) . c) '((1 2) 3) (cons b c))
  :should be '(2 3))

(test-wc "strip-lambda-keywords works"
  :valueof (strip-lambda-keywords '(a &rest b))
  :should be '(a b))
