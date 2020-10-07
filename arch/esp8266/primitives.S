.macro DPUSH reg    
    addi a15, a15, -CELLS
    s32i \reg, a15, 0
.endm

.macro DPOP reg    
    l32i \reg, a15, 0
    addi a15, a15, CELLS
.endm

.macro RPUSH reg    
    addi a13, a13, -CELLS
    s32i \reg, a13, 0    
.endm

.macro RPOP reg    
    l32i \reg, a13, 0
    addi a13, a13, CELLS
.endm

.macro READTOS1 reg
    l32i \reg, a15, 0
.endm

.macro READTOS2 reg
    l32i \reg, a15, CELLS
.endm

.macro READTOS3 reg
    l32i \reg, a15, 2*CELLS
.endm

.macro READTOS4 reg
    l32i \reg, a15, 3*CELLS
.endm

.macro WRTETOS1 reg
    s32i \reg, a15, 0
.endm

.macro WRTETOS2 reg
    s32i \reg, a15, CELLS
.endm

.macro WRTETOS3 reg
    s32i \reg, a15, 2*CELLS
.endm

.macro WRTETOS4 reg
    s32i \reg, a15, 3*CELLS
.endm

defprimitive "dup",3,dup,REGULAR /* ( a -- a a ) */
    READTOS1 a8
    DPUSH a8
    NEXT

defprimitive "drop",4,drop,REGULAR /* ( a -- ) */
    addi a15, a15, CELLS
    NEXT

defprimitive "swap",4,swap,REGULAR /* ( a b -- b a ) */
    READTOS1 a8
    READTOS2 a9
    WRTETOS1 a9
    WRTETOS2 a8
    NEXT

defprimitive "rot",3,rot,REGULAR /* ( a b c -- b c a ) */    
    READTOS1 a8
    READTOS2 a9
    READTOS3 a10
    WRTETOS3 a9
    WRTETOS2 a8
    WRTETOS1 a10
    NEXT

defprimitive "2swap",5,swap2,REGULAR /* ( a b c d -- c d a b ) */    
    READTOS1 a8
    READTOS2 a9
    READTOS3 a10
    READTOS4 a11
    WRTETOS1 a10
    WRTETOS2 a11
    WRTETOS3 a8
    WRTETOS4 a9
    NEXT

defprimitive "2over",5,over2,REGULAR /* ( a b c d -- a b c d a b ) */    
    READTOS3 a10
    READTOS4 a11
    DPUSH a11
    DPUSH a10
    NEXT

defprimitive "+",1,plus,REGULAR
    DPOP a8
    READTOS1 a9
    add a8, a8, a9
    WRTETOS1 a8
    NEXT

defprimitive "-",1,minus,REGULAR
    DPOP a9
    READTOS1 a8
    sub a8, a8, a9
    WRTETOS1 a8
    NEXT

defprimitive "*",1,multiply,REGULAR
    DPOP a8
    READTOS1 a9
    mull a8, a8, a9
    WRTETOS1 a8
    NEXT

.literal_position
defprimitive "/mod",4,divmod,REGULAR /* ( n d -- m q ) */    
    DPOP a3            // denom
    DPOP a2            // numer
    CCALL forth_divmod
    DPUSH a3           // remainder
    DPUSH a2           // quotient
    NEXT

defprimitive "or",2,or,REGULAR
    DPOP a8
    READTOS1 a9
    or a8, a8, a9
    WRTETOS1 a8
    NEXT

defprimitive "and",3,and,REGULAR
    DPOP a8
    READTOS1 a9
    and a8, a8, a9
    WRTETOS1 a8
    NEXT

defprimitive "xor",3,xor,REGULAR
    DPOP a8
    READTOS1 a9
    xor a8, a8, a9
    WRTETOS1 a8    
    NEXT

defprimitive "invert",6,invert,REGULAR
    READTOS1 a8
    movi a9, TRUE
    xor a8, a8, a9
    WRTETOS1 a8
    NEXT

defprimitive "lshift",6,lshift,REGULAR
    DPOP a8
    READTOS1 a9
    ssl a8
    sll a8, a9
    WRTETOS1 a8
    NEXT

