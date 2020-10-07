.macro defprimitive name, namelen, label, flags
    .section .rodata
     .align WORD_ALIGN
    .globl name_\label
name_\label :
    .int link
    .set link,name_\label
    .byte \flags + \namelen
    .ascii "\name"
     .align WORD_ALIGN
    .globl xt_\label
xt_\label :
    .int code_\label
CODE_SECTION    
    .align WORD_ALIGN
    .globl code_\label
code_\label :
.endm

.macro defword name, namelen, label, flags
    .section .rodata
     .align WORD_ALIGN
    .globl name_\label
name_\label :
    .int link
    .set link,name_\label
    .byte \flags + \namelen
    .ascii "\name"
     .align WORD_ALIGN
    .globl xt_\label
xt_\label :
    .int ENTERCOL
.endm

.macro lbl label
    .int \label - . 
.endm
