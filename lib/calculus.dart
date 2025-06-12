// calculus_functions.dart
import 'dart:math';

class Token {
  String value;
  bool isOperator;
  bool isVariable;
  bool isNumber;

  Token(this.value, this.isOperator, this.isVariable, this.isNumber);
}

class ExprPart {
  List<Token> expr;
  bool isNumber;
  double numValue;

  ExprPart(this.expr, [this.isNumber = false, this.numValue = 0.0]);
}

class TermDeriv {
  List<Token> term;
  List<Token> deriv;

  TermDeriv(this.term, this.deriv);
}

class ExprInfo {
  String expr;
  int precedence;
  bool isUnary;

  ExprInfo(this.expr, this.precedence, this.isUnary);
}

List<Token> tokenize(String expr) {
  List<Token> tokens = [];
  String current = "";
  bool expectUnary = true;
  int i = 0;

  while (i < expr.length) {
    if (expr[i].trim().isEmpty) {
      i++;
      continue;
    }

    if (expectUnary && (expr[i] == '+' || expr[i] == '-')) {
      String op = expr[i] == '-' ? "u-" : "u+";
      tokens.add(Token(op, true, false, false));
      i++;
      expectUnary = false;
      continue;
    }

    if (RegExp(r'\d').hasMatch(expr[i]) ||
        (expr[i] == '.' && i + 1 < expr.length && RegExp(r'\d').hasMatch(expr[i + 1]))) {
      current += expr[i++];
      while (i < expr.length &&
          (RegExp(r'\d').hasMatch(expr[i]) || expr[i] == '.')) {
        current += expr[i++];
      }
      tokens.add(Token(current, false, false, true));
      current = "";
      expectUnary = false;
      continue;
    }

    if (RegExp(r'[a-zA-Z]').hasMatch(expr[i])) {
      tokens.add(Token(expr[i], false, true, false));
      i++;
      expectUnary = false;
      continue;
    }

    if ("^*/+-()".contains(expr[i])) {
      tokens.add(Token(expr[i], true, false, false));
      i++;
      expectUnary = expr[i - 1] == '(' ||
          "^*/+-".contains(expr[i - 1]) ||
          expr[i - 1] == '^';
      continue;
    }

    i++;
  }

  return tokens;
}

List<Token> infixToPostfix(List<Token> tokens) {
  List<Token> output = [];
  List<Token> opStack = [];

  int precedence(String op) {
    if (op == "u-" || op == "u+") return 5;
    if (op == "^") return 4;
    if (op == "*" || op == "/") return 3;
    if (op == "+" || op == "-") return 2;
    return 0;
  }

  bool isRightAssoc(String op) => op == "^";

  for (Token token in tokens) {
    if (!token.isOperator) {
      output.add(token);
    } else if (token.value == "(") {
      opStack.add(token);
    } else if (token.value == ")") {
      while (opStack.isNotEmpty && opStack.last.value != "(") {
        output.add(opStack.removeLast());
      }
      if (opStack.isNotEmpty) opStack.removeLast();
    } else {
      while (opStack.isNotEmpty &&
          opStack.last.value != "(" &&
          (precedence(opStack.last.value) > precedence(token.value) ||
              (precedence(opStack.last.value) == precedence(token.value) &&
                  !isRightAssoc(token.value)))) {
        output.add(opStack.removeLast());
      }
      opStack.add(token);
    }
  }

  while (opStack.isNotEmpty) output.add(opStack.removeLast());
  return output;
}

String formatNumber(double num) {
  if (num == num.toInt()) return num.toInt().toString();
  String s = num.toStringAsFixed(6);
  int last = s.length - 1;
  while (last >= 0 && s[last] == '0') last--;
  if (last >= 0 && s[last] == '.') last--;
  return s.substring(0, last + 1);
}

