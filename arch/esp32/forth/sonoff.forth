GPIO load

\ module for sonoff smart socket

12 constant: RELAY
RELAY GPIO_OUT gpio-mode
FALSE init-variable: relay-state

: on? ( -- bool ) relay-state @ ;

: on  ( -- )
    on? if exit then
    TRUE relay-state !
    RELAY GPIO_HIGH gpio-write ;
    
: off ( -- )
    on? if
        FALSE relay-state !
        RELAY GPIO_LOW gpio-write
    then ;
    
: toggle ( -- ) on? if off else on then ;

13 constant: LED
LED GPIO_OUT gpio-mode
    
: led-on  ( -- ) LED GPIO_LOW  gpio-write ; 
: led-off ( -- ) LED GPIO_HIGH gpio-write ;

: flash ( n -- ) LED swap times-blink led-off ;
: alert ( -- ) 10 flash ; 

/end

