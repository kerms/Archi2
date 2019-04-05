#################################################################################
#	File : reset.s
#	Author : Alain Greiner
#	Date : 25/12/2011
#################################################################################
#       This is an improved boot code for a bi-processor architecture.
#	Depending on the proc_id, each processor
#       - initializes the interrupt vector.
#       - initializes the ICU MASK registers.
#       - initializes the TIMER .
#       - initializes the Status Register.
#       - initializes the stack pointer.
#       - initializes the EPC register, and jumps to the user code.
#################################################################################
		
	.section .reset,"ax",@progbits

	.extern	seg_stack_base
	.extern	seg_data_base
    .extern seg_timer_base
    .extern seg_icu_base

	.func	reset
	.type   reset, %function

reset:
       	.set noreorder

# get the processor id
        mfc0	$27,	$15,	1		# get the proc_id
        andi	$27,	$27,	0x1		# no more than 2 processors
        bne	$27,	$0,	proc1
        nop

proc0:
        # initialises interrupt vector entries for PROC[0]


        la  $26,    _interrupt_vector
        la  $27,    _isr_timer
        sw  $27, 8($26)
        la  $27,    _isr_tty_get #F
        sw  $27, 12($26) #F

        #initializes the ICU[0] MASK register
        la $26, seg_icu_base
        li $27, 0b1100
        sw $27, 8($26)            #mask <= mask | wdata
        

        # initializes TIMER[0] PERIOD and RUNNING registers
        la $26, seg_timer_base
        li $27, 500000 
        sw $27, 8($26)              # on stocke la période pour le timer0 dans le registre TIMER_PERIOD[i]
        li $27, 1
        sw $27, 4($26)              # Activation en écrivant 1 dans le registre TIMER_RUNNING[i]
            

        # initializes stack pointer for PROC[0]
        la	$29,	seg_stack_base
        li	$27,	0x10000			# stack size = 64K
        addu	$29,	$29,	$27    		# $29 <= seg_stack_base + 64K

        # initializes SR register for PROC[0]
       	li	 $26,	0x0000FF13	
       	mtc0	$26,	$12			# SR <= 0x0000FF13

        # jump to main in user mode: main[0]
	    la	   $26,	seg_data_base
        lw	   $26,	0($26)			# $26 <= main[0]
	    mtc0   $26,	$14			# write it in EPC register
	    eret

proc1:
        # initialises interrupt vector entries for PROC[1]

        la  $26,    _interrupt_vector
        la  $27,    _isr_timer
        sw  $27, 16($26)
        la  $28,    _isr_tty_get #F init
        sw  $28, 20($26) #F
        #initializes the ICU[1] MASK register
        la $26, seg_icu_base
        addiu $26, $26, 32    # changer de base pour le proc1, le composant icu prend 32 * NPROC octets
        #li $27, 0b10000  
        li $27, 0b100000   
        sw $27, 8($26)        #mask <= mask | wdata

        # initializes TIMER[1] PERIOD and RUNNING registers
        la $26, seg_timer_base
        addiu $26, $26, 16       # changer de base pour le proc1
        li $27, 100000
        sw $27, 8($26)             # on stocke la période pour le timer1 dans le registre TIMER_PERIOD[i]
        li $27, 1
        sw $27, 4($26)              # Activation en écrivant 1 dans le registre TIMER_RUNNING[i]

        # initializes stack pointer for PROC[1]

        la      $29,    seg_stack_base
        li      $27,    0x10000         # stack size = 64K
        sll     $27,    $27,    1
        addu    $29,    $29,    $27         # $29 <= seg_stack_base + 64K

        # initializes SR register for PROC[1]
        li      $26,    0x0000FF13  
        mtc0    $26,    $12         # SR <= 0x0000FF13

        # jump to main in user mode: main[1]
        la      $26,    seg_data_base
        lw      $26,    4($26)          # $26 <= main[1]
        mtc0    $26,    $14         # write it in EPC register
        eret

        # initializes SR register for PROC[1]

        # jump to main in user mode: main[1]

	.set reorder

	.set reorder

	.endfunc
	.size	reset, .-reset

