SSD1306SPI load

BUFFER_SIZE buffer: screen2

: xchg-screen ( -- )
    screen screen1 = if
        screen2 actual !
    else
        screen1 actual !
    then ;    
    
: north      ( x y -- x' y' ) 1- 63 and ;
: north-east ( x y -- x' y' ) swap 1+ swap 1- ;
: east       ( x y -- x' y' ) swap 1+ 127 and swap ;
: south-east ( x y -- x' y' ) swap 1+ swap 1+ ;
: south      ( x y -- x' y' ) 1+ 63 and ;
: south-west ( x y -- x' y' ) swap 1- swap 1+ ;
: west       ( x y -- x' y' ) swap 1- 127 and swap ;
: north-west ( x y -- x' y' ) swap 1- swap 1- ;

: xyover ( x y n -- x y n x y ) >r 2dup r> -rot ;

: #neighbours ( x y -- n )    
    2dup    north       pixel-set?
    xyover  north-east  pixel-set? +
    xyover  east        pixel-set? +
    xyover  south-east  pixel-set? +
    xyover  south       pixel-set? +
    xyover  south-west  pixel-set? +
    xyover  west        pixel-set? +
    xyover  north-west  pixel-set? + 
    nip nip abs ;

: kill-life ( x y ) xchg-screen unset-pixel xchg-screen ;
: give-life ( x y ) xchg-screen set-pixel xchg-screen ;
: cell-state ( x y ) pixel-set? 1 and ;

: next-generation ( -- )
    DISPLAY_HEIGHT 1- 0 do
        DISPLAY_WIDTH 1- 0 do
            i j cell-state
            i j #neighbours or     \ newstate = (oldstate | #neighbors) == 3.
            3 = if
                i j give-life
            else
                i j kill-life
            then            
        loop
    loop ;

: evolve ( ntimes -- )
    0 do 
        next-generation
        xchg-screen
        display
    loop ;

: place-random-cell ( -- ) 
    random DISPLAY_WIDTH 2 - %
    random DISPLAY_HEIGHT 2 - %
    set-pixel ;

: random-population ( size -- ) 
    0 do place-random-cell loop ;

display-init
1024 random-population
10 evolve
