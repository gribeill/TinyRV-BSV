To build an assembly file to riscv:

riscv32-unknown-elf-as input.s -march=rv32i -mabi=ilp32 -o output.out

Dump assembly with native register numbering:

riscv32-unknown-elf-objdump -S -d output.out -M numeric

Compile from C:

riscv32-unknown-elf-gcc -g -ffreestanding -O0 -Wl,--gc-sections -nostartfiles -nostdlib -nodefaultlibs -Wl,-T,riscv32i.ld crt0.s input.c

Convert to register file:
riscv32-unknown-elf-objcopy -O binary input.out foo.bin
python3 bin_to_hex.py foo.bin bar.hex