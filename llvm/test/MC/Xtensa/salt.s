# RUN: llvm-mc %s -triple=xtensa -show-encoding --mattr=+salt \
# RUN:     | FileCheck -check-prefix=CHECK-INST %s
# RUN: not llvm-mc %s -triple=xtensa 2>&1 | FileCheck -check-prefix=CHECK-NO %s

## SALT and SALTU (LX7): the encodings GNU as gives them for the ESP32-S3.

# CHECK-INST: salt a9, a9, a8
# CHECK-INST: encoding: [0x80,0x99,0x72]
# CHECK-NO: error: instruction use requires an option to be enabled
salt a9, a9, a8

# CHECK-INST: saltu a10, a8, a9
# CHECK-INST: encoding: [0x90,0xa8,0x62]
saltu a10, a8, a9
