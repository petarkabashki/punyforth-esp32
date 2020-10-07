#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "task.h"
#include "ws2812.h"

void forth_ws2812_rgb(uint32_t gpio_num, uint32_t rgb) { 
    ws2812_seq_rgb(gpio_num, rgb);
}

void forth_ws2812_set(uint32_t gpio_num, uint32_t rgb) { 
    ws2812_set(gpio_num, rgb);
}
