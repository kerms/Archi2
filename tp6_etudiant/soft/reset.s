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
        la 		$29, 	_interrupt_vector  	# from irq_handler.c or ICU 0x0
        la 		$27,	_isr_timer		   	# from irq_handler.c
       	sw		$27,	8($29)				# IN (2+2*0)*4

        #initializes the ICU[0] MASK register
        la 		$29, 	seg_icu_base
        addiu 	$29,	$29,	0x0		# +0 to ICU[0]
        addiu	$27,	$0,		0x8		# +8 = (2+2*0)*4 = IRQ_TIME[0]
        sw 		$27,	8($29)			# ICU_MASK_SET 	(0x08) <= 8

        # initializes TIMER[0] PERIOD and RUNNING registers
        la 		$29, 	seg_timer_base
        addiu 	$29,	$29,	0x0		# +0 to TIMER[0]
        li		$27,	100000			# period <= 50 000
        sw 		$27,	8($29)			# TIMER_PERIOD (0x08)
        addiu	$27,	$27,	1		# TIMER_RUNNING <= TRUE
        sw 		$27,	4($29)			# TIMER_RUNNING (0x04)

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
        la 		$29, 	_interrupt_vector  	# from irq_handler.c
        la 		$27,	_isr_timer		   	# from irq_handler.c
       	sw		$27,	16($29)				# IN (2+2*1)*4

        #initializes the ICU[1] MASK register
        la 		$29, 	seg_icu_base
        addiu 	$29,	$29,	0x20	# +32 to ICU[1]
        addiu	$27,	$0,		0x10	# +16 = (2+2*1)*4 = IRQ_TIME[1]
        sw 		$27,	8($29)			# ICU_MASK_SET 	(0x08) <= 16

        # initializes TIMER[1] PERIOD and RUNNING registers
        la 		$29, 	seg_timer_base
        addiu 	$29,	$29,	0x10	# +16 to TIMER[1]
        li		$27,	100000			# period <= 100 000
        sw 		$27,	8($29)			# TIMER_PERIOD (0x08)
        addiu	$27,	$27,	1		# TIMER_RUNNING <= TRUE
        sw 		$27,	4($29)			# TIMER_RUNNING (0x04)

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

