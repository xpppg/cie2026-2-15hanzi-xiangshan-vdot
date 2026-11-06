/* One unmasked RVV 1.0 vector addition, SEW=8, LMUL=1, VL=2.
 * a0=input1, a1=input2, a2=result; returns the actual VL in a0.
 * Vector state is caller-clobbered under the standard calling convention.
 */
    .section .text.vadd_once,"ax",@progbits
    .balign 4
    .globl vadd_once
    .type vadd_once,@function
vadd_once:
    /* Enable vector state (mstatus.VS), independently of startup code. */
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    csrwi vcsr, 0
    vsetivli t0, 2, e8, m1, tu, mu
    vle8.v v2, (a0)
    vle8.v v3, (a1)

    .balign 4
    .globl vadd_target
vadd_target:
    vadd.vv v4, v2, v3

    vse8.v v4, (a2)
    mv a0, t0
    ret
    .size vadd_once, .-vadd_once
    .section .note.GNU-stack,"",@progbits
