defword "readchar",8,readchar,REGULAR
    .int xt_xpause, xt_fetch, xt_branch0
    lbl readchar_blocking
readchar_again:
    .int xt_readchar_nowait, xt_dup, xt_btick, -1, xt_eq, xt_branch0
    lbl readchar_available
    .int xt_drop
    .int xt_xpause, xt_fetch, xt_execute
    .int xt_branch
    lbl readchar_again
readchar_available:
    .int xt_exit
readchar_blocking:
    .int xt_readchar_wait
    .int xt_exit

defword "xpause",6,xpause,REGULAR
    .int xt_btick, _M var_pause_xt
    .int xt_exit

defprimitive "readchar-wait",13,readchar_wait,REGULAR
    CCALL forth_getchar
    DPUSH a2
    NEXT    

defprimitive "readchar-nowait",15,readchar_nowait,REGULAR /* ( -- char | -1 ) */
    CCALL forth_getchar_nowait
    DPUSH a2
    NEXT

defprimitive "load",4,load,REGULAR
    DPOP a2			// block number
    CCALL forth_load
    NEXT

defprimitive "loading?",8,loading,REGULAR
    CCALL forth_loading
    DPUSH a2
    NEXT

defprimitive "/end",4,end_load,REGULAR
    CCALL forth_end_load
    NEXT

defprimitive "over",4,over,REGULAR /* ( a b -- a b a ) */
    READTOS2 a8
    DPUSH a8
    NEXT

defprimitive "-rot",4,mrot,REGULAR /*( a b c -- c a b ) */
    READTOS1 a8
    READTOS2 a9
    READTOS3 a10
    WRTETOS3 a8
    WRTETOS2 a10
    WRTETOS1 a9
    NEXT

defprimitive "2dup",4,dup2,REGULAR
    READTOS2 a9
    READTOS1 a8
    DPUSH a9
    DPUSH a8
    NEXT

defprimitive "2drop",5,"drop2",REGULAR
    addi a15, a15, 2*CELLS
    NEXT

defprimitive "4drop",5,"drop4",REGULAR
    addi a15, a15, 4*CELLS
    NEXT

defprimitive "cells",5,cells,REGULAR
    READTOS1 a9
    movi a8, 2
    ssl a8
    sll a8, a9
    WRTETOS1 a8
    NEXT

defprimitive ">",1,gt,REGULAR 
    DPOP a8
    READTOS1 a9
    movi a10, FALSE
    bge a8, a9, L5
    movi a10, TRUE
L5: WRTETOS1 a10
    NEXT

defprimitive "=",1,eq,REGULAR 
    DPOP a8
    READTOS1 a9
    movi a10, FALSE
    bne a8, a9, L6
    movi a10, TRUE
L6: WRTETOS1 a10
    NEXT

defprimitive "<>",2,noteq,REGULAR 
    DPOP a8
    READTOS1 a9
    movi a10, FALSE
    beq a8, a9, L7
    movi a10, TRUE
L7: WRTETOS1 a10
    NEXT

defprimitive "<=",2,lte,REGULAR 
    DPOP a8
    READTOS1 a9
    movi a10, FALSE
    blt a8, a9, L8
    movi a10, TRUE
L8: WRTETOS1 a10
    NEXT

defprimitive ">=",2,gte,REGULAR 
    DPOP a8
    READTOS1 a9
    movi a10, FALSE
    blt a9, a8, L9
    movi a10, TRUE
L9: WRTETOS1 a10
    NEXT

defprimitive "1+",2,inc,REGULAR
    READTOS1 a8
    addi a8, a8, 1
    WRTETOS1 a8
    NEXT

defprimitive "1-",2,dec,REGULAR
    READTOS1 a8
    addi a8, a8, -1
    WRTETOS1 a8
    NEXT

defprimitive "0=",2,eq0,REGULAR
    READTOS1 a8
    movi a9, FALSE
    movi a10, TRUE
    moveqz a9, a10, a8 // move a10 to a9 if a8 is zero
    WRTETOS1 a9
    NEXT

defprimitive "0<>",3,noteq0,REGULAR
    READTOS1 a8
    movi a9, FALSE
    movi a10, TRUE
    movnez a9, a10, a8 // move a10 to a9 if a8 is not zero
    WRTETOS1 a9
    NEXT

defprimitive "0<",2,lt0,REGULAR
    READTOS1 a8
    movi a9, FALSE
    movi a10, TRUE
    movltz a9, a10, a8 // move a10 to a9 if a8 is less than zero
    WRTETOS1 a9
    NEXT

