/* a0/a1: input arrays, 16 bytes per block; a2: full-vector outputs;
 * a3: number of blocks; a4: repeats; a5: 0=baseline, 1=vdot.
 * Returns total cycles for the complete batch computation.
 */
    .section .text.dot_workload,"ax",@progbits
    .balign 4
    .globl dot_workload
    .type dot_workload,@function
dot_workload:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0

    # On this XiangShan revision FENCE drains the ROB and flushes the pipe.
    fence
    rdcycle t0
    fence
    beqz a5, .Lbaseline

    vsetivli zero, 16, e8, m1, tu, mu
.Ldot_repeat:
    mv t2, a0
    mv t3, a1
    mv t4, a2
    mv t5, a3
.Ldot_block:
    vl1re8.v v2, (t2)
    vl1re8.v v3, (t3)
    .word 0x0221820b             # vdot.vv v4, v2, v3
    vs1r.v v4, (t4)
    addi t2, t2, 16
    addi t3, t3, 16
    addi t4, t4, 16
    addi t5, t5, -1
    bnez t5, .Ldot_block
    addi a4, a4, -1
    bnez a4, .Ldot_repeat
    j .Ldone

.Lbaseline:
    vsetivli zero, 16, e16, m2, tu, mu
    vmv.v.i v12, 0              # 32-bit zero reduction seed
    vmv.v.i v4, 0               # clear output tail once; tu preserves it in the loop
.Lbase_repeat:
    mv t2, a0
    mv t3, a1
    mv t4, a2
    mv t5, a3
.Lbase_block:
    vl1re8.v v2, (t2)
    vl1re8.v v3, (t3)
    vsext.vf2 v8, v2
    vsext.vf2 v10, v3
    vmul.vv v8, v8, v10
    vwredsum.vs v4, v8, v12
    vs1r.v v4, (t4)
    addi t2, t2, 16
    addi t3, t3, 16
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
