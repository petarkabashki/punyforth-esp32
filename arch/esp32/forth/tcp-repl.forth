NETCON  load
WIFI    load
MAILBOX load

wifi-ip constant: HOST
1983 constant: PORT
    
0 init-variable: client
128 buffer: line 
    
1 mailbox: connections
0 task: repl-server-task
0 task: repl-worker-task

: type-composite ( str -- )
    client @ if
        client @ swap netcon-write
    else
        _type
    then ;
    
2 buffer: emit-buf 0 emit-buf 1+ c!

: emit-composite ( char -- )
    client @ if
        emit-buf c!
        client @ emit-buf netcon-write
    else
        _emit
    then ;
    
: eval ( str -- i*x )
    0 #tib !
    tib >in ! 
    dup strlen 0 do 
        dup i + c@ chr>in
    loop
    13 chr>in 10 chr>in
    drop
    push-enter ;

: server ( task -- )       
    activate
    PORT HOST netcon-tcp-server
    begin
        print: 'PunyREPL started on port ' PORT . 
        print: ' on host ' HOST type cr
        dup netcon-accept
        connections mailbox-send
    again 
    deactivate ;

: command-loop ( -- )   
    client @ "PunyREPL ready. Type quit to exit.\r\n" netcon-write
    push-enter
    begin        
        client @ 128 line netcon-readln -1 <>
        line "quit" =str invert and
    while
        line strlen if line eval then
    repeat ;
        
: worker ( task -- )
    activate
    begin
        connections mailbox-receive client !
        print: "Client connected: " client ? cr
        ['] command-loop catch ?dup if
            print: 'error while handling client: ' client ? cr
            ex-type        
        then
        client @ netcon-dispose
        0 client !
    again
    deactivate ;

: repl-start ( -- )
    println: 'Starting PunyREPL..'
    multi    
    ['] type-composite xtype !
    ['] emit-composite xemit !
    repl-server-task server
    repl-worker-task worker ;

/end