List<Token> simplify(List<Token> tokens) {
  List<ExprPart> st = [];

  bool isZero(ExprPart p) => p.isNumber && p.numValue.abs() < 1e-10;
  bool isOne(ExprPart p) => p.isNumber && (p.numValue - 1.0).abs() < 1e-10;

  for (Token tok in tokens) {
    if (!tok.isOperator) {
      if (tok.isNumber) {
        double num = double.parse(tok.value);
        st.add(ExprPart([tok], true, num));
      } else {
        st.add(ExprPart([tok]));
      }
    } else if (tok.value == "u-") {
      if (st.isEmpty) continue;
      ExprPart a = st.removeLast();
      if (a.isNumber) {
        st.add(ExprPart([Token(formatNumber(-a.numValue), false, false, true)],
            true, -a.numValue));
      } else {
        List<Token> ne = [Token("u-", true, false, false)]..addAll(a.expr);
        st.add(ExprPart(ne));
      }
    } else {
      if (st.length < 2) continue;
      ExprPart b = st.removeLast(), a = st.removeLast();
      List<Token> newExpr = [];

      switch (tok.value) {
        case '+':
          if (isZero(a)) st.add(b);
          else if (isZero(b)) st.add(a);
          else if (a.isNumber && b.isNumber) {
            double num = a.numValue + b.numValue;
            st.add(ExprPart([Token(formatNumber(num), false, false, true)],
                true, num));
          } else {
            newExpr..addAll(a.expr)..addAll(b.expr)..add(Token("+", true, false, false));
            st.add(ExprPart(newExpr));
          }
          break;

        case '-':
          if (isZero(b)) st.add(a);
          else if (a.isNumber && b.isNumber) {
            double num = a.numValue - b.numValue;
            st.add(ExprPart([Token(formatNumber(num), false, false, true)],
                true, num));
          } else {
            newExpr..addAll(a.expr)..addAll(b.expr)..add(Token("-", true, false, false));
            st.add(ExprPart(newExpr));
          }
          break;

        case '*':
          if (isZero(a) || isZero(b)) {
            st.add(ExprPart([Token("0", false, false, true)], true, 0.0));
          } else if (isOne(a)) {
            st.add(b);
          } else if (isOne(b)) {
            st.add(a);
          } else if (a.isNumber && b.isNumber) {
            double num = a.numValue * b.numValue;
            st.add(ExprPart([Token(formatNumber(num), false, false, true)],
                true, num));
          } else {
            newExpr..addAll(a.expr)..addAll(b.expr)..add(Token("*", true, false, false));
            st.add(ExprPart(newExpr));
          }
          break;

        case '/':
          if (isZero(a)) {
            st.add(ExprPart([Token("0", false, false, true)], true, 0.0));
          } else if (isZero(b)) {
            throw Exception("Division by zero");
          } else if (isOne(b)) {
            st.add(a);
          } else if (a.isNumber && b.isNumber) {
            double num = a.numValue / b.numValue;
            st.add(ExprPart([Token(formatNumber(num), false, false, true)],
                true, num));
          } else {
            newExpr..addAll(a.expr)..addAll(b.expr)..add(Token("/", true, false, false));
            st.add(ExprPart(newExpr));
          }
          break;

        case '^':
          if (isZero(b)) {
            st.add(ExprPart([Token("1", false, false, true)], true, 1.0));
          } else if (isOne(b)) {
            st.add(a);
          } else if (isZero(a)) {
            st.add(ExprPart([Token("0", false, false, true)], true, 0.0));
          } else if (a.isNumber && b.isNumber) {
            double num = pow(a.numValue, b.numValue).toDouble();
            st.add(ExprPart([Token(formatNumber(num), false, false, true)],
                true, num));
          } else {
            newExpr..addAll(a.expr)..addAll(b.expr)..add(Token("^", true, false, false));
            st.add(ExprPart(newExpr));
          }
          break;

        default:
          newExpr..addAll(a.expr)..addAll(b.expr)..add(Token(tok.value, true, false, false));
          st.add(ExprPart(newExpr));
      }
    }
  }

  return st.isEmpty ? [Token("0", false, false, true)] : st.last.expr;
}

