    .section .text.vimac_case,"ax",@progbits
    .balign 4
    .globl vimac_case
    .type vimac_case,@function
vimac_case:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    csrwi vxrm, 2
    csrwi vxsat, 0
    vsetvl zero, a5, a4
    vl1re8.v v2, (a0)
    vl1re8.v v3, (a1)
    vl2re8.v v8, (a2)
    vl1re8.v v0, (a7)
    .macro SELECT id
    li t0, \id
    beq a6, t0, .Lop\id
    .endm
    SELECT 0
    SELECT 1
    SELECT 2
    SELECT 3
    SELECT 4
    SELECT 5
    SELECT 6
    SELECT 7
    SELECT 8
    SELECT 9
    SELECT 10
    SELECT 11
    SELECT 12
    SELECT 13
    SELECT 14
    SELECT 15
    j .Lop16
    .macro OP id, mnemonic
.Lop\id:
    \mnemonic v8, v2, v3
    j .Ldone
    .endm
    OP 0, vmul.vv
    OP 1, vmulh.vv
    OP 2, vmulhu.vv
    OP 3, vmulhsu.vv
    OP 4, vmacc.vv
    OP 5, vnmsac.vv
    OP 6, vmadd.vv
    OP 7, vnmsub.vv
    OP 8, vwmul.vv
    OP 9, vwmulu.vv
    OP 10, vwmulsu.vv
    OP 11, vwmacc.vv
    OP 12, vwmaccu.vv
    OP 13, vwmaccsu.vv
    OP 14, vsmul.vv
.Lop15:
    vmul.vv v8, v2, v3, v0.t
    j .Ldone
.Lop16:
    vmacc.vv v8, v2, v3, v0.t
.Ldone:
    csrr a0, vxsat
    vs2r.v v8, (a3)
    ret
    .size vimac_case, .-vimac_case

    .balign 4
    .globl vimac_dot_mixed
    .type vimac_dot_mixed,@function
vimac_dot_mixed:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    csrwi vxrm, 2
    csrwi vxsat, 0
    vsetivli zero, 16, e8, m1, tu, mu
    vl1re8.v v2, (a0)
    vl1re8.v v3, (a1)
    vl2re8.v v8, (a2)
    .word 0x0221820b             # vdot.vv v4, v2, v3
    vmul.vv v5, v2, v3
    vmacc.vv v8, v2, v3
    .word 0x0221830b             # vdot.vv v6, v2, v3
    vsmul.vv v7, v2, v3
    .word 0x0221848b             # vdot.vv v9, v2, v3
    csrr a0, vxsat
    vs1r.v v4, (a3)
    addi a3, a3, 16
    vs1r.v v5, (a3)
    addi a3, a3, 16
    vs1r.v v6, (a3)
    addi a3, a3, 16
    vs1r.v v7, (a3)
    addi a3, a3, 16
    vs1r.v v8, (a3)
    addi a3, a3, 16
    vs1r.v v9, (a3)
    ret
    .size vimac_dot_mixed, .-vimac_dot_mixed
