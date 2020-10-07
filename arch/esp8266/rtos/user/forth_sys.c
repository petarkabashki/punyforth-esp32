#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "task.h"

void forth_abort() { 
    printf("Restarting ESP ..\n");
    sdk_system_restart();
}

void forth_yield() { 
    taskYIELD();
}

void forth_enter_critical() {
    taskENTER_CRITICAL();
}	


void forth_exit_critical() {
    taskEXIT_CRITICAL();
}	

int forth_free_heap() {
    return (int)xPortGetFreeHeapSize();
}
