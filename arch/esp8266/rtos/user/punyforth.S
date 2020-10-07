
#include "../../defs.S"
#include "../../../../generic/data.S"
#include "../../../../generic/macros.S"
#include "../../cinterop.S"
#include "../../../../generic/outerinterpreter.S"
#include "../../innerinterpreter.S"
#include "../../primitives.S"
#include "../../ext.S"
#include "../../../../generic/words.S"

.global forth_start

.section .irom0.text
.align 4

forth_start:
    movi a8, input_buffer
    movi a9, input_index
    s32i a8, a9, 0

    movi a15, stack
    movi a13, rstack_top

    movi a8, stack_top
    s32i a15, a8, 0

    movi a14, outer_interpreter
    NEXT
