SCRN_SEL = 0x18
TSS0_SEL    = 0x20
LDT0_SEL    = 0x28
TSS1_SEL    = 0X30
LDT1_SEL    = 0x38
TSS2_SEL    = 0X40
LDT2_SEL    = 0x48

.globl startup_32
.text
startup_32:
    movl $0x10,%eax
    mov %ax,%ds
    mov %ax,%es
    mov %ax,%gs
    mov %ax,%fs

    lss init_stack,%esp

    call setup_idt
    call setup_gdt

    # init again
    movl $0x10,%eax
    mov %ax,%ds
    mov %ax,%es
    mov %ax,%gs
    mov %ax,%fs
    lss init_stack,%esp

# setup timer & system call interrupt descriptors.
    movl $0x00080000, %eax   
    movw $timer_interrupt, %ax
    movw $0x8E00, %dx
    movl $0x08, %ecx
    lea idt(,%ecx,8), %esi
    movl %eax,(%esi)
    movl %edx,4(%esi)
    movw $system_interrupt, %ax
    movw $0xef00, %dx
    movl $0x80, %ecx
    lea idt(,%ecx,8), %esi
    movl %eax,(%esi)
    movl %edx,4(%esi)

# Move to user mode (task 0)
    pushfl
    andl $0xffffbfff, (%esp)
    popfl
    movl $TSS0_SEL, %eax
    ltr %ax
    movl $LDT0_SEL, %eax
    lldt %ax
    movl $0, current
    sti
    pushl $0x17
    pushl $usr_stk0
    pushfl
    pushl $0x0f
    pushl $task0
    iret

die:
    jmp die

.align 2
ignore_int:
    push %ds
    pushl %eax
    movl $0x10, %eax
    mov %ax, %ds
    mov $0x0c98, %ax            /* print 'C' */
    call write_char
    popl %eax
    pop %ds
    iret

write_char:
    push %gs
    pushl %ebx

    mov $SCRN_SEL,%ebx
    mov %bx,%gs

    mov src_loc,%bx
    shl $1,%ebx
    mov %ax,%gs:(%ebx)
    shr $1,%ebx
    incl %ebx
    cmpl $2000,%ebx
    jb 1f
    movl $0,%ebx
1:
    movl %ebx,src_loc

    popl %ebx
    pop %gs
    ret

.align 2
timer_interrupt:
    push %ds
    pushl %edx
    pushl %ecx
    pushl %ebx
    pushl %eax
    movl $0x10, %eax
    mov %ax, %ds
    movb $0x20, %al
    outb %al, $0x20
    // is 1
    movl $1, %eax
    cmpl %eax, current
    je 3f
    // is 2
    movl $2, %eax
    cmpl %eax, current
    je 1f
    // is 0
    movl $0, %eax
    cmpl %eax, current
    je 2f
1:    movl $0, current
    ljmp $TSS0_SEL, $0
    jmp 4f
2:    movl $1, current
    ljmp $TSS1_SEL, $0
    jmp 4f
3:    movl $2, current
    ljmp $TSS2_SEL, $0
    jmp 4f
4:    popl %eax
    popl %ebx
    popl %ecx
    popl %edx
    pop %ds
    iret

/* system call handler */
.align 2
system_interrupt:
    push %ds
    pushl %edx
    pushl %ecx
    pushl %ebx
    pushl %eax
    movl $0x10, %edx
    mov %dx, %ds
    call write_char
    popl %eax
    popl %ebx
    popl %ecx
    popl %edx
    pop %ds
    iret

/*********************************************/
current:
    .long 0

setup_idt:
    lea ignore_int,%edx
    movl $0x00080000,%eax
    movw %dx,%ax        /* selector = 0x0008 = cs */
    movw $0x8E00,%dx    /* interrupt gate - dpl=0, present */
    lea idt,%edi
    mov $256,%ecx
rp_sidt:
    movl %eax,(%edi)
    movl %edx,4(%edi)
    addl $8,%edi
    dec %ecx
    jne rp_sidt
    lidt lidt_opcode
    ret

setup_gdt:
    lgdt lgdt_opcode
    ret

.align 2
lidt_opcode:
    .word 256*8-1
    .long idt
lgdt_opcode:
    .word (end_gdt-gdt)-1
    .long gdt

src_loc:
    .long 0

.align 2
idt:
    .fill 256,8,0

