
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/uart.h"

#include "soc/timer_group_struct.h"
#include "soc/timer_group_reg.h"

// #include "esp_common.h"
// #include "esp_softap.h"
// #include "task.h"
// #include "esp/uart.h"
// #include "espressif/esp8266/esp8266.h"
#include "punyforth.h"
#include "forth_evt.h"
#include "forth_io.h"

static void forth_init(void* dummy) {
    uart_set_baudrate(0, 115200);
    printf("\nLoading Punyforth\n");
    forth_load(0x52000 / 4096);
    init_event_queue();
    forth_start();   
}

//void user_init(void) {
void app_main(void) {
    xTaskCreate(forth_init, "punyforth", 640, NULL, 2, NULL); 
    
    // while(1){
    //     vTaskDelay(10 / portTICK_PERIOD_MS);

    //     TIMERG0.wdt_wprotect=TIMG_WDT_WKEY_VALUE;
    //     TIMERG0.wdt_feed=1;
    //     TIMERG0.wdt_wprotect=0;
    // }
}
