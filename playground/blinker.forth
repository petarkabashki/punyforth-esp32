( This is a simple Punyforth application that blinks a LED )
GPIO load \ load GPIO module first otherwise we won't be able to use GPIO related words

\ This constant defines the GPIO pin that is attached to a LED
13 constant: LED \ D7 leg on a nodemcu devboard

\ Let's define a new word that will blink the LED 10 times
: start-blinking ( -- )
    println: 'Starting blinking LED'
    LED 10 times-blink
    println: 'Stopped blinking LED' ;

\ execute the previously defined word
start-blinking