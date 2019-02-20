# source /users/outil/soc/env_soclib.sh
export GIET_SYS_PATH=/users/enseig/alain/giet_2011/sys
export GIET_APP_PATH=/users/enseig/alain/giet_2011/app
export AS=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-as
export CC=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-gcc
export LD=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-ld
export DU=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-objdump

SOFT_SYS = drivers.o common.o ctx_handler.o irq_handler.o sys_handler.o exc_handler.o
SOFT_APP = stdio.o main.o
SOFT     = $(SOFT_APP) $(SOFT_SYS)
TXT      = sys.bin.txt app.bin.txt
EXEC 	 = sys.bin app.bin

all : $(EXEC) txt

init : 
	export GIET_SYS_PATH=/users/enseig/alain/giet_2011/sys
	export GIET_APP_PATH=/users/enseig/alain/giet_2011/app
	export AS=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-as
	export CC=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-gcc
	export LD=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-ld
	export DU=/opt/gcc-cross-mipsel/4.3.3/bin/mipsel-unknown-elf-objdump

sys.bin : reset.o giet.o drivers.o common.o ctx_handler.o irq_handler.o sys_handler.o exc_handler.o
app.bin : stdio.o main.o 
stdio.o : %.o:$(GIET_APP_PATH)/%.c
main.o  : %.o:%.c
txt : $(TXT)

reset.o : reset.s
	$(AS) -g -mips32 -o reset.o $<

giet.o   : $(GIET_SYS_PATH)/giet.s 
	$(AS) -g -mips32 -o giet.o $<

$(EXEC) : %.bin:
	$(LD) -o $@ -T $*.ld $^

$(TXT) : %.txt : %
	$(DU) -D $< > $@

$(SOFT_APP) : %.o:
	$(CC) -Wall -mno-gpopt -ffreestanding -mips32 -I$(GIET_APP_PATH) -I. -c -o  $@ $<

$(SOFT_SYS):%.o:$(GIET_SYS_PATH)/%.c
	$(CC) -Wall -mno-gpopt -ffreestanding -mips32 -I$(GIET_SYS_PATH) -I. -c -o  $@ $<

clean : 
	rm -f *.o

clean_all : clean
	rm -f $(EXEC) $(TXT)

.PHONY : clean clean_all all init