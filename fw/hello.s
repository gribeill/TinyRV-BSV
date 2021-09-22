addi x1, x0, 4  #int a = 4;
addi x2, x0, 7  #int b = 7;
add  x3, x0, x0 #int c = 0;
add  x4, x0, x0 #int i = 0;
addi x5, x0, 3  #loop exit condition
loop:
	bge x4, x5, loop_exit #i < 3
	add x3, x3, x4 #c += i
	add x3, x3, x1 #c += a
	add x3, x3, x2 #c += b
	addi x4, x4, 1 # i += 1
	j loop 
loop_exit:
	sw x3, 0x100(x0)

