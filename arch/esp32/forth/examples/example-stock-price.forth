NETCON     load
SSD1306SPI load
FONT57     load
WIFI       load

\ stock price display with servo control
\ see it in action: https://youtu.be/4ad7dZmnoH8

1024 constant: buffer-len
buffer-len buffer: buffer
variable: price
variable: change
variable: open

4 constant: SERVO \ d2
SERVO GPIO_OUT gpio-mode

\ servo control
: short  19250 750  ; immediate
: medium 18350 1650 ; immediate
: long   17200 2800 ; immediate
: pulse ( off-cycle-us on-cycle-us -- ) immediate
  ['], SERVO , ['], GPIO_HIGH , ['] gpio-write ,
  ['], ( on cycle ) , ['] us ,
  ['], SERVO , ['], GPIO_LOW , ['] gpio-write ,
  ['], ( off cycle ) , ['] us , ;

: down   ( -- ) 30 0 do short  pulse loop ;
: midway ( -- ) 30 0 do medium pulse loop ;
: up     ( -- ) 30 0 do long   pulse loop ;

: parse-code ( buffer -- code | throws:ECONVERT )
    9 + 3 >number invert if
        ECONVERT throw
    then ;
    
exception: EHTTP
    
: read-code ( netconn -- http-code | throws:EHTTP )
    buffer-len buffer netcon-readln
    0 <= if EHTTP throw then
    buffer "HTTP/" str-starts? if
        buffer parse-code
    else
        EHTTP throw
    then ;
   
: skip-headers ( netconn -- netconn )
    begin
        dup buffer-len buffer netcon-readln -1 <>
    while
        buffer strlen 0= if exit then
    repeat
    EHTTP throw ;
   
: read-resp ( netconn -- response-code )
    dup read-code
    swap skip-headers
    buffer-len buffer netcon-readln
    print: 'len=' . cr ;
    
: log ( response-code -- response-code ) dup print: 'HTTP:' . space buffer type cr ;
: consume ( netcon -- )
    dup read-resp log
    swap netcon-dispose
    200 <> if EHTTP throw then ;
  
: connect ( -- netconn ) 8319 "zeroflag.dynu.net" TCP netcon-connect ;      
: stock-fetch ( -- )
    connect
    dup "GET /stock/CLDR HTTP/1.0\r\n\r\n" netcon-write
    consume ;

exception: ESTOCK

variable: idx
: reset ( -- ) 0 idx ! ;
: pos ( -- addr ) buffer idx @ + ;
: peek ( -- chr ) pos c@ ;
: next ( -- chr ) 1 idx +! idx @ buffer-len >= if ESTOCK throw then ; 
: take ( chr -- ) begin dup peek <> while next repeat drop ;
: 0! ( -- ) 0 pos c! ;
: parse ( -- )
    reset buffer price !
    $, take 0!
    next pos change !
    $, take 0!
    next pos open !
    10 take 0! ;

: trend ( str -- )
    c@ case
        $+ of up   endof
        $- of down endof
        drop midway
    endcase ;
    
: open? ( -- bool ) open @ "1" =str ;

: center ( str -- ) DISPLAY_WIDTH swap str-width - 2 / font-size @ / text-left ! ;
: spacer ( -- ) draw-lf draw-cr 2 text-top +! ;
: stock-draw ( -- )    
    stock-fetch parse
    price @ center price @ draw-str
    spacer
    change @ center change @ draw-str
    change @ trend ;

: error-draw ( exception -- )
    display-clear
    0 text-left ! 0 text-top !
    "Err: " draw-str 
    case
        ENETCON of "NET"  draw-str endof
        EHTTP   of "HTTP" draw-str endof
        ESTOCK  of "API"  draw-str endof
        "Other" draw-str
        ex-type        
    endcase 
    display ;
    
: show ( -- )
    display-clear
    3 text-top  ! 
    0 text-left !    
    stock-draw
    display ;

0 task: stock-task
0 init-variable: last-refresh

: expired? ( -- bool ) ms@ last-refresh @ - 60 1000 * > ;

: stock-start ( task -- )
    activate
    begin
        last-refresh @ 0= expired? or if            
            ms@ last-refresh !            
            { show } catch ?dup if error-draw then            
        then
        pause
    again ;

: main ( -- )
    stack-show
    font-medium
    font5x7 font !
    display-init
    multi 
    stock-task stock-start ;

\ ' boot is: main
\ turnkey
main
