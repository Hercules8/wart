cell* eval(string s) {
  TEMP(form, read(s));
  return eval(form);
}

void test_fn_works() {
  TEMP(result, eval("(fn(x) x)"));
  // (object function {sig: (x), body: (x)})
  CHECK(is_object(result));
  CHECK_EQ(type(result), sym_function);
  CHECK_EQ(car(get(rep(result), sym_sig)), new_sym("x"));
  CHECK_EQ(cdr(get(rep(result), sym_sig)), nil);
  CHECK_EQ(car(get(rep(result), sym_body)), new_sym("x"));
  CHECK_EQ(cdr(get(rep(result), sym_body)), nil);
}



void test_if_sees_args_in_then_and_else() {
  run("(<- f (fn(x) (if 34 x)))");
  CLEAR_TRACE;
  run("(f 35)");
  CHECK_TRACE_TOP("eval", "=> 35\n");
  end_dynamic_scope("f");
}

void test_not_works() {
  run("(not 35)");
  CHECK_TRACE_TOP("eval", "compiled fn\n=> nil\n");
}

void test_not_works2() {
  run("(not nil)");
  CHECK_TRACE_TOP("eval", "compiled fn\n=> 1\n");
}

void test_cons_works() {
  run("(cons 1 2)");
  CHECK_TRACE_TOP("eval", "compiled fn\n=> (1 ... 2)\n");
}

void test_assign_to_non_sym_warns() {
  run("(<- 3 nil)");
  CHECK_EQ(Raise_count, 1);   Raise_count=0;
}

void test_assign_lexical_var() {
  run("((fn (x) (<- x 34) x))");
  CHECK_TRACE_TOP("eval", "=> 34\n");
}

void test_assign_overrides_dynamic_vars() {
  run("(<- x 3)");
  run("(<- x 5)");
  CLEAR_TRACE;
  run("x");
  CHECK_TRACE_TOP("eval", "sym\n=> 5\n");
  end_dynamic_scope("x");
}

void test_assign_overrides_within_lexical_scope() {
  run("(<- x 3)");
  run("((fn () (<- x 5)))");
  CLEAR_TRACE;
  run("x");
  CHECK_TRACE_TOP("eval", "sym\n=> 5\n");
  end_dynamic_scope("x");
}

void test_assign_never_overrides_lexical_vars_in_caller_scope() {
  run("((fn (x) (<- y x)) 34)");
  CLEAR_TRACE;
  run("y");
  CHECK_TRACE_CONTENTS("eval", "sym\n=> 34\n");
  end_dynamic_scope("y");
}

void test_assign_overrides_lexical_var() {
  run("((fn (x) (<- x 35) (<- x 36) x) 34)");
  CHECK_TRACE_TOP("eval", "=> 36\n");
}

void test_unbind_works() {
  new_dynamic_scope("x", new_num(3));
  CHECK_EQ(Dynamics[new_sym("x")].size(), 1);
  cell* expr = read("(unbind x)");
  eval(expr);   // always returns nil
  CHECK_EQ(Dynamics[new_sym("x")].size(), 0);
  rmref(expr);
}

void test_unbind_handles_unbound_vars() {
  CHECK_EQ(Dynamics[new_sym("x")].size(), 0);
  cell* expr = read("(unbind x)");
  eval(expr);   // always returns nil
  CHECK_EQ(Dynamics[new_sym("x")].size(), 0);
  rmref(expr);
}

void test_bound_works() {
  cell* call = read("(bound? 'a)");
  cell* result1 = eval(call);
  CHECK_EQ(result1, nil);
  new_dynamic_scope("a", new_num(3));
  cell* result2 = eval(call);
  CHECK_EQ(result2, new_sym("a"));
  rmref(result2);
  end_dynamic_scope("a");
  rmref(result1);
  rmref(call);
}

void test_equal_handles_nil() {
  run("(= nil nil)");
  CHECK_TRACE_DOESNT_CONTAIN("eval", 1, "=> nil\n");
}

void test_equal_handles_floats() {
  run("(= (/ 3.0 2) 1.5)");
  CHECK_TRACE_DOESNT_CONTAIN("eval", 1, "=> nil\n");
}

void test_equal_handles_float_vs_nil() {
  run("(= nil 1.5)");
  CHECK_EQ(Raise_count, 0);
  CHECK_TRACE_TOP("eval", "compiled fn\n=> nil\n");
}

void test_eval_handles_eval() {
  new_dynamic_scope("a", new_num(34));
  new_dynamic_scope("x", new_sym("a"));
  cell* call = read("(eval x)");
  cell* result = eval(call);
  CHECK_EQ(result, new_num(34));
  rmref(result);
  rmref(call);
  end_dynamic_scope("x");
  end_dynamic_scope("a");
}

