/*
    Indirect threaded inner interpreter:
        - esi forth instruction pointer
        - eax working register
*/

.intel_syntax noprefix

.macro NEXT
    lodsd
    jmp [eax]
.endm