defprimitive "rshift",6,rshift,REGULAR
    DPOP a8
    READTOS1 a9
    ssr a8
    srl a8, a9
    WRTETOS1 a8
    NEXT

.literal_position
defprimitive "_emit",5,uemit,REGULAR
    DPOP a2
    CCALL forth_putchar
    NEXT    

defprimitive "abort",5,abort,REGULAR
    CCALL forth_abort
    NEXT

defprimitive "@",1,fetch,REGULAR
    READTOS1 a8
    l32i a9, a8, 0
    WRTETOS1 a9
    NEXT

defprimitive "c@",2,fetchbyte,REGULAR
    READTOS1 a8
    l8ui a9, a8, 0
    WRTETOS1 a9
    NEXT

defprimitive "!",1,store,REGULAR
    DPOP a8
    DPOP a9
    s32i a9, a8, 0
    NEXT

defprimitive "c!",2,storebyte,REGULAR
    DPOP a8
    DPOP a9
    s8i a9, a8, 0
    NEXT

defprimitive "[']",3,btick,REGULAR    // compile only
    l32i a8, a14, 0
    addi a14, a14, CELLS
    DPUSH a8
    NEXT

defprimitive "<",1,lt,REGULAR         // only need to define this, all other comparisions are implemented in terms of lt
    DPOP a8
    READTOS1 a9
    movi a10, FALSE
    bge a9, a8, L4              // a9 >= a8 ?
    movi a10, TRUE
L4: WRTETOS1 a10
    NEXT

defprimitive "branch",6,branch,REGULAR
    l32i a8, a14, 0                 // read relative address as the next instruction
    add a14, a14, a8                // advance forth PC
    NEXT

defprimitive "branch0",7,branch0,REGULAR
    DPOP a9
    beqz a9, code_branch
    addi a14, a14, CELLS
    NEXT

defprimitive ">r",2,rpush,REGULAR
    DPOP a8
    RPUSH a8
    NEXT

defprimitive "r>",2,rpop,REGULAR
    RPOP a8
    DPUSH a8
    NEXT

defprimitive "i",1,i,REGULAR
    l32i a8, a13, 0
    DPUSH a8
    NEXT

defprimitive "j",1,j,REGULAR
    l32i a8, a13, 2*CELLS
    DPUSH a8
    NEXT

defprimitive "execute",7,execute,REGULAR    
    DPOP a8                             // xt
    l32i a9, a8, 0                      // fetch codeword the same way as the inner interpreter does
    jx a9  

// this exit primitive is only used by the compiler, this is used for detecting word endings works some as regular exit
defprimitive "<exit>",6,end_word,REGULAR 
    RPOP a14                            // pop forth PC from the return stack
    NEXT

defprimitive "exit",4,exit,REGULAR
    RPOP a14                            // pop forth PC from the return stack
    NEXT

defprimitive "sp@",3,spat,REGULAR
    mov a8, a15
    DPUSH a8
    NEXT

defprimitive "sp!",3,spstore,REGULAR
    DPOP a8
    mov a15, a8
    NEXT

defprimitive "rp@",3,rpat,REGULAR
    DPUSH a13
    NEXT

defprimitive "rp!",3,rpstore,REGULAR
    DPOP a8
    mov a13, a8
    NEXT

// Different types of code words

.section .irom0.text
.align 4

ENTERCOL:                       // codeword for word (colon) definitions
    RPUSH a14                   // save program counter before entering the word
    addi a14, a8, CELLS         // a8 points to the ENTERCOL, skip this cell    
    NEXT

ENTERDOES:
    RPUSH a14                   // save program counter before entering the word
    addi a8, a8, CELLS          // a8 is on the codeword after there is the behaviour pointer
    l32i a14, a8, 0     // set the FORTH PC to the behaviour
    addi a8, a8, CELLS          // after the behaviour there is the data
    DPUSH a8                    // invoke behavour with the data pointer on the stack
    NEXT

ENTERCONST:
    l32i a8, a8, CELLS
    DPUSH a8
    NEXT

ENTERVAR:
    addi a8, a8, CELLS
    DPUSH a8
    NEXT