defprimitive "0>",2,gt0,REGULAR
    READTOS1 a8
    movi a9, TRUE
    movi a10, FALSE
    movltz a9, a10, a8 // move a10 to a9 if a8 is less than zero
    moveqz a9, a10, a8 // move a10 to a9 if a8 is zero
    WRTETOS1 a9
    NEXT

defprimitive "ms@",3,msat,REGULAR
    CCALL forth_time_ms
    DPUSH a2
    NEXT

defprimitive "_type",5,utype,REGULAR    // ( a -- )
    DPOP a2			// string
    CCALL forth_type
    NEXT

defprimitive "uart-set-bps",12,uart_set_bps,REGULAR    // ( bps uart_num -- )
    DPOP a2			// uart_num
    DPOP a3			// bps
    CCALL forth_uart_set_baud
    NEXT

defprimitive "gpio-mode",9,gpio_mode,REGULAR
    DPOP a3                     // gpio direction
    DPOP a2                     // gpio num
    CCALL forth_gpio_mode
    NEXT

defprimitive "gpio-set-interrupt",18,gpiointerrupt,REGULAR
    DPOP a3                     // gpio interrupt type
    DPOP a2                     // gpio num
    CCALL forth_gpio_set_interrupt
    NEXT

defprimitive "gpio-write",10,gpiowrite,REGULAR
    DPOP a3                     // bool
    DPOP a2                     // gpio num
    CCALL forth_gpio_write
    NEXT

defprimitive "gpio-read",9,gpioread,REGULAR
    DPOP a2                     // gpio num
    CCALL forth_gpio_read
    DPUSH a2
    NEXT

defprimitive "adc-read",8,adcread,REGULAR
    CCALL sdk_system_adc_read
    DPUSH a2
    NEXT

defprimitive "pwm-init",8,pwminit,REGULAR
    DPOP a2                     // pins array
    DPOP a3                     // number of pins in array
    CCALL pwm_init
    NEXT

defprimitive "pwm-freq",8,pwmfreq,REGULAR
    DPOP a2                     // freq 16b
    CCALL forth_pwm_freq
    NEXT

defprimitive "pwm-duty",8,pwmduty,REGULAR
    DPOP a2                     // duty 16b
    CCALL forth_pwm_duty
    NEXT

defprimitive "pwm-start",9,pwmstart,REGULAR
    CCALL pwm_start
    NEXT

defprimitive "pwm-stop",8,pwmstop,REGULAR
    CCALL pwm_stop
    NEXT

defprimitive "ms",2,ms,REGULAR
    DPOP a2                     // millis to wait
    CCALL forth_delay_ms
    NEXT

// internal timeout
defprimitive "netcon-set-recvtimeout",22,netcon_set_recvtimeout,REGULAR 
    DPOP a2                    // conn
    DPOP a3                    // recv timeout ms
    CCALL forth_netcon_set_recvtimeout
    NEXT

// get user defined socket read timeout
defprimitive "netcon-read-timeout@",20,netcon_get_readtimeout,REGULAR
    DPOP a2                   // netcon
    CCALL forth_netcon_get_read_timeout
    DPUSH a2                  // timeout_sec
    NEXT

// set user defined socket read timeout
defprimitive "netcon-read-timeout!",20,netcon_set_readtimeout,REGULAR
    DPOP a2                   // netcon
    DPOP a3                   // timeout_sec
    CCALL forth_netcon_set_read_timeout
    NEXT

defprimitive "netcon-new",10,netcon_new,REGULAR
    DPOP a2                    // conn type
    CCALL forth_netcon_new
    DPUSH a2
    NEXT

defprimitive "netcon-connect",14,netcon_connect,REGULAR       
    DPOP a2                    // conn
    DPOP a3                    // host
    DPOP a4                    // port
    CCALL forth_netcon_connect
    DPUSH a2
    NEXT

defprimitive "netcon-bind",11,netcon_bind,REGULAR       
    DPOP a2                    // conn
    DPOP a3                    // host
    DPOP a4                    // port
    CCALL forth_netcon_bind
    DPUSH a2
    NEXT

defprimitive "netcon-listen",13,netcon_listen,REGULAR       
    DPOP a2                    // netcon
    CCALL forth_netcon_listen
    DPUSH a2
    NEXT

defprimitive "netcon-send",11,netcon_send,REGULAR
    DPOP a2                    // conn
    DPOP a3                    // data
    DPOP a4                    // len
    CCALL forth_netcon_send
    DPUSH a2
    NEXT

defprimitive "netcon-write",12,netcon_write,REGULAR
    DPOP a2                    // conn
    DPOP a3                    // data
    DPOP a4                    // size
    CCALL forth_netcon_write
    DPUSH a2
    NEXT

