0 constant: NULL_MODE
1 constant: STATION_MODE
2 constant: SOFTAP_MODE
3 constant: STATIONAP_MODE
4 constant: MAX_MODE

0 constant: AUTH_OPEN
1 constant: AUTH_WEP
2 constant: AUTH_WPA_PSK
3 constant: AUTH_WPA2_PSK
4 constant: AUTH_WPA_WPA2_PSK
5 constant: AUTH_MAX

exception: EWIFI

: >ipv4 ( octet1 octet2 octet3 octet4 -- n )
    255 and 24 lshift >r
    255 and 16 lshift >r
    255 and  8 lshift >r
    255 and           >r
    r> r> r> r>
    or or or ;
    
: check-status ( status -- | throws:EWIFI )
    1 <> if EWIFI throw then ;
    
\ Connect to an existing Wi-Fi access point with the given ssid and password
\ For example:
\   "ap-pass" "ap-ssid" wifi-connect
: wifi-connect ( password ssid  -- | throws:EWIFI )
    STATION_MODE wifi-set-mode check-status
    wifi-set-station-config check-status
    wifi-station-connect check-status ;

\ Creates an access point mode with the given properties
\ For example:
\   172 16 0 1 >ipv4 wifi-set-ip
\   4 3 0 AUTH_WPA2_PSK "1234567890" "my-ssid" wifi-softap
\   8 172 16 0 2 >ipv4 dhcpd-start
\   max-connections should be <= max-leases
: wifi-softap ( max-connections channels hidden authmode password ssid -- | throws:EWIFI )
    SOFTAP_MODE wifi-set-mode check-status
    wifi-set-softap-config check-status ;
    
: ip ( interface -- str )
    { here 16 over } dip
    16 allot
    wifi-ip-str ;

\ station ip    
: wifi-ip ( -- str ) 0 ip ;
: softap-ip ( -- str ) 1 ip ;

/end

