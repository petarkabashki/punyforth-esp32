#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "task.h"
#include "esp/spi.h"

bool forth_bool(int b) {
    return b == 0 ? false : true;
}

bool forth_spi_init(int bus, int mode, int freq_div, int msb, int endian, int minimal_pins) { 
    return spi_init(bus, (spi_mode_t)mode, (uint32_t)freq_div, forth_bool(msb), (spi_endianness_t)endian, forth_bool(minimal_pins));
}

int forth_spi_send8(int bus, int data) {
    return spi_transfer_8(bus, data & 0xFF);
}

int forth_spi_send(int bus, const void* out_data, void *in_data, int size, int word_size) {
    return spi_transfer(bus, out_data, in_data, size, (spi_word_size_t) word_size);
}