List<Token> differentiate(List<Token> postfix, String variable) {
  List<TermDeriv> diffStack = [];

  for (Token token in postfix) {
    if (!token.isOperator) {
      List<Token> deriv = [];
      if (token.isVariable) {
        deriv = (token.value == variable)
            ? [Token("1", false, false, true)]
            : [Token("0", false, false, true)];
      } else if (token.isNumber) {
        deriv = [Token("0", false, false, true)];
      }
      diffStack.add(TermDeriv([token], deriv));
    } else if (token.value == "u-") {
      TermDeriv a = diffStack.removeLast();
      List<Token> newDeriv = [...a.deriv, Token("u-", true, false, false)];
      diffStack.add(TermDeriv([], newDeriv));
    } else if (token.value == "+" || token.value == "-") {
      TermDeriv b = diffStack.removeLast();
      TermDeriv a = diffStack.removeLast();
      List<Token> newDeriv = [...a.deriv, ...b.deriv, Token(token.value, true, false, false)];
      diffStack.add(TermDeriv([], newDeriv));
    } else if (token.value == "*") {
      TermDeriv b = diffStack.removeLast();
      TermDeriv a = diffStack.removeLast();
      List<Token> t1 = [...a.deriv, ...b.term, Token("*", true, false, false)];
      List<Token> t2 = [...a.term, ...b.deriv, Token("*", true, false, false)];
      diffStack.add(TermDeriv([], [...t1, ...t2, Token("+", true, false, false)]));
    } else if (token.value == "^") {
      TermDeriv e = diffStack.removeLast();
      TermDeriv base = diffStack.removeLast();

      List<Token> derivTerm = [];
      if (e.term.length == 1 && e.term[0].isNumber) {
        double exponentValue = double.parse(e.term[0].value);
        double newExp = exponentValue - 1;
        derivTerm = [
          ...e.term,
          ...base.term,
          Token(formatNumber(newExp), false, false, true),
          Token("^", true, false, false),
          Token("*", true, false, false),
          ...base.deriv,
          Token("*", true, false, false),
        ];
      } else {
        derivTerm = [Token("0", false, false, true)];
      }
      diffStack.add(TermDeriv([...base.term, ...e.term, Token("^", true, false, false)], derivTerm));
    }
  }

  if (diffStack.isEmpty) return [Token("0", false, false, true)];
  return simplify(diffStack.last.deriv);
}

String tokensToString(List<Token> tokens) {
  List<ExprInfo> exprStack = [];

  int getPrec(String op) {
    if (op == "u-" || op == "u+") return 5;
    if (op == "^") return 4;
    if (op == "*" || op == "/") return 3;
    if (op == "+" || op == "-") return 2;
    return 0;
  }

  for (var token in tokens) {
    if (!token.isOperator) {
      exprStack.add(ExprInfo(token.value, 0, false));
    } else if (token.value == "u-" || token.value == "u+") {
      if (exprStack.isEmpty) continue;
      ExprInfo opnd = exprStack.removeLast();
      int prec = getPrec(token.value);
      String opChar = token.value == "u-" ? "-" : "+";
      bool needParen = opnd.precedence < prec ||
        (opnd.isUnary && opnd.precedence == prec);
      String e = needParen ? "$opChar(${opnd.expr})" : "$opChar${opnd.expr}";
      exprStack.add(ExprInfo(e, prec, true));
    } else {
      if (exprStack.length < 2) continue;
      ExprInfo r = exprStack.removeLast();
      ExprInfo l = exprStack.removeLast();
      int prec = getPrec(token.value);
      bool rightAssoc = token.value == "^";

      String lStr = (l.precedence != 0 &&
        (l.precedence < prec ||
          (l.precedence == prec && !rightAssoc)))
        ? "(${l.expr})"
        : l.expr;

      String rStr = (r.precedence != 0 &&
        (r.precedence < prec ||
          (r.precedence == prec && rightAssoc)))
        ? "(${r.expr})"
        : r.expr;

      exprStack.add(ExprInfo("$lStr ${token.value} $rStr", prec, false));
    }
  }

  if (exprStack.isEmpty) return "0";
  return exprStack.last.expr;
}

