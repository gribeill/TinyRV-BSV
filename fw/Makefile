hello: hello.s
	riscv32-unknown-elf-as hello.s -march=rv32i -mabi=ilp32 -o hello.out
	riscv32-unknown-elf-objdump -S -d hello.out -M numeric > hello.dump
	riscv32-unknown-elf-objcopy -O binary hello.out hello.bin
	python3 bin_to_hex.py hello.bin hello.hex
	cp ./hello.hex ~/GitHub/TinyRV-BSV/test/bsv/test_rv32i.txt

hello_c: hello.c 
	riscv32-unknown-elf-gcc -g -ffreestanding -O0 -Wl,--gc-sections -nostartfiles \
	-nostdlib -nodefaultlibs -Wl,-T,riscv32i.ld crt0.s hello.c -o hello_c.out 
	riscv32-unknown-elf-objdump -S -d hello_c.out -M numeric > hello_c.dump
	riscv32-unknown-elf-objcopy -O binary hello_c.out hello_c.bin
	python3 bin_to_hex.py hello_c.bin hello_c.hex
	cp ./hello_c.hex ~/GitHub/TinyRV-BSV/test/bsv/test_rv32i.txt