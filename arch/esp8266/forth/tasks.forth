0 constant: PAUSED
1 constant: SKIPPED

struct
    cell field: .next
    cell field: .status
    cell field: .sp
    cell field: .rp
    cell field: .ip
    cell field: .s0
    cell field: .r0
    cell field: .handler
constant: Task

here Task allot constant: REPL
REPL REPL .next !
SKIPPED REPL .status !
_s0 REPL .s0 !
_r0 REPL .r0 !

112 init-variable: task-stack-size
112 init-variable: task-rstack-size
REPL init-variable: last
REPL init-variable: current

: alloc-stack  ( -- a ) task-stack-size  @ allot here ;
: alloc-rstack ( -- a ) task-rstack-size @ allot here ;

: task: ( user-space-size "name" ) ( -- task )
    create:
        here                                 \ task header begins here
        swap Task + allot                    \ make room for task header + user space
        SKIPPED             over .status !   \ new status is SKIPPED
        last @ .next @      over .next !     \ this.next = last-task.next
        dup last @               .next !     \ last-task.next = this
        alloc-stack         over .sp !       \ this.sp = allocated
        alloc-rstack        over .rp !       \ this.sp = allocated
        0                   over .handler !  \ exception handler of this thread
        dup .sp @ over .s0 !                 \ init s0 = top of stack address
        dup .rp @ over .r0 !                 \ init r0 = top of rstack address
        last ! ;                             \ last-task = this

: choose ( -- ) current @ begin .next @ dup .status @ PAUSED = until ;

: save ( sp ip rp -- ) \ XXX temporal coupling
    current @ .rp !
    current @ .ip !
    current @ .sp ! ;

: restore ( -- )    
    current @ .sp @ sp!
    current @ .rp @ rp!
    current @ .ip @ >r ;

: switch ( task -- )
    current !
    SKIPPED current @ .status !
    restore ;

: user-space ( -- a ) current @ Task + ;

defer: pause

: pause-multi ( -- )
    PAUSED current @ .status !
    sp@ r> rp@ save
    choose switch ;

: s0-multi ( -- top-stack-adr )  current @ .s0 @ ;
: r0-multi ( -- top-rstack-adr ) current @ .r0 @ ;

' s0 is: s0-multi
' r0 is: r0-multi

: activate ( task -- )
    r> over .ip !
    PAUSED current @ .status !   \ pause current task
    sp@ cell + r> rp@ save
    switch ;

: stop ( task -- ) SKIPPED swap .status ! choose switch ;
: deactivate ( -- ) current @ stop ;

: task-find ( task -- link )
    lastword
    begin
        dup
    while
        2dup link>body cell + = if nip exit then \ XXX skip behaviour pointer
        @
    repeat
    2drop 0 ;

: tasks-print ( -- )
    current @
    begin
        dup task-find ?dup if link-type cr else println: "interpreter" then
        .next @ dup current @ =
    until
    drop ;
   
: semaphore: ( -- ) init-variable: ;
: mutex: ( -- ) 1 semaphore: ;
: wait ( semaphore -- ) begin pause dup @ until -1 swap +! ; 
: signal ( semaphore -- ) 1 swap +!  pause ;
 
: multi-handler ( -- a ) current @ .handler ;

: multi ( -- ) \ switch to multi-task mode
    ['] handler is: multi-handler \ each tasks should have its own exception handler
    ['] pause xpause !
    ['] pause is: pause-multi ;     
    
: single ( -- ) \ switch to signle-task mode
    ['] handler is: single-handler \ use global handler
    0 xpause !
    ['] pause is: nop ;

single

/end

