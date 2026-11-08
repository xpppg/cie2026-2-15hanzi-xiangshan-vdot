#if BENCH_LMUL == 2
#define VLOAD vl2re8.v
#define VSTORE vs2r.v
#define INPUT_TYPE e8, m2
#define PRODUCT_TYPE e16, m4
#elif BENCH_LMUL == 4
#define VLOAD vl4re8.v
#define VSTORE vs4r.v
#define INPUT_TYPE e8, m4
#define PRODUCT_TYPE e16, m8
#elif BENCH_LMUL == 8
#define VLOAD vl8re8.v
#define VSTORE vs8r.v
#define INPUT_TYPE e8, m8
#define PRODUCT_TYPE e16, m8
#else
#error Unsupported LMUL
#endif
#define ELEMENTS (16 * BENCH_LMUL)

    .section .text.scale,"ax",@progbits
    .balign 4
    .globl fill_vectors
    .type fill_vectors,@function
fill_vectors:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    vsetvli t0, zero, INPUT_TYPE, tu, mu
    vid.v v24
    vadd.vx v8, v24, a2
    vmv.v.x v16, a3
    VSTORE v8, (a0)
    VSTORE v16, (a1)
    ret
    .size fill_vectors, .-fill_vectors

    # a0/a1: inputs; a2: outputs; a3: blocks; a4: repeats; a5: mode.
    .globl dot_workload
    .type dot_workload,@function
dot_workload:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    fence
    rdcycle t0
    fence
    beqz a5, .Lbase
    li t6, ELEMENTS
    vsetvli zero, t6, INPUT_TYPE, tu, mu
.Ldot_repeat:
    mv t2, a0
    mv t3, a1
    mv t4, a2
    mv t5, a3
.Ldot_block:
    VLOAD v8, (t2)
    VLOAD v16, (t3)
    .word 0x0288020b             # vdot.vv v4, v8, v16
    vs1r.v v4, (t4)
    addi t2, t2, ELEMENTS
    addi t3, t3, ELEMENTS
    addi t4, t4, 16
    addi t5, t5, -1
    bnez t5, .Ldot_block
    addi a4, a4, -1
    bnez a4, .Ldot_repeat
    j .Ldone
.Lbase:
    vsetivli zero, 4, e32, m1, tu, mu
    vmv.v.i v0, 0
    vmv.v.i v4, 0
#if BENCH_LMUL == 8
    li t6, 64
#else
    li t6, ELEMENTS
#endif
.Lbase_repeat:
    mv t2, a0
    mv t3, a1
    mv t4, a2
    mv t5, a3
.Lbase_block:
    VLOAD v8, (t2)
    VLOAD v16, (t3)
#if BENCH_LMUL == 8
    vsetvli zero, t6, e8, m4, tu, mu
#else
    vsetvli zero, t6, INPUT_TYPE, tu, mu
#endif
    vwmul.vv v24, v8, v16
    vsetvli zero, t6, PRODUCT_TYPE, tu, mu
    vwredsum.vs v4, v24, v0
#if BENCH_LMUL == 8
    vsetvli zero, t6, e8, m4, tu, mu
    vwmul.vv v24, v12, v20
    vsetvli zero, t6, PRODUCT_TYPE, tu, mu
    vwredsum.vs v4, v24, v4
#endif
    vs1r.v v4, (t4)
    addi t2, t2, ELEMENTS
    addi t3, t3, ELEMENTS
    addi t4, t4, 16
    addi t5, t5, -1
    bnez t5, .Lbase_block
    addi a4, a4, -1
    bnez a4, .Lbase_repeat
.Ldone:
    fence
    rdcycle t1
    fence
    sub a0, t1, t0
    ret
    .size dot_workload, .-dot_workload
