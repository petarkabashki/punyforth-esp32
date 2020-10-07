\ World Clock App

\ Misc Forth Utilities
\ Written for PunyForth
\ By: Craig A. Lindley and others
\ Last Update: 01/21/2017

\ (* Surround multiline comments with these *)
: (* 
  begin  
      begin key [ char: * ] literal = until
      key [ char: ) ] literal =
      if
          exit
      then
  again
; immediate

\ Add missing functions
: negate -1 * ;

: r@ ( -- n )
    r> r> dup >r swap >r ; 
;

\ ST7735 65K Color LCD Display Driver for the Adafruit 1.8" SPI LCD
\ Only supports landscape mode with LCD connector on right
\ Written for PunyForth
\ By: Craig A. Lindley
\ Last Update: 01/21/2017
\ Must have core and gpio modules loaded

\ Define the wiring between the NodeMCU Amica and the LCD display
14 constant: SCL  \ SCL D5
13 constant: SDA  \ SDA D7
 2 constant: DC   \ DC  D4
15 constant: CS   \ CS  D8
\ NOTE: the RESET and LITE signals on the LCD are tied to 3.3VDC

\ SPI interface number
1  constant: BUS  

\ Define some 16 bit color values
hex: 0000 constant: BLK
hex: F800 constant: RED
hex: FFE0 constant: YEL
hex: 07E0 constant: GRN
hex: 001F constant: BLU
hex: 07FF constant: CYA
hex: F81F constant: MAG
hex: FFFF constant: WHT

\ ST7735 commands
hex: 01 constant: SWRST   \ software reset
hex: 11 constant: SLPOUT  \ sleep out
hex: 29 constant: DISPON  \ display on
hex: 2A constant: CASET   \ column address set
hex: 2B constant: RASET   \ row address set
hex: 2C constant: RAMWR   \ RAM write
hex: 36 constant: MADCTL  \ pixel direction control
hex: 3A constant: COLMOD  \ color mode

\ Display rotation constants
hex: 80 constant: CTL_MY
hex: 40 constant: CTL_MX
hex: 20 constant: CTL_MV
\ hex: 08 constant: CTL_BGR

exception: EST7735

\ Display dimensions in landscape mode
160 constant: WIDTH
128 constant: HEIGHT

\ Check result of SPI write
: cWrt ( code -- | EST7735 )
    255 <> if 
        EST7735 throw 
    then
;

\ Write an 8 bit command to the display via SPI
: wCmd ( cmd -- | EST7735 )
    DC GPIO_LOW gpio-write
    CS GPIO_LOW gpio-write
    BUS spi-send8 
    cWrt
    CS GPIO_HIGH gpio-write 
;

\ Write 8 bit data to the display via SPI
: w8 ( data -- | EST7735 ) 
    DC GPIO_HIGH gpio-write
    CS GPIO_LOW gpio-write
    BUS spi-send8
    cWrt
    CS GPIO_HIGH gpio-write 
;

\ Write 16 bit data to the display via SPI
: w16 ( data -- | EST7735 ) 
    DC GPIO_HIGH gpio-write
    CS GPIO_LOW gpio-write
    dup
    8 rshift    BUS spi-send8
    cWrt 
    hex: FF and BUS spi-send8
    cWrt
    CS GPIO_HIGH gpio-write 
;

\ Initialize the SPI interface and the display controller
: initLCD ( -- | EST7735 )

    \ Initilize GPIO pins
    DC GPIO_OUT  gpio-mode
    CS GPIO_OUT  gpio-mode
    DC GPIO_LOW  gpio-write
    CS GPIO_HIGH gpio-write

    \ Setup SPI interface
    TRUE 1 TRUE 2 10 16 lshift swap 65535 and or 0 BUS 
    spi-init 1 <> if
        EST7735 throw
    then

    \ Initialize the display controller for operation
    SWRST wCmd
    200 ms
    SLPOUT wCmd
    500 ms
    \ Set 16 bit color
    COLMOD  wCmd
    100 ms
    hex: 05 w8 
    100 ms
    MADCTL wCmd
    \ Must add CTL_BGR for Sainsmart display
    CTL_MY CTL_MV or w8
    100 ms
    DISPON wCmd 
    200 ms
;

\ Temp variables
variable: _wx0_
variable: _wy0_
variable: _wx1_
variable: _wy1_

\ Sets a rectangular display window into which pixel data is written
\ Values should be set into variable above before call
: setWin ( -- )
    CASET wCmd
    _wx0_ @ w16
    _wx1_ @ w16
    RASET wCmd
    _wy0_ @ w16
    _wy1_ @ w16
    RAMWR wCmd 
;

\ Graphic Functions for the ST7735 65K Color LCD Controller
\ Written for PunyForth
\ By: Craig A. Lindley
\ Last Update: 01/21/2017
\ Must have ST7735 loaded

\ Temp variables
variable: _w_
variable: _h_

\ Draw a pixel on the display
: pixel ( x y color -- )
    >r
    dup _wy0_ ! _wy1_ !
    dup _wx0_ ! _wx1_ !
    setWin
    r>
    w16 ;


\ Fill a rectangle on the display
: fillRect ( x0 y0 x1 y1 color -- )
    >r
    _wy1_ ! _wx1_ ! _wy0_ ! _wx0_ !
    _wx1_ @ _wx0_ @ - 1+ _w_  !
    _wy1_ @ _wy0_ @ - 1+ _h_ !
    
    setWin
    r>
    _w_ @ _h_ @ * 0 
    do
        dup w16
    loop
    drop ;

\ Draw horizontal line of length with color
: hLine		( x y len color -- )
    >r          ( x y len color -- x y len )
    >r          ( x y len -- x y )	
    over over	( x y -- x y x y )
    swap	( x y x y -- x y y x )
    r>		( x y y x --- x y y x len )
    +		( x y y x len -- x y y x+len )
    swap	( x y y x+len -- x y x+len y )
    r>          ( x y x+len y -- x y x+len y color )
    fillRect    ( x y x+len y color -- )
;


\ Draw vertical line of length with color
: vLine		( x y len color -- )
    >r		( x y len color -- x y len )
    over	( x y len -- x y len y )
    +		( x y len y -- x y y+len )
    >r	        ( x y y+len -- x y )
    over	( x y -- x y x )
    r>          ( x y x -- x y x y+len )
    r>          ( x y x y+len -- x y x y+len color )
    fillRect    ( x y x y+len color -- )
;

\ Text Functions for the ST7735 65K Color LCD Controller
\ Written for PunyForth
\ By: Craig A. Lindley
\ Last Update: 01/21/2017

5 constant: FW
7 constant: FH

