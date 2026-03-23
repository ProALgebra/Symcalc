import sympy as sp
import time

# Переменная
x = sp.Symbol('x')

# Построение выражения

import sympy as sp

x = sp.Symbol('x')

def build_deep(n):
    expr = x
    for _ in range(n):
        expr = 1 + 2*expr + 3*x**2
    return expr





# Замер времени упрощения
start = time.perf_counter()
expr = build_deep(61)
simplified = sp.simplify(expr)
end = time.perf_counter()

print("\nУпрощённое выражение:")
print(simplified)

print(f"\nВремя упрощения: {end - start:.10f} секунд")
