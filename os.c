#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/atomic.h>
#include <string.h>
#include "os.h"
#include "os_config.h"

#ifndef ARRAYSIZE
#define ARRAYSIZE(x) (sizeof(x)/sizeof(*(x)))
#endif

// Assemble tasks
void os_asm_switch_to_task(void);

// Temporary buffers for context switch
volatile uint16_t ins_tmp;
volatile uint8_t sreg_tmp;
volatile uint16_t stack_tmp;
volatile uint8_t reg_tmp[32];

struct os_task {
    uint8_t valid;
    os_task_func code_ptr;
    void* data_ptr;
    uint8_t* stack_ptr;
    uint8_t status;
    uint8_t registers[32];
    uint8_t stack[OS_STACK_SIZE];
} tasks[OS_TASK_COUNT];

typedef size_t os_task_id_t;
#define TASK_IDX_INVALID -1
static os_task_id_t task_current_idx = TASK_IDX_INVALID;

void os_init(void) {
    for (size_t i = 0; i < ARRAYSIZE(tasks); i++) {
        tasks[i].valid = 0;
    }
}

void os_run(void) {
    TCCR0A = 0;
    OCR0A = 0xFF;
    TCCR0B = _BV(WGM12) | _BV(CS10);
    TIMSK0 |= _BV(OCIE1A);

    // Wait fo fist task switch
    sei();
    TCNT0 = 0xFF;
    while (1);
}

static void os_do_switch_to_task(os_task_id_t task_idx) {
    task_current_idx = task_idx;
    struct os_task* task = tasks + task_idx;

    for (size_t i = 0; i < ARRAYSIZE(task->registers); i++) {
        reg_tmp[i] = task->registers[i];
    }
    ins_tmp = (uint16_t) task->code_ptr;
    sreg_tmp = task->status;
    stack_tmp = (uint16_t) task->stack_ptr;

    // Reset Timer and do context switch
    TCNT0 = 0;
    TIFR0 &= ~_BV(OCF0A);
    os_asm_switch_to_task();
}

void os_interrupt_saved(void) {
    os_task_id_t next_task_idx = TASK_IDX_INVALID;

    if (task_current_idx != TASK_IDX_INVALID) {
        struct os_task* task_current = tasks + task_current_idx;

        for (size_t i = 0; i < ARRAYSIZE(task_current->registers); i++) {
            task_current->registers[i] = reg_tmp[i];
        }

        task_current->code_ptr = (void*) ins_tmp;
        task_current->status = sreg_tmp;
        task_current->stack_ptr = (uint8_t*) stack_tmp;

        next_task_idx = task_current_idx + 1;
        next_task_idx %= ARRAYSIZE(tasks);
    } else {
        if (tasks[0].valid) {
            next_task_idx = 0;
        }
    }

    if (next_task_idx == TASK_IDX_INVALID) {
        while (1);
    }

    os_do_switch_to_task(next_task_idx);
}

void os_task_add(os_task_func func, void* data) {
    ATOMIC_BLOCK(ATOMIC_RESTORESTATE) {
        for (size_t i = 0; i < ARRAYSIZE(tasks); i++) {
            struct os_task* t = tasks + i;
            if (t->valid) {
                continue;
            }

            t->valid = 1;
            t->code_ptr = func;
            t->stack_ptr = t->stack + sizeof (t->stack) - 1;
            t->status = 0;
            t->data_ptr = data;
            break;
        }
    }
}

void* os_current_task_get_data(void) {
    return tasks[task_current_idx].data_ptr;
}

void os_current_task_kill(void) {
    ATOMIC_BLOCK(ATOMIC_RESTORESTATE) {
        tasks[task_current_idx].valid = 0;
    }

    // Wait fo context switch.
    while (1);
}

// Linker magic to add interrupt vector
void TIMER0_COMPA_vect(void) __attribute__((signal, naked, __INTR_ATTRS));