\ 5x7 font for characters 0x20 .. 0x7E
create: FNT
hex: 00  c, hex: 00  c, hex: 00  c, hex: 00  c, hex: 00  c, \ space
hex: 00  c, hex: 00  c, hex: 5F  c, hex: 00  c, hex: 00  c, \ !
hex: 00  c, hex: 07  c, hex: 00  c, hex: 07  c, hex: 00  c, \ "
hex: 14  c, hex: 7F  c, hex: 14  c, hex: 7F  c, hex: 14  c, \ #
hex: 24  c, hex: 2A  c, hex: 7F  c, hex: 2A  c, hex: 12  c, \ $
hex: 23  c, hex: 13  c, hex: 08  c, hex: 64  c, hex: 62  c, \ %
hex: 36  c, hex: 49  c, hex: 56  c, hex: 20  c, hex: 50  c, \ &
hex: 00  c, hex: 08  c, hex: 07  c, hex: 03  c, hex: 00  c, \ '
hex: 00  c, hex: 1C  c, hex: 22  c, hex: 41  c, hex: 00  c, \ (
hex: 00  c, hex: 41  c, hex: 22  c, hex: 1C  c, hex: 00  c, \ )
hex: 2A  c, hex: 1C  c, hex: 7F  c, hex: 1C  c, hex: 2A  c, \ *
hex: 08  c, hex: 08  c, hex: 3E  c, hex: 08  c, hex: 08  c, \ +
hex: 00  c, hex: 80  c, hex: 70  c, hex: 30  c, hex: 00  c, \ ,
hex: 08  c, hex: 08  c, hex: 08  c, hex: 08  c, hex: 08  c, \ -
hex: 00  c, hex: 00  c, hex: 60  c, hex: 60  c, hex: 00  c, \ .
hex: 20  c, hex: 10  c, hex: 08  c, hex: 04  c, hex: 02  c, \ /
hex: 3E  c, hex: 51  c, hex: 49  c, hex: 45  c, hex: 3E  c, \ 0
hex: 00  c, hex: 42  c, hex: 7F  c, hex: 40  c, hex: 00  c, \ 1
hex: 72  c, hex: 49  c, hex: 49  c, hex: 49  c, hex: 46  c, \ 2
hex: 21  c, hex: 41  c, hex: 49  c, hex: 4D  c, hex: 33  c, \ 3
hex: 18  c, hex: 14  c, hex: 12  c, hex: 7F  c, hex: 10  c, \ 4
hex: 27  c, hex: 45  c, hex: 45  c, hex: 45  c, hex: 39  c, \ 5
hex: 3C  c, hex: 4A  c, hex: 49  c, hex: 49  c, hex: 31  c, \ 6
hex: 41  c, hex: 21  c, hex: 11  c, hex: 09  c, hex: 07  c, \ 7
hex: 36  c, hex: 49  c, hex: 49  c, hex: 49  c, hex: 36  c, \ 8
hex: 46  c, hex: 49  c, hex: 49  c, hex: 29  c, hex: 1E  c, \ 9
hex: 00  c, hex: 00  c, hex: 14  c, hex: 00  c, hex: 00  c, \ :
hex: 00  c, hex: 40  c, hex: 34  c, hex: 00  c, hex: 00  c, \ ;
hex: 00  c, hex: 08  c, hex: 14  c, hex: 22  c, hex: 41  c, \ <
hex: 14  c, hex: 14  c, hex: 14  c, hex: 14  c, hex: 14  c, \ =
hex: 00  c, hex: 41  c, hex: 22  c, hex: 14  c, hex: 08  c, \ >
hex: 02  c, hex: 01  c, hex: 59  c, hex: 09  c, hex: 06  c, \ ?
hex: 3E  c, hex: 41  c, hex: 5D  c, hex: 59  c, hex: 4E  c, \ @
hex: 7C  c, hex: 12  c, hex: 11  c, hex: 12  c, hex: 7C  c, \ A
hex: 7F  c, hex: 49  c, hex: 49  c, hex: 49  c, hex: 36  c, \ B
hex: 3E  c, hex: 41  c, hex: 41  c, hex: 41  c, hex: 22  c, \ C
hex: 7F  c, hex: 41  c, hex: 41  c, hex: 41  c, hex: 3E  c, \ D
hex: 7F  c, hex: 49  c, hex: 49  c, hex: 49  c, hex: 41  c, \ E
hex: 7F  c, hex: 09  c, hex: 09  c, hex: 09  c, hex: 01  c, \ F
hex: 3E  c, hex: 41  c, hex: 41  c, hex: 51  c, hex: 73  c, \ G
hex: 7F  c, hex: 08  c, hex: 08  c, hex: 08  c, hex: 7F  c, \ H
hex: 00  c, hex: 41  c, hex: 7F  c, hex: 41  c, hex: 00  c, \ I
hex: 20  c, hex: 40  c, hex: 41  c, hex: 3F  c, hex: 01  c, \ J
hex: 7F  c, hex: 08  c, hex: 14  c, hex: 22  c, hex: 41  c, \ K
hex: 7F  c, hex: 40  c, hex: 40  c, hex: 40  c, hex: 40  c, \ L
hex: 7F  c, hex: 02  c, hex: 1C  c, hex: 02  c, hex: 7F  c, \ M
hex: 7F  c, hex: 04  c, hex: 08  c, hex: 10  c, hex: 7F  c, \ N
hex: 3E  c, hex: 41  c, hex: 41  c, hex: 41  c, hex: 3E  c, \ O
hex: 7F  c, hex: 09  c, hex: 09  c, hex: 09  c, hex: 06  c, \ P
hex: 3E  c, hex: 41  c, hex: 51  c, hex: 21  c, hex: 5E  c, \ Q
hex: 7F  c, hex: 09  c, hex: 19  c, hex: 29  c, hex: 46  c, \ R
hex: 26  c, hex: 49  c, hex: 49  c, hex: 49  c, hex: 32  c, \ S
hex: 03  c, hex: 01  c, hex: 7F  c, hex: 01  c, hex: 03  c, \ T
hex: 3F  c, hex: 40  c, hex: 40  c, hex: 40  c, hex: 3F  c, \ U
hex: 1F  c, hex: 20  c, hex: 40  c, hex: 20  c, hex: 1F  c, \ V
hex: 3F  c, hex: 40  c, hex: 38  c, hex: 40  c, hex: 3F  c, \ W
hex: 63  c, hex: 14  c, hex: 08  c, hex: 14  c, hex: 63  c, \ X
hex: 03  c, hex: 04  c, hex: 78  c, hex: 04  c, hex: 03  c, \ Y

