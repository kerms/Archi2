/*
 * These routines must be "installed" by the boot code in the interrupt vector
 * (_interrupt_vector), depending on the system architecture
 */

#include <config.h>
#include <irq_handler.h>
#include <drivers.h>
#include <common.h>
#include <ctx_handler.h>
#include <hwr_mapping.h>

/*
 * Initialize the whole interrupt vector with the default ISR
 */
_isr_func_t _interrupt_vector[32] = { [0 ... 31] = &_isr_default };

/*
 * _int_demux()
 *
 * This functions uses an external ICU component (Interrupt Controler Unit)
 * that concentrates up to 32 interrupts lines up to (NB_PROCS) IRQ lines that
 * can be connected to any of the (NB_PROCS) MIPS32 IRQ inputs.
 *
 * This component returns the highest priority active interrupt index (smaller
 * indexes have the highest priority) by reading the ICU_IT_VECTOR register.
 * Any value larger than 31 means "no active interrupt", and the default ISR
 * (that does nothing) is executed.
 *
 * The interrupt vector (32 ISR addresses array stored at _interrupt_vector
 * address) is initialised with the default ISR address. The actual ISR
 * addresses are supposed to be written in the interrupt vector array by the
 * boot code.
 */
void _int_demux(void)
{
    int interrupt_index;
    _isr_func_t isr;

    /* retrieves the highest priority active interrupt index */
    if (!_icu_read(ICU_IT_VECTOR, (unsigned int*)&interrupt_index))
    {
        /* no interrupt is active */
        if (interrupt_index > 31)
            return;

        /* call the ISR corresponding to this index */
        isr = _interrupt_vector[interrupt_index];
        isr();
    }
}

/*
 * _isr_default()
 *
 * The default ISR is called when no specific ISR has been installed in the
 * interrupt vector. It simply displays a message on TTY0.
 */
void _isr_default()
{
    _putk("\n\n!!! Default ISR !!!\n");
}

/*
 * _isr_dma
 *
 * This ISR acknowledges the interrupt from the dma controller, depending on
 * the proc_id. It reset the global variable _dma_busy[i] for software
 * signaling, after copying the DMA status into the _dma_status[i] variable.
 */
void _isr_dma()
{
    volatile unsigned int* dma_address;
    unsigned int proc_id;

    proc_id = _procid();
    dma_address = (unsigned int*)&seg_dma_base + (proc_id * DMA_SPAN);

    _dma_status[proc_id] = dma_address[DMA_LEN]; /* save status */
    _dma_busy[proc_id] = 0;                      /* release DMA */
    dma_address[DMA_RESET] = 0;         /* reset IRQ */
}

/*
 * _isr_ioc
 *
 * There is only one IOC controler shared by all tasks. It acknowledge the IRQ
 * using the ioc base address, save the status, and set the _ioc_done variable
 * to signal completion.
 */
void _isr_ioc()
{
    volatile unsigned int* ioc_address;

    ioc_address = (unsigned int*)&seg_ioc_base;

    _ioc_status = ioc_address[BLOCK_DEVICE_STATUS]; /* save status & reset IRQ */
    _ioc_done   = 1;                                /* signals completion */
}

/*
 * _isr_timer
 *
 * This ISR handles up to 8 IRQs generated by 8 independant timers, and
 * connected to 8 different processors. The behaviour depends on the processor
 * id: It acknowledges the IRQ on TIMER[id] and displays a message on TTY[id]
 */
void _isr_timer()
{
    volatile unsigned int *timer_address;
    unsigned int proc_id;

    proc_id = _procid();
    timer_address = (unsigned int*)&seg_timer_base + (proc_id * TIMER_SPAN);

    timer_address[TIMER_RESETIRQ] = 0; /* reset IRQ */

    _putk("\n\n!!! Interrupt timer received at cycle: ");

    char *buf = "          ";
    int date = (int)_proctime();
    _itoa_dec(date, buf);

    _putk(buf);

    _putk("\n\n");
}

/*
 * _isr_tty_get_task* (* = 0,1,2,3)
 *
 * A single processor can run up to 4 tasks in pseudo-parallelismr, and each
 * task has is own private terminal.
 *
 * These 4 ISRs handle up to 4 IRQs associate to 4 independant terminals
 * connected to a single processor.
 *
 * It acknowledge the IRQ using the terminal basee address depending on both
 * the proc_id and the task_id (0,1,2,3).
 *
 * There is one communication buffer _tty_get_buf[tty_id] per terminal.
 * protected by a set/reset variable _tty_get_full[tty_id].
 *
 * The _tty_get_full[tty_id] synchronisation variable is set by the ISR, and
 * reset by the OS.
 *
 * To access these buffers, the terminal index is computed as
 *     tty_id = proc_id*ntasks + task_id
 * A character is lost if the buffer is full when the ISR is executed.
 */
void _isr_tty_get_indexed(unsigned int task_id)
{
    volatile unsigned int *tty_address;
    unsigned int proc_id;

    proc_id = _procid();
    tty_address = (unsigned int*)&seg_tty_base
        + (proc_id * NB_MAXTASKS * TTY_SPAN)
        + (task_id * TTY_SPAN);

    unsigned int tty_id = _procid() * NB_MAXTASKS + task_id;

    /* save character and reset IRQ */
    _tty_get_buf[tty_id] = (unsigned char)tty_address[TTY_READ];

    /* signals character available */
    _tty_get_full[tty_id] = 1;
}

void _isr_tty_get()
{
    _isr_tty_get_indexed(0);
}
void _isr_tty_get_task0()
{
    _isr_tty_get_indexed(0);
}
void _isr_tty_get_task1()
{
    _isr_tty_get_indexed(1);
}
void _isr_tty_get_task2()
{
    _isr_tty_get_indexed(2);
}
void _isr_tty_get_task3()
{
    _isr_tty_get_indexed(3);
}

/*
 * _isr_switch
 *
 * This ISR is in charge of context switch. It handles up to 4 IRQs,
 * corresponding to 4 different processors. If the processor uses several
 * timers, the context switch is driven by the IRQ associated to timer0. It
 * acknowledges the IRQ on TIMER[proc_id] and calls the _ctx_switch() function.
 */
void _isr_switch()
{
    volatile unsigned int *timer_address;
    unsigned int proc_id;

    proc_id = _procid();
    timer_address = (unsigned int*)&seg_timer_base + (proc_id * TIMER_SPAN);

    timer_address[TIMER_RESETIRQ] = 0; /* reset IRQ */
    _ctx_switch();
}

