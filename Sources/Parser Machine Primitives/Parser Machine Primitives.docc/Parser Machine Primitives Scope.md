# Parser Machine Primitives Scope

## Identity

`swift-parser-machine-primitives` is a **discipline package over the
upstream `Parser` namespace** (owned by `swift-parser-primitives`,
`Parser.swift:73`). It extends that namespace with
`extension Parser { enum Machine {} }` — a defunctionalized,
constant-call-stack parsing machine. Because every declaration extends an
upstream-owned namespace and imports external modules (`Machine`, `Parser`,
`Tagged`, and — for execution — `Stack`, `Slab`), the package has **no
zero-dependency `{Domain} Primitive` substrate root** of its own (per the
discipline-package rule, /modularization §7). It splits into
sub-namespace modules + an umbrella.

## Core targets

The package separates the parsing machine along the **IR / program
representation vs. runtime / execution** axis:

- `Parser Machine Program Primitives` — the **IR / program-representation**
  module. Owns the `Parser.Machine` namespace shell and the `Machine.*`
  capture/transform typealiases, the program data types (`Node`, `Leaf`,
  `Program`), and the program-construction types (`Builder`, `Expression`,
  `Reference`, the `leaf()` factory). Depends on `Parser`, `Machine`,
  `Tagged`; no `Stack` / `Slab`.
- `Parser Machine Runtime Primitives` — the **runtime / execution** module.
  Owns the assembled `Parser.Machine.Parser` parser type, the `run(...)`
  interpreter (which uses `Stack` and `Slab`), and the execution-time
  support types (`Frame` / `Extra`, `Failure` recovery, `Runtime.Error`).
  Depends on `Parser Machine Program Primitives` (directed; runtime over IR,
  no cycle) plus `Parser`, `Machine`, `Tagged`, `Stack`, `Slab`.
- `Parser Machine Memoization Primitives`, `Parser Machine Compile
  Primitives`, `Parser Machine Combinator Primitives`,
  `Parser Machine Parse Primitives` — the existing capability sub-namespaces,
  each importing the Program and/or Runtime modules they actually use.
- `Parser Machine Primitives` — the umbrella, re-exporting every
  sub-namespace.

## Out of scope

- A zero-dependency namespace root: this is a discipline package over
  upstream `Parser`; it mints no `Parser Machine Primitive` root.
- `Parser Machine Core Primitives` is a transitional DEPRECATED shim
  re-exporting the dissolved Core surface (the Program + Runtime modules and
  the externals Core previously funneled). It is removed in the
  core-dissolution cleanup wave and is not part of the package's identity.

## Evaluation rule

Sub-target additions are evaluated against this scope. Place each new type by
whether it is program-representation (→ `Parser Machine Program Primitives`)
or execution (→ `Parser Machine Runtime Primitives`); a capability that bears
its own distinct external dependency extracts to its own sub-namespace
target, never accreted into an existing module.
