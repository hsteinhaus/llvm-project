; RUN: llc --mtriple=xtensa -mattr=+windowed -xtensa-long-calls=false < %s \
; RUN:   | FileCheck %s --check-prefix=DIRECT
; RUN: llc --mtriple=xtensa -mattr=+windowed < %s | FileCheck %s --check-prefix=LONG

;; Without long calls a call names its callee directly, and the linker extends its reach
;; where it must; by default every call loads the callee's address from a literal.

declare i32 @external_function(i32)

define i32 @test_call_external(i32 %a) nounwind {
; DIRECT-LABEL: test_call_external:
; DIRECT:         or a10, a2, a2
; DIRECT-NEXT:    call8 external_function
; DIRECT-NOT:     callx8
; LONG-LABEL:   test_call_external:
; LONG:           l32r a8, .LCPI0_0
; LONG-NEXT:      callx8 a8
  %1 = call i32 @external_function(i32 %a)
  ret i32 %1
}

define i32 @defined_function(i32 %a) nounwind {
  %1 = add i32 %a, 1
  ret i32 %1
}

define i32 @test_call_defined(i32 %a) nounwind {
; DIRECT-LABEL: test_call_defined:
; DIRECT:         call8 defined_function
; DIRECT-NOT:     callx8
; LONG-LABEL:   test_call_defined:
; LONG:           callx8 a8
  %1 = call i32 @defined_function(i32 %a) nounwind
  ret i32 %1
}

;; A library call the backend emits itself goes by external symbol.
define void @test_call_libcall(ptr %d, ptr %s, i32 %n) nounwind {
; DIRECT-LABEL: test_call_libcall:
; DIRECT:         call8 memcpy
; DIRECT-NOT:     callx8
; LONG-LABEL:   test_call_libcall:
; LONG:           callx8 a8
  call void @llvm.memcpy.p0.p0.i32(ptr %d, ptr %s, i32 %n, i1 false)
  ret void
}

;; A call through a pointer stays indirect either way.
define i32 @test_call_indirect(ptr %f, i32 %a) nounwind {
; DIRECT-LABEL: test_call_indirect:
; DIRECT:         callx8 a{{[0-9]+}}
  %1 = call i32 %f(i32 %a)
  ret i32 %1
}

declare void @llvm.memcpy.p0.p0.i32(ptr, ptr, i32, i1)
