current_dir = $(shell pwd)


all : compil simul

compil : 
	soclib-cc -p $(current_dir)/tp2.desc -t systemc_21 -o simul.x

simul : 
	./simul.x -NCYCLES 10000000

trace : 
	./simul.x -TRACE 0 -NCYCLES 10000 > trace
