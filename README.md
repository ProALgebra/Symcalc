# Symcalc

## English

`symcalc` is a symbolic computation project in Cangjie.  
It supports expression normalization, simplification by function rules, substitution, symbolic differentiation, partial sums, geometric sums, and basic trigonometric simplification.

### Features

- Expression AST:
  - `Constant(A)`
  - `Variable(String)`
  - `Add(A, HashMap<Expression_<A>, A>)`
  - `Multiply(A, HashMap<Expression_<A>, A>)`
  - `Function(String, ArrayList<Expression_<A>>)`
- Normalization with `toNormalForm()`
- Core API for simplify / derivative / substitution
- Function rule registry for extensible simplify/derivative behavior
- `partial_sum(term, iterator, from, to)`
- `geom_sum(a, q, from, to)`
- `pow(base, exp)` for constant non-negative integer exponents
- `sin` / `cos`:
  - symbolic behavior for non-constants
  - constant evaluation via Taylor series
- Built-in regression tests in `src/tests.cj`

### Project Structure

- `src/expression.cj` - expression type and base operators
- `src/expression_normal_form.cj` - normalization logic
- `src/expression_derivative.cj` - derivative logic
- `src/expression_hash.cj` - hashing and structural ordering
- `src/expression_function_rules.cj` - central function rule registry
- `src/expression_trigonometric_rules.cj` - `sin/cos` rules
- `src/expression_partial_sum.cj` - `partial_sum` rules
- `src/expression_geometric_rules.cj` - `pow` and `geom_sum` rules
- `src/scalar.cj` - `Scalar` interface and `Int64` / `Float64` implementations
- `src/core.cj` - public facade API
- `src/tests.cj` - regression test function
- `src/main.cj` - executable demo and test runner call

### Core API

```cj
let core = Core<Float64>()
```

- `simplifyExpression(expr: Expression_<A>): Expression_<A>`
- `derivativeExpression(expr: Expression_<A>, element: Expression_<A>): Expression_<A>`
- `substituteVariable(expr, variableName, replacement)`
- `substituteVariable(expr, variableExpr, replacement)`

### Examples

#### Simplify

```cj
let core = Core<Float64>()
let expr = Function<Float64>("sin", ArrayList<Expression_<Float64>>([Constant(1.0)]))
println(core.simplifyExpression(expr))
```

#### Derivative

```cj
let core = Core<Float64>()
let x = Variable<Float64>("x")
let expr = Function<Float64>("sin", ArrayList<Expression_<Float64>>([x]))
println(core.derivativeExpression(expr, x))
```

#### Partial Sum

```cj
let core = Core<Int64>()
let i = Variable<Int64>("i")
let s = Function<Int64>(
    "partial_sum",
    ArrayList<Expression_<Int64>>([
        Add(2, HashMap<Expression_<Int64>, Int64>((i, 1),)),
        i,
        Constant(1),
        Constant(4)
    ])
)
println(core.simplifyExpression(s))
```

#### Geometric Sum

```cj
let core = Core<Float64>()
let g = Function<Float64>(
    "geom_sum",
    ArrayList<Expression_<Float64>>([
        Constant(2.0), Constant(3.0), Constant(0.0), Constant(4.0)
    ])
)
println(core.simplifyExpression(g))
```

### Testing

Regression tests are implemented in `src/tests.cj` and called from `main()`.

Build:

```bash
cjpm build
```

Run:

```bash
cjpm run
```

### Current Limits

- No dedicated piecewise/domain-constraint AST yet
- `pow` simplification only for constant non-negative integer exponents
- `Int64` division is integer division
- Custom lightweight test runner (no external framework)

---

## Русский

`symcalc` - проект символьных вычислений на Cangjie.  
Поддерживает нормализацию выражений, упрощение через правила функций, подстановку, символьное дифференцирование, частичные суммы, суммы геометрической прогрессии и базовое тригонометрическое упрощение.

### Возможности

- AST выражений:
  - `Constant(A)`
  - `Variable(String)`
  - `Add(A, HashMap<Expression_<A>, A>)`
  - `Multiply(A, HashMap<Expression_<A>, A>)`
  - `Function(String, ArrayList<Expression_<A>>)`
- Нормализация через `toNormalForm()`
- API ядра для `simplify` / `derivative` / `substitute`
- Реестр правил функций для расширяемого поведения
- `partial_sum(term, iterator, from, to)`
- `geom_sum(a, q, from, to)`
- `pow(base, exp)` для константной неотрицательной целой степени
- `sin` / `cos`:
  - символическое поведение для неконстант
  - вычисление констант через ряд Тейлора
- Регрессионные тесты в `src/tests.cj`

### Структура проекта

- `src/expression.cj` - тип выражения и базовые операторы
- `src/expression_normal_form.cj` - нормализация
- `src/expression_derivative.cj` - производные
- `src/expression_hash.cj` - хеширование и структурное упорядочивание
- `src/expression_function_rules.cj` - центральный реестр правил
- `src/expression_trigonometric_rules.cj` - правила `sin/cos`
- `src/expression_partial_sum.cj` - правила `partial_sum`
- `src/expression_geometric_rules.cj` - правила `pow` и `geom_sum`
- `src/scalar.cj` - интерфейс `Scalar` и реализации `Int64` / `Float64`
- `src/core.cj` - публичный фасад
- `src/tests.cj` - регрессионные тесты
- `src/main.cj` - исполняемый пример и вызов тестов

### API ядра

```cj
let core = Core<Float64>()
```

- `simplifyExpression(expr: Expression_<A>): Expression_<A>`
- `derivativeExpression(expr: Expression_<A>, element: Expression_<A>): Expression_<A>`
- `substituteVariable(expr, variableName, replacement)`
- `substituteVariable(expr, variableExpr, replacement)`

### Примеры

#### Упрощение

```cj
let core = Core<Float64>()
let expr = Function<Float64>("sin", ArrayList<Expression_<Float64>>([Constant(1.0)]))
println(core.simplifyExpression(expr))
```

#### Производная

```cj
let core = Core<Float64>()
let x = Variable<Float64>("x")
let expr = Function<Float64>("sin", ArrayList<Expression_<Float64>>([x]))
println(core.derivativeExpression(expr, x))
```

#### Частичная сумма

```cj
let core = Core<Int64>()
let i = Variable<Int64>("i")
let s = Function<Int64>(
    "partial_sum",
    ArrayList<Expression_<Int64>>([
        Add(2, HashMap<Expression_<Int64>, Int64>((i, 1),)),
        i,
        Constant(1),
        Constant(4)
    ])
)
println(core.simplifyExpression(s))
```

#### Геометрическая сумма

```cj
let core = Core<Float64>()
let g = Function<Float64>(
    "geom_sum",
    ArrayList<Expression_<Float64>>([
        Constant(2.0), Constant(3.0), Constant(0.0), Constant(4.0)
    ])
)
println(core.simplifyExpression(g))
```

### Тестирование

Регрессионные тесты реализованы в `src/tests.cj` и вызываются из `main()`.

Сборка:

```bash
cjpm build
```

Запуск:

```bash
cjpm run
```

### Текущие ограничения

- Пока нет отдельного AST для piecewise/ограничений области определения
- Упрощение `pow` только для константной неотрицательной целой степени
- Для `Int64` деление целочисленное
- Используется собственный легковесный раннер тестов
