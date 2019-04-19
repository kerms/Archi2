
ARGS?= -NPROCS 2 -SNOOP 1
APP?=soft/fifo.bin

simul.x : tp5_top.cpp tp5.desc
	/users/outil/soc/soclib/utils/bin/soclib-cc -p tp5.desc -t systemc_21 -o simul.x

run : simul.x
	make -C soft/
	./simul.x $(ARGS) -APP $(APP)
	@echo ./simul.x $(ARGS) -APP $(APP)

