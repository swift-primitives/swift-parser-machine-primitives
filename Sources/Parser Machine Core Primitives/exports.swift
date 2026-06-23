// DEPRECATED — transitional shim (L1 core-dissolution sweep 2026-06-23). Re-exports the dissolved Core surface; removed in the cleanup wave.
//
// The misnamed `Parser Machine Core Primitives` Core has been dissolved into two
// sub-namespace modules — `Parser Machine Program Primitives` (IR / program
// representation) and `Parser Machine Runtime Primitives` (execution). This shim
// preserves the FULL pre-migration product surface so out-of-package consumers
// keep resolving until the cleanup wave repoints them.
@_exported public import Parser_Machine_Program_Primitives
@_exported public import Parser_Machine_Runtime_Primitives
@_exported public import Machine_Primitives
@_exported public import Parser_Primitives
@_exported public import Slab_Primitives
@_exported public import Stack_Primitives
@_exported public import Tagged_Primitives
