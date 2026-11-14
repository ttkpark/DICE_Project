lw x1,776(x0) # BIAS_BASE
addi x2,x0,-16 # tile offsets become 0 then 16 after adding instruction offsets
lw x28,0(x1)
lw x29,4(x1)
lw x30,8(x1)
lw x31,12(x1)
tile:
lw x1,768(x0) # X_BASE
lw x3,772(x0) # W_BASE
add x1,x1,x2
add x3,x3,x2
lw x4,16(x1)
lw x6,24(x1)
lw x7,28(x1)
lw x5,20(x1)
lw x8,16(x3)
lw x9,48(x3)
lw x10,80(x3)
lw x11,112(x3)
lw x12,20(x3)
lw x13,52(x3)
lw x14,84(x3)
lw x15,116(x3)
lw x16,24(x3)
lw x17,56(x3)
lw x18,88(x3)
lw x19,120(x3)
lw x20,28(x3)
lw x21,60(x3)
lw x22,92(x3)
lw x23,124(x3)
addi x24,x0,0
addi x25,x0,0
addi x26,x0,0
addi x27,x0,0
addi x1,x0,128
and x3,x4,x1
beq x3,x0,bit_7_skip_0
sub x24,x24,x8
sub x25,x25,x9
sub x26,x26,x10
sub x27,x27,x11
bit_7_skip_0:
and x3,x5,x1
beq x3,x0,bit_7_skip_1
sub x24,x24,x12
sub x25,x25,x13
sub x26,x26,x14
sub x27,x27,x15
bit_7_skip_1:
and x3,x6,x1
beq x3,x0,bit_7_skip_2
sub x24,x24,x16
sub x25,x25,x17
sub x26,x26,x18
sub x27,x27,x19
bit_7_skip_2:
and x3,x7,x1
beq x3,x0,bit_7_skip_3
sub x24,x24,x20
sub x25,x25,x21
sub x26,x26,x22
sub x27,x27,x23
bit_7_skip_3:
addi x1,x0,64
add x24,x24,x24
add x25,x25,x25
add x26,x26,x26
add x27,x27,x27
and x3,x4,x1
beq x3,x0,bit_6_skip_0
add x24,x24,x8
add x25,x25,x9
add x26,x26,x10
add x27,x27,x11
bit_6_skip_0:
and x3,x5,x1
beq x3,x0,bit_6_skip_1
add x24,x24,x12
add x25,x25,x13
add x26,x26,x14
add x27,x27,x15
bit_6_skip_1:
and x3,x6,x1
beq x3,x0,bit_6_skip_2
add x24,x24,x16
add x25,x25,x17
add x26,x26,x18
add x27,x27,x19
bit_6_skip_2:
and x3,x7,x1
beq x3,x0,bit_6_skip_3
add x24,x24,x20
add x25,x25,x21
add x26,x26,x22
add x27,x27,x23
bit_6_skip_3:
addi x1,x0,32
add x24,x24,x24
add x25,x25,x25
add x26,x26,x26
add x27,x27,x27
and x3,x4,x1
beq x3,x0,bit_5_skip_0
add x24,x24,x8
add x25,x25,x9
add x26,x26,x10
add x27,x27,x11
bit_5_skip_0:
and x3,x5,x1
beq x3,x0,bit_5_skip_1
add x24,x24,x12
add x25,x25,x13
add x26,x26,x14
add x27,x27,x15
bit_5_skip_1:
and x3,x6,x1
beq x3,x0,bit_5_skip_2
add x24,x24,x16
add x25,x25,x17
add x26,x26,x18
add x27,x27,x19
bit_5_skip_2:
and x3,x7,x1
beq x3,x0,bit_5_skip_3
add x24,x24,x20
add x25,x25,x21
add x26,x26,x22
add x27,x27,x23
bit_5_skip_3:
addi x1,x0,16
add x24,x24,x24
add x25,x25,x25
add x26,x26,x26
add x27,x27,x27
and x3,x4,x1
beq x3,x0,bit_4_skip_0
add x24,x24,x8
add x25,x25,x9
add x26,x26,x10
add x27,x27,x11
bit_4_skip_0:
and x3,x5,x1
beq x3,x0,bit_4_skip_1
add x24,x24,x12
add x25,x25,x13
add x26,x26,x14
add x27,x27,x15
bit_4_skip_1:
and x3,x6,x1
beq x3,x0,bit_4_skip_2
add x24,x24,x16
add x25,x25,x17
add x26,x26,x18
add x27,x27,x19
bit_4_skip_2:
and x3,x7,x1
beq x3,x0,bit_4_skip_3
add x24,x24,x20
add x25,x25,x21
add x26,x26,x22
add x27,x27,x23
bit_4_skip_3:
addi x1,x0,8
add x24,x24,x24
add x25,x25,x25
add x26,x26,x26
add x27,x27,x27
and x3,x4,x1
beq x3,x0,bit_3_skip_0
add x24,x24,x8
add x25,x25,x9
add x26,x26,x10
add x27,x27,x11
bit_3_skip_0:
and x3,x5,x1
beq x3,x0,bit_3_skip_1
add x24,x24,x12
add x25,x25,x13
add x26,x26,x14
add x27,x27,x15
bit_3_skip_1:
and x3,x6,x1
beq x3,x0,bit_3_skip_2
add x24,x24,x16
add x25,x25,x17
add x26,x26,x18
add x27,x27,x19
bit_3_skip_2:
and x3,x7,x1
beq x3,x0,bit_3_skip_3
add x24,x24,x20
add x25,x25,x21
add x26,x26,x22
add x27,x27,x23
bit_3_skip_3:
addi x1,x0,4
add x24,x24,x24
add x25,x25,x25
add x26,x26,x26
add x27,x27,x27
and x3,x4,x1
beq x3,x0,bit_2_skip_0
add x24,x24,x8
add x25,x25,x9
add x26,x26,x10
add x27,x27,x11
bit_2_skip_0:
and x3,x5,x1
beq x3,x0,bit_2_skip_1
add x24,x24,x12
add x25,x25,x13
add x26,x26,x14
add x27,x27,x15
bit_2_skip_1:
and x3,x6,x1
beq x3,x0,bit_2_skip_2
add x24,x24,x16
add x25,x25,x17
add x26,x26,x18
add x27,x27,x19
bit_2_skip_2:
and x3,x7,x1
beq x3,x0,bit_2_skip_3
add x24,x24,x20
add x25,x25,x21
add x26,x26,x22
add x27,x27,x23
bit_2_skip_3:
addi x1,x0,2
last_two_bits:
add x24,x24,x24
add x25,x25,x25
add x26,x26,x26
add x27,x27,x27
and x3,x4,x1
beq x3,x0,bit_1_or_0_skip_0
add x24,x24,x8
add x25,x25,x9
add x26,x26,x10
add x27,x27,x11
bit_1_or_0_skip_0:
and x3,x5,x1
beq x3,x0,bit_1_or_0_skip_1
add x24,x24,x12
add x25,x25,x13
add x26,x26,x14
add x27,x27,x15
bit_1_or_0_skip_1:
and x3,x6,x1
beq x3,x0,bit_1_or_0_skip_2
add x24,x24,x16
add x25,x25,x17
add x26,x26,x18
add x27,x27,x19
bit_1_or_0_skip_2:
and x3,x7,x1
beq x3,x0,bit_1_or_0_skip_3
add x24,x24,x20
add x25,x25,x21
add x26,x26,x22
add x27,x27,x23
bit_1_or_0_skip_3:
addi x1,x1,-1
addi x3,x1,-1
beq x3,x0,last_two_bits
tile_done:
add x28,x28,x24
add x29,x29,x25
add x30,x30,x26
add x31,x31,x27
addi x2,x2,16
beq x2,x0,tile
addi x0,x0,0
addi x0,x0,0
done:
lw x21,780(x0) # Y_BASE
lw x22,800(x0) # DONE_TOKEN
lw x23,796(x0) # DONE_ADDR
sw x28,0(x21)
sw x29,4(x21)
sw x30,8(x21)
sw x31,12(x21)
sw x22,0(x23)
park:
jal x0,park