(*
hex: 61  c, hex: 59  c, hex: 49  c, hex: 4D  c, hex: 43  c, \ Z \ Z unused 
hex: 00  c, hex: 7F  c, hex: 41  c, hex: 41  c, hex: 41  c, \ [
hex: 02  c, hex: 04  c, hex: 08  c, hex: 10  c, hex: 20  c, \ \
hex: 00  c, hex: 41  c, hex: 41  c, hex: 41  c, hex: 7F  c, \ ]
hex: 04  c, hex: 02  c, hex: 01  c, hex: 02  c, hex: 04  c, \ ^
hex: 40  c, hex: 40  c, hex: 40  c, hex: 40  c, hex: 40  c, \ _
hex: 00  c, hex: 03  c, hex: 07  c, hex: 08  c, hex: 00  c, \ `
hex: 20  c, hex: 54  c, hex: 54  c, hex: 78  c, hex: 40  c, \ a
hex: 7F  c, hex: 28  c, hex: 44  c, hex: 44  c, hex: 38  c, \ b
hex: 38  c, hex: 44  c, hex: 44  c, hex: 44  c, hex: 28  c, \ c
hex: 38  c, hex: 44  c, hex: 44  c, hex: 28  c, hex: 7F  c, \ d
hex: 38  c, hex: 54  c, hex: 54  c, hex: 54  c, hex: 18  c, \ e
hex: 00  c, hex: 08  c, hex: 7E  c, hex: 09  c, hex: 02  c, \ f
hex: 18  c, hex: A4  c, hex: A4  c, hex: 9C  c, hex: 78  c, \ g
hex: 7F  c, hex: 08  c, hex: 04  c, hex: 04  c, hex: 78  c, \ h
hex: 00  c, hex: 44  c, hex: 7D  c, hex: 40  c, hex: 00  c, \ i
hex: 20  c, hex: 40  c, hex: 40  c, hex: 3D  c, hex: 00  c, \ j
hex: 7F  c, hex: 10  c, hex: 28  c, hex: 44  c, hex: 00  c, \ k
hex: 00  c, hex: 41  c, hex: 7F  c, hex: 40  c, hex: 00  c, \ l
hex: 7C  c, hex: 04  c, hex: 78  c, hex: 04  c, hex: 78  c, \ m
hex: 7C  c, hex: 08  c, hex: 04  c, hex: 04  c, hex: 78  c, \ n
hex: 38  c, hex: 44  c, hex: 44  c, hex: 44  c, hex: 38  c, \ o
hex: FC  c, hex: 18  c, hex: 24  c, hex: 24  c, hex: 18  c, \ p
hex: 18  c, hex: 24  c, hex: 24  c, hex: 18  c, hex: FC  c, \ q
hex: 7C  c, hex: 08  c, hex: 04  c, hex: 04  c, hex: 08  c, \ r
hex: 48  c, hex: 54  c, hex: 54  c, hex: 54  c, hex: 24  c, \ s
hex: 04  c, hex: 04  c, hex: 3F  c, hex: 44  c, hex: 24  c, \ t
hex: 3C  c, hex: 40  c, hex: 40  c, hex: 20  c, hex: 7C  c, \ u
hex: 1C  c, hex: 20  c, hex: 40  c, hex: 20  c, hex: 1C  c, \ v
hex: 3C  c, hex: 40  c, hex: 30  c, hex: 40  c, hex: 3C  c, \ w
hex: 44  c, hex: 28  c, hex: 10  c, hex: 28  c, hex: 44  c, \ x
hex: 4C  c, hex: 90  c, hex: 90  c, hex: 90  c, hex: 7C  c, \ y
hex: 44  c, hex: 64  c, hex: 54  c, hex: 4C  c, hex: 44  c, \ z
*)

\ Foreground and background color storage
WHT init-variable: fgC
BLK init-variable: bgC

\ Set the text's foreground color
: setFG	( color -- )
  fgC !
;

\ Set the text's background color
: setBG	( color -- )
  bgC !
;

1 init-variable: _sz_

\ Set the size of the text
: setSize	( size -- )
  _sz_ !
;

\ A variation on fillRect
: fr            ( x y width height color -- )
  >r            ( x y width height color -- x y width height )
  rot                 ( x y width height -- x width height y )
  dup                 ( x width height y -- x width height y y )
  rot               ( x width height y y -- x width y y height )
  +                 ( x width y y height -- x width y y+height )
  >r                ( x width y y+height -- x width y )
  -rot                       ( x width y -- y x width )
  over                       ( y x width -- y x width x )
  +                        ( y x width x -- y x x+width )
  >r                       ( y x width+x -- y x )
  swap                             ( y x -- x y )
  r>                               ( x y -- x y x+width )
  r>                       ( x y x+width -- x y x+width y+height )
  r>              ( x y x+width y+height -- x y x+width y+height color )
  fillRect  ( x y x+width y+height color -- )
;

variable: _c_

\ Print a character from the font
: pChr		        ( x y c -- )

  \ For this app convert LC chars to UC chars
  dup                   ( x y c -- x y c c )
  hex: 61	      ( x y c c -- x y c c x61 )
  swap            ( x y c c x61 -- x y c x61 c )
  hex: 7A         ( x y c x61 c -- x y c x61 c x7A )
  between?    ( x y c x61 c x7A -- x y c f )
  if
      hex: DF and
  then

  \ Calculate offset of char data in font
  hex: 20 - FW *	                                 ( x y c -- x y offset )

  FW 1+ 0		\ For each column
  do
      dup                                           ( x y offset -- x y offset offset )
      FNT + i + c@                           ( x y offset offset -- x y offset c )
      i 5 =		\ Add a blank final column between characters
      if
           drop 0    
      then
      8 0		\ For each row
      do
          dup                                      ( x y offset c -- x y offset c c ) 
          1 i lshift                             ( x y offset c c -- x y offset c c mask )
          and                               ( x y offset c c mask -- x y offset c f )
          if
              fgC @                                ( x y offset c -- x y offset c color )
          else
              bgC @                                ( x y offset c -- x y offset c color ) 
          then    
          _c_ !                              ( x y offset c color -- x y offset c )
          2over                                    ( x y offset c -- x y offset c x y )
          swap                                 ( x y offset c x y -- x y offset c y x )
          _sz_ @ 1 =             
          if  \ No scaling ?
              j +                              ( x y offset c y x -- x y offset c y x+j )
              swap                           ( x y offset c y x+j -- x y offset c x+j y )
              i +                            ( x y offset c x+j y -- x y offset c x+j y+i )
              _c_ @                        ( x y offset c x+j y+i -- x y offset c x+j y+i color )
              pixel                  ( x y offset c x+j y+i color -- x y offset c )
          else \ Scaling
              _sz_ @ dup                       ( x y offset c y x -- x y offset c y x size size )
              j *                    ( x y offset c y x size size -- x y offset c y x size size*j )
              swap                 ( x y offset c y x size size*j -- x y offset c y x size*j size )
              i *                  ( x y offset c y x size*j size -- x y offset c y x size*j size*i )
              rot rot            ( x y offset c y x size*j size*i --  x y offset c y size*i x size*j )
              +                  ( x y offset c y size*i x size*j -- x y offset c y size*i x+size*j )
              rot rot            ( x y offset c y size*i x+size*j -- x y offset c x+size*j y size*i )
              +                  ( x y offset c x+size*j y size*i -- x y offset c x+size*j y+size*i )
              _sz_ @ dup         ( x y offset c x+size*j y+size*i -- x y offset c x+size*j y+size*i size size )
              _c_ @             ( ... x+size*j y+size*i size size -- ... x+size*j y+size*i size size color )
              fr          ( ... x+size*j y+size*i size size color -- x y offset c )
          then 
      loop
      drop
  loop
  3drop
;

\ Print zero terminated string onto display at specified position 
\ with current text size and foreground and background colors
: pStr		                  ( x y addr -- )
  begin
      dup		          ( x y addr -- x y addr addr )
      c@ dup		     ( x y addr addr -- x y addr c c )
      0 <>		     ( x y addr c c  -- x y addr c f )
  while
      >r                     ( x y addr c    --  x y addr )
      3dup                        ( x y addr -- x y addr x y addr )
      -rot               ( x y addr x y addr -- x y addr addr x y )
      r>                 ( x y addr addr x y -- x y addr addr x y c ) 
      pChr             ( x y addr addr x y c -- x y addr addr )
      drop                   ( x y addr addr -- x y addr )
      1+                          ( x y addr -- x y addr+1 )
      rot                       ( x y addr+1 -- y addr+1 x )
      FW 1+ _sz_ @ * +          ( y addr+1 x -- y addr+1 x' )
      -rot                     ( y addr+1 x' -- 'x y addr+1 )
  repeat
  4drop
;

\ Print a horizontally centered text string
: pCStr                        ( y addr -- )
  dup                          ( y addr -- y addr addr )
  strlen                  ( y addr addr -- y addr len )
  FW 1+ _sz_ @ * *         ( y addr len -- y addr pixelcount )
  WIDTH             ( y addr pixelcount -- y addr pixelcount width )
  swap        ( y addr pixelcount width -- y addr width pixelcount )
  -           ( y addr width pixelcount -- y addr width-pixelcount )
  2 /         ( y addr width-pixelcount -- y addr x )
  rot rot                    ( y addr x -- x y addr )
  pStr
;

\ NTP - Network Time Protocol Access
\ Written for PunyForth
\ By: Craig A. Lindley
\ Last Update: 01/21/2017

\ Program Constants
123  constant: NTP_PRT \ Port to send NTP requests to
48   constant: PK_SZ   \ NTP time stamp in first 48 bytes of message

\ Buffer for UDP packets
PK_SZ byte-array: pBuf

\ NTP server host
str: "time.nist.gov" constant: NTP_SRV

\ Send an NTP request packet and read response packet
: getTime     ( -- secondsSince1970 | 0 )

  \ Clear all bytes of the packet buffer
  PK_SZ 0
  do
      0 i pBuf c!
  loop

  \ Initialize values needed to form NTP request
  hex: E3  0 pBuf c! \ LI, Version, Mode
  hex: 06  2 pBuf c! \ Polling interval
  hex: EC  3 pBuf c! \ Peer clock precision
  hex: 31 12 pBuf c!
  hex: 4E 13 pBuf c!
  hex: 31 14 pBuf c!
  hex: 34 15 pBuf c!
 
  \ Send the UDP packet containing the NTP request
  \ Make connection to NTP server
  NTP_PRT NTP_SRV UDP netcon-connect

  \ Send the NTP packet
  dup 0 pBuf PK_SZ netcon-send-buf

  \ Read response into buffer
  dup
  PK_SZ 0 pBuf netcon-read ( -- netcon bytesRead )
  
  swap                      ( netcon bytesRead -- bytesRead netcon )
  
  \ Terminate the connection
  netcon-dispose            ( bytesRead netcon -- bytesRead )

  PK_SZ =
  if 
      \ Assemble the response into time value
      40 pBuf c@ 24 lshift
      41 pBuf c@ 16 lshift or
      42 pBuf c@  8 lshift or
      43 pBuf c@           or

      2208988800 -	\ SECS_TO_1970         
  else
      0
  then
;


\ Time Library
\ Based on Arduino Time library by Michael Margolis & Paul Stoffregen
\ Written for PunyForth
\ By: Craig A. Lindley
\ Last Update: 01/21/2017

\ Program constants
60       constant: SPM
SPM 60 * constant: SPH
SPH 24 * constant: SPD

600 constant: syncInt       \ NTP time refresh interval in seconds

\ Program variables
variable: sysTime                \ System time
variable: prevMS
variable: nextSync
variable: cacheTime

\ Time element structure - holds time and date
struct 
  cell field: .second 
  cell field: .minute
  cell field: .hour
  cell field: .wday \ Day of week, sunday is day 1
  cell field: .day
  cell field: .month
  cell field: .year
constant: timeElements

\ Create a new time elements object
: newTimeElements: ( "name" -- ) 
  timeElements create: allot
;

\ Instantiate timeElements object for current time
newTimeElements: time

\ Instantiate timeElements object for use with makeTime
newTimeElements: newTime

(*
str: "Year: " constant: yStr
str: "Mon: "  constant: monStr
str: "Day: "  constant: dStr
str: "WDay: " constant: wdStr
str: "Hour: " constant: hStr
str: "Min: "  constant: minStr
str: "Sec: "  constant: sStr


\ Show time elements object
: showTE	( tm -- )
  yStr   type dup .year    @ . space
  monStr type dup .month   @ . space
  dStr   type dup .day     @ . space
  wdStr  type dup .wday    @ . space
  hStr   type dup .hour    @ . space
  minStr type dup .minute  @ . space
  sStr   type     .second  @ . cr cr
;
*)

\ Initialized byte array creator
: byteArray ( N .. 1 number "name" -- ) ( index -- value )
    create: 
        0 do c, loop 
    does> + c@
;

\ Array of days in each month
31 30 31 30 31 31 30 31 30 31 28 31 12 byteArray MONTHDAYS

\ Leap year calc expects argument as years offset from 1970
: leapYear?                   ( year -- f )
  1970 +                      ( year -- year+1970 ) 
  dup dup                    ( year' -- year' year' year' )
  4 % 0=            ( year year year -- year year f )
  swap                 ( year year f -- year f year )
  100 % 0<>            ( year f year -- year f f )
  and                     ( year f f -- year f )
  swap                      ( year f -- f year )
  400 % 0=                  ( f year -- f f )
  or                           ( f f -- f )
;

variable: _year_
variable: _mon_
variable: _monLen_
variable: _days_
variable: _exit_

\ Breakup the seconds since 1970 into individual time elements
: breakTime  ( timeSecs -- )

  dup                           ( timeSecs -- timeSecs timeSecs )  
  60 % time .second !  ( timeSecs timeSecs -- timeSecs )
  60 /                          ( timeSecs -- timeMins )
  dup                           ( timeMins -- timeMins timeMins )
  60 % time .minute !  ( timeMins timeMins -- timeMins )
  60 /                          ( timeMins -- timeHours )
  dup                          ( timeHours -- timeHours timeHours )
  24 % time .hour !  ( timeHours timeHours -- timeHours )
  24 /                         ( timeHours -- timeDays )
  dup                           ( timeDays -- timeDays timeDays )
  4 + 7 % 1+ time .wday ! \ Sunday is day 1
  
  0 _year_ !                    ( timeDays -- )
  0 _days_ !

  begin
      dup                       ( timeDays -- timeDays timeDays )
      _year_ @ leapYear? 
      if 
          366 _days_ +!
      else
          365 _days_ +!
      then
      _days_ @ >       ( timeDays timeDays -- timeDays f )
  while
      1 _year_ +!
  repeat                        ( timeDays -- )
  _year_ @ dup time .year !     ( timeDays -- timeDays year )
  leapYear?                ( timeDays year -- timeDays f ) 
  if 
      366 negate _days_ +!
  else
      365 negate _days_ +!
  then
  _days_ @ -      \ Time is now days in this year starting at 0

  0 _days_ !	  ( -- timeDays )
  0 _mon_ !
  0 _monLen_ !
  FALSE _exit_ !

  begin
      _mon_ @ 12 < _exit_ @ 0= and
  while
      _mon_ @ 1 =        \ Feb ?
      if 
          _year_ @ leapYear?
          if
              29 _monLen_ !
          else
              28 _monLen_ !
          then
      else
          _mon_ @ MONTHDAYS _monLen_ !
      then
      dup                     ( timeDays -- timeDays timeDays )
      _monLen_ @ >=
      if
          _monLen_ @ -
      else
          TRUE _exit_ !
      then
      1 _mon_ +!
  repeat
  _mon_ @ time .month !
  1+ time .day !
;

\ Convert newTime timeElements object into seconds since 1970
\ NOTE: Year is offset from 1970
: makeTime		              ( -- timeSecs )
  \ Seconds from 1970 till 1 jan 00:00:00 of the given year
  newTime .year @	              ( -- year )
  dup			         ( year -- year year )
  365 *                     ( year year -- year daysInYears )
  SPD *     ( year daysInYears -- year secsInYears )
  over               ( year secsInYears -- year secsInYears year )
  0
  do          ( year secsInYears year 0 -- year secsInYears )
      i leapYear?
      if
          SPD +
      then
  loop

  \ Add days for this year, months start from 1
  newTime .month @   ( year secsInYears -- year secsInYears month )
  dup                ( year secsInYears month -- year secsInYears month month )
  1 <>
  if
      1
      do         ( year secsInYears month 1 -- year secsInYears )
          swap dup       ( year secsInYears -- secsInYears year year )
          leapYear? ( secsInYears year year -- secsInYears year f )
          i 2 = and		\ Feb in a leap year?
          if
              swap       ( secsInYears year -- year secsInYears )
              29 SPD * +
          else
              swap       ( secsInYears year -- year secsInYears )
              i 1- MONTHDAYS 
              SPD * +
          then
      loop
  else
      drop      
  then
  nip

  newTime .day    @ 1- SPD  * +
  newTime .hour   @    SPH * +
  newTime .minute @    SPM  * +  
  newTime .second @                    +
;

\ Return the current system time syncing with NTP as appropriate
: now			( -- sysTime )
  \ Calculate number of seconds since last call to now
  begin
    ms@ prevMS @ - abs 1000 >=
  while
    1 sysTime +!	\ Advance system time by one second
    1000 prevMS +!
  repeat

  \ Is it time to sync with NTP ?
  nextSync @ sysTime @ <=
  if
      getTime	( -- ntpTime )
      dup
      sysTime !
      syncInt +
      nextSync !
      ms@ prevMS !
  then
  sysTime @ 
;

\ Check and possibly refresh time cache
: refreshCache   	                  ( timeSecs -- )
  dup dup		                  ( timeSecs -- timeSecs timeSecs timeSecs )
  cacheTime @ <>	( timeSecs timeSecs timeSecs -- timeSecs timeSecs f )
  if
      breakTime		         ( timeSecs timeSecs -- timeSecs )
      cacheTime !	                  ( timeSecs -- )
  else
      2drop			 ( timeSecs timeSecs -- )
  then
;

\ Given time in seconds since 1970 return hour
: hour_t	   ( timeSecs -- hour )
  refreshCache	   ( timeSecs -- )
  time .hour @              ( -- hour )
;

(*
\ Return the now hour
: hour			    ( -- hour )
  now hour_t
;
*)

\ Given time in seconds since 1970 return hour in 12 hour format
: hourFormat12_t    ( timeSecs -- hour12 )
  refreshCache	    ( timeSecs -- )
  time .hour @ dup           ( -- hour hour )
  0=               ( hour hour -- hour f )
  if
      drop              ( hour -- ) 
      12                     ( -- 12 )
  else                       ( -- hour )
      dup               ( hour -- hour hour )
      12 >         ( hour hour -- hour f )
      if
          12 -
      then
  then
;

(*
\ Return now hour in 12 hour format
: hourFormat12               ( -- hour12 )
  now hourFormat12_t
;
*)

\ Given time in seconds since 1970 return PM status
: isPM_t	    ( timeSecs -- f )
  refreshCache	    
  time .hour @ 12 >=
;

(*
\ Determine if now time is PM
: isPM			     ( -- f )
  now isPM_t
;
*)

\ Given time in seconds since 1970 return AM status
: isAM_t 	   ( timeSecs -- f )
  refreshCache	    
  time .hour @ 12 <
;

(*
\ Determine if now time is AM
: isAM			   ( -- f ) 
  now isAM_t
;
*)

\ Given time in seconds since 1970 return minute
: minute_t	   ( timeSecs -- minute )
  refreshCache
  time .minute @
;

(*
\ Return the now minute
: minute			 ( -- minute )
  now minute_t
;
*)

\ Given time in seconds since 1970 return second
: second_t	        ( timeSecs -- second )
  refreshCache
  time .second @
;

(*
\ Return the now second
: second			 ( -- second )
  now second_t
;
*)

\ Given time in seconds since 1970 return day
: day_t 		( timeSecs -- day )
  refreshCache
  time .day @
;

(*
\ Return the now day
: day 			         ( -- day )
  now day_t
;
*)

\ Given time in seconds since 1970 return the week day with Sun as day 1
: weekDay_t		( timeSecs -- weekDay )
  refreshCache
  time .wday @
;

(*
\ Return the now week day with Sun as day 1
: weekDay		 	 ( -- weekDay )
  now weekDay_t
;
*)

\ Given time in seconds since 1970 return month
: month_t		( timeSecs -- month )
  refreshCache
  time .month @
;

(*
\ Return the now month
: month				 ( -- month )
  now month_t
;
*)

\ Given time in seconds since 1970 return year in full 4 digit format
: year_t		( timeSecs -- year )
  refreshCache
  time .year @ 1970 +
;

(*
\ Return the now year in full 4 digit format
: year			 	 ( -- year )
  now year_t
;
*)

(*
Test cases for breakTime and makeTime from Arduino program
ALL SUCCESSFUL
time_t: 1484340438 - Year: 47, Mon:  1, Day: 13, Hour: 20, Min: 47, Sec: 18
time_t: 1525094490 - Year: 48, Mon:  4, Day: 30, Hour: 13, Min: 21, Sec: 30
time_t: 1561177080 - Year: 49, Mon:  6, Day: 22, Hour:  4, Min: 18, Sec: 0
time_t: 1603973175 - Year: 50, Mon: 10, Day: 29, Hour: 12, Min:  6, Sec: 15
time_t: 68166375   - Year:  2, Mon:  2, Day: 28, Hour: 23, Min:  6, Sec: 15
*)

\ Time Zone and Daylight Savings Time Library
\ Based on Arduino Timezone library by Jack Christensen
\ Written for PunyForth
\ By: Craig A. Lindley
\ Last Update: 01/21/2017

\ Structure for describing a time change rule
struct
    cell field: .wk	\ last = 0 first second third fourth
    cell field: .dow	\ Sun = 1 .. Sat
    cell field: .mon	\ Jan = 1 .. Dec
    cell field: .hr     \ 0 .. 23
    cell field: .off	\ Offset from UTC in minutes
constant: TCR

\ Time change rule object creator
: newTCR:	( "name" -- addrTCR ) 
  TCR create: allot
;

\ Structure for describing a title and two time change rules
struct
    cell field: .name
    cell field: .dstTCR
    cell field: .stdTCR
constant: TZ

\ Time zone object creator
: newTZ:	( "name" -- addrTZ )
  TZ create: allot
;

\ Program variables
variable: dstUTC	\ DST start for given/current year, given in UTC
variable: stdUTC	\ STD start for given/current year, given in UTC
variable: dstLoc	\ DST start for given/current year, given in local time
variable: stdLoc	\ STD start for given/current year, given in local time
variable: theTZ		\ Variable holding the current TZ object

\ Temp vars
variable: _y_
variable: _t_
variable: _m_
variable: _w_

\ Convert a time change rule (TCR) to a time_t value for given year
: toTime_t		( TCR year -- time_t )
  _y_ !			( TCR year -- TCR )
  dup .mon  @ _m_ !
  dup .wk @ _w_ !              ( -- TCR )

  _w_ @ 0=		\ Last week ?
  if
      1 _m_ +!
      _m_ @ 12 >
      if
          1 _m_ !
          1 _y_ +!
      then
      1 _w_ !
  then
  dup .hr @ 
    newTime .hour   !
  0 newTime .minute !
  0 newTime .second !
  1 newTime .day    !
  _m_ @ 
    newTime .month  !
  _y_ @ 1970 -
    newTime .year   ! 
  makeTime _t_ !			   ( -- TCR )
  7 _w_ @ 1- *			       ( TCR -- TCR f1 )
  over				    ( TCR f1 -- TCR f1 TCR )
  .dow @			( TCR f1 TCR -- TCR f1 DOW )
  _t_ @ weekDay_t		( TCR f1 DOW -- TCR f1 DOW WD )
  - 			     ( TCR f1 DOW WD -- TCR f1 DOW-WD )
  7 +			     ( TCR f1 DOW-WD -- TCR f1 DOW-WD+7 ) 
  7 %			   ( TCR f1 DOW-WD+7 -- TCR f1 DOW-WD+7%7 )
  +			 ( TCR f1 DOW-WD+7%7 -- TCR DOW-WD+7%7+f1 ) 
  SPD *	                 ( TCR DOW-WD+7%7+f1 -- TCR DOW-WD+7%7+f1*SPD )
   _t_ +!	     ( TCR DOW-WD+7%7+f1*SPD -- TCR )
  .wk @ 0=			       ( TCR -- f )
  if
      -7 SPD * _t_ +!
  then
  _t_ @
;

\ Calculate the DST and standard time change points for the given
\ given year as local and UTC time_t values.  
: calcTC 	            ( year -- )
  dup			    ( year -- year year )
  >r		       ( year year -- year )
  theTZ @ .dstTCR @ 
  swap		            ( year -- TCR year )
  toTime_t dstLoc !	( TCR year -- )
  r>			         ( -- year )
  theTZ @ .stdTCR @
  swap		            ( year -- TCR year )
  toTime_t stdLoc !	( TCR year -- )

  dstLoc @ 
  theTZ @ .stdTCR @
  .off @
  SPM *
  -
  dstUTC !

  stdLoc @ 
  theTZ @ .dstTCR @
  .off @
  SPM *
  -
  stdUTC !
;

\ Determine whether the given UTC time_t is within the DST interval
\ or the Standard time interval
: utcIsDST	               ( utc -- f )
  dup		               ( utc -- utc utc )
  year_t		   ( utc utc -- utc utc_yr )
  dstUTC @	        ( utc utc_yr -- utc utc_yr utc_dst )
  year_t	( utc utc_yr utc_dst -- utc utc_yr dst_yr )
  over		 ( utc utc_yr dst_yr -- utc utc_yr dst_yr utc_yr )
  <> 	  ( utc utc_yr dst_yr utc_yr -- utc utc_yr f )
  if
      calcTC
  else
      drop
  then		                   ( -- utc )
  dup 			       ( utc -- utc utc )
  stdUTC @ 
  dstUTC @  >
  if		\ Northern hemisphere
      dstUTC @ >=	   ( utc utc -- utc f )
      swap		     ( utc f -- f utc )
      stdUTC @ <
      and
  else		\ Southern hemisphere
      stdUTC @ >=	   ( utc utc -- utc f )
      swap		     ( utc f -- f utc )
      dstUTC @ <
      and 0=
  then
;

\ Convert the given UTC time to local time, standard or
\ daylight time, as appropriate
: toLocal		       ( utc -- time_t )
  dup		               ( utc -- utc utc )
  year_t		   ( utc utc -- utc utc_yr )
  dstUTC @	        ( utc utc_yr -- utc utc_yr utc_dst )
  year_t	( utc utc_yr utc_dst -- utc utc_yr dst_yr )
  over		 ( utc utc_yr dst_yr -- utc utc_yr dst_yr utc_yr )
  <> 	  ( utc utc_yr dst_yr utc_yr -- utc utc_yr f )
  if
      calcTC            ( utc utc_yr -- utc )
  else
      drop
  then		                   ( -- utc )
  dup 			       ( utc -- utc utc )
  utcIsDST		   ( utc utc -- utc f )
  if
      theTZ @ .dstTCR @
     .off @
      SPM *
      +
  else
      theTZ @ .stdTCR @
     .off @
      SPM *
      +
  then
;

\ Set the timezone in preparation for time conversion
: setTZ			( tz -- )

  \ Store tz into global variable
  theTZ !

  \ Clear all local variables for new calculation
  0 dstLoc !
  0 stdLoc !
  0 dstUTC !
  0 stdUTC !
;

\ World Clock App
\ Written for PunyForth
\ By: Craig A. Lindley
\ Last Update: 01/21/2017

\ Set TRUE for 12 hour format; FALSE for 24 hour format
TRUE constant: 12HF

\ BEGIN TIME CHANGE RULE DEFINITIONS

(*
Australia Eastern Time Zone (Sydney, Melbourne)
TTimeChangeRule aEDT = {"AEDT", First, Sun, Oct, 2, 660};    //UTC + 11 hours
TimeChangeRule aEST = {"AEST", First, Sun, Apr, 3, 600};    //UTC + 10 hours
Timezone ausET(aEDT, aEST);
*)

\ Create TCR for daylight saving time
newTCR: aEDT

\ Initialize rule
 1 aEDT .wk   ! \ First week
 1 aEDT .dow  ! \ Sun
10 aEDT .mon  ! \ Oct
 2 aEDT .hr   ! \ 2 PM
660 aEDT .off ! \ TZ offset 11 hours

\ Create TCR for standard time
newTCR: aEST

\ Initialize rule
 1 aEST .wk   ! \ First week
 1 aEST .dow  ! \ Sun
 4 aEST .mon  ! \ Apr
 3 aEST .hr   ! \ 3 PM
600 aEST .off ! \ TZ offset 10 hours

\ Create TZ object to hold TCRs
newTZ: ausET

str: "Sydney" ausET .name !
aEDT ausET .dstTCR !
aEST ausET .stdTCR !

(* CURRENTLY NOT USED
//Central European Time (Frankfurt, Paris)
TimeChangeRule CEST = {"CEST", Last, Sun, Mar, 2, 120};     //Central European Summer Time
TimeChangeRule CET = {"CET ", Last, Sun, Oct, 3, 60};       //Central European Standard Timezone CE(CEST, CET);

\ Create TCR for daylight saving time
newTCR: CEST

\ Initialize rule
 0 CEST .wk   ! \ Last week
 1 CEST .dow  ! \ Sun
 3 CEST .mon  ! \ Mar
 2 CEST .hr   ! \ 2 PM
120 CEST .off ! \ TZ offset 2 hours

\ Create TCR for standard time
newTCR: CET

\ Initialize rule
 0 CET .wk   ! \ Last week
 1 CET .dow  ! \ Sun
10 CET .mon  ! \ Oct
 3 CET .hr   ! \ 3 PM
60 CET .off  ! \ TZ offset 1 hours

\ Create TZ object to hold TCRs
newTZ: CE

str: "Frankfurt" CE .name !
CEST CE .dstTCR !
CET  CE .stdTCR !
*)

(*
//United Kingdom (London, Belfast)
TimeChangeRule BST = {"BST", Last, Sun, Mar, 1, 60};        //British Summer Time
TimeChangeRule GMT = {"GMT", Last, Sun, Oct, 2, 0};         //Standard Time
Timezone UK(BST, GMT);
*)

\ Create TCR for daylight saving time
newTCR: BST

\ Initialize rule
 0 BST .wk   ! \ Last week
 1 BST .dow  ! \ Sun
 3 BST .mon  ! \ Mar
 1 BST .hr   ! \ 1 PM
60 BST .off  ! \ TZ offset 1 hours

\ Create TCR for standard time
newTCR: GMT

\ Initialize rule
 0 GMT .wk   ! \ First week
 1 GMT .dow  ! \ Sun
10 GMT .mon  ! \ Oct
 2 GMT .hr   ! \ 2 PM
 0 GMT .off  ! \ TZ offset 1 hours

\ Create TZ object to hold TCRs
newTZ: UK

str: "London" UK .name !
BST UK .dstTCR !
GMT UK .stdTCR !

(*
//US Eastern Time Zone (New York, Detroit)
TimeChangeRule usEDT = {"EDT", Second, Sun, Mar, 2, -240};
TimeChangeRule usEST = {"EST", First, Sun, Nov, 2, -300};
Timezone usET(usEDT, usEST);
*)

\ Create TCR for daylight saving time
newTCR: usEDT

\ Initialize rule
 2 usEDT .wk    ! \ Second week
 1 usEDT .dow   ! \ Sun
 3 usEDT .mon   ! \ Mar
 2 usEDT .hr    ! \ 2 PM
-240 usEDT .off ! \ TZ offset -4 hours

\ Create TCR for standard time
newTCR: usEST

\ Initialize rule
 1 usEST .wk     ! \ First week
 1 usEST .dow    ! \ Sun
11 usEST .mon    ! \ Nov
 2 usEST .hr     ! \ 2 PM
-300 usEST .off  ! \ TZ offset -5 hours

\ Create TZ object to hold TCRs
newTZ: usET

str: "New York" usET .name !
usEDT usET .dstTCR !
usEST usET .stdTCR !

(* CURRENTLY NOT USED
//US Central Time Zone (Chicago, Houston)
TimeChangeRule usCDT = {"CDT", Second, Sun, Mar, 2, -300};
TimeChangeRule usCST = {"CST", First, Sun, Nov, 2, -360};
Timezone usCT(usCDT, usCST);

\ Create TCR for daylight saving time
newTCR: usCDT

\ Initialize rule
 2 usCDT .wk    ! \ Second week
 1 usCDT .dow   ! \ Sun
 3 usCDT .mon   ! \ Mar
 2 usCDT .hr    ! \ 2 PM
-300 usCDT .off ! \ TZ offset -5 hours

\ Create TCR for standard time
newTCR: usCST

\ Initialize rule
 1 usCST .wk     ! \ First week
 1 usCST .dow    ! \ Sun
11 usCST .mon    ! \ Nov
 2 usCST .hr     ! \ 2 PM
-360 usCST .off  ! \ TZ offset -6 hours

\ Create TZ object to hold TCRs
newTZ: usCT

str: "Houston" usCT .name !
usCDT usCT .dstTCR !
usCST usCT .stdTCR !
*)
 
(*
//US Mountain Time Zone (Denver, Salt Lake City)
TimeChangeRule usMDT = {"MDT", Second, Sun, Mar, 2, -360};
TimeChangeRule usMST = {"MST", First, Sun, Nov, 2, -420};
Timezone usMT(usMDT, usMST);
*)

\ Create TCR for daylight savings time
newTCR: usMDT

\ Initialize rule
 2 usMDT .wk    ! \ Second week
 1 usMDT .dow   ! \ Sun
 3 usMDT .mon   ! \ Mar
 2 usMDT .hr    ! \ 2 PM
-360 usMDT .off ! \ TZ offset -6 hours

\ Create TCR for standard time
newTCR: usMST

\ Initialize rule
 1 usMST .wk    ! \ First week
 1 usMST .dow   ! \ Sun
11 usMST .mon   ! \ Nov
 2 usMST .hr    ! \ 2 PM
-420 usMST .off ! \ TZ offset -7 hours

\ Create TZ object to hold TCRs
newTZ: usMT

str: "Denver" usMT .name !
usMDT usMT .dstTCR !
usMST usMT .stdTCR !

(* CURRENTLY NOT USED
//Arizona is US Mountain Time Zone but does not use DST
Timezone usAZ(usMST, usMST);

\ Create TZ object to hold TCRs
newTZ: usAZ

str: "Phoenix" usAZ .name !
usMST usAZ .dstTCR !
usMST usAZ .stdTCR !
*)

(*
//US Pacific Time Zone (Las Vegas, Los Angeles)
TimeChangeRule usPDT = {"PDT", Second, Sun, Mar, 2, -420};
TimeChangeRule usPST = {"PST", First, Sun, Nov, 2, -480};
Timezone usPT(usPDT, usPST);
*)

\ Create TCR for daylight savings time
newTCR: usPDT

\ Initialize rule
 2 usPDT .wk    ! \ Second week
 1 usPDT .dow   ! \ Sun
 3 usPDT .mon   ! \ Mar
 2 usPDT .hr    ! \ 2 PM
-420 usPDT .off ! \ TZ offset -7 hours

\ Create TCR for standard time
newTCR: usPST

\ Initialize rule
 1 usPST .wk    ! \ First week
 1 usPST .dow   ! \ Sun
11 usPST .mon   ! \ Nov
 2 usPST .hr    ! \ 2 PM
-480 usPST .off ! \ TZ offset -8 hours

\ Create TZ object to hold TCRs
newTZ: usPT

str: "Los Angeles" usPT .name !
usPDT usPT .dstTCR !
usPST usPT .stdTCR !

\ END TIME CHANGE RULE DEFINITIONS

\ Format buffer
20 buffer: fbuf
variable: i

\ Copy a string into format buffer
: cat                 ( sAddr -- ) 
  begin
      dup             ( sAddr -- sAddr sAddr )
      c@        ( sAddr sAddr -- sAddr c )
      dup           ( sAddr c -- sAddr c c )
      0           ( sAddr c c -- sAddr c c 0 )
      <>        ( sAddr c c 0 -- sAddr c f )
  while
      i @ fbuf + c! ( sAddr c -- sAddr )
      1 i +!
      1+              ( sAddr -- sAddr+1 )
  repeat
  i @ fbuf + c!     ( sAddr c -- sAddr )
  drop
;

5 buffer: nbuf
variable: j
variable: i1

\ Integer to string conversion
\ Can only do positive numbers with less than 5 digits
: i2s		           ( n -- )
  0 i1 !
  begin
     dup	           ( n -- n n )
     10 %	         ( n n -- n n%10 )
     48 +	      ( n n%10 -- n n%10+48 ) 
     i1 @ nbuf + c! ( n n%10+48 -- n )
     1 i1 +!
     10 /		   ( n -- n/10 )
     dup                ( n/10 -- n/10 n/10 )
     0 <=	   ( n/10 n/10 -- n/10 f )
  until
  drop
  0 i1 @ nbuf + c!

  \ Now reverse the characters in the string

  i1 @ 1- j !
  0 i1 !

  begin
      i1 @ nbuf + c@	             ( -- nbuf[i] )
      j @ nbuf + c@          ( nbuf[i] -- nbuf[i] nbuf[j] )
      i1 @ nbuf + c! ( nbuf[i] nbuf[j] -- nbuf[i] )
      j @ nbuf + c!          ( nbuf[i] -- )
       1 i1 +!
      -1 j +!
       i1 @ j @ >
  until
; 

\ String array creator
: sa: ( strN .. str1 number "name" -- ) ( index -- addr of string )
    create: 
        0 do , loop 
    does> swap cells + @
;

\ Months string array
str: "Dec" str: "Nov" str: "Oct" str: "Sep"    
str: "Aug" str: "Jul" str: "Jun" str: "May"
str: "Apr" str: "Mar" str: "Feb" str: "Jan"
str: ""  
13 sa: MON

\ Days string array
str: "Sat" str: "Fri" str: "Thu" str: "Wed" 
str: "Tue" str: "Mon" str: "Sun" str: ""  
8 sa: DOW

\ Am - Pm string array
str: "PM" str: "AM"
2 sa: AMPM

\ Display time and date. Assumes theTZ set before call
: dtd

  \ Clear the dynamic area of the screen
  2 14 WIDTH 3 - HEIGHT 15 - BLK fillRect

  \ Print using larger text
  2 _sz_ !

  \ Print the name of the city
  20 theTZ @ .name @ pCStr

  \ Get the UTC time and convert it to local time
  now toLocal >r   

  \ Print day of the week
  41 r@ weekDay_t DOW pCStr
   
  \ Initialize format buffer index
  0 i !

  \ Format date string like: Wed Jan 18, 2017
  r@ month_t   MON cat str: " " cat
  r@ day_t     i2s nbuf cat str: ", " cat
  r@ year_t    i2s nbuf cat
  \ Print the centered date line
  62 fbuf pCStr  

  \ Initialize format buffer index
  0 i !

  \ Format the time string like: 9:59 AM
  r@
  12HF
  if
      hourFormat12_t
  else
      hour_t
  then
  i2s nbuf cat
  str: ":" cat
  r@ minute_t i2s nbuf
  \ If minutes single digit 0..9 add leading zero to string 
  dup strlen 1 =
  if
      str: "0" cat
  then
  cat
  str: " " cat
  r@ isAM_t
  if
      0 AMPM
  else
      1 AMPM
  then
  cat

  \ Print the centered time line
  3 _sz_ !	\ Print large text
  85 fbuf pCStr  
 
  \ Clean up
  r> drop
;

variable: tz

\ Run the world clock app
: wc

  \ Initialize the LCD controller
  initLCD

  \ Clear the LCD to black
  0 0 WIDTH 1- HEIGHT 1- BLK fillRect

  \ Draw display frame
  0    0      WIDTH     YEL hLine
  0 HEIGHT 1- WIDTH     YEL hLine
  0    1     HEIGHT 2 - YEL vLine
  WIDTH 1- 1 HEIGHT 2 - YEL vLine

  GRN setFG

  \ Draw fixed text
  5   str: "World Clock"      pCStr
  116 str: "Craig A. Lindley" pCStr

  begin
      tz @
      case
          0 of ausET setTZ endof
          1 of UK    setTZ endof
          2 of usET  setTZ endof
          3 of usMT  setTZ endof
          4 of usPT  setTZ endof
      endcase
      \ Print the time and data for selected time zone
      dtd
      1 tz +!
      tz @ 4 >
      if
            0 tz !
      then
      \ Wait 30 seconds
      30000 ms
  again
;

wc










