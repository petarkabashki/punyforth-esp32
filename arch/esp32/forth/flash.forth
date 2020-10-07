exception: EBLOCK
4096       constant:      SIZE
FALSE      init-variable: dirty
SIZE       buffer:        buf
variable:  offs

: check ( code -- | 0=OK,1=ERR,2=TIMEOUT,3=UNKNOWN ) ?dup if print: 'FLASH ERR: ' . cr EBLOCK throw then ; 
: flush ( -- )
    dirty @ if
        offs @ 12 rshift ( >sector ) erase-flash check
        SIZE buf offs @ write-flash check
        FALSE dirty !
    then ;
    
: block ( block# -- addr )
    flush 12 lshift ( SIZE * ) offs !
    SIZE buf offs @ read-flash check buf ;
    
( screen editor requires to flash with --block-format yes )

128 constant: COLS
32  constant: ROWS

: row   ( y -- addr )   COLS * buf + ;
: ch    ( y x -- addr ) swap row + ;
: type# ( y -- )        dup 10 < if space then . space ;
    
: list ( block# -- )
    block drop
    ROWS 0 do
        i type#
        i row COLS type-counted
    loop ;

\ editor command: blank row
: b ( y -- )
    COLS 2 - 0 do 32 over i ch c! loop
    13 over COLS 2 - ch c!
    10 swap COLS 1-  ch c!
    TRUE dirty ! ;
    
: copy-row ( dst-y src-y -- ) COLS 0 do 2dup i ch c@ swap i ch c! loop 2drop ;
    
\ editor command: delete row
: d ( y -- )
    ROWS 1- swap do i i 1+ copy-row loop
    ROWS 1- b ;

\ editor command: clear screen    
: c ( -- ) ROWS 0 do i b loop ;

\ editor command: overwrite row
: r: ( y "line" -- )
    dup b row
    begin key dup crlf? invert while over c! 1+ repeat
    2drop ;

\ editor command: prepends empty row before the given y
: p ( y -- ) dup ROWS 1- do i i 1- copy-row -1 +loop b ;

/end

