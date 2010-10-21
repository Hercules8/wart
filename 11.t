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

(test-wc "rest args are optional"
  :valueof (foo7 3)
  :should be nil)

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

(test-wc "partition-keywords siphons keyword-arg val pairs into a hash table"
  :valueof (partition-keywords '(1 2 :c 3))
  :should be (list '(1 2) '((c . 3))))

(test-wc "merge-keyword-vars takes args from list giving priority to hash"
  :valueof (merge-keyword-vars '(1 3) '((b . 2)) '(a b c))
  :should be '(1 2 3))

(test-wc "merge-keyword-vars is idempotent with non-keyword args"
  :valueof (merge-keyword-vars '(1 2 3) () '(a b c))
  :should be '(1 2 3))

(test-wc "merge-keyword-vars is idempotent with non-keyword dotted args"
  :valueof (merge-keyword-vars '(1 2) () '(a . b))
  :should be '(1 2))

(test-wc "merge-keyword-vars is idempotent with non-keyword rest args"
  :valueof (merge-keyword-vars '(1 2) () '(a &rest b))
  :should be '(1 2))

(test-wc "wc-complex-bind handles an optional keyword param"
  :valueof (wc-complex-bind (a) '(:a 1) a)
  :should be 1)

(eval (wc '(def foo11(a b) (- a b))))
(test-wc "allow param names"
  :valueof (foo11 :a 3 :b 4)
  :should be -1)

(test-wc "allow just some param names"
  :valueof (foo11 :a 3 4)
  :should be -1)

(test-wc "allow args in any order when giving param names"
  :valueof (foo11 :b 3 :a 4)
  :should be 1)

(test-wc "take positional args in order after keyword args have been matched"
  :valueof (foo11 3 :a 4)
  :should be 1)

(test-wc "strip-default-values works"
  :valueof (strip-default-values '(a (b 2)))
  :should be '(a b))

(test-wc "strip-default-values works when the default val is nil"
  :valueof (strip-default-values '(a (b nil)))
  :should be '(a b))

(test-wc "strip-default-values passes through expressions needing destructuring"
  :valueof (strip-default-values '(a (b c)))
  :should be '(a (b c)))

(test-wc "simplify-arg-list passes lists through by default"
  :valueof (simplify-arg-list '(a b))
  :should be '(a b))

(test-wc "simplify-arg-list strips default values"
  :valueof (simplify-arg-list '(a (b 2)))
  :should be '(a b))

(test-wc "simplify-arg-list works on dotted lists"
  :valueof (simplify-arg-list '(a . b))
  :should be '(a &rest b))

(test-wc "add-optional-vars works"
  :valueof (add-optional-vars '(a (b 2)) ())
  :should be '((b . 2)))

(test-wc "add-optional-vars doesn't override existing vals"
  :valueof (add-optional-vars '(a (b 2)) '((b . 1)))
  :should be '((b . 1)))

(eval (wc '(def foo12(a (b nil)) (cons a b))))
(test-wc "optional param"
  :valueof (foo12 3)
  :should be '(3))

(eval (wc '(def foo13(a (b 4)) (cons a b))))
(test-wc "optional param with a default"
  :valueof (foo13 3)
  :should be '(3 . 4))

(test-wc "optional named arg"
  :valueof (foo13 :a 3)
  :should be '(3 . 4))

(test-wc "distinguish destructured from optional params"
  :valueof ((fn((a b)) (list a b)) '(1 (2)))
  :should be '(1 (2)))

(test-wc "distinguish destructured from optional params - 2"
  :valueof ((fn((a (b))) (list a b)) '(1 (2)))
  :should be '(1 2))
