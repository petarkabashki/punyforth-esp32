#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "espressif/esp_softap.h"
#include "task.h"
#include "esp/uart.h"
#include "espressif/esp8266/esp8266.h"
#include "punyforth.h"
#include "forth_evt.h"
#include "forth_io.h"

static void forth_init(void* dummy) {
    forth_start();   
}

void user_init(void) {
    uart_set_baud(0, 115200);
    printf("\nLoading Punyforth\n");
    forth_load(0x52000 / 4096);
    init_event_queue();
    xTaskCreate(forth_init, "punyforth", 640, NULL, 2, NULL); 
}
