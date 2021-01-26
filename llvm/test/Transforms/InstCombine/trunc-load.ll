; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S -data-layout="e-n16:32:64" | FileCheck %s
; RUN: opt < %s -instcombine -S -data-layout="E-n16:32:64" | FileCheck %s

; Don't narrow if it would lose information about the dereferenceable range of the pointer.

define i32 @truncload_no_deref(i64* %ptr) {
; CHECK-LABEL: @truncload_no_deref(
; CHECK-NEXT:    [[X:%.*]] = load i64, i64* [[PTR:%.*]], align 4
; CHECK-NEXT:    [[R:%.*]] = trunc i64 [[X]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %x = load i64, i64* %ptr
  %r = trunc i64 %x to i32
  ret i32 %r
}

define i32 @truncload_small_deref(i64* dereferenceable(7) %ptr) {
; CHECK-LABEL: @truncload_small_deref(
; CHECK-NEXT:    [[X:%.*]] = load i64, i64* [[PTR:%.*]], align 4
; CHECK-NEXT:    [[R:%.*]] = trunc i64 [[X]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %x = load i64, i64* %ptr
  %r = trunc i64 %x to i32
  ret i32 %r
}

; On little-endian, we can narrow the load without an offset.

define i32 @truncload_deref(i64* dereferenceable(8) %ptr) {
; CHECK-LABEL: @truncload_deref(
; CHECK-NEXT:    [[X:%.*]] = load i64, i64* [[PTR:%.*]], align 4
; CHECK-NEXT:    [[R:%.*]] = trunc i64 [[X]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %x = load i64, i64* %ptr
  %r = trunc i64 %x to i32
  ret i32 %r
}

; Preserve alignment.

define i16 @truncload_align(i32* dereferenceable(14) %ptr) {
; CHECK-LABEL: @truncload_align(
; CHECK-NEXT:    [[X:%.*]] = load i32, i32* [[PTR:%.*]], align 16
; CHECK-NEXT:    [[R:%.*]] = trunc i32 [[X]] to i16
; CHECK-NEXT:    ret i16 [[R]]
;
  %x = load i32, i32* %ptr, align 16
  %r = trunc i32 %x to i16
  ret i16 %r
}

; Negative test - extra use means we would not eliminate the original load.

declare void @use(i64)

define i32 @truncload_extra_use(i64* dereferenceable(100) %ptr) {
; CHECK-LABEL: @truncload_extra_use(
; CHECK-NEXT:    [[X:%.*]] = load i64, i64* [[PTR:%.*]], align 2
; CHECK-NEXT:    call void @use(i64 [[X]])
; CHECK-NEXT:    [[R:%.*]] = trunc i64 [[X]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %x = load i64, i64* %ptr, align 2
  call void @use(i64 %x)
  %r = trunc i64 %x to i32
  ret i32 %r
}

; Negative test - don't create a load if the type is not allowed by the data-layout.

define i8 @truncload_type(i64* dereferenceable(9) %ptr) {
; CHECK-LABEL: @truncload_type(
; CHECK-NEXT:    [[X:%.*]] = load i64, i64* [[PTR:%.*]], align 2
; CHECK-NEXT:    [[R:%.*]] = trunc i64 [[X]] to i8
; CHECK-NEXT:    ret i8 [[R]]
;
  %x = load i64, i64* %ptr, align 2
  %r = trunc i64 %x to i8
  ret i8 %r
}

; Negative test - don't transform volatiles.

define i32 @truncload_volatile(i64* dereferenceable(8) %ptr) {
; CHECK-LABEL: @truncload_volatile(
; CHECK-NEXT:    [[X:%.*]] = load volatile i64, i64* [[PTR:%.*]], align 8
; CHECK-NEXT:    [[R:%.*]] = trunc i64 [[X]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %x = load volatile i64, i64* %ptr, align 8
  %r = trunc i64 %x to i32
  ret i32 %r
}

; Preserve address space.

define i32 @truncload_address_space(i64 addrspace(1)* dereferenceable(8) %ptr) {
; CHECK-LABEL: @truncload_address_space(
; CHECK-NEXT:    [[X:%.*]] = load i64, i64 addrspace(1)* [[PTR:%.*]], align 4
; CHECK-NEXT:    [[R:%.*]] = trunc i64 [[X]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %x = load i64, i64 addrspace(1)* %ptr, align 4
  %r = trunc i64 %x to i32
  ret i32 %r
}
