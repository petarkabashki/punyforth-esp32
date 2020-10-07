NETCON  load
WIFI    load
MAILBOX load

\ server listens on this port
80 constant: PORT
wifi-ip constant: HOST

\ task local variables    
struct
    cell field: .client
    128  field: .line
constant: WorkerSpace

\ access to task local variables from worker tasks
: client ( -- a ) user-space .client ;
: line ( -- a ) user-space .line ;

\ a mailbox used for communication between server and worker tasks
4 mailbox: connections
\ server and worker task allocations
0 task: server-task
WorkerSpace task: worker-task1
WorkerSpace task: worker-task2

\ server task listens for incoming connections and passes them to the workers
: server ( task -- )
    activate
    PORT HOST netcon-tcp-server
    begin
        print: "Waiting for clients on host " HOST type print: " on port " PORT . cr
        dup netcon-accept
        connections mailbox-send      \ send the client connection to one of the worker tasks
    again 
    deactivate ;
    
\ index page as a mult line string
"
HTTP/1.0 200\r\n
Content-Type: text/html\r\n
Connection: close\r\n
\r\n
<html>
    <body>
        <h1>Punyforth demo</h1>
    </body>
</html>" constant: HTML
    
: serve-client ( -- )    
    client @ 128 line netcon-readln
    print: 'received: ' line type print: ' len=' . cr
    line "GET /" str-starts? if
        client @ HTML netcon-write
    then ;
    
\ worker taks receives clients from the server task then serves them with a static html    
: worker ( task -- )
    activate
    begin
        connections mailbox-receive client !       \ receive client connection from the server task
        print: "Client connected: " client ? cr
        ['] serve-client catch ?dup if
            print: 'error handling client: ' client ? cr
            ex-type
        then
        client @ netcon-dispose
    again
    deactivate ;

: start-http-server ( -- )
    multi                      \ switch to multi task mode then start the server + worker taks
    server-task server
    worker-task1 worker
    worker-task2 worker ;

start-http-server

