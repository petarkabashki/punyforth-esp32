#include "espressif/esp_common.h"
#include "espressif/esp_wifi.h"
#include "esplibs/libnet80211.h"
#include "FreeRTOS.h"
#include "string.h"
#include "dhcpserver.h"
#include "punycommons.h"


// workaround see github.com/SuperHouse/esp-open-rtos/issues/140
// void sdk_hostap_handle_timer(void *cnx_node) { } 

int forth_wifi_set_opmode(int mode) {
    return sdk_wifi_set_opmode(mode);
}

int forth_wifi_station_connect() {
    return sdk_wifi_station_connect();
}

int forth_wifi_station_disconnect() {
    return sdk_wifi_station_disconnect();
}

int forth_wifi_set_station_config(char* ssid, char* pass) {
    struct sdk_station_config config;
    memset(config.ssid, 0, 32);
    memset(config.password, 0, 64);
    memcpy(config.ssid, ssid, MIN(32, strlen(ssid)));
    memcpy(config.password, pass, MIN(64, strlen(pass)));
    return sdk_wifi_station_set_config(&config);
}

int forth_wifi_set_softap_config(char* ssid, char* pass, AUTH_MODE auth_mode, int hidden, int channel, int max_connections) {
    struct sdk_softap_config config;
    memset(config.ssid, 0, 32);
    memset(config.password, 0, 64);
    memcpy(config.ssid, ssid, MIN(32, strlen(ssid)));
    memcpy(config.password, pass, MIN(64, strlen(pass)));
    config.ssid_len = (uint8_t)(strlen(ssid) & 0xFF);
    config.ssid_hidden = (uint8_t)(hidden & 0xFF);
    config.channel = (uint8_t)(channel & 0xFF);
    config.authmode = auth_mode;
    config.max_connection = (uint8_t)(max_connections & 0xFF);
    config.beacon_interval = 100;
    return sdk_wifi_softap_set_config(&config);
}

void forth_wifi_set_ip(int ipv4) {
    struct ip_info ip;
    ip4_addr_set_u32(&ip.ip, ipv4);
    IP4_ADDR(&ip.gw, 0, 0, 0, 0);
    IP4_ADDR(&ip.netmask, 255, 255, 0, 0);
    sdk_wifi_set_ip_info(1, &ip);
}

void forth_wifi_get_ip_str(int interface, char * buffer, int size) {
    struct ip_info wifi_info;
    sdk_wifi_get_ip_info(interface, &wifi_info);
    struct ip4_addr ip = wifi_info.ip; 
    snprintf(buffer, size, IPSTR, IP2STR(&ip));
}

void forth_dhcpd_start(int first_client_ipv4, int max_leases) {
    ip_addr_t ip;
    ip4_addr_set_u32(&ip, first_client_ipv4);
    dhcpserver_start(&ip, (uint8_t)(max_leases & 0xFF));
}

void forth_dhcpd_stop() {
    dhcpserver_stop();
}

void forth_wifi_stop() {
    if (sdk_wifi_get_opmode() != 2) sdk_wifi_station_stop();
    if (sdk_wifi_get_opmode() != 1) sdk_wifi_softap_stop();
}

