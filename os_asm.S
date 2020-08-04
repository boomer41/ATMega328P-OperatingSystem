#include <avr/io.h>

.section .text

// Task switch interrupt
.global TIMER0_COMPA_vect
TIMER0_COMPA_vect:
    push r26
    push r27
    push r28
    push r29
    push r30
    push r31

    // Save SREG
    in r26, 0x3F
    ldi r31, hi8(sreg_tmp)
    ldi r30, lo8(sreg_tmp)
    st Z, r26

    // Save Instruction + Stack
    in r29, 0x3E // SPH
    in r28, 0x3D // SPL
    adiw YL, 6+2

    // Save Stack
    ldi r31, hi8(stack_tmp)
    ldi r30, lo8(stack_tmp)
    st Z+, r28
    st Z+, r29
    sbiw YL, 1

    // Save instruction
    ld r26, Y+
    ld r27, Y+
    ldi r31, hi8(ins_tmp)
    ldi r30, lo8(ins_tmp)
    st Z+, r27
    st Z+, r26

    // r26 = i
    // r27 = tmp
    // Z = register file
    // Y = reg_tmp

    // Z = 0
    ldi r31, 0
    ldi r30, 0
    ldi r29, hi8(reg_tmp)
    ldi r28, lo8(reg_tmp)
    ldi r26, 0

_os_interrupt_cpy_next:
    ld r27, Z+
    st Y+, r27

    inc r26

    // We can only save the first 26 registers, the rest is used here
    cpi r26, 26
    breq _os_interrupt_regsaved
    rjmp _os_interrupt_cpy_next

_os_interrupt_regsaved:
    pop r31
    pop r30
    pop r29
    pop r28
    pop r27
    pop r26

    mov r16, r26
    mov r17, r27
    mov r18, r28
    mov r19, r29
    mov r20, r30
    mov r21, r31

    // Z = register file
    // Y = reg_tmp
    ldi ZH, 0
    ldi ZL, 16
    ldi YH, hi8(reg_tmp + 26)
    ldi YL, lo8(reg_tmp + 26)

    mov r26, 0

    // r26 = i
    // r27 = tmp
_os_interrupt_cpy_next_2:
    ld r27, Z+
    st Y+, r27

    inc r26

    cpi r26, 6
    breq _os_interrupt_regsaved_2
    rjmp _os_interrupt_cpy_next_2

    // Pop last instruction addr
    pop r31

_os_interrupt_regsaved_2:
    jmp os_interrupt_saved





// Restore task context and jump to task
.global os_asm_switch_to_task
os_asm_switch_to_task:

    // Stack
    ldi YL, lo8(stack_tmp)
    ldi YH, hi8(stack_tmp)
    ld ZL, Y+
    ld ZH, Y
    out 0x3E, ZH // SPH
    out 0x3D, ZL // SPL

    // Old Instruction
    ldi YH, hi8(ins_tmp)
    ldi YL, lo8(ins_tmp)
    ld ZL, Y+
    ld ZH, Y+
    push ZL
    push ZH

    // R30-31
    ldi YH, hi8(reg_tmp+30)
    ldi YL, lo8(reg_tmp+30)
    ld ZH, Y+
    push ZH
    ld ZH, Y+
    push ZH

    // SREG
    ldi YL, lo8(sreg_tmp)
    ldi YH, hi8(sreg_tmp)
    ld ZL, Y
    push ZL

    // R26-R29
    ldi YL, lo8(reg_tmp+26)
    ldi YH, hi8(reg_tmp+26)
    ldi ZL, 0

_reg_copy1_next:
    cpi ZL, 4
    breq _reg_copy1_finished

    ld ZH, Y+
    push ZH

    inc ZL

    jmp _reg_copy1_next
_reg_copy1_finished:

    // R0-R25
    ldi YL, lo8(reg_tmp)
    ldi YH, hi8(reg_tmp)
    ldi ZL, 0
    ldi ZH, 0

_reg_copy2_next:
    cpi ZL, 26
    brge _reg_copy2_finished

    ld r26, Y+
    st Z+, r26

    rjmp _reg_copy2_next

_reg_copy2_finished:

    pop r29
    pop r28
    pop r27
    pop r26

    pop r31
    out 0x3F, r31 // SREG

    pop r31
    pop r30

    reti
