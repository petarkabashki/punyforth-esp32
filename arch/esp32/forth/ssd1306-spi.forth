GPIO load

\ ssd1306 SPI display driver

\ define the wiring
14 constant: SCL  \ SCL D5 leg
13 constant: SDA  \ SDA D7 leg
2  constant: DC   \ DC  D4 leg
0  constant: RST  \ RST D3 leg
1  constant: BUS

1 constant: SPI_WORD_SIZE_8BIT

: freq ( divider count -- freq ) 16 lshift swap 65535 and or ;

5 2 freq constant: SPI_FREQ_DIV_8M    \ < 8MHz

128 constant: DISPLAY_WIDTH
64  constant: DISPLAY_HEIGHT

exception: ESSD1306
exception: ESSD1306_WRITE

DISPLAY_WIDTH DISPLAY_HEIGHT * 8 / constant: BUFFER_SIZE

BUFFER_SIZE buffer: screen1
screen1 init-variable: actual
: screen ( -- buffer ) actual @ ;

: wire ( -- )
    DC GPIO_OUT gpio-mode
    RST GPIO_OUT gpio-mode
    DC  GPIO_LOW gpio-write
    RST GPIO_LOW gpio-write ;

: check-write-result ( code -- | ESSD1306_WRITE ) 255 <> if ESSD1306_WRITE throw then ;

: write-command ( cmd -- | ESSD1306_WRITE ) 
    DC GPIO_LOW gpio-write
    BUS spi-send8 
    check-write-result ;

: display-invert ( -- ) 167 write-command ;
: display-normal ( -- ) 166 write-command ;

38 constant: RIGHT
39 constant: LEFT

\ activate scroll. Display is 16 row tall
: scroll-start ( stop-row start-row direction -- )
        write-command ( direction )
    0   write-command
        write-command ( start )
    0   write-command
        write-command ( stop )
    0   write-command
    255 write-command
    47  write-command ( SSD1306_SCROLL_ON ) ;

: scroll-stop ( -- ) 46 write-command ;    
    
: write-data ( data -- | ESSD1306_WRITE ) 
    DC GPIO_HIGH gpio-write
    BUS spi-send8 
    check-write-result ;

: display-on ( -- )
    RST GPIO_HIGH gpio-write
    1 ms
    RST GPIO_LOW gpio-write
    10 ms
    RST GPIO_HIGH gpio-write ;

: init ( -- )
    174 write-command ( SSD1306_DISP_SLEEP )
    213 write-command ( SSD1306_SET_DISP_CLOCK )
    128 write-command
    168 write-command ( SSD1306_SET_MULTIPLEX_RATIO )
    63  write-command
    211 write-command ( SSD1306_SET_VERTICAL_OFFSET )
    0   write-command
    64  write-command ( SSD1306_SET_DISP_START_LINE )
    141 write-command ( SSD1306_CHARGE_PUMP_REGULATOR )
    20  write-command ( SSD1306_CHARGE_PUMP_ON )
    32  write-command ( SSD1306_MEM_ADDRESSING )
    0   write-command
    160 write-command ( SSD1306_SET_SEG_REMAP_0 )
    192 write-command ( SSD1306_SET_COM_SCAN_NORMAL )
    218 write-command ( SSD1306_SET_WIRING_SCHEME )
    18  write-command
    219 write-command ( SSD1306_SET_VCOM_DESELECT_LEVEL )
    64  write-command
    164 write-command ( SSD1306_RESUME_TO_RAM_CONTENT )
    display-normal
    175 write-command ( SSD1306_DISP_ON ) ;

: display-reset ( -- )
    33  write-command
    0   write-command
    127 write-command
    34  write-command
    0   write-command
    7   write-command 
    1025 0 do 0 write-data loop ;

: y>bitmask ( y -- bit-index ) 7 and 1 swap lshift ;
: xy-trunc ( x y -- x' y' ) swap 127 and swap 63 and ;
    
: xy>i ( x y -- bit-mask buffer-index )
    xy-trunc
    dup 
    y>bitmask -rot
    3 rshift            \  8 /
    7 lshift + ;        \  DISPLAY_WIDTH * +

: or! ( value addr -- ) tuck c@ or swap c! ;
: and! ( value addr -- ) tuck c@ and swap c! ;
: set-pixel ( x y -- )    xy>i screen + or! ;
: unset-pixel ( x y -- ) xy>i screen + swap invert swap and! ;
: pixel-set? ( x y -- ) xy>i screen + c@ and 0<> ;
: hline ( x y width -- ) 0 do 2dup set-pixel { 1+ } dip loop 2drop ;
: rect-fill ( x y width height -- ) 0 do 3dup hline { 1+ } dip loop 3drop ;
: fill-buffer ( value -- ) BUFFER_SIZE 0 do dup i screen + c!  loop drop ;

: display ( -- )
    SPI_WORD_SIZE_8BIT
    BUFFER_SIZE
    0 ( ignore output )
    screen
    BUS 
    spi-send BUFFER_SIZE <> if
        ESSD1306 throw
    then ;

: display-clear ( -- ) 0 fill-buffer display ;

: display-init ( -- | ESSD1306 )
    wire
    TRUE 0 ( little endian ) TRUE SPI_FREQ_DIV_8M 0 ( SPI_MODE0 ) BUS 
    spi-init 1 <> if ESSD1306 throw then
    display-on init display-reset ;

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

: dot ( x y -- )
    { font-size @ * } bi@
    font-size @ dup rect-fill ;
    
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

