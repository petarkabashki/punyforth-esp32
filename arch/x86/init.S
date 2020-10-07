.intel_syntax noprefix

.macro init_forth
    cld
    mov [stack_top], esp
    mov ebp, OFFSET FLAT:rstack_top             // ebp is used to track the return stack 
    mov esi, OFFSET FLAT:outer_interpreter      // esi works as an instruction pointer 
    NEXT                                        // start the outer interpreter (repl)
.endm
