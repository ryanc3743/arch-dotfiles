#!/usr/bin/env python3
"""Small bounded arithmetic evaluator. No eval, names, calls, or attributes."""
import ast
import math
import operator
import sys

OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul,
       ast.Div: operator.truediv, ast.FloorDiv: operator.floordiv, ast.Mod: operator.mod,
       ast.Pow: operator.pow}
def calculate(expression):
    if len(expression) > 256:
        raise ValueError('Expression too long')
    tree = ast.parse(expression, mode='eval')
    if sum(1 for _ in ast.walk(tree)) > 100:
        raise ValueError('Expression too complex')
    def visit(node):
        if isinstance(node, ast.Constant) and type(node.value) in (int, float):
            value = node.value
        elif isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.UAdd, ast.USub)):
            value = visit(node.operand) * (-1 if isinstance(node.op, ast.USub) else 1)
        elif isinstance(node, ast.BinOp) and type(node.op) in OPS:
            a, b = visit(node.left), visit(node.right)
            if isinstance(node.op, ast.Pow) and abs(b) > 100:
                raise ValueError('Exponent must be between -100 and 100')
            value = OPS[type(node.op)](a, b)
        else:
            raise ValueError('Use numbers, parentheses and + - * / // % **')
        if isinstance(value, complex) or not math.isfinite(value) or abs(value) > 1e100:
            raise ValueError('Result out of range')
        return value
    return str(visit(tree.body))

if __name__ == '__main__':
    try:
        print(calculate(sys.argv[1]))
    except (ValueError, SyntaxError, ZeroDivisionError, OverflowError, RecursionError) as error:
        print('Error: ' + str(error).split('\n')[0])
        sys.exit(1)
