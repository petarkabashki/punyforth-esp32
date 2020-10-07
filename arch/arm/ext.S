defprimitive "=",1,eq,REGULAR
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    moveq r2, #TRUE
    push {r2}
    NEXT

defprimitive ">",1,gt,REGULAR
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    movgt r2, #TRUE
    push {r2}
    NEXT

defprimitive ">=",2,gte,REGULAR
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    movge r2, #TRUE
    push {r2}
    NEXT

defprimitive "<=",2,lte,REGULAR
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    movle r2, #TRUE
    push {r2}
    NEXT

defprimitive "0=",2,eq0,REGULAR
    pop {r0}
    mov r1, #FALSE
    cmp r0, #0
    moveq r1, #TRUE
    push {r1}
    NEXT

defprimitive "1=",2,eq1,REGULAR
    pop {r0}
    mov r1, #FALSE
    cmp r0, #1
    moveq r1, #TRUE
    push {r1}
    NEXT

defprimitive "1+",2,inc,REGULAR
    pop {r0}
    add r0, #1
    push {r0}
    NEXT

defprimitive "1-",2,dec,REGULAR
    pop {r0}
    sub r0, #1
    push {r0}
    NEXT

defprimitive "0<",2,lt0,REGULAR
    pop {r0}
    mov r1, #FALSE
    cmp r0, #0
    movlt r1, #TRUE
    push {r1}
    NEXT

defprimitive "0>",2,gt0,REGULAR
    pop {r0}
    mov r1, #FALSE
    cmp r0, #0
    movgt r1, #TRUE
    push {r1}
    NEXT

defprimitive "over",4,over,REGULAR 
    ldr r0, [SP, #CELLS]
    push {r0}
    NEXT

// TODO
defprimitive "time",4,time,REGULAR /* ( -- unixtime ) */
    push {r0}
    NEXT

defprimitive "r@",2,rfetch,REGULAR
    ldr r0, [r6]
    push {r0}
    NEXT
