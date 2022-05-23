//===-- hwasan_setjmp.S --------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of HWAddressSanitizer.
//
// HWAddressSanitizer runtime.
//===----------------------------------------------------------------------===//

#include "sanitizer_common/sanitizer_asm.h"

#if HWASAN_WITH_INTERCEPTORS
#include "sanitizer_common/sanitizer_platform.h"
#if defined(__aarch64__)

// We want to save the context of the calling function.
// That requires
// 1) No modification of the link register by this function.
// 2) No modification of the stack pointer by this function.
// 3) (no modification of any other saved register, but that's not really going
// to occur, and hence isn't as much of a worry).
//
// There's essentially no way to ensure that the compiler will not modify the
// stack pointer when compiling a C function.
// Hence we have to write this function in assembly.

.section .text
.file "hwasan_setjmp.S"

.global __interceptor_setjmp
ASM_TYPE_FUNCTION(__interceptor_setjmp)
__interceptor_setjmp:
  CFI_STARTPROC
  mov	x1, #0
  b	__interceptor_sigsetjmp
  CFI_ENDPROC
ASM_SIZE(__interceptor_setjmp)

#if SANITIZER_ANDROID
// Bionic also defines a function `setjmp` that calls `sigsetjmp` saving the
// current signal.
.global __interceptor_setjmp_bionic
ASM_TYPE_FUNCTION(__interceptor_setjmp_bionic)
__interceptor_setjmp_bionic:
  CFI_STARTPROC
  mov	x1, #1
  b	__interceptor_sigsetjmp
  CFI_ENDPROC
ASM_SIZE(__interceptor_setjmp_bionic)
#endif

.global __interceptor_sigsetjmp
ASM_TYPE_FUNCTION(__interceptor_sigsetjmp)
__interceptor_sigsetjmp:
  CFI_STARTPROC
  stp	x19, x20, [x0, #0<<3]
  stp	x21, x22, [x0, #2<<3]
  stp	x23, x24, [x0, #4<<3]
  stp	x25, x26, [x0, #6<<3]
  stp	x27, x28, [x0, #8<<3]
  stp	x29, x30, [x0, #10<<3]
  stp	 d8,  d9, [x0, #14<<3]
  stp	d10, d11, [x0, #16<<3]
  stp	d12, d13, [x0, #18<<3]
  stp	d14, d15, [x0, #20<<3]
  mov	x2,  sp
  str	x2,  [x0, #13<<3]
  // We always have the second argument to __sigjmp_save (savemask) set, since
  // the _setjmp function above has set it for us as `false`.
  // This function is defined in hwasan_interceptors.cc
  b	__sigjmp_save
  CFI_ENDPROC
ASM_SIZE(__interceptor_sigsetjmp)


.macro ALIAS first second
  .globl \second
  .equ \second\(), \first
.endm

#if SANITIZER_ANDROID
ALIAS __interceptor_sigsetjmp, sigsetjmp
.weak sigsetjmp

ALIAS __interceptor_setjmp_bionic, setjmp
.weak setjmp
#else
ALIAS __interceptor_sigsetjmp, __sigsetjmp
.weak __sigsetjmp
#endif

ALIAS __interceptor_setjmp, _setjmp
.weak _setjmp

#elif SANITIZER_RISCV64

.section .text
.file "hwasan_setjmp.S"

.global __interceptor_setjmp
ASM_TYPE_FUNCTION(__interceptor_setjmp)
__interceptor_setjmp:
  CFI_STARTPROC
  addi	x11, x0, 0
  j	__interceptor_sigsetjmp
  CFI_ENDPROC
ASM_SIZE(__interceptor_setjmp)

#if SANITIZER_ANDROID
// Bionic also defines a function `setjmp` that calls `sigsetjmp` saving the
// current signal.
.global __interceptor_setjmp_bionic
ASM_TYPE_FUNCTION(__interceptor_setjmp_bionic)
__interceptor_setjmp_bionic:
  CFI_STARTPROC
  addi	x11, x0, 1
  j	__interceptor_sigsetjmp
  CFI_ENDPROC
ASM_SIZE(__interceptor_setjmp_bionic)
#endif

.hidden __interceptor_sigsetjmp
ASM_TYPE_FUNCTION(__interceptor_sigsetjmp)
__interceptor_sigsetjmp:
  CFI_STARTPROC
  sd    ra,   0<<3(x10)
  sd    s0,   1<<3(x10)
  sd    s1,   2<<3(x10)
  sd    s2,   3<<3(x10)
  sd    s3,   4<<3(x10)
  sd    s4,   5<<3(x10)
  sd    s5,   6<<3(x10)
  sd    s6,   7<<3(x10)
  sd    s7,   8<<3(x10)
  sd    s8,   9<<3(x10)
  sd    s9,   10<<3(x10)
  sd    s10,  11<<3(x10)
  sd    s11,  12<<3(x10)
  sd    sp,   13<<3(x10)
#ifndef __riscv_float_abi_soft
  fsd   fs0,  14<<3(x10)
  fsd   fs1,  15<<3(x10)
  fsd   fs2,  16<<3(x10)
  fsd   fs3,  17<<3(x10)
  fsd   fs4,  18<<3(x10)
  fsd   fs5,  19<<3(x10)
  fsd   fs6,  20<<3(x10)
  fsd   fs7,  21<<3(x10)
  fsd   fs8,  22<<3(x10)
  fsd   fs9,  23<<3(x10)
  fsd   fs10, 24<<3(x10)
  fsd   fs11, 25<<3(x10)
#endif
  // We always have the second argument to __sigjmp_save (savemask) set, since
  // the _setjmp function above has set it for us as `false`.
  // This function is defined in hwasan_interceptors.cc
  j	__sigjmp_save
  CFI_ENDPROC
ASM_SIZE(__interceptor_sigsetjmp)


.macro ALIAS first second
  .globl \second
  .equ \second\(), \first
.endm

#if SANITIZER_ANDROID
ALIAS __interceptor_sigsetjmp, sigsetjmp
.weak sigsetjmp

ALIAS __interceptor_setjmp_bionic, setjmp
.weak setjmp
#else
ALIAS __interceptor_sigsetjmp, __sigsetjmp
.weak __sigsetjmp
#endif

ALIAS __interceptor_setjmp, _setjmp
.weak _setjmp
#else
#endif
#endif //HWASAN_WITH_INTERCEPTORS

// We do not need executable stack.
NO_EXEC_STACK_DIRECTIVE
