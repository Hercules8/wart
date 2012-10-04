//// transform infix expressions into prefix
const string extraSymChars = "$?!_";

AstNode transformInfix(AstNode n) {
  if (infixOpCalledWithoutArgs(n))
    return *++n.elems.begin();

  if (n.isAtom() && !containsInfixChar(n.atom.token))
    return n;

  if (n.isAtom() && n.atom.token[0] == '\"')
    return n;

  if (n.isAtom() && parseableAsFloat(n.atom.token))
    return n;

  if (n.isAtom())
    n = tokenizeInfix(n);

  if (n.elems.front() != Token("("))
    return transformAll(n);

  if (n.elems.size() == 2)
    return n;   // must be ()

  int oldsize = n.elems.size();

  // now n is guaranteed to have at least 3 ops
  // slide a window of 3, pinching into s-exprs when middle elem is an op
  auto prev = n.elems.begin();
  auto curr=prev; ++curr;
  auto next=curr; ++next;
  for (; next != n.elems.end(); ++prev, ++curr, ++next) {
    *curr = transformInfix(*curr);
    if (!curr->isAtom() || !isInfixOp(curr->atom.token)) continue;
    if (prev == n.elems.begin()) continue;  // prefix op
    if (next == --n.elems.end()) continue;  // postfix op
    list<AstNode> tmp;
    tmp.push_back(*curr);  // op
    tmp.push_back(*prev);
    tmp.push_back(transformInfix(*next));
    // parens
    tmp.push_front(AstNode(Token("(")));
    tmp.push_back(AstNode(Token(")")));
    // insert the new s-expr
    *curr = AstNode(tmp);
    // update other iterators
    n.elems.erase(prev);
    prev=curr; --prev;
    n.elems.erase(next);
    next=curr; ++next;
  }

  // (a + b) will have become ((+ a b)); strip out one pair of parens
  if (n.elems.size() == 3 && oldsize > 3)
    return *++n.elems.begin();

  return n;
}

AstNode transformAll(AstNode n) {
  if (n.isAtom()) return n;
  list<AstNode> results;
  for (auto p = n.elems.begin(); p != n.elems.end(); ++p)
    results.push_back(transformInfix(*p));
  n.elems.swap(results);
  return n;
}

AstNode tokenizeInfix(AstNode n) {
  string var = n.atom.token;
  string out;
  out += var[0];
  for (size_t x = 1; x < var.size(); ++x) {
    if ((isInfixChar(var[x]) && isRegularChar(var[x-1])
            // special-case: dollarvar
            && var[x-1]!='$')
        ||
        (isRegularChar(var[x]) && isInfixChar(var[x-1])
            // special-case: ssyntax followed by negative number
            && (x <= 1 || !find(ssyntaxChars, var[x-2]) || var[x-1] != '-' || !isdigit(var[x]))))
      out += " ";
    out += var[x];
  }
  CodeStream cs(stream(out));
  return nextAstNode(cs);
}



bool isInfixOp(string name) {
  string::iterator p = name.begin();
  if (*p != '$' && !isInfixChar(*p))
    return false;
  for (++p; p != name.end(); ++p)
    if (!isInfixChar(*p))
      return false;
  return true;
}

bool containsInfixChar(string name) {
  for (string::iterator p = name.begin(); p != name.end(); ++p) {
    if (p == name.begin() && *p == '-')
      continue;

    if (isInfixChar(*p)) return true;
  }
  return false;
}

bool isInfixChar(char c) {
  return !find(punctuationChars, c)
      && !find(quoteAndUnquoteChars, c) && !find(ssyntaxChars, c)
      && !isalnum(c) && !find(extraSymChars, c);
}

bool isRegularChar(char c) {
  return isalnum(c) || find(extraSymChars, c);
}

bool infixOpCalledWithoutArgs(AstNode n) {
  if (!n.isList() || n.elems.size() != 3) return false;
  list<AstNode>::iterator p = n.elems.begin();
  if (*p != Token("(")) return false;
  ++p;
  if (!p->isAtom() || !isInfixOp(p->atom.token))
    return false;
  ++p;
  return *p == Token(")");
}

bool parseableAsFloat(string s) {
  errno = 0;
  char* end = NULL;
  strtof(s.c_str(), &end);
  return *end == '\0' && errno == 0;
}