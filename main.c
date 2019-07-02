#include "os.h"

static void single_shot_task(void* data) {
    /* Do stuff */

    os_current_task_kill();
}

static void looping_task(void* data) {
    while (1) {
        /* Do stuff */
    }
}

int main(void) {
    os_init();

    os_task_add(single_shot_task, 0);
    os_task_add(looping_task, 0);

    os_run();
}