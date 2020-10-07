NTP load
SSD1306I2C load
FONT57 load

variable: clock
variable: tick
variable: timezone
0 init-variable: offset
0 init-variable: last-sync
3 byte-array: ]mm   0 2 ]mm c!  : mm 0 ]mm ;
3 byte-array: ]hh   0 2 ]hh c!  : hh 0 ]hh ;

: age ( -- ms ) ms@ last-sync @ - ;
: expired? ( -- bool ) age 60000 15 * > ;
: stale? ( -- bool ) age 60000 60 * > clock @ 0= or ;
: fetch ( -- ts ) 123 "time.google.com" network-time ;
: sync ( -- ) { fetch clock ! ms@ last-sync ! } catch ?dup if print: 'sync error:' ex-type cr then ;
: time  ( -- ts )  clock @ offset @ 60 * + age 1000 / + ;
: mins ( ts -- n ) 60 / 60 % ;
: hour ( ts -- n ) 3600 / 24 % ;
: secs ( ts ---n ) 60 % ;

\ based on: http://howardhinnant.github.io/date_algorithms.html#civil_from_days
: era   ( ts -- n ) 86400 / 719468 + dup 0< if 146096 - then 146097 / ;
: doe   ( ts -- n ) dup 86400 / 719468 + swap era 146097 * - ;
: yoe   ( ts -- n ) doe dup 1460 / over 36524 / + over 146096 / - - 365 / ;
: doy   ( ts -- n ) dup doe swap yoe dup 365 * over 4 / + swap 100 / - - ;
: mp    ( ts -- n ) doy 5 * 2 + 153 / ;
: epoch-days ( ts -- n ) dup era 146097 * swap doe + 719468 - ;
: weekday ( ts -- 1..7=mon..sun ) epoch-days dup -4 >= if 4 + 7 % else 5 + 7 % 6 + then ?dup 0= if 7 then ;
: day   ( ts -- 1..31 ) dup doy swap mp 153 * 2 + 5 / - 1+ ;
: month ( ts -- 1..12 ) mp dup 10 < if 3 else -9 then + ;
: year  ( ts -- n ) dup yoe over era 400 * + swap month 2 < if 1 else 0 then + ;

: era ( year -- n ) dup 0< if 399 - then 400 / ;
: yoe ( year --n ) dup era 400 * - ;
: doy ( d m -- n ) dup 2 > if -3 else 9 then + 153 * 2 + 5 / swap + 1- ;
: doe ( d m y -- n ) yoe dup 365 * over 4 / + swap 100 / - -rot doy + ;
: days ( d m y -- days-since-epoch ) over 2 <= if 1- then dup era 146097 * >r doe r> + 719468 - ;
: >ts ( d m y -- ts ) days 86400 * ;

struct
    cell field: .week    \ 1st..4th
    cell field: .dow     \ 1..7 mon..sun
    cell field: .month   \ 1..12
    cell field: .hour    \ 0..23
    cell field: .offset  \ Offset from UTC in minutes
    cell field: .name
constant: RULE
: rule: RULE create: allot ;

struct
    cell field: .standard
    cell field: .summer
constant: TZ
: tz: TZ create: allot ;

( US West Coast )
rule:  PST
 1     PST .week     !
 7     PST .dow      !
11     PST .month    !
 2     PST .hour     !
-480   PST .offset   !
"PST"  PST .name     !
rule:  PDT
 2     PDT .week     !
 7     PDT .dow      !
 3     PDT .month    !
 2     PDT .hour     !
-420   PDT .offset   !
"PDT"  PDT .name     !
tz:    US3
PST    US3 .standard !
PDT    US3 .summer   !

( US East Coast )
rule:  EST
 1     EST .week     !
 7     EST .dow      !
11     EST .month    !
 2     EST .hour     !
-300   EST .offset   !
"EST"  EST .name     !
rule:  EDT
 2     EDT .week     !
 7     EDT .dow      !
 3     EDT .month    !
 2     EDT .hour     !
-240   EDT .offset   !
"EDT"  EDT .name     !
tz:    US1
EST    US1 .standard !
EDT    US1 .summer   !

: 1stday ( month -- 1..7 ) 1 swap time year >ts weekday ;
: dday ( rule -- day )
    dup  .dow @ 
    over .month @ 1stday 2dup >= if - else 7 swap - + then 1+ 
    swap .week @ 1- 7 * + ;

: shifting-time ( rule -- utc )
    dup  dday
    over .month @ time year >ts 
    over .offset @ -60 * +
    swap .hour   @ 3600 * + ;

: summer-start   ( -- utc ) timezone @ .summer   @ shifting-time ;
: standard-start ( -- utc ) timezone @ .standard @ shifting-time ;
: [a,b)? ( a n b -- bool ) over > -rot <= and ;
: daylight-saving? ( -- bool )
    standard-start summer-start > if
        summer-start time standard-start [a,b)?
    else
        summer-start time standard-start [a,b)? invert
    then ;
: current-zone ( -- rule ) daylight-saving? if timezone @ .summer @ else timezone @ .standard @ then ;
: apply-zone ( -- ) current-zone .offset @ offset ! ;

: format ( -- )
    time hour 10 < if $0 hh c! 1 else 0 then ]hh time hour >str
    time mins 10 < if $0 mm c! 1 else 0 then ]mm time mins >str ;

: center ( -- ) 
    WIDTH  2 / "00:00 PDT" str-width 2 / - text-left !
    HEIGHT 2 / 8 font-size @ * 2 / -       text-top  ! ;
: colon ( -- ) tick @ if ":" else " " then draw-str tick @ invert tick ! ;
: clean ( -- ) 0 fill-buffer ;
: draw-time ( -- )
    format
    WIDTH 128 >= if font-medium else font-small then
    center hh draw-str colon mm draw-str " " draw-str
    current-zone .name @ draw-str ;

: stale-warning ( -- ) font-small 0 text-top ! 0 text-left ! "Stale" draw-str ;
: draw ( -- ) clean stale? if stale-warning else apply-zone draw-time then display ;
: start ( task -- ) activate begin expired? if sync then draw 1000 ms pause again ;

0 task: time-task
: main ( -- )
    US3 timezone !
    display-init font5x7 font !  
    sync multi time-task start ;

main
