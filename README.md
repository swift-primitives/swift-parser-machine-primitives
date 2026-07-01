# Parser Machine Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-parser-machine-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-parser-machine-primitives/actions/workflows/ci.yml)

A defunctionalized parser machine — grammars are built as flat program graphs and executed on an explicit, heap-allocated frame stack, so recursion depth is a runtime parameter instead of a call-stack limit. A recursive-descent parser overflows the thread stack on deeply nested input; a `Parser.Machine` program parses thousands of nesting levels with a bounded `maxDepth` you choose.

`Parser.Machine` extends the `Parser` namespace from [`swift-parser-primitives`](https://github.com/swift-primitives/swift-parser-primitives): any existing `Parser.Protocol` parser embeds into a program as a leaf node, and the assembled program is itself a `Parser.Protocol` parser, so machine-compiled parsers compose with the rest of the parser ecosystem unchanged.

---

## Key Features

- **Stack-safe recursion** — programs run on an explicit frame stack; deeply nested grammars (5,000+ levels in the test suite) parse without growing the call stack.
- **Combinator surface over an IR** — `pure`, `leaf`, `map`, `tryMap`, `flatMap`, `sequence`, `oneOf`, `many`, `optional` allocate nodes in a `Builder`; `recursive` ties the knot for self-referential grammars.
- **Typed throws end-to-end** — `parse(_:)` throws the grammar's own `Failure` type; `leaf(_:mapError:in:)` lifts a leaf parser's error into the grammar's error.
- **Incremental re-parsing** — `parser.parse.incremental` maintains a memoization table across invocations and invalidates entries by edit descriptor.
- **Compile existing parsers** — `.parse.compiled()` wraps any `Parser.Protocol` parser with lazy compilation and a cached program; `.parse.prepared()` compiles eagerly into an immutable wrapper.

---

## Quick Start

A balanced-parentheses grammar. The recursive self-reference goes through `selfRef`, and `maxDepth` bounds nesting explicitly — depths that would overflow a recursive-descent parser's call stack:

```swift
import Parser_Machine_Primitives
import Parser_Primitives_Test_Support  // Parser.Test.Input — any input type works

typealias Input = Parser.Test.Input

struct Match: Parser.`Protocol` {
    let byte: UInt8
    enum Error: Swift.Error { case expected }
    func parse(_ input: inout Input) throws(Error) {
        guard input.first == byte else { throw .expected }
        try! input.advance()
    }
}

enum ParenError: Swift.Error { case open, close }

// depth("") == 0, depth("((()))") == 3
let parens: Parser.Machine.Parser<Input, Int, ParenError> =
    Parser.Machine.recursive(maxDepth: 10000) { builder, selfRef in
        let empty = Parser.Machine.pure(0, in: &builder)
        let open = Parser.Machine.leaf(Match(byte: UInt8(ascii: "(")), mapError: { _ in ParenError.open }, in: &builder)
        let close = Parser.Machine.leaf(Match(byte: UInt8(ascii: ")")), mapError: { _ in ParenError.close }, in: &builder)
        let inner = selfRef.expression(in: &builder)
        let nested = Parser.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
        let closed = Parser.Machine.sequence(nested, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)
        return Parser.Machine.oneOf([closed, empty], in: &builder)
    }

// 5,000 nesting levels — parses on the machine's explicit stack, not the thread's.
var input = Input(
    Swift.Array(repeating: UInt8(ascii: "("), count: 5000)
        + Swift.Array(repeating: UInt8(ascii: ")"), count: 5000)
)
let depth = try parens.parse(&input)  // 5000
```

Non-recursive grammars use `Parser.Machine.build { builder in ... }`, and existing parsers compile without a builder at all:

```swift
let prepared = existingParser.parse.prepared()  // eager compile, immutable, shareable
let result = try prepared.parse(&input)
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-parser-machine-primitives.git", branch: "main")
]
```

Add a product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Parser Machine Primitives", package: "swift-parser-machine-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

The umbrella re-exports six modules; import a subset when you need less surface.

| Product | Contents | When to import |
|---------|----------|----------------|
| `Parser Machine Primitives` | Umbrella — re-exports all modules below | Most consumers |
| `Parser Machine Program Primitives` | The program IR — `Builder`, `Expression`, `Reference`, `leaf` | Building or inspecting programs without executing them |
| `Parser Machine Runtime Primitives` | `Parser.Machine.Parser` and explicit-stack execution | Running a program handed to you |
| `Parser Machine Combinator Primitives` | `pure`, `map`, `tryMap`, `flatMap`, `sequence`, `oneOf`, `many`, `optional`, `recursive`, `build` | Writing grammars |
| `Parser Machine Memoization Primitives` | Memoization table, keys, edit descriptors | Custom memoization control |
| `Parser Machine Compile Primitives` | `Compiled`, `Prepared`, `Compile.Witness` | Compiling existing `Parser.Protocol` parsers |
| `Parser Machine Parse Primitives` | `parse` accessor — direct, `incremental`, `.compiled()` / `.prepared()` | Execution-variant selection on assembled parsers |
| `Parser Machine Primitives Test Support` | Shared test helpers | Test targets only |

Neither `Builder` nor the assembled `Parser` is `Sendable`; construct on one task and transport across isolation domains via `sending`. `prepared()` returns an immutable wrapper for cross-task sharing.

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |

---

## Related Packages

- [`swift-parser-primitives`](https://github.com/swift-primitives/swift-parser-primitives) — the `Parser` namespace, `Parser.Protocol`, and the leaf parsers this package compiles.
- [`swift-machine-primitives`](https://github.com/swift-primitives/swift-machine-primitives) — the generic defunctionalized-machine substrate (builder, capture store, value arena) the parser machine specializes.
- [`swift-input-primitives`](https://github.com/swift-primitives/swift-input-primitives) — the input-cursor protocol and concrete cursors the parsers consume.
- [`swift-stack-primitives`](https://github.com/swift-primitives/swift-stack-primitives) — the frame stack the runtime executes on.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
