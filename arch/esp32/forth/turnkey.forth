4096       constant: SIZE
16r51000   constant: BOOT_ADDR

exception: ETURNKEY
defer: boot

: dst ( -- n ) 16r51000 SIZE + ;
: heap-size ( -- n ) usedmem align ;
: check ( code -- | ETURNKEY ) ?dup if print: 'SPI FLASH ERROR: ' . cr ETURNKEY throw then ;

: n, ( addr n -- addr+strlen ) over >r >str r> dup strlen + ;
: s, ( str-dst str-src -- str-dst+strlen ) tuck strlen 2dup + { cmove } dip ;
    
: save-loader ( -- )
    here dup
    heap-size n, " heap-start " s, dst n, " read-flash drop boot" s,
    0 swap c!
    BOOT_ADDR SIZE /    erase-flash check
    SIZE swap BOOT_ADDR write-flash check ;
    
: turnkey ( -- )
    heap-size SIZE / heap-size SIZE % 0> abs + 0 
    do
        dst SIZE / i + erase-flash check
    loop
    heap-size heap-start dst write-flash check
    save-loader ;

/end

