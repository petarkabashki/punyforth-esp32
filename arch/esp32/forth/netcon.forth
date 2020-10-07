TASKS load

1 constant: UDP
2 constant: TCP

\ internal timeout, used for yielding control to other tasks in  read loop
70 constant: RECV_TIMEOUT_MSEC

exception: ENETCON   ( indicates general netcon error )
exception: ERTIMEOUT ( indicates read timeout )

\ netcon errors. see: esp-open-rtos/lwip/lwip/src/include/lwip/err.h
 -3 constant:  NC_ERR_TIMEOUT     \ Timeout.
 -15 constant: NC_ERR_CLSD        \ Connection closed. 

: netcon-new ( type -- netcon | throws:ENETCON ) override
    netcon-new dup 0= if ENETCON throw then 
    RECV_TIMEOUT_MSEC over netcon-set-recvtimeout ;

: check ( errcode --  | throws:ENETCON ) ?dup if print: "NETCON error: " . cr ENETCON throw then ;

\ Connect to a remote port/ip. Must be used in both TCP and UDP case.
: netcon-connect ( port host type -- netcon | throws:ENETCON ) override netcon-new dup >r netcon-connect check r> ;
: netcon-bind ( port host netcon -- | throws:ENETCON ) override netcon-bind check ;
: netcon-listen ( netcon -- | throws:ENETCON ) override netcon-listen check ;

\ Create a TCP server by binding a connection to the given port host.
\ Leaves a netcon connection associated to the server socket on the stack.
: netcon-tcp-server ( port host -- netcon | throws:ENETCON )
    TCP netcon-new
    ['] netcon-bind keep
    dup netcon-listen ;

\ Create a UDP server by binding a connection to the given port host.
\ Leaves a netcon connection associated to the server socket on the stack.
: netcon-udp-server ( port host -- netcon | throws:ENETCON ) UDP netcon-new ['] netcon-bind keep ;
    
\ Accept an incoming connection on a listening TCP connection.
\ Leaves a new netcon connection that is associated to the client socket on the stack.
: netcon-accept ( netcon -- new-netcon | throws:ENETCON) override
    begin
        pause
        dup netcon-accept dup NC_ERR_TIMEOUT <> if
            check nip
            RECV_TIMEOUT_MSEC over netcon-set-recvtimeout
            exit
        then
        2drop
    again ;

\ Write the content of the given buffer to a UDP socket.
: netcon-send-buf ( netcon buffer len -- | throws:ENETCON ) swap rot netcon-send check ;
\ Write the content of the given buffer to a TCP socket.
: netcon-write-buf ( netcon buffer len -- | throws:ENETCON ) swap rot netcon-write check ;
\ Write a null terminated string to a TCP socket.
: netcon-write ( netcon str -- | throws:ENETCON ) override dup strlen netcon-write-buf ;
\ Write a null terminated string then a CRLF to a TCP socket.
: netcon-writeln ( netcon str -- | throws:ENETCON ) over swap netcon-write "\r\n" netcon-write ;

: read-ungreedy ( size buffer netcon -- count code | throws:ERTIMEOUT )
    ms@ >r
    begin
        3dup netcon-recvinto
        dup NC_ERR_TIMEOUT <> if            
            rot drop rot drop rot drop
            r> drop ( start time )
            exit
        else
            pause
        then
        2drop ( count code )
        dup netcon-read-timeout@ 0> if
            ms@ r@ - over netcon-read-timeout@ 1000 * > if
                ERTIMEOUT throw
            then
        then
    again ;

\ Read maximum `size` amount of bytes into the buffer.
\ Leaves the amount of bytes read on the top of the stack, or -1 if the connection was closed.
: netcon-read ( netcon size buffer -- count | -1 | throws:ENETCON/ERTIMEOUT )
    rot read-ungreedy dup NC_ERR_CLSD = if 2drop -1 exit then check ;

\ Read one line into the given buffer. The line terminator is CRLF.
\ Leaves the length of the line on the top of the stack, or -1 if the connection was closed.
\ If the given buffer is not large enough to hold EOVERFLOW is thrown.
: netcon-readln ( netcon size buffer -- count | -1 | throws:ENETCON/EOVERFLOW/ERTIMEOUT )
    swap 0 do
        2dup
        1 swap i + netcon-read -1 = if
            i + 0 swap c!
            drop
            i 0= if -1 else i then
            unloop exit
        then
        dup i + c@ 10 = i 1 >= and if            
            dup i + 1- c@ 13 = if
                i + 1- 0 swap c!
                drop i 1- 
                unloop exit
            then            
        then
    loop 
    EOVERFLOW throw ;    
    
\ Close then dispose the given socket.
: netcon-dispose ( netcon -- ) dup netcon-close netcon-delete ;

/end

