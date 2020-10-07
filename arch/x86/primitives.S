.intel_syntax noprefix

// Primitives are implemented in assembly language

defprimitive "dup",3,dup,REGULAR /* ( a -- a a ) */
    mov eax, [esp]
    push eax
    NEXT

defprimitive "drop",4,drop,REGULAR /* ( a -- ) */
    add esp, CELLS
    NEXT

defprimitive "swap",4,swap,REGULAR /* ( a b -- b a ) */
    pop eax
    pop ebx
    push eax
    push ebx
    NEXT

defprimitive "rot",3,rot,REGULAR /* ( a b c -- b c a ) */
    pop ecx
    pop ebx
    pop eax
    push ebx
    push ecx
    push eax
    NEXT

defprimitive "2swap",5,swap2,REGULAR /* ( a b c d -- c d a b ) */
    pop edx
    pop ecx
    pop ebx
    pop eax
    push ecx
    push edx
    push eax
    push ebx
    NEXT

defprimitive "2over",5,over2,REGULAR /* ( a b c d -- a b c d a b ) */
    pop edx
    pop ecx
    pop ebx
    pop eax
    push eax
    push ebx
    push ecx
    push edx
    push eax
    push ebx
    NEXT

defprimitive "+",1,plus,REGULAR
    pop eax
    add [esp], eax
    NEXT

defprimitive "-",1,minus,REGULAR
    pop eax
    sub [esp], eax
    NEXT

defprimitive "*",1,multiply,REGULAR
    pop eax
    pop ebx
    imul ebx
    push eax
    NEXT

defprimitive "/mod",4,divmod,REGULAR /* ( n d -- m q ) */
    pop ebx
    pop eax
    xor edx, edx
    cdq
    idiv ebx
    push edx
    push eax
    NEXT

defprimitive "or",2,or,REGULAR
    pop eax
    or [esp], eax
    NEXT

defprimitive "and",3,and,REGULAR
    pop eax
    and [esp], eax
    NEXT

defprimitive "xor",3,xor,REGULAR
    pop eax
    xor [esp], eax
    NEXT

defprimitive "lshift",6,lshift,REGULAR
    pop ecx
    pop eax
    shl eax, cl
    push eax
    NEXT

defprimitive "rshift",6,rshift,REGULAR
    pop ecx
    pop eax
    shr eax, cl
    push eax
    NEXT

defprimitive "_emit",5,uemit,REGULAR
    mov edx, 1      // length
    mov ecx, esp    // emit right off the stack
    mov ebx, 1      // stdout
    mov eax, 4      // sys_write
    int 0x80
    pop ebx
    NEXT

defprimitive "abort",5,abort,REGULAR
    mov esp, [stack_top]
    mov eax, 1
    int 0x80

defprimitive "@",1,fetch,REGULAR
    pop eax
    mov ebx, [eax]
    push ebx
    NEXT

defprimitive "!",1,store,REGULAR
    pop edi
    pop eax
    stosd
    NEXT

defprimitive "c!",2,storebyte,REGULAR
    pop edi
    pop eax
    stosb
    NEXT

defprimitive "[']",3,btick,REGULAR    // compile only
    lodsd
    push eax
    NEXT

defprimitive "<",1,lt,REGULAR         // only need to define this, all other comparisions are implemented in terms of lt
    pop eax
    pop ebx
    cmp ebx, eax
    setl al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive "invert",6,invert,REGULAR
    not dword ptr [esp]
    NEXT

defprimitive "branch",6,branch,REGULAR
    add esi, dword ptr [esi]
    NEXT

defprimitive "branch0",7,branch0,REGULAR
    pop eax
    test eax, eax
    jz code_branch
    lodsd // skip the the offs
    NEXT

defprimitive ">r",2,rpush,REGULAR
    pop eax
    sub ebp, CELLS
    mov [ebp], eax
    NEXT

defprimitive "r>",2,rpop,REGULAR
    mov eax, [ebp]
    add ebp, CELLS
    push eax
    NEXT

defprimitive "i",1,i,REGULAR
    mov eax, [ebp]
    push eax
    NEXT

defprimitive "j",1,j,REGULAR
    mov eax, [ebp + 2 * CELLS]
    push eax
    NEXT

defprimitive "execute",7,execute,REGULAR
    pop eax
    jmp [eax]
    
// this exit primitive is only used by the compiler, this is used for detecting word endings works some as regular exit
defprimitive "<exit>",6,end_word,REGULAR 
    mov esi, [ebp]
    add ebp, CELLS
    NEXT

defprimitive "exit",4,exit,REGULAR
    mov esi, [ebp]
    add ebp, CELLS
    NEXT

defprimitive "sp@",3,spat,REGULAR
    push esp
    NEXT

defprimitive "sp!",3,spstore,REGULAR
    pop esp
    NEXT

defprimitive "rp@",3,rpat,REGULAR
    push ebp
    NEXT

defprimitive "rp!",3,rpstore,REGULAR
    pop ebp
    NEXT

defprimitive "readchar",8,readchar,REGULAR
    xor ebx, ebx                                                        // reads from stdin (FD 0)
    push ebx                                                            // make room for buffer
    mov ecx, esp
    mov eax, 3                                                          // use syscall 3 (read) to read from stdin
    mov edx, 1                                                          // read one character
    int 0x80                                                            // invoke system call to read from stdin
    cmp eax, 0                                                          // number bytes read
    jbe code_abort
    NEXT

// Different types of code words

ENTERCOL:                   // codeword for word (colon) definitions
    sub ebp, CELLS
    mov [ebp], esi          // save esi (forth instruction pointer) to the return stack
    add eax, CELLS          // eax points to the ENTERCOL, skip this cell
    mov esi, eax            // set the instruction pointer to the body of this word
    NEXT

ENTERDOES:
    sub ebp, CELLS
    mov [ebp], esi          // save esi to return stack
    add eax, CELLS          // eax points to the codeword field, skip tshi
    mov esi, [eax]          // after the codeword there is the behaviour pointer
    add eax, CELLS          // after the behaviour pointer there is the data field
    push eax
    NEXT                    // jump to behavour

ENTERCONST:
   mov eax, [eax + CELLS]
   push eax
   NEXT

ENTERVAR:
   add eax, CELLS
   push eax
   NEXT
