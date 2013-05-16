void test_lookup_returns_dynamic_binding() {
  Cell* sym = newSym("a");
  Cell* val = newNum(34);
  newBinding(sym, val);
  CHECK_EQ(lookup(sym), val);
}