defprimitive "netcon-recvinto",15,netcon_recvinto,REGULAR
    DPOP a2                    // conn
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_netcon_recvinto
    DPUSH a3                   // count read
    DPUSH a2                   // err_t
    NEXT

defprimitive "netbuf-del",10,netbuf_del,REGULAR
    DPOP a2                    // netbuf
    CCALL forth_netbufdel
    NEXT

defprimitive "netbuf-next",11,netbuf_next,REGULAR
    DPOP a2                    // netbuf
    CCALL forth_netbuf_next
    DPUSH a2
    NEXT

defprimitive "netbuf-data",11,netbuf_data,REGULAR
    DPOP a2                    // netbuf
    CCALL forth_netbuf_data
    DPUSH a3                   // buffer
    DPUSH a2                   // size
    NEXT

defprimitive "netcon-recv",11,netcon_recv,REGULAR
    DPOP a2                    // netcon
    CCALL forth_netcon_recv
    DPUSH a3                   // netbuf
    DPUSH a2                   // err_t
    NEXT

defprimitive "netcon-accept",13,netcon_accep,REGULAR
    DPOP a2                    // netcon
    CCALL forth_netcon_accept
    DPUSH a3                   // netcon
    DPUSH a2                   // err_t
    NEXT

defprimitive "netcon-close",12,netcon_close,REGULAR
    DPOP a2                    // conn
    CCALL forth_netcon_close
    NEXT

defprimitive "netcon-delete",13,netcon_delete,REGULAR
    DPOP a2                    // conn
    CCALL forth_netcon_delete
    NEXT

defprimitive "task-yield",10,task_yield,REGULAR
    CCALL forth_yield
    NEXT

defprimitive "os-enter-critical",17,os_enter_critical,REGULAR
    CCALL forth_enter_critical
    NEXT

defprimitive "os-exit-critical",16,os_exit_critical,REGULAR
    CCALL forth_exit_critical
    NEXT

defprimitive "wait-event",10,wait_event,REGULAR
    DPOP a2                    // delay ms
    DPOP a3                    // event buffer
    CCALL forth_wait_event
    DPUSH a2
    NEXT

defprimitive "random",6,random,REGULAR
    CCALL forth_random
    DPUSH a2
    NEXT

defprimitive "erase-flash",11,erase_flash,REGULAR
    DPOP a2                    // sector
    CCALL forth_flash_erase_sector
    DPUSH a2
    NEXT

defprimitive "read-flash",10,read_flash,REGULAR
    DPOP a2                    // address
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_flash_read
    DPUSH a2
    NEXT

defprimitive "write-flash",11,write_flash,REGULAR
    DPOP a2                    // address
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_flash_write
    DPUSH a2
    NEXT

defprimitive "spi-init",8,spi_init,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // mode
    DPOP a4                    // freq_div
    DPOP a5                    // msb
    DPOP a6                    // endianness
    DPOP a7                    // minimal_pins
    CCALL forth_spi_init
    DPUSH a2
    NEXT

defprimitive "spi-send8",9,spi_send8,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // data
    CCALL forth_spi_send8
    DPUSH a2
    NEXT

defprimitive "spi-send",8,spi_send,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // out_data
    DPOP a4                    // in_data
    DPOP a5                    // size_data
    DPOP a6                    // word_size
    CCALL forth_spi_send
    DPUSH a2
    NEXT

defprimitive "wifi-stop",9,wifi_stop,REGULAR
    CCALL forth_wifi_stop
    NEXT

defprimitive "wifi-softap-start",17,wifi_softap_start,REGULAR
    CCALL sdk_wifi_softap_start
    DPUSH a2                   // c bool
    NEXT

defprimitive "wifi-station-start",18,wifi_station_start,REGULAR
    CCALL sdk_wifi_station_start
    DPUSH a2                   // c bool
    NEXT

defprimitive "wifi-set-mode",13,wifi_set_mode,REGULAR
    DPOP a2                    // mode
    CCALL forth_wifi_set_opmode
    DPUSH a2                   // c bool
    NEXT

defprimitive "wifi-set-station-config",23,wifi_set_station_config,REGULAR
    DPOP a2                    // ssid
    DPOP a3                    // password
    CCALL forth_wifi_set_station_config
    DPUSH a2                   // c bool
    NEXT

defprimitive "wifi-set-softap-config",22,wifi_set_softap_config,REGULAR
    DPOP a2                    // ssid
    DPOP a3                    // password
    DPOP a4                    // auth_mode
    DPOP a5                    // hidden
    DPOP a6                    // channels
    DPOP a7                    // max_connections
    CCALL forth_wifi_set_softap_config
    DPUSH a2                   // c bool
    NEXT

