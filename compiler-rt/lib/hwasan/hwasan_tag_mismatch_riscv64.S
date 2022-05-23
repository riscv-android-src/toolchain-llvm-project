#include "sanitizer_common/sanitizer_asm.h"

// The content of this file is RISCV64-only:
#if SANITIZER_RISCV64

// The responsibility of the HWASan entry point in compiler-rt is to primarily
// readjust the stack from the callee and save the current register values to
// the stack.
// This entry point function should be called from a __hwasan_check_* symbol.
// These are generated during a lowering pass in the backend, and are found in
// AArch64AsmPrinter::EmitHwasanMemaccessSymbols(). Please look there for
// further information.
// The __hwasan_check_* caller of this function should have expanded the stack
// and saved the previous values of x0, x1, x29, and x30. This function will
// "consume" these saved values and treats it as part of its own stack frame.
// In this sense, the __hwasan_check_* callee and this function "share" a stack
// frame. This allows us to omit having unwinding information (.cfi_*) present
// in every __hwasan_check_* function, therefore reducing binary size. This is
// particularly important as hwasan_check_* instances are duplicated in every
// translation unit where HWASan is enabled.
// This function calls HwasanTagMismatch to step back into the C++ code that
// completes the stack unwinding and error printing. This function is is not
// permitted to return.


// |              ...                |
// |              ...                |
// | Previous stack frames...        |
// +=================================+
// | Unused 8-bytes for maintaining  |
// | 16-byte SP alignment.           |
// +---------------------------------+
// | Return address (x30) for caller |
// | of __hwasan_check_*.            |
// +---------------------------------+
// | Frame address (x29) for caller  |
// | of __hwasan_check_*             |
// +---------------------------------+ <-- [SP + 232] TODO: FIX
// |              ...                |
// |                                 |
// | Stack frame space for x2 - x28. |
// |                                 |
// |              ...                |
// +---------------------------------+ <-- [SP + 16] TODO: FIX
// |                                 |
// | Saved x1, as __hwasan_check_*   |
// | clobbers it.                    |
// +---------------------------------+
// | Saved x0, likewise above.       |
// +---------------------------------+ <-- [x30 / SP] TODO: FIX

// This function takes two arguments:
//   * a0: The data address.
//   * a1: The encoded access info for the failing access.

// This function has two entry points. The first, __hwasan_tag_mismatch, is used
// by clients that were compiled without short tag checks (i.e. binaries built
// by older compilers and binaries targeting older runtimes). In this case the
// outlined tag check will be missing the code handling short tags (which won't
// be used in the binary's own stack variables but may be used on the heap
// or stack variables in other binaries), so the check needs to be done here.
//
// The second, __hwasan_tag_mismatch_v2, is used by binaries targeting newer
// runtimes. This entry point bypasses the short tag check since it will have
// already been done as part of the outlined tag check. Since tag mismatches are
// uncommon, there isn't a significant performance benefit to being able to
// bypass the check; the main benefits are that we can sometimes avoid
// clobbering the x17 register in error reports, and that the program will have
// a runtime dependency on the __hwasan_tag_mismatch_v2 symbol therefore it will
// fail to start up given an older (i.e. incompatible) runtime.
.section .text
.file "hwasan_tag_mismatch_riscv64.S"
.global __hwasan_tag_mismatch_v2
.type __hwasan_tag_mismatch_v2, %function
__hwasan_tag_mismatch_v2:
  CFI_STARTPROC

  // Set the CFA to be the return address for caller of __hwasan_check_*. Note
  // that we do not emit CFI predicates to describe the contents of this stack
  // frame, as this proxy entry point should never be debugged. The contents
  // are static and are handled by the unwinder after calling
  // __hwasan_tag_mismatch. The frame pointer is already correctly setup
  // by __hwasan_check_*.
  addi fp, sp, 256
  CFI_DEF_CFA(fp, 16)
  CFI_OFFSET(ra, -8)
  CFI_OFFSET(fp, -16)

  // Save the rest of the registers into the preallocated space left by
  // __hwasan_check.
  sd x31, 248(sp)
  sd x30, 240(sp)
  sd x29, 232(sp)
  sd x28, 224(sp)
  sd x27, 216(sp)
  sd x26, 208(sp)
  sd x25, 200(sp)
  sd x24, 192(sp)
  sd x23, 184(sp)
  sd x22, 176(sp)
  sd x21, 168(sp)
  sd x20, 160(sp)
  sd x19, 152(sp)
  sd x18, 144(sp)
  sd x17, 136(sp)
  sd x16, 128(sp)
  sd x15, 120(sp)
  sd x14, 112(sp)
  sd x13, 104(sp)
  sd x12, 96(sp)
  // sd x11, 88(sp) ; these are already saved
  // sd x10, 80(sp) ; these are already saved
  sd x9, 72(sp)
  sd x8, 64(sp)
  sd x7, 56(sp)
  sd x6, 48(sp)
  sd x5, 40(sp)
  sd x4, 32(sp)
  sd x3, 24(sp)
  sd x2, 16(sp)
  sd x1, 8(sp)
  sd x0, 0(sp)

  // Pass the address of the frame to __hwasan_tag_mismatch4, so that it can
  // extract the saved registers from this frame without having to worry about
  // finding this frame.
  mv x12, sp

  call __hwasan_tag_mismatch4
  CFI_ENDPROC

.Lfunc_end0:
  .size __hwasan_tag_mismatch_v2, .Lfunc_end0-__hwasan_tag_mismatch_v2

#endif  // defined(__riscv64)

// We do not need executable stack.
NO_EXEC_STACK_DIRECTIVE
