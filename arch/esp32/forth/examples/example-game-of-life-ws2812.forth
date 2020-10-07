GPIO load

\ 8x8 pixel ws2812 led matrix game of life written in Punyforth
\ see it in action: https://youtu.be/XMPZt5o3QAc

64 array: world
5 constant: PIN ( data pin of ws2812 )

16r000000 constant: DEAD
16r250025 constant: DYING
16r08040C constant: LIVE
16r000C00 constant: BORN

: clamp      ( n -- n ) 7 and ;
: north      ( x y -- x' y' ) 1- clamp ;
: south      ( x y -- x' y' ) 1+ clamp ;
: west       ( x y -- x' y' ) swap 1- clamp swap ;
: east       ( x y -- x' y' ) swap 1+ clamp swap ;
: north-east ( x y -- x' y' ) swap 1+ clamp swap 1- clamp ;
: south-east ( x y -- x' y' ) swap 1+ clamp swap 1+ clamp ;
: south-west ( x y -- x' y' ) swap 1- clamp swap 1+ clamp ;
: north-west ( x y -- x' y' ) swap 1- clamp swap 1- clamp ;

: >i ( x y -- idx ) 3 lshift + ;
: set! ( x y state -- ) -rot >i world ! ;
: at ( x y -- n ) >i world @ ;
: live? ( x y -- bool ) at LIVE = ;
: dead? ( x y -- bool ) at DEAD = ;
: kill ( x y -- ) 2dup live? if DYING set! else 2drop then ;
: live ( x y -- ) 2dup dead? if BORN  set! else 2drop then ;
: status ( x y -- 0/1 ) at dup LIVE = swap DYING = or 1 and ;

: xyover ( x y n -- x y n x y ) >r 2dup r> -rot ;
: neighbours ( x y -- n )
    2dup   north      status
    xyover north-east status +
    xyover east       status +
    xyover south-east status +
    xyover south      status +
    xyover south-west status +
    xyover west       status +
    -rot   north-west status + ;

: evolve ( -- )
    8 0 do
        8 0 do
            i j status i j neighbours or 3 = \ newstatus = (oldstatus | #neighbors) == 3.
            if i j live else i j kill then
        loop
    loop ;

: finalize ( -- )
  64 0 do i world @
    case
      DYING of DEAD i world ! endof
      BORN  of LIVE i world ! endof
      drop
    endcase
  loop ;

: paint ( color -- ) PIN ws2812rgb ;
: show ( -- ) os-enter-critical 64 0 do i world @ paint loop os-exit-critical ;
: generations ( n -- ) 0 do evolve show 100 ms finalize show 100 ms loop ;
: seed ( -- ) random clamp random clamp live ;
: randomize ( n -- ) 0 do seed loop ;
: destroy ( -- ) 64 0 do 0 i world ! loop ;
: load ( buffer -- ) 64 0 do dup i cells + @ i world ! loop drop ;

: # LIVE , ;
: _ DEAD , ;

create: INFINITE
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _
  _ _ _ # # # _ _
  _ _ # _ _ # _ _
  _ _ # # # _ _ _
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _

create: ACORN
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _
  _ _ # _ _ _ _ _
  _ _ _ _ # _ _ _
  _ # # _ _ # # #
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _

create: GLIDER
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _
  _ _ _ # _ _ _ _
  _ _ _ _ # _ _ _
  _ _ # # # _ _ _
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _

create: CALLAHANS
  _ _ _ _ _ _ _ _
  _ _ _ _ _ _ _ _
  _ # # # _ # _ _
  _ # _ _ _ _ _ _
  _ _ _ _ # # _ _
  _ _ # # _ # _ _
  _ # _ # _ # _ _
  _ _ _ _ _ _ _ _

PIN GPIO_OUT gpio-mode
wifi-stop ( ws2812 requires precise timing )

: curtain ( -- )
  destroy show
  8 0 do
    8 0 do
        i j 16r1F0212 set!
    loop
    show 50 ms
  loop
  destroy show 50 ms ;

: demo ( -- )
  curtain
  INFINITE  load 50 generations 100 ms
  ACORN     load 29 generations 100 ms
  GLIDER    load 30 generations 100 ms
  15 randomize   10 generations 100 ms
  CALLAHANS load 13 generations 100 ms
  curtain ;
