#include "espressif/esp_common.h"
#include "espressif/spi_flash.h"

int map_err(sdk_SpiFlashOpResult code) {
    switch (code) {
        case SPI_FLASH_RESULT_OK: return 0;
        case SPI_FLASH_RESULT_ERR: return 1;
        case SPI_FLASH_RESULT_TIMEOUT: return 2;
        default: return 3;	
    }
}

int forth_flash_erase_sector(int sector) {
    return map_err(sdk_spi_flash_erase_sector((uint16_t)sector));
}

int forth_flash_write(int address, void* buffer, int size) {
    return map_err(sdk_spi_flash_write((uint32_t)address, buffer, (uint32_t)size));
}

int forth_flash_read(int address, void* buffer, int size) {
    return map_err(sdk_spi_flash_read((uint32_t)address, buffer, (uint32_t)size));
}
