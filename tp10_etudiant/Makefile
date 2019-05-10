
ARGS?= -NPROCS 4 -SNOOP 1
APP?=soft/app.bin

simul.x : tp10_top.cpp tp10.desc
	/users/outil/soc/soclib/utils/bin/soclib-cc -p tp10.desc -t systemc_21 -o simul.x

run : simul.x
	make -C soft/
	./simul.x $(ARGS) -APP $(APP)
	@echo ./simul.x $(ARGS) -APP $(APP)

