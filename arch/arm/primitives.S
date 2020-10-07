defprimitive "dup",3,dup,REGULAR /* ( a -- a a ) */
    ldr r0, [sp]
    push {r0}
    NEXT

defprimitive "drop",4,drop,REGULAR /* ( a -- ) */
    add sp, #CELLS
    NEXT

defprimitive "swap",4,swap,REGULAR /* ( a b -- b a ) */
    pop {r0, r1}
    push {r0}
    push {r1}
    NEXT

defprimitive "rot",3,rot,REGULAR /* ( a b c -- b c a ) */    
    pop {r0, r1, r2}
    push {r1}
    push {r0}
    push {r2}
    NEXT

defprimitive "2swap",5,swap2,REGULAR /* ( a b c d -- c d a b ) */
    pop {r0, r1, r2, r3}
    push {r1}
    push {r0}
    push {r3}
    push {r2}
    NEXT

defprimitive "2over",5,over2,REGULAR /* ( a b c d -- a b c d a b ) */
    pop {r0, r1, r2, r3}
    push {r3}
    push {r2}
    push {r1}
    push {r0}
    push {r3}
    push {r2}
    NEXT

defprimitive "+",1,plus,REGULAR
    pop {r1}
    pop {r0}
    add r0, r1
    push {r0}
    NEXT

defprimitive "-",1,minus,REGULAR
    pop {r1}
    pop {r0}
    sub r0, r1
    push {r0}
    NEXT

defprimitive "*",1,multiply,REGULAR
    pop {r0}
    pop {r1}
    mul r0, r1
    push {r0}
    NEXT

defprimitive "/mod",4,divmod,REGULAR /* ( n d -- m q ) */
    pop {r1}
    pop {r0}
    sdiv r2, r0, r1
    mls r0, r1, r2, r0
    push {r0}
    push {r2}
    NEXT

defprimitive "or",2,or,REGULAR
    pop {r1}
    pop {r0}
    orr r0, r1
    push {r0}
    NEXT

defprimitive "and",3,and,REGULAR
    pop {r1}
    pop {r0}
    and r0, r1
    push {r0}
    NEXT

defprimitive "xor",3,xor,REGULAR
    pop {r1}
    pop {r0}
    eor r0, r1
    push {r0}
    NEXT

defprimitive "invert",6,invert,REGULAR
    ldr r0, [sp]
    mvns r0, r0
    str r0, [sp]
    NEXT

defprimitive "lshift",6,lshift,REGULAR
    pop {r1}
    pop {r0}
    lsl r0, r1
    push {r0}
    NEXT

defprimitive "rshift",6,rshift,REGULAR
    pop {r1}
    pop {r0}
    lsr r0, r1
    push {r0}
    NEXT

defprimitive "_emit",5,uemit,REGULAR
    mov r3, r7                      // save forth ip
    mov r1, sp                      // char to print
    mov r0, #1                      // fd <- stdout
    mov r2, #1                      // length
    mov r7, #4                      // syscall <- sys_write
    swi 0                           // system call
    mov r7, r3
    pop {r0}                        // discard char
    NEXT    

defprimitive "abort",5,abort,REGULAR
    mov r0, #0     // set exit code to 0
    mov r7, #1     // syscall for exit
    swi 0          // invoke the syscall from linux
    NEXT

defprimitive "@",1,fetch,REGULAR
    pop {r0}
    ldr r1, [r0]
    push {r1}
    NEXT

defprimitive "!",1,store,REGULAR
    pop {r1}
    pop {r0}
    str r0, [r1]
    NEXT

defprimitive "c!",2,storebyte,REGULAR
    pop {r1}
    pop {r0}
    strb r0, [r1]
    NEXT

defprimitive "[']",3,btick,REGULAR    // compile only
    ldr r0, [r7]
    add r7, #CELLS
    push {r0}
    NEXT

defprimitive "<",1,lt,REGULAR         // only need to define this, all other comparisions are implemented in terms of lt
    pop {r1}
    pop {r0}
    mov r2, #0
    cmp r0, r1
    movlt r2, #TRUE
    push {r2}
    NEXT

defprimitive "branch",6,branch,REGULAR
    ldr r0, [r7]
    add r7, r0
    NEXT

defprimitive "branch0",7,branch0,REGULAR
    pop {r1}                                  // check condition
    cmp r1, #0
    beq code_branch
    add r7, #CELLS                            // skip address
    NEXT

defprimitive ">r",2,rpush,REGULAR
    pop {r0}
    sub r6, #CELLS
    str r0, [r6]
    NEXT

defprimitive "r>",2,rpop,REGULAR
    ldr r0, [r6]
    add r6, #CELLS
    push {r0}
    NEXT

defprimitive "i",1,i,REGULAR
    ldr r0, [r6]
    push {r0}
    NEXT

defprimitive "j",1,j,REGULAR
    ldr r0, [r6, #2*CELLS]
    push {r0}
    NEXT

defprimitive "execute",7,execute,REGULAR
    pop {r0}
    ldr r1, [r0]
    mov pc, r1

// this exit primitive is only used by the compiler, this is used for detecting word endings works some as regular exit
defprimitive "<exit>",6,end_word,REGULAR 
    ldr r7, [r6]
    add r6, #CELLS
    NEXT

defprimitive "exit",4,exit,REGULAR
    ldr r7, [r6]
    add r6, #CELLS
    NEXT

defprimitive "sp@",3,spat,REGULAR
    mov r0, sp
    push {r0}
    NEXT

defprimitive "sp!",3,spstore,REGULAR
    pop {r0}
    mov sp, r0
    NEXT

defprimitive "rp@",3,rpat,REGULAR
    push {r6}
    NEXT

defprimitive "rp!",3,rpstore,REGULAR
    pop {r6}
    NEXT

defprimitive "readchar",8,readchar,REGULAR
    mov r3, r7              // save forth ip
    push {r0}               // make place for buffer
    mov r1, sp              // buffer for one character
    mov r0, #0              // read system call
    str r0, [r1]
    mov r2, #1              // length
    mov r7, #3
    swi 0
    cmp r0, #0
    ble code_abort
    mov r7, r3
    ldr r0, [r1]
    NEXT

// Different types of code words

ENTERCOL:                   // codeword for word (colon) definitions
    sub r6, #CELLS
    str r7, [r6]            // save r7 (forth instruction pointer) to the return stack
    add r7, r0, #CELLS      // r0 points to the ENTERCOL, skip this cell and set the instruction pointer to the body of this word
    NEXT

ENTERDOES:
    sub r6, #CELLS
    str r7, [r6]            // save r7 (forth instruction pointer) to the return stack
    add r0, #CELLS         
    ldr r7, [r0]            // load the behaviour pointer to FORTH PC
    add r0, #CELLS          // after the behaviour pointer there is the data
    push {r0}               // invoke behaviour with data pointer on the stack
    NEXT

ENTERCONST:
    add r0, #CELLS
    ldr r0, [r0]
    push {r0}
    NEXT

ENTERVAR:
    add r0, #CELLS
    push {r0}
    NEXT

