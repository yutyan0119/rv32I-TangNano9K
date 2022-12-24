# cross compiler

GCC_DIR = $(HOME)/riscv-tool
GCC_PREFIX = riscv32-unknown-elf-
GCC_NATIVE = $(GCC_DIR)/bin

CC = $(GCC_NATIVE)/$(GCC_PREFIX)gcc
AS = $(GCC_NATIVE)/$(GCC_PREFIX)as
LD = $(GCC_NATIVE)/$(GCC_PREFIX)ld
OBJDUMP = $(GCC_NATIVE)/$(GCC_PREFIX)objdump
OBJCOPY = $(GCC_NATIVE)/$(GCC_PREFIX)objcopy

CFLAGS = \
	-g \
	-O3 \
	-fno-stack-protector \
	-fno-zero-initialized-in-bss \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	-mstrict-align \
	-march=rv32i \

ASFLAGS = \
  -march=rv32i \

LDFLAGS= \
    -static \

LIBC =
LIBGCC = \
  -L$(GCC_DIR)/lib/gcc/riscv32-unknown-elf/12.2.0 \
	-lgcc \
	-lgcov \
	-L$(GCC_DIR)/riscv32-unknown-elf/lib \
	-lm

# start up routine
CRTOBJ = crt.o
CRTASM = crt.s
LDSCRIPT = ld.script

# Coremark specific definition
ITERATIONS = 0
CLOCKS_PER_SEC = 27000000
FLAGS_STR = ""


CORE_FILES = \
	core_list_join.c \
	core_main.c \
	core_matrix.c \
	core_state.c \
	core_util.c \

PORT_DIR = barebones
PORT_FILES = \
	$(PORT_DIR)/core_portme.c \
	$(PORT_DIR)/ee_printf.c \


SRCS = $(CORE_FILES) $(PORT_FILES)
OBJS = $(SRCS:.c=.o)


XCFLAGS = \
	-g \
	-DITERATIONS=$(ITERATIONS) \
	-DCLOCKS_PER_SEC=$(CLOCKS_PER_SEC) \
	-I ./ \
	-I $(PORT_DIR) \
	-DFLAGS_STR=\"$(FLAGS_STR)\" \


all: prog.hex prog.dump


%.o: %.c Makefile
	$(CC) $(CFLAGS) $(XCFLAGS) -o $@ -c $<

prog.elf: $(OBJS) $(CRTOBJ) Makefile
	$(LD) $(CRTOBJ) $(OBJS) $(LIBGCC) $(LIBC) -T$(LDSCRIPT) $(LDFLAGS) -o prog.elf

prog.dump: prog.elf
	$(OBJDUMP) -D prog.elf > prog.dump

prog.bin: prog.elf
	$(OBJCOPY) -O binary prog.elf prog.bin

prog.hex: prog.bin
	od -An - tx4 -w4 -v prog.bin > prog.hex

$(CRTOBJ): $(CRTASM)
	$(AS) $(ASFLAGS) -o $@ -c $<

.PHONY: clean
clean:
	rm $(OBJS) code.hex prog.hex prog.dump prog.bin prog.elf crt.o -f
