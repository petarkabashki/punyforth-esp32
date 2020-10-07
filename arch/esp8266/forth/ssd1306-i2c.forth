GPIO load

\ ssd1306 I2C display driver for OLED displays  
\ Tested with 64x48 wemos oled shield and 128x32 integrated display of wifi kit 8
\ Usage:
\  display-init
\  font5x7 font !
\  10 text-top ! 8 text-left ! 
\  "Hello" draw-str 
\  display
\  display-clear

\ change width/height
64 constant: WIDTH
48 constant: HEIGHT
\ 128 constant: WIDTH
\ 32 constant: HEIGHT
 
5 ( D1 SCL ) constant: SCL
4 ( D2 SDA ) constant: SDA
0 ( D3 RST ) constant: RST 
16r3C        constant: SLAVE
0            constant: BUS
2 ( 400K )   constant: FREQ

WIDTH HEIGHT * 8 / constant: SIZE
SIZE 1+ buffer: screen1
16r40 ( control byte ) screen1 !
: screen ( -- buffer ) screen1 1+ ;

exception: EI2C

: wire ( -- )
    SCL GPIO_OUT gpio-mode
    SDA GPIO_OUT gpio-mode    
    RST GPIO_LOW gpio-write ;

: check ( code -- | throws:EI2C ) 0<> if EI2C throw then ;

create: buf 16r80 c, 0 c,
: cmd ( byte -- | throws:EI2C ) buf 1+ c! 2 buf 0 ( data ) SLAVE BUS i2c-write-slave check ;

: reset ( -- )
    RST GPIO_HIGH gpio-write 1 ms
    RST GPIO_LOW  gpio-write 10 ms
    RST GPIO_HIGH gpio-write ;

\ https://github.com/micropython/micropython/blob/master/drivers/display/ssd1306.py
: init ( -- )
   16rAE ( SSD1306_DISPLAYOFF )           cmd
   16rD5 ( SSD1306_SETDISPLAYCLOCKDIV )   cmd
   16r80                                  cmd
   16rA8 ( SSD1306_SETMULTIPLEX )         cmd
   HEIGHT 1-                              cmd
   16rD3 ( SSD1306_SETDISPLAYOFFSET )     cmd
   16r00                                  cmd
   16r40 ( SSD1306_SETSTARTLINE )         cmd
   16r8D ( SSD1306_CHARGEPUMP )           cmd
   16r14                                  cmd
   16r20 ( SSD1306_MEMORYMODE )           cmd
   16r00                                  cmd
   16rA1 ( SSD1306_SEGREMAP )             cmd
   16rC8 ( SSD1306_COMSCANDEC )           cmd
   16rDA ( SSD1306_SETCOMPINS )           cmd
   HEIGHT 32 = if 16r02 else 16r12 then   cmd
   16r81 ( SSD1306_SETCONTRAST )          cmd 
   16rCF                                  cmd
   16rD9 ( SSD1306_SETPRECHARGE )         cmd
   16rF1                                  cmd
   16rDB ( SSD1306_SETVCOMDETECT )        cmd 
   16r40                                  cmd
   16rA4 ( SSD1306_DISPLAYALLON_RESUME )  cmd
   16rA6 ( SSD1306_NORMALDISPLAY )        cmd
   16rAF ( SSD1306_DISPLAYON )            cmd ;

\ precompile some words for speed
: width*, immediate
    WIDTH case
        128 of ['], 7 , ['] lshift , endof
        64  of ['], 6 , ['] lshift , endof
        ['], , ['] * ,
    endcase ; 

: clampx, immediate
    WIDTH case
        128 of ['], 127 , ['] and , endof
        64  of ['], 63  , ['] and , endof
        ['], , ['] % ,
    endcase ;
    
: clampy, immediate
    HEIGHT case
        64  of ['], 63  , ['] and , endof
        32  of ['], 31  , ['] and , endof
        ['], , ['] % ,
    endcase ;

: clamp ( x y -- x' y' ) swap clampx, swap clampy, ;
: y>bitmask ( y -- bit-index ) 7 and 1 swap lshift ;
: xy>i ( x y -- bit-mask buffer-index ) clamp dup y>bitmask -rot 3 rshift width*, + ;
: or! ( value addr -- ) tuck c@ or swap c! ;
: and! ( value addr -- ) tuck c@ and swap c! ;
: set-pixel ( x y -- )  xy>i screen + or! ;
: unset-pixel ( x y -- ) xy>i screen + swap invert swap and! ;
: pixel-set? ( x y -- ) xy>i screen + c@ and 0<> ;
: hline ( x y width -- ) 0 do 2dup set-pixel { 1+ } dip loop 2drop ;
: rect-fill ( x y width height -- ) 0 do 3dup hline { 1+ } dip loop 3drop ;
: fill-buffer ( value -- ) SIZE 0 do dup i screen + c! loop drop ;

: c1 WIDTH 64 = if 32 else 0 then ;
: c2 WIDTH 64 = if WIDTH 31 + else WIDTH 1- then ;
: display ( -- )
    16r21 ( COLUMNADDR )           cmd 
    [ c1 ] literal                 cmd 
    [ c2 ] literal                 cmd 
    16r22 ( PAGEADD )              cmd 
    0                              cmd 
    [ HEIGHT 3 rshift 1- ] literal cmd
    SIZE 1+ screen 1- 0 ( data ) SLAVE BUS i2c-write-slave check ;

: display-clear ( -- ) 0 fill-buffer display ;
: bus-init ( -- ) FREQ SDA SCL BUS i2c-init check ;
: display-init ( -- | throws:ESSD1306 ) wire bus-init reset init display-clear ;  

\ TODO move these to common place as they're used in the spi driver too
0 init-variable: font
0 init-variable: text-left
0 init-variable: text-top
1 init-variable: font-size

: font-small  ( -- ) 1 font-size ! ;  
: font-medium ( -- ) 2 font-size ! ;
: font-big    ( -- ) 3 font-size ! ;
: font-xbig   ( -- ) 4 font-size ! ;
: draw-lf ( -- ) 9 text-top +! ;
: draw-cr ( -- ) 0 text-left ! ;
: dot ( x y -- ) { font-size @ * } bi@ font-size @ dup rect-fill ;
    
: stripe ( bits -- )
    8 0 do
        dup 1 and 1= if
            text-left @ text-top @ i + dot
        then
        1 rshift
    loop
    drop ;

: draw-char ( char -- )
    255 and 5 * font @ +
    5 0 do
        dup c@ stripe 1+
        1 text-left +!
    loop
    1 text-left +!
    drop ;
    
: draw-str ( str -- )
    font @ 0= if 
        println: 'Set a font like: "font5x7 font !"'
        drop exit 
    then
    dup strlen 0 do
        dup i + c@
        case
            10 of draw-lf endof
            13 of draw-cr endof
            draw-char
        endcase
    loop
    drop ;
    
: str-width ( str -- ) strlen 6 * font-size @ * ;

/end