List<List<Token>> splitInfixTerms(List<Token> tokens) {
  List<List<Token>> terms = [];
  List<Token> current = [];
  List<Token> sign = [];

  for (var t in tokens) {
    if (t.value == "+" || t.value == "-") {
      if (current.isNotEmpty) {
        current.insertAll(0, sign);
        terms.add([...current]);
        current.clear();
        sign.clear();
      }
      if (t.value == "-") {
        sign = [Token("u-", true, false, false)];
      }
    } else {
      current.add(t);
    }
  }
  if (current.isNotEmpty) {
    current.insertAll(0, sign);
    terms.add([...current]);
  }

  return terms;
}

List<Token> integrateTerm(List<Token> postfix, String variable) {
  List<double> coeff = [], expn = [];
  List<bool> hasVar = [];

  for (var t in postfix) {
    if (t.isNumber) {
      coeff.add(double.parse(t.value));
      expn.add(0);
      hasVar.add(false);
    } else if (t.isVariable && t.value == variable) {
      coeff.add(1.0);
      expn.add(1.0);
      hasVar.add(true);
    } else if (t.value == "u-") {
      if (coeff.isEmpty) return [Token("0", false, false, true)];
      coeff[coeff.length - 1] *= -1;
    } else if (t.value == "u+") {
      continue;
    } else if (t.isOperator) {
      if (coeff.length < 2) return [Token("0", false, false, true)];
      double c2 = coeff.removeLast(), e2 = expn.removeLast();
      bool v2 = hasVar.removeLast();
      double c1 = coeff.removeLast(), e1 = expn.removeLast();
      bool v1 = hasVar.removeLast();

      switch (t.value) {
        case "*":
          coeff.add(c1 * c2);
          expn.add(e1 + e2);
          hasVar.add(v1 || v2);
          break;
        case "/":
          if (v2) return [Token("0", false, false, true)];
          coeff.add(c1 / c2);
          expn.add(e1);
          hasVar.add(v1);
          break;
        case "^":
          if (v1) {
            coeff.add(c1);
            expn.add(e1 * c2);
            hasVar.add(true);
          } else {
            coeff.add(pow(c1, c2).toDouble());
            expn.add(0);
            hasVar.add(false);
          }
          break;
      }
    }
  }

  if (coeff.isEmpty) return [Token("0", false, false, true)];

  double c = coeff.last, e = expn.last;
  bool v = hasVar.last;

  if (!v) {
    return [
      Token(formatNumber(c), false, false, true),
      Token("*", true, false, false),
      Token(variable, false, true, false)
    ];
  }

  double newE = e + 1;
  double newC = c / newE;
  List<Token> result = [
    Token(formatNumber(newC), false, false, true),
    Token("*", true, false, false),
    Token(variable, false, true, false)
  ];

  if ((newE - 1).abs() > 1e-12) {
    result..add(Token("^", true, false, false))
          ..add(Token(formatNumber(newE), false, false, true));
  }

  return result;
}

List<Token> integrateExpression(List<Token> infix, String variable) {
  var terms = splitInfixTerms(infix);
  List<Token> result = [];

  for (int i = 0; i < terms.length; i++) {
    bool isNeg = terms[i].isNotEmpty && terms[i][0].value == "u-";
    var tokensTerm = List<Token>.from(terms[i]);
    if (isNeg) tokensTerm.removeAt(0);

    var postfix = infixToPostfix(tokensTerm);
    var integrated = integrateTerm(postfix, variable);
    if (integrated.isEmpty) continue;

    if (isNeg) {
      result.add(Token("-", true, false, false));
    } else if (result.isNotEmpty) {
      result.add(Token("+", true, false, false));
    }

    result.addAll(integrated);
  }

  return result.isEmpty
      ? [Token("0", false, false, true)]
      : result;
}