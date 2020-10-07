NETCON load
EVENT  load
GPIO   load

\ Detects motion using a PIR sensor and notifies a server via TCP
\ I tested this with these mini IR PIR sensors 
\ http://www.banggood.com/3Pcs-Mini-IR-Infrared-Pyroelectric-PIR-Body-Motion-Human-Sensor-Detector-Module-p-1020422.html

4 ( D2 leg ) constant: PIN
Event buffer: event
defer: listener
variable: last-time

: pir? ( evt -- bool ) { .type @ EVT_GPIO = } { .payload @ PIN = } bi and ;
: recent? ( evt -- bool ) ms@ swap .ms @ - 800 < ;
: time-since-last ( -- ms ) ms@ last-time @ - ;
: handle? ( -- bool ) event pir? event recent? time-since-last 5000 > and and ;

: start-detector ( -- )
    PIN GPIO_IN gpio-mode
    PIN GPIO_INTTYPE_EDGE_POS gpio-set-interrupt
    begin
        event next-event handle?  if
            ms@ last-time !
            ['] listener catch ?dup if ex-type cr then
        then
    again ;

"K" constant: ID
variable: server

: connect ( -- ) 8030 "192.168.0.10" TCP netcon-connect server ! ;
: dispose ( -- ) server @ netcon-dispose ;
: send ( -- ) server @ ID 1 netcon-write-buf ;
: notify-server ( -- ) connect ['] send catch dispose throw ;

' listener is: notify-server
start-detector
