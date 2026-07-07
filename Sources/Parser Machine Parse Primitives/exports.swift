// Deliberately non-exported (MemberImportVisibility): implementation-only
// dependency, not consumer surface — re-exporting would leak Machine
// vocabulary into every consumer (ascii f40c3c9 precedent; carve-out escalated
// to the linter arc).
// swiftlint:disable:next exports_swift_strict_shape
internal import Machine_Primitives
@_exported public import Parser_Machine_Compile_Primitives
@_exported public import Parser_Machine_Memoization_Primitives
@_exported public import Parser_Machine_Runtime_Primitives
