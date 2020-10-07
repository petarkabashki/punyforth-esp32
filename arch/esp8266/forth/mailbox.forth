RINGBUF load

: mailbox: ( size ) ( -- mailbox ) ringbuf: ;

: mailbox-send ( message mailbox -- )
    begin
        dup ringbuf-full? 
    while
        pause 
    repeat
    ringbuf-enqueue ;

: mailbox-receive ( mailbox -- message )
    begin
        dup ringbuf-empty?
    while
        pause
    repeat
    ringbuf-dequeue ;

/end

