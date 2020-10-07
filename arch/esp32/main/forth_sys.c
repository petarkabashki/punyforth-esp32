#include "freertos/FreeRTOS.h"
// #include "espressif/esp_common.h"
#include "freertos/task.h"

void forth_abort() { 
    printf("Restarting ESP ..\n");
    esp_restart();
}

void forth_yield() { 
    taskYIELD();
}

void forth_enter_critical() {
    //???
    portENTER_CRITICAL(NULL);
}	


void forth_exit_critical() {
    //???
    portEXIT_CRITICAL(NULL);
}	

int forth_free_heap() {
    return (int)xPortGetFreeHeapSize();
}
