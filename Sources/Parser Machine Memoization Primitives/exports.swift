// Deliberately non-exported (MemberImportVisibility): implementation-only
// dependencies, not consumer surface — re-exporting would leak Machine/Stack/
// Tagged vocabulary into every consumer (ascii f40c3c9 precedent; carve-out
// escalated to the linter arc).
// swiftlint:disable:next exports_swift_strict_shape
internal import Machine_Primitives
@_exported public import Parser_Machine_Program_Primitives
@_exported public import Parser_Machine_Runtime_Primitives
// swiftlint:disable:next exports_swift_strict_shape
internal import Stack_Primitives
// swiftlint:disable:next exports_swift_strict_shape
internal import Tagged_Primitives