defprimitive "wifi-set-ip",11,wifi_set_ip,REGULAR
    DPOP a2                    // ipv4addr
    CCALL forth_wifi_set_ip
    NEXT

defprimitive "wifi-ip-str",11,wifi_ip_str,REGULAR
    DPOP a2                    // interface 0 = station, 1 = softap
    DPOP a3                    // buffer
    DPOP a4                    // buffer size
    CCALL forth_wifi_get_ip_str
    NEXT

defprimitive "wifi-station-connect",20,wifi_station_connection,REGULAR
    CCALL forth_wifi_station_connect
    DPUSH a2                   // c bool
    NEXT

defprimitive "wifi-station-disconnect",23,wifi_station_disconnection,REGULAR
    CCALL forth_wifi_station_disconnect
    DPUSH a2                   // c bool
    NEXT

defprimitive "dhcpd-start",11,dhcp_start,REGULAR
    DPOP a2                    // first client ip
    DPOP a3                    // max leases 
    CCALL forth_dhcpd_start
    NEXT

defprimitive "dhcpd-stop",10,dhcp_stop,REGULAR
    CCALL forth_dhcpd_stop
    NEXT

defprimitive "push-enter",10,push_enter,REGULAR
    CCALL forth_push_enter
    NEXT

defprimitive "osfreemem",9,osfreemem,REGULAR
    CCALL forth_free_heap
    DPUSH a2                   // free heap size in bytes
    NEXT

defprimitive "us@",3,usat,REGULAR
    CCALL sdk_system_get_time
    DPUSH a2 // clock time in us
    NEXT

defprimitive "us",2,us,REGULAR
    DPOP a2                     // us to wait
    CCALL forth_delay_us
    NEXT

defprimitive "deep-sleep",10,deep_sleep,REGULAR
    DPOP a2                    // time in us
    CCALL sdk_system_deep_sleep
    NEXT	

defprimitive "pulse-in",8,pulse_in,REGULAR
    DPOP a2                    // pin
    DPOP a3                    // state
    DPOP a4                    // timeout
    CCALL forth_pulse_in
    DPUSH a2                   // pulse len us
    NEXT	

defprimitive "r@",2,rfetch,REGULAR
    l32i a2, a13, 0 
    DPUSH a2
    NEXT

defprimitive "i2c-start",9,i2c_start,REGULAR
    DPOP a2                 // bus
    CCALL forth_i2c_start
    NEXT

defprimitive "i2c-stop",8,i2c_stop,REGULAR
    DPOP a2                 // bus
    CCALL forth_i2c_stop
    DPUSH a2                // cbool
    NEXT

defprimitive "i2c-init",8,i2c_init,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // scl_pin
    DPOP a4                    // sda_pin
    DPOP a5                    // freq
    CCALL forth_i2c_init
    DPUSH a2                   // int result
    NEXT

defprimitive "i2c-read",8,i2c_read,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // ack
    CCALL forth_i2c_read
    DPUSH a2                   // data
    NEXT

defprimitive "i2c-write",9,i2c_write,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // byte
    CCALL forth_i2c_write
    DPUSH a2                   // cbool
    NEXT

defprimitive "i2c-read-slave",14,i2c_read_slave,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // slave_addr
    DPOP a4                    // data
    DPOP a5                    // buffer
    DPOP a6                    // len
    CCALL forth_i2c_slave_read
    DPUSH a2                   // int result
    NEXT

defprimitive "i2c-write-slave",15,i2c_write_slave,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // slave_addr
    DPOP a4                    // data
    DPOP a5                    // buffer
    DPOP a6                    // len
    CCALL forth_i2c_slave_write
    DPUSH a2                   // int result
    NEXT

defprimitive "cpufreq!",8,setcpufreq,REGULAR
    DPOP a2                    // frequency in mhz (byte)
    CCALL sdk_system_update_cpu_freq
    DPUSH a2                   // C bool
    NEXT

defprimitive "cpufreq@",8,getcpufreq,REGULAR
    CCALL sdk_system_get_cpu_freq
    DPUSH a2                   // C bool
    NEXT

defprimitive "ws2812rgb",9,ws2812rgb,REGULAR
    DPOP a2                    // gpio num
    DPOP a3                    // rgb
    CCALL forth_ws2812_rgb
    NEXT

defprimitive "ws2812set",9,ws2812set,REGULAR
    DPOP a2                    // gpio num
    DPOP a3                    // rgb
    CCALL forth_ws2812_set
    NEXT
