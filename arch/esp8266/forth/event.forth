TASKS load

struct
    cell field: .type
    cell field: .ms
    cell field: .us    
    cell field: .payload
constant: Event

100 constant: EVT_GPIO
70 init-variable: event-timeout

: next-event ( event-struct -- event )
    begin
        dup event-timeout @ wait-event 0=
    while
        pause
    repeat 
    drop ;

/end

