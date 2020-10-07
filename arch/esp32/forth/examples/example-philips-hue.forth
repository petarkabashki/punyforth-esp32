NETCON load

\ HUE Bridge local IP and port
"192.168.0.12" constant: BRIDGE_IP 
80 constant: BRIDGE_PORT
\ Base URL containing the HUE API key
"/api/<YOUR_HUE_API_KEY>/lights/" constant: BASE_URL
\ Light bulb ids for each room
"1" constant: HALL
"2" constant: BEDROOM

1024 constant: buffer-len
buffer-len buffer: buffer

: parse-http-code ( buffer -- code | throws:ECONVERT )
    9 + 3 >number invert if
        ECONVERT throw
    then ;
    
exception: EHTTP
    
: read-http-code ( netconn -- http-code | throws:EHTTP )
    buffer-len buffer netcon-readln
    0 <= if EHTTP throw then           
    buffer "HTTP/" str-starts? if
        buffer parse-http-code        
    else
        EHTTP throw
    then ;
   
: skip-http-headers ( netconn -- netconn )   
    begin
        dup buffer-len buffer netcon-readln -1 <>
    while
        \ print: 'skipping header: ' buffer type cr
        buffer strlen 0= if
            \ println: 'end of header detected'
            exit
        then
    repeat
    EHTTP throw ;
   
: read-http-resp ( netconn -- response-code )    
    dup read-http-code
    swap skip-http-headers    
    buffer-len buffer netcon-readln      
    print: 'body len=' . cr ;
    
: log-http-resp ( response-code -- response-code )
    dup print: 'HTTP:' . space buffer type cr ;
        
: consume&dispose ( netcon -- )      
    dup read-http-resp log-http-resp
    swap netcon-dispose
    200 <> if EHTTP throw then ;
        
: bridge ( -- netconn )
    BRIDGE_PORT BRIDGE_IP TCP netcon-connect ;

: on? ( bulb -- bool )
    bridge
        dup "GET "     netcon-write
        dup BASE_URL        netcon-write
        dup rot             netcon-write
        dup "\r\n\r\n" netcon-write
        consume&dispose
        buffer "\"on\":true" str-in? ;        
    
: request-change-state ( bulb netconn -- )
    dup "PUT "                               netcon-write
    dup BASE_URL                                  netcon-write
    dup rot                                       netcon-write
    dup "/state HTTP/1.1\r\n"                netcon-write
    dup "Content-Type: application/json\r\n" netcon-write
    dup "Accept: */*\r\n"                    netcon-write
    dup "Connection: Close\r\n"              netcon-write
    drop ;

: on ( bulb -- )
    bridge
        tuck request-change-state
        dup "Content-length: 22\r\n\r\n" netcon-write        
        dup "{\"on\":true,\"bri\": 255}\r\n" netcon-write
        netcon-dispose ;
        
: off ( bulb -- )
    bridge
        tuck request-change-state
        dup "Content-length: 12\r\n\r\n" netcon-write        
        dup "{\"on\":false}\r\n"           netcon-write
        netcon-dispose ;

: toggle ( bulb -- )
    dup ['] on? catch ?dup if
        print: 'Error checking light. ' ex-type cr
        2drop
        exit
    then
    { if off else on then } catch ?dup if
        print: 'Error toggling light. ' ex-type cr
        2drop
    then ;
