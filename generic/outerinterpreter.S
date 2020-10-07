// This is the outer text interpreter (REPL) implemented in binary forth.

.section .rodata
.align 4

outer_interpreter:
    .int xt_word                           // ( a len )
    .int xt_dup2
    .int xt_find, xt_dup, xt_branch0       // dictionary lookup returns (link | 0)
    lbl not_found_in_dictionary
    .int xt_link2xt
    .int xt_nip, xt_nip                          
    .int xt_execute
    .int xt_branch
    lbl outer_interpreter 
not_found_in_dictionary:                   // word was not found in the dictionary try to convert it to number
    .int xt_drop                           // 0
    .int xt_dup2                           // save (len wordadr) for printing if error occurs during conversion
    .int xt_tonumber
    .int xt_branch0
    lbl invalid_number
    .int xt_nip, xt_nip                    // drop saved word 
    .int xt_branch 
    lbl outer_interpreter
invalid_number:
    .int xt_eundefi, xt_fetch, xt_execute
    .int xt_branch
    lbl outer_interpreter
