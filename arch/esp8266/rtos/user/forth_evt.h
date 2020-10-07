#ifndef __FORTH_EVT_H__
#define __FORTH_EVT_H__

#include "FreeRTOS.h"
#include "task.h"

#define EVT_GPIO 100

struct forth_event {
    int event_type;
    unsigned int event_time_ms;
    unsigned int event_time_us;
    int event_payload;
};

void init_event_queue();
void forth_add_event_isr(struct forth_event *event);

#endif
