/*
    Indirect threaded inner interpreter:
        - a14 forth instruction pointer
        - a8, a9 working registers
        - a15 stack pointer	
        - a13 rstack pointer
*/

.macro NEXT
    l32i a8, a14, 0
    addi a14, a14, 4
    l32i a9, a8, 0
    jx a9
.endm
