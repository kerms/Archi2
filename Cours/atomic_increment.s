# atomic_increment

	# $4 = addr
	# $5 = value

loop :
	ll 	$3, 0($4) 		# r3 <= value read 
	add $3, $3, $5   	# r3 <= r3 + r5
	sc  $3, 0($4)		# *addr <= r3
	bne	$3, $0, loop
	nop 









void atomic_increment (addr, value)
int to_store;
int read_value;
int store_ok;

while (1) {
	read_value = ll(addr); // give value read from addr

	to_store = value + read_value;

	store_ok = sc(addr, to_store);
	if (store_ok == 1) // failed
		continue;
}
