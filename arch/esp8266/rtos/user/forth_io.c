#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "espressif/sdk_private.h"
#include "esp/uart.h"
#include "task.h"
#include "forth_io.h"

void forth_putchar(char c) { printf("%c", c); fflush(stdout); }
void forth_type(char* text) { printf("%s", text); fflush(stdout); }
void forth_uart_set_baud(int uart_num, int bps) { uart_set_baud(uart_num, bps); }

#define BUFFER_SIZE 4096 // should be multiple of 4
bool loading = false;
char *buffer = NULL;
int buffer_offset;
uint32_t source_address;

void err(char *msg) {
    printf(msg);
    sdk_system_restart();
}

uint32_t stack[8];
int sp = 0;
bool empty() { return sp == 0; }
bool full()  { return sp >= 8; }
void push(int e) {
    if (full()) err("Overflow while loading\n");
    stack[sp++] = e;
}
int pop() {
    if (empty()) err("Underflow while loading\n");
    return stack[--sp];
}

void load(uint32_t addr) {
    if (buffer == NULL) buffer = malloc(BUFFER_SIZE);
    buffer_offset = -1;
    if (loading) push(source_address);
    source_address = addr;
    loading = true;
}

void forth_load(uint32_t block_num) {
    load(block_num * 4096);
}

bool forth_loading() {
    return loading;
}

void forth_end_load() {
    if (!empty()) {
        loading = false;
        load(pop());
    } else {
        loading = false;
        free(buffer);
        buffer = NULL;
        printf("\n");
    }
}

int next_char_from_flash() { // read source stored code from flash memory
    if (buffer_offset < 0 || buffer_offset >= BUFFER_SIZE) {
        //printf("Reading 16r%x\n", source_address);
        forth_putchar('.');
        sdk_spi_flash_read(source_address, (void *) buffer, BUFFER_SIZE);
        buffer_offset = 0;
    }
    source_address++;
    return buffer[buffer_offset++];
}

int forth_getchar() { 
    return loading ? next_char_from_flash() : getchar();
}

bool _enter_press = false; // XXX this is ugly, use for breaking out key loop
void forth_push_enter() { _enter_press = true; }

int check_enter() { 
   if (_enter_press) {
       _enter_press = false;
       return 10;
   }
   return -1;
}

int forth_getchar_nowait() {
   if (loading) return next_char_from_flash();
   taskYIELD();
   char buf[1];
   return sdk_uart_rx_one_char(buf) != 0 ? check_enter() : buf[0];
}

