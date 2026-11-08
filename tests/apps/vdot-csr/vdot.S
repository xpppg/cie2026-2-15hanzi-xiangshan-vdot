/* Case arguments: a,b,old,out,vl,vtype,variant,flags. Whole-register transfers
 * preload all source bytes regardless of the tested VL and fractional LMUL.
 */
    .section .text,"ax",@progbits
    .balign 4
    .globl vdot_csr_case
    .type vdot_csr_case,@function
vdot_csr_case:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    andi t0, a7, 1
    csrw vxsat, t0
    srli t0, a7, 1
    andi t0, t0, 3
    csrw vxrm, t0
    vsetivli zero, 16, e8, m1, tu, mu
    vl1re8.v v1, (a2)
    vl1re8.v v0, (a2)
    vl1re8.v v31, (a2)
    vl8re8.v v8, (a0)
    vl8re8.v v16, (a1)
    .macro SELECT id
    li t0, \id
    beq a6, t0, .Lcase\id
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
    vl8re8.v v0, (a0)
    SELECT 9
    j .Lcase10
    .macro CASE id, dst, src2, src1
.Lcase\id:
    vsetvl zero, a4, a5
    .word (0x0200000b | (\src2 << 20) | (\src1 << 15) | (\dst << 7))
    csrr t0, vstart
    sd t0, 16(a3)
    csrr t0, vl
    sd t0, 24(a3)
    csrr t0, vtype
    sd t0, 32(a3)
    csrr t0, vxsat
    sd t0, 40(a3)
    csrr t0, vxrm
    sd t0, 48(a3)
    vs1r.v v\dst, (a3)
    ret
    .endm
    CASE 0, 1, 8, 16
    CASE 1, 8, 8, 16
    CASE 2, 15, 8, 16
    CASE 3, 16, 8, 16
    CASE 4, 23, 8, 16
    CASE 5, 0, 8, 16
    CASE 6, 31, 8, 16
    CASE 7, 1, 8, 8
    CASE 8, 8, 8, 8
    CASE 9, 31, 0, 16
    CASE 10, 0, 0, 0
    .size vdot_csr_case, .-vdot_csr_case

    .balign 4
    .globl vdot_csr_chain
    .type vdot_csr_chain,@function
vdot_csr_chain:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    vsetivli zero, 16, e8, m1, tu, mu
    vl1re8.v v2, (a0)
    vl1re8.v v3, (a1)
    .word 0x0221820b
    .word 0x0221828b
    .word 0x0241030b
    vs1r.v v4, (a2)
    addi a2, a2, 16
    vs1r.v v5, (a2)
    addi a2, a2, 16
    vs1r.v v6, (a2)
    ret
    .size vdot_csr_chain, .-vdot_csr_chain

    .balign 4
    .globl vdot_csr_group_chain
    .type vdot_csr_group_chain,@function
vdot_csr_group_chain:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    li t0, 128
    vsetvli zero, t0, e8, m8, tu, mu
    vl8re8.v v8, (a0)
    vl8re8.v v16, (a1)
    vl8re8.v v24, (a3)
    .word (0x0200000b | (8 << 20) | (16 << 15) | (24 << 7))
    .word (0x0200000b | (8 << 20) | (16 << 15) | (0 << 7))
    .word (0x0200000b | (24 << 20) | (16 << 15) | (3 << 7))
    vs1r.v v24, (a2)
    addi a2, a2, 16
    vs1r.v v0, (a2)
    addi a2, a2, 16
    vs1r.v v3, (a2)
    ret
    .size vdot_csr_group_chain, .-vdot_csr_group_chain

/* Each illegal case changes only the condition under test. Inputs remain
 * unused. The trap handler returns mcause and skips exactly one instruction.
 */
    .balign 4
    .globl vdot_csr_illegal
    .type vdot_csr_illegal,@function
vdot_csr_illegal:
    li t0, 0x200
    csrs mstatus, t0
    csrwi vstart, 0
    vsetivli zero, 16, e8, m1, tu, mu
    vl1re8.v v1, (a0)
    csrr t3, mtvec
    la t0, .Lillegal_trap
    csrw mtvec, t0
    li a0, -1
    .macro BAD_SELECT id
    li t0, \id
    beq a2, t0, .Lbad\id
    .endm
    BAD_SELECT 0
    BAD_SELECT 1
    BAD_SELECT 2
    BAD_SELECT 3
    BAD_SELECT 4
    BAD_SELECT 5
    BAD_SELECT 6
    BAD_SELECT 7
    BAD_SELECT 8
    BAD_SELECT 9
    BAD_SELECT 10
    BAD_SELECT 11
    j .Lbad12
.Lbad0:
    .word (0x0000000b | (8 << 20) | (16 << 15) | (1 << 7))
    j .Lillegal_done
.Lbad1:
    vsetivli zero, 1, e16, m1, tu, mu
    j .Lillegal_exec
.Lbad2:
    vsetivli zero, 1, e32, m1, tu, mu
    j .Lillegal_exec
.Lbad3:
    vsetivli zero, 1, e64, m1, tu, mu
    j .Lillegal_exec
.Lbad4:
    csrwi vstart, 1
    j .Lillegal_exec
.Lbad5:
    csrwi vstart, 7
    j .Lillegal_exec
.Lbad6:
    li t0, 127
    csrw vstart, t0
    j .Lillegal_exec
.Lbad7:
    vsetivli zero, 1, e8, m2, tu, mu
    .word (0x0200000b | (9 << 20) | (16 << 15) | (1 << 7))
    j .Lillegal_done
.Lbad8:
    vsetivli zero, 1, e8, m2, tu, mu
    .word (0x0200000b | (8 << 20) | (17 << 15) | (1 << 7))
    j .Lillegal_done
.Lbad9:
    li t0, -1
    vsetvl zero, zero, t0
    j .Lillegal_exec
.Lbad10:
    li t0, 0x600
    csrc mstatus, t0
    j .Lillegal_exec
.Lbad11:
    li t0, 4
    vsetvl zero, zero, t0
    j .Lillegal_exec
.Lbad12:
    .word (0x0600000b | (8 << 20) | (16 << 15) | (1 << 7))
    j .Lillegal_done
.Lillegal_exec:
    .word (0x0200000b | (8 << 20) | (16 << 15) | (1 << 7))
.Lillegal_done:
    li t0, 0x200
    csrs mstatus, t0
    csrr t0, vstart
    sd t0, 16(a1)
    csrwi vstart, 0
    csrw mtvec, t3
    vsetivli zero, 16, e8, m1, tu, mu
    vs1r.v v1, (a1)
    ret
    .balign 4
.Lillegal_trap:
    csrr a0, mcause
    csrr t5, mepc
    addi t5, t5, 4
    csrw mepc, t5
    mret
    .size vdot_csr_illegal, .-vdot_csr_illegal
    .section .note.GNU-stack,"",@progbits
