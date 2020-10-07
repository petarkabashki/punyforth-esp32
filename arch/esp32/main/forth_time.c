#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
// #include "espressif/esp_common.h"

void forth_delay_ms(int millis) {
    vTaskDelay(millis / portTICK_PERIOD_MS);
}

int forth_time_ms() {
    return xTaskGetTickCount() * portTICK_PERIOD_MS;
}

/**
 * Delay microseconds
 *
 * sdk os_delay_us has only 16bits, so mask them
 */
void forth_delay_us(unsigned int microseconds) {
    //???
    esp_rom_delay_us(microseconds & 0x0ffff);
}
