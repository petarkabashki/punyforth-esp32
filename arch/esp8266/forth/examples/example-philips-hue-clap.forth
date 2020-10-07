\ simple clap sound detector demo that toggles philips hue lights

4 constant: SOUND_PIN         \ D2 leg

variable: last-sound
variable: started
variable: clap1
variable: clap2
variable: silence

200 constant: SILENCE_LOW
450 constant: SILENCE_HIGH
0   constant: CLAP_LOW
150 constant: CLAP_HIGH

defer: clap-detected
Event buffer: event
0 task: detector-task

: sound-event? ( event -- bool )
    { .type @ EVT_GPIO = }
    { .payload @ SOUND_PIN = } bi and ;

: recent-event? ( event -- bool )
    ms@ swap .ms @ - 1000 < ;

: clap? ( -- bool )
    print: 'clap1: ' clap1 ? cr
    print: 'clap2: ' clap2 ? cr
    print: 'silence: ' silence ? cr
    SILENCE_LOW silence @ SILENCE_HIGH between?
    CLAP_LOW clap2 @ CLAP_HIGH between?
    CLAP_LOW clap1 @ CLAP_HIGH between? 
    and and ;

: event-loop ( task -- )
    activate
    begin
        event next-event 
        event sound-event? event recent-event? and if
            event .ms @ last-sound @ - silence !
            silence @ 60 > if
                last-sound @ started @ - clap2 !
                clap? if clap-detected then
                clap2 @ clap1 !
                event .ms @ started !
            then
            event .ms @ last-sound !
        then
    again
    deactivate ;

: lights-on ( -- ) BEDROOM toggle ;

: clap-detector-start ( -- )
    multi
    SOUND_PIN GPIO_IN gpio-mode
    SOUND_PIN GPIO_INTTYPE_EDGE_NEG gpio-set-interrupt
    ['] clap-detected is: lights-on
    detector-task event-loop ;
    
clap-detector-start