gdt:
    .quad 0x0000000000000000
    .quad 0x00c09a00000007ff
    .quad 0x00c09200000007ff
    .quad 0x00c0920b80000002

    .word 0x68,tss0,0xe900,0x0
    .word 0x40,ldt0,0xe200,0x0
    .word 0x68,tss1,0xe900,0x0
    .word 0x40,ldt1,0xe200,0x0
    .word 0x68,tss2,0xe900,0x0
    .word 0x40,ldt2,0xe200,0x0
end_gdt:

    .fill 128,4,0
init_stack:
    .long init_stack
    .word 0x10

.align 2
ldt0:   
    .quad 0x0000000000000000
    .quad 0x00c0fa00000003ff    # 0x0f, base = 0x10000
    .quad 0x00c0f200000003ff    # 0x17
tss0:
    .long 0             /* back link */
    .long stack0_krn_ptr, 0x10    /* esp0, ss0 */
    .long 0, 0            /* esp1, ss1 */
    .long 0, 0            /* esp2, ss2 */
    .long 0                /* cr3 */
    .long task0            /* eip */
    .long 0x200            /* eflags */
    .long 0, 0, 0, 0        /* eax, ecx, edx, ebx */
    .long usr_stk0, 0, 0, 0    /* esp, ebp, esi, edi */
    .long 0x17,0x0f,0x17,0x17,0x17,0x17 /* es, cs, ss, ds, fs, gs */
    .long LDT0_SEL            /* ldt */
    .long 0x8000000            /* trace bitmap */

    .fill 128,4,0
stack0_krn_ptr:
    .long 0

/************************************/
.align 2
ldt1:   
    .quad 0x0000000000000000
    .quad 0x00c0fa00000003ff    # 0x0f, base = 0x10000
    .quad 0x00c0f200000003ff    # 0x17
tss1:
    .long 0             /* back link */
    .long stack1_krn_ptr, 0x10    /* esp0, ss0 */
    .long 0, 0            /* esp1, ss1 */
    .long 0, 0            /* esp2, ss2 */
    .long 0                /* cr3 */
    .long task1            /* eip */
    .long 0x200            /* eflags */
    .long 0, 0, 0, 0        /* eax, ecx, edx, ebx */
    .long usr_stk1, 0, 0, 0    /* esp, ebp, esi, edi */
    .long 0x17,0x0f,0x17,0x17,0x17,0x17 /* es, cs, ss, ds, fs, gs */
    .long LDT1_SEL            /* ldt */
    .long 0x8000000            /* trace bitmap */

    .fill 128,4,0
stack1_krn_ptr:
    .long 0
/************************************/
.align 2
ldt2:   
    .quad 0x0000000000000000
    .quad 0x00c0fa00000003ff    # 0x0f, base = 0x10000
    .quad 0x00c0f200000003ff    # 0x17
tss2:
    .long 0             /* back link */
    .long stack2_krn_ptr, 0x10    /* esp0, ss0 */
    .long 0, 0            /* esp1, ss1 */
    .long 0, 0            /* esp2, ss2 */
    .long 0                /* cr3 */
    .long task2            /* eip */
    .long 0x200            /* eflags */
    .long 0, 0, 0, 0        /* eax, ecx, edx, ebx */
    .long usr_stk2, 0, 0, 0    /* esp, ebp, esi, edi */
    .long 0x17,0x0f,0x17,0x17,0x17,0x17 /* es, cs, ss, ds, fs, gs */
    .long LDT2_SEL            /* ldt */
    .long 0x8000000            /* trace bitmap */

    .fill 128,4,0
stack2_krn_ptr:
    .long 0

.align 2
task0:
    movw $0x0c61, %ax              /* print 'a' */
    int $0x80
    movl $0xefff, %ecx
1:    loop 1b
    jmp task0

    .fill 128,4,0
usr_stk0:
    .long 0

task1:
    movw $0x0d62, %ax              /* print 'b' */
    int $0x80
    movl $0xffff, %ecx
1:    loop 1b
    jmp task1

    .fill 128,4,0
usr_stk1:
    .long 0

task2:
    movw $0x0e63, %ax              /* print 'c' */
    int $0x80
    movl $0xfff, %ecx
1:    loop 1b
    jmp task2

    .fill 128,4,0
usr_stk2:
    .long 0