#include "FreeRTOS.h"
#include "i2c/i2c.h"

int forth_i2c_init(int bus, int scl_pin, int sda_pin, int freq) {
    return i2c_init(bus, scl_pin, sda_pin, (i2c_freq_t)freq);
}

bool forth_i2c_write(int bus, int byte) {
    return i2c_write(bus, byte);
}

uint8_t forth_i2c_read(int bus, int ack) {
    return i2c_read(bus, (bool)ack);
}

void forth_i2c_start(int bus) {
    return i2c_start(bus);
}

bool forth_i2c_stop(int bus) {
    return i2c_stop(bus);
}

int forth_i2c_slave_write(int bus, int slave_addr, const uint8_t *data, const uint8_t *buf, int len) {
    return i2c_slave_write(bus, slave_addr, data, buf, len);
}

int forth_i2c_slave_read(int bus, int slave_addr, const uint8_t *data, uint8_t *buf, int len) {
    return i2c_slave_read(bus, slave_addr, data, buf, len);
}
