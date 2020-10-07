.data
.align 4

.set CELLS,4
.set link,0                    // points to the last defined word
.set STATE_COMPILE,1
.set STATE_INTERPRET,0
.set IMMEDIATE,128
.set HIDDEN,64
.set REGULAR,0
.set TRUE,-1
.set FALSE,0
.set INPUT_BUFFER_SIZE,128
.set MAX_WORD_LEN,63

stack_top:    .int 0
state_var:    .int STATE_INTERPRET
input_index:  .int input_buffer
input_buffer: .space INPUT_BUFFER_SIZE,' '
.align 4,32
input_size:   .int . - input_buffer
dictionary:   
    var_last_word: .int FINAL_WORD
    var_prompt_xt: .int xt_exit
    var_pause_xt:  .int 0
    var_emit_xt:   .int xt_uemit
    var_type_xt:   .int xt_utype
    var_eundefi_xt:.int xt_eundef
    var_eundefc_xt:.int xt_eundef
    var_dp:        .int heap
heap:    
    .space 25152
end_dictionary:
rstack_space: .space 112
rstack_top:
stack_space:  .space 112 // used only by ESP port
stack:
compile_only_warning: .asciz "\nWord has no interpretation semantics\n"
undef_word_error:     .asciz "\nUndefined word: "
inbuf_overflow_error: .asciz "\nInput overflow\n"
word_overflow_error:  .asciz "\nName too long: "
