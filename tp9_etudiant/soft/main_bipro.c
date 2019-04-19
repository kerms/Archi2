/********************************************************
 * File : main_bipro.c
 * Author : Alain Greiner
 * Date : 08/04/2010
 * Copyright : UPMC/LIP6
 ********************************************************
 * This file contains a very simple parallel, 
 * cooperative application.
 * - The producer task writes a sequence of integer 
 * values in a shared memory buffer BUF, after
 * displaying each value on its private TTY.
 * The parameter PRODUCER_DELAY can be used to 
 * adjust the producer data rate.  
 * - The consumer task reads those values in the
 * communication buffer, and displays the values on
 * its private TTY.
 * The parameter CONSUMER_DELAY can be used to 
 * adjust the consumer data rate.
*********************************************************/
#include "stdio.h"

#define NMAX 		50

#define PRODUCER_DELAY 	100
#define CONSUMER_DELAY	100

#define SYNC_MODE

int	BUF = 0;

#ifdef SYNC_MODE
int 	SYNC = 0;
#endif

/******************************************/
__attribute ((constructor)) void producer()
{
    int x;
    int n;
    int tempo = PRODUCER_DELAY;
    int val;

    tty_printf("*** Starting task producer on processor %d ***\n\n", procid());

    for(n = 0 ; n < NMAX ; n++) 
    { 
	for(x = 0 ; x < tempo ; x++) asm volatile ("");
	#ifdef SYNC_MODE
	while (SYNC);
	#endif
	BUF = n;
	__sync_synchronize();
	#ifdef SYNC_MODE
	SYNC = 1;
	#endif
        tty_printf("transmitted value : %d     temporisation = %d\n", n , tempo);
    }

    tty_printf("\n*** Completing producer at cycle %d ***\n", proctime());
    exit();

} // end producer()

/******************************************/
__attribute ((constructor)) void consumer()
{
    int x;
    int n;
    int val;
    int tempo = CONSUMER_DELAY;

    tty_printf("*** Starting task consumer on processor %d ***\n\n", procid());

    for(n = 0 ; n < NMAX ; n++) 
    { 
	for(x = 0 ; x < tempo ; x++) asm volatile ("");
	#ifdef SYNC_MODE
		while(!SYNC);
	#endif
        val = BUF;
		__sync_synchronize();
	#ifdef SYNC_MODE
		SYNC = 0;
	#endif
        tty_printf("received value : %d     temporisation = %d\n", val, tempo);
    }

    tty_printf("\n*** Completing consumer at cycle %d ***\n", proctime());
    exit();

} // end consumer()

