# REQUIRES: xtensa
# RUN: rm -rf %t && split-file %s %t && cd %t
# RUN: llvm-mc -filetype=obj -triple=xtensa -mcpu=esp32s3 calls.s -o calls.o
# RUN: ld.lld calls.o --image-base=0 --section-start=.text=0x1000 --defsym=near=0x2000 \
# RUN:   --defsym=far=0x10000000 -o calls
# RUN: llvm-objdump -d --no-show-raw-insn --mcpu=esp32s3 --print-imm-hex calls | FileCheck %s
# RUN: llvm-objdump -s -j .text calls | FileCheck %s --check-prefix=LIT

## A CALL8 out of its 512 KiB goes through one thunk per callee: the callee's address as a
## literal, then l32r a9 + jx a9. A CALL8 in reach stays direct.
# CHECK:       [[#%x,THUNK:]] <__Call8Thunk_far>:
# CHECK-NEXT:    l32r a9, 0x[[#%x,THUNK - 4]]
# CHECK-NEXT:    jx a9
# CHECK-LABEL: <_start>:
# CHECK-NEXT:    call8 0x2000
# CHECK-NEXT:    call8 0x[[#%x,THUNK]]
# CHECK-NEXT:    call8 0x[[#%x,THUNK]]
## The literal holds the callee's address, 0x10000000.
# LIT: 1000 00000010

## Only a CALL8 is extended: a jump or a call4 out of reach stays an error, since a thunk
## would lose a live a9.
# RUN: llvm-mc -filetype=obj -triple=xtensa -mcpu=esp32s3 jump.s -o jump.o
# RUN: not ld.lld jump.o --image-base=0 --section-start=.text=0x1000 --defsym=far=0x10000000 -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=ERR
# RUN: llvm-mc -filetype=obj -triple=xtensa -mcpu=esp32s3 call4.s -o call4.o
# RUN: not ld.lld call4.o --image-base=0 --section-start=.text=0x1000 --defsym=far=0x10000000 -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=ERR
# ERR: relocation R_XTENSA_SLOT0_OP out of range

#--- calls.s
.text
.globl _start
.balign 4
_start:
  call8 near
  call8 far
  call8 far

#--- jump.s
.text
.globl _start
_start:
  j far

#--- call4.s
.text
.globl _start
.balign 4
_start:
  call4 far
