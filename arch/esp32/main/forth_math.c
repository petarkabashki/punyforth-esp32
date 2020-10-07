#include "freertos/FreeRTOS.h"
#include "esp_attr.h"
// #include "espressif/esp_common.h"

//TODO:P fix IRAM
div_t /*IRAM*/IRAM_ATTR forth_divmod(int a, int b) { return div(a,b); }
int /*IRAM*/IRAM_ATTR forth_random() { return rand(); }
