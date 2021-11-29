hello: hello.s
	riscv32-unknown-elf-as hello.s -march=rv32i -mabi=ilp32 -o hello.out
	riscv32-unknown-elf-objdump -S -d hello.out -M numeric > hello.dump
	riscv32-unknown-elf-objcopy -O binary hello.out hello.bin
	python3 bin_to_hex.py hello.bin hello.hex
	# cp ./hello.hex ../test/bsv/test_rv32i.txt

hello_c: hello.c 
	riscv32-unknown-elf-gcc -g -ffreestanding -O0 -Wl,--gc-sections -nostartfiles \
	-nostdlib -nodefaultlibs -Wl,-T,riscv32i.ld crt0.s hello.c -o hello_c.out 
	riscv32-unknown-elf-objdump -S -d hello_c.out -M numeric > hello_c.dump
	riscv32-unknown-elf-objcopy -O binary hello_c.out hello_c.bin
	python3 bin_to_hex.py hello_c.bin hello_c.hex
	# cp ./hello_c.hex ../test/bsv/test_rv32i.txt

hello_quantum: hello_xquantum.s
	riscv32-unknown-elf-as hello_xquantum.s -march=rv32i_xquantum1p0 -mabi=ilp32 -o hello_quantum.out
	riscv32-unknown-elf-objdump -S -d hello_quantum.out -M numeric > hello_quantum.dump
	riscv32-unknown-elf-objcopy -O binary hello_quantum.out hello_quantum.bin
	python3 bin_to_hex.py hello_quantum.bin hello_quantum.hex
	# cp ./hello_quantum.hex ../test/bsv/test_rv32i.txt

hello_c_quantum: hello_quantum.c 
	riscv32-unknown-elf-gcc -g -ffreestanding -O0 -Wl,--gc-sections -nostartfiles \
	-march=rv32i_xquantum1p0 -mabi=ilp32 \
	-nostdlib -nodefaultlibs -Wl,-T,riscv32i.ld crt0.s hello_quantum.c -o hello_c_quantum.out #\
	# -save-temps \
	riscv32-unknown-elf-objdump -S -d hello_c_quantum.out -M numeric > hello_c_quantum.dump
	riscv32-unknown-elf-objcopy -O binary hello_c_quantum.out hello_c_quantum.bin
	python3 bin_to_hex.py hello_c_quantum.bin hello_c_quantum.hex
	# cp ./hello_c.hex ../test/bsv/test_rv32i.txt
