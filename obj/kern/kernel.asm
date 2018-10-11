
obj/kern/kernel:     formato del fichero elf32-i386


Desensamblado de la sección .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 07 00 00 00       	call   f0100045 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
	if (x > 0)
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);*/
}
f0100043:	5d                   	pop    %ebp
f0100044:	c3                   	ret    

f0100045 <i386_init>:

void
i386_init(void)
{
f0100045:	55                   	push   %ebp
f0100046:	89 e5                	mov    %esp,%ebp
f0100048:	83 ec 1c             	sub    $0x1c,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010004b:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f0100050:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100055:	50                   	push   %eax
f0100056:	6a 00                	push   $0x0
f0100058:	68 00 23 11 f0       	push   $0xf0112300
f010005d:	e8 ba 13 00 00       	call   f010141c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100062:	e8 c6 04 00 00       	call   f010052d <cons_init>
	
	unsigned   int i = 0x00646c72;
f0100067:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
	cprintf("H%x Wo%s\n" ,   57616 ,   &i);
f010006e:	83 c4 0c             	add    $0xc,%esp
f0100071:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100074:	50                   	push   %eax
f0100075:	68 10 e1 00 00       	push   $0xe110
f010007a:	68 60 18 10 f0       	push   $0xf0101860
f010007f:	e8 3a 08 00 00       	call   f01008be <cprintf>
	cprintf("6828 decimal is %o octal!\n", 6828);
f0100084:	83 c4 08             	add    $0x8,%esp
f0100087:	68 ac 1a 00 00       	push   $0x1aac
f010008c:	68 6a 18 10 f0       	push   $0xf010186a
f0100091:	e8 28 08 00 00       	call   f01008be <cprintf>
f0100096:	83 c4 10             	add    $0x10,%esp
	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100099:	83 ec 0c             	sub    $0xc,%esp
f010009c:	6a 00                	push   $0x0
f010009e:	e8 a5 06 00 00       	call   f0100748 <monitor>
f01000a3:	83 c4 10             	add    $0x10,%esp
f01000a6:	eb f1                	jmp    f0100099 <i386_init+0x54>

f01000a8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	56                   	push   %esi
f01000ac:	53                   	push   %ebx
f01000ad:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000b0:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000b7:	74 0f                	je     f01000c8 <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000b9:	83 ec 0c             	sub    $0xc,%esp
f01000bc:	6a 00                	push   $0x0
f01000be:	e8 85 06 00 00       	call   f0100748 <monitor>
f01000c3:	83 c4 10             	add    $0x10,%esp
f01000c6:	eb f1                	jmp    f01000b9 <_panic+0x11>
	panicstr = fmt;
f01000c8:	89 35 40 29 11 f0    	mov    %esi,0xf0112940
	asm volatile("cli; cld");
f01000ce:	fa                   	cli    
f01000cf:	fc                   	cld    
	va_start(ap, fmt);
f01000d0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d3:	83 ec 04             	sub    $0x4,%esp
f01000d6:	ff 75 0c             	pushl  0xc(%ebp)
f01000d9:	ff 75 08             	pushl  0x8(%ebp)
f01000dc:	68 85 18 10 f0       	push   $0xf0101885
f01000e1:	e8 d8 07 00 00       	call   f01008be <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	53                   	push   %ebx
f01000ea:	56                   	push   %esi
f01000eb:	e8 a8 07 00 00       	call   f0100898 <vcprintf>
	cprintf("\n");
f01000f0:	c7 04 24 c1 18 10 f0 	movl   $0xf01018c1,(%esp)
f01000f7:	e8 c2 07 00 00       	call   f01008be <cprintf>
f01000fc:	83 c4 10             	add    $0x10,%esp
f01000ff:	eb b8                	jmp    f01000b9 <_panic+0x11>

f0100101 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100101:	55                   	push   %ebp
f0100102:	89 e5                	mov    %esp,%ebp
f0100104:	53                   	push   %ebx
f0100105:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100108:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010010b:	ff 75 0c             	pushl  0xc(%ebp)
f010010e:	ff 75 08             	pushl  0x8(%ebp)
f0100111:	68 9d 18 10 f0       	push   $0xf010189d
f0100116:	e8 a3 07 00 00       	call   f01008be <cprintf>
	vcprintf(fmt, ap);
f010011b:	83 c4 08             	add    $0x8,%esp
f010011e:	53                   	push   %ebx
f010011f:	ff 75 10             	pushl  0x10(%ebp)
f0100122:	e8 71 07 00 00       	call   f0100898 <vcprintf>
	cprintf("\n");
f0100127:	c7 04 24 c1 18 10 f0 	movl   $0xf01018c1,(%esp)
f010012e:	e8 8b 07 00 00       	call   f01008be <cprintf>
	va_end(ap);
}
f0100133:	83 c4 10             	add    $0x10,%esp
f0100136:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100139:	c9                   	leave  
f010013a:	c3                   	ret    

f010013b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010013e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100143:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100144:	a8 01                	test   $0x1,%al
f0100146:	74 0b                	je     f0100153 <serial_proc_data+0x18>
f0100148:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010014d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010014e:	0f b6 c0             	movzbl %al,%eax
}
f0100151:	5d                   	pop    %ebp
f0100152:	c3                   	ret    
		return -1;
f0100153:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100158:	eb f7                	jmp    f0100151 <serial_proc_data+0x16>

f010015a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015a:	55                   	push   %ebp
f010015b:	89 e5                	mov    %esp,%ebp
f010015d:	53                   	push   %ebx
f010015e:	83 ec 04             	sub    $0x4,%esp
f0100161:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100163:	ff d3                	call   *%ebx
f0100165:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100168:	74 2d                	je     f0100197 <cons_intr+0x3d>
		if (c == 0)
f010016a:	85 c0                	test   %eax,%eax
f010016c:	74 f5                	je     f0100163 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f010016e:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f0100174:	8d 51 01             	lea    0x1(%ecx),%edx
f0100177:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f010017d:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100183:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100189:	75 d8                	jne    f0100163 <cons_intr+0x9>
			cons.wpos = 0;
f010018b:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f0100192:	00 00 00 
f0100195:	eb cc                	jmp    f0100163 <cons_intr+0x9>
	}
}
f0100197:	83 c4 04             	add    $0x4,%esp
f010019a:	5b                   	pop    %ebx
f010019b:	5d                   	pop    %ebp
f010019c:	c3                   	ret    

f010019d <kbd_proc_data>:
{
f010019d:	55                   	push   %ebp
f010019e:	89 e5                	mov    %esp,%ebp
f01001a0:	53                   	push   %ebx
f01001a1:	83 ec 04             	sub    $0x4,%esp
f01001a4:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a9:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001aa:	a8 01                	test   $0x1,%al
f01001ac:	0f 84 fa 00 00 00    	je     f01002ac <kbd_proc_data+0x10f>
	if (stat & KBS_TERR)
f01001b2:	a8 20                	test   $0x20,%al
f01001b4:	0f 85 f9 00 00 00    	jne    f01002b3 <kbd_proc_data+0x116>
f01001ba:	ba 60 00 00 00       	mov    $0x60,%edx
f01001bf:	ec                   	in     (%dx),%al
f01001c0:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001c2:	3c e0                	cmp    $0xe0,%al
f01001c4:	0f 84 8e 00 00 00    	je     f0100258 <kbd_proc_data+0xbb>
	} else if (data & 0x80) {
f01001ca:	84 c0                	test   %al,%al
f01001cc:	0f 88 99 00 00 00    	js     f010026b <kbd_proc_data+0xce>
	} else if (shift & E0ESC) {
f01001d2:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f01001d8:	f6 c1 40             	test   $0x40,%cl
f01001db:	74 0e                	je     f01001eb <kbd_proc_data+0x4e>
		data |= 0x80;
f01001dd:	83 c8 80             	or     $0xffffff80,%eax
f01001e0:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001e2:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001e5:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	shift |= shiftcode[data];
f01001eb:	0f b6 d2             	movzbl %dl,%edx
f01001ee:	0f b6 82 00 1a 10 f0 	movzbl -0xfefe600(%edx),%eax
f01001f5:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f01001fb:	0f b6 8a 00 19 10 f0 	movzbl -0xfefe700(%edx),%ecx
f0100202:	31 c8                	xor    %ecx,%eax
f0100204:	a3 00 23 11 f0       	mov    %eax,0xf0112300
	c = charcode[shift & (CTL | SHIFT)][data];
f0100209:	89 c1                	mov    %eax,%ecx
f010020b:	83 e1 03             	and    $0x3,%ecx
f010020e:	8b 0c 8d e0 18 10 f0 	mov    -0xfefe720(,%ecx,4),%ecx
f0100215:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100219:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010021c:	a8 08                	test   $0x8,%al
f010021e:	74 0d                	je     f010022d <kbd_proc_data+0x90>
		if ('a' <= c && c <= 'z')
f0100220:	89 da                	mov    %ebx,%edx
f0100222:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100225:	83 f9 19             	cmp    $0x19,%ecx
f0100228:	77 74                	ja     f010029e <kbd_proc_data+0x101>
			c += 'A' - 'a';
f010022a:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010022d:	f7 d0                	not    %eax
f010022f:	a8 06                	test   $0x6,%al
f0100231:	75 31                	jne    f0100264 <kbd_proc_data+0xc7>
f0100233:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100239:	75 29                	jne    f0100264 <kbd_proc_data+0xc7>
		cprintf("Rebooting!\n");
f010023b:	83 ec 0c             	sub    $0xc,%esp
f010023e:	68 b7 18 10 f0       	push   $0xf01018b7
f0100243:	e8 76 06 00 00       	call   f01008be <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100248:	b8 03 00 00 00       	mov    $0x3,%eax
f010024d:	ba 92 00 00 00       	mov    $0x92,%edx
f0100252:	ee                   	out    %al,(%dx)
f0100253:	83 c4 10             	add    $0x10,%esp
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xc7>
		shift |= E0ESC;
f0100258:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010025f:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100264:	89 d8                	mov    %ebx,%eax
f0100266:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100269:	c9                   	leave  
f010026a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010026b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100271:	89 cb                	mov    %ecx,%ebx
f0100273:	83 e3 40             	and    $0x40,%ebx
f0100276:	83 e0 7f             	and    $0x7f,%eax
f0100279:	85 db                	test   %ebx,%ebx
f010027b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010027e:	0f b6 d2             	movzbl %dl,%edx
f0100281:	0f b6 82 00 1a 10 f0 	movzbl -0xfefe600(%edx),%eax
f0100288:	83 c8 40             	or     $0x40,%eax
f010028b:	0f b6 c0             	movzbl %al,%eax
f010028e:	f7 d0                	not    %eax
f0100290:	21 c8                	and    %ecx,%eax
f0100292:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100297:	bb 00 00 00 00       	mov    $0x0,%ebx
f010029c:	eb c6                	jmp    f0100264 <kbd_proc_data+0xc7>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 1a             	cmp    $0x1a,%edx
f01002a7:	0f 42 d9             	cmovb  %ecx,%ebx
f01002aa:	eb 81                	jmp    f010022d <kbd_proc_data+0x90>
		return -1;
f01002ac:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002b1:	eb b1                	jmp    f0100264 <kbd_proc_data+0xc7>
		return -1;
f01002b3:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01002b8:	eb aa                	jmp    f0100264 <kbd_proc_data+0xc7>

f01002ba <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ba:	55                   	push   %ebp
f01002bb:	89 e5                	mov    %esp,%ebp
f01002bd:	57                   	push   %edi
f01002be:	56                   	push   %esi
f01002bf:	53                   	push   %ebx
f01002c0:	83 ec 1c             	sub    $0x1c,%esp
f01002c3:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01002c5:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ca:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cf:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d4:	eb 09                	jmp    f01002df <cons_putc+0x25>
f01002d6:	89 ca                	mov    %ecx,%edx
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	ec                   	in     (%dx),%al
f01002da:	ec                   	in     (%dx),%al
f01002db:	ec                   	in     (%dx),%al
	     i++)
f01002dc:	83 c3 01             	add    $0x1,%ebx
f01002df:	89 f2                	mov    %esi,%edx
f01002e1:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e2:	a8 20                	test   $0x20,%al
f01002e4:	75 08                	jne    f01002ee <cons_putc+0x34>
f01002e6:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002ec:	7e e8                	jle    f01002d6 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01002ee:	89 f8                	mov    %edi,%eax
f01002f0:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f8:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002f9:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002fe:	be 79 03 00 00       	mov    $0x379,%esi
f0100303:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100308:	eb 09                	jmp    f0100313 <cons_putc+0x59>
f010030a:	89 ca                	mov    %ecx,%edx
f010030c:	ec                   	in     (%dx),%al
f010030d:	ec                   	in     (%dx),%al
f010030e:	ec                   	in     (%dx),%al
f010030f:	ec                   	in     (%dx),%al
f0100310:	83 c3 01             	add    $0x1,%ebx
f0100313:	89 f2                	mov    %esi,%edx
f0100315:	ec                   	in     (%dx),%al
f0100316:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010031c:	7f 04                	jg     f0100322 <cons_putc+0x68>
f010031e:	84 c0                	test   %al,%al
f0100320:	79 e8                	jns    f010030a <cons_putc+0x50>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100322:	ba 78 03 00 00       	mov    $0x378,%edx
f0100327:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010032b:	ee                   	out    %al,(%dx)
f010032c:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100331:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100336:	ee                   	out    %al,(%dx)
f0100337:	b8 08 00 00 00       	mov    $0x8,%eax
f010033c:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010033d:	89 fa                	mov    %edi,%edx
f010033f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100345:	89 f8                	mov    %edi,%eax
f0100347:	80 cc 07             	or     $0x7,%ah
f010034a:	85 d2                	test   %edx,%edx
f010034c:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f010034f:	89 f8                	mov    %edi,%eax
f0100351:	0f b6 c0             	movzbl %al,%eax
f0100354:	83 f8 09             	cmp    $0x9,%eax
f0100357:	0f 84 b6 00 00 00    	je     f0100413 <cons_putc+0x159>
f010035d:	83 f8 09             	cmp    $0x9,%eax
f0100360:	7e 73                	jle    f01003d5 <cons_putc+0x11b>
f0100362:	83 f8 0a             	cmp    $0xa,%eax
f0100365:	0f 84 9b 00 00 00    	je     f0100406 <cons_putc+0x14c>
f010036b:	83 f8 0d             	cmp    $0xd,%eax
f010036e:	0f 85 d6 00 00 00    	jne    f010044a <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f0100374:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010037b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100381:	c1 e8 16             	shr    $0x16,%eax
f0100384:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100387:	c1 e0 04             	shl    $0x4,%eax
f010038a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
	if (crt_pos >= CRT_SIZE) {
f0100390:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100397:	cf 07 
f0100399:	0f 87 ce 00 00 00    	ja     f010046d <cons_putc+0x1b3>
	outb(addr_6845, 14);
f010039f:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01003a5:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003aa:	89 ca                	mov    %ecx,%edx
f01003ac:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003ad:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01003b4:	8d 71 01             	lea    0x1(%ecx),%esi
f01003b7:	89 d8                	mov    %ebx,%eax
f01003b9:	66 c1 e8 08          	shr    $0x8,%ax
f01003bd:	89 f2                	mov    %esi,%edx
f01003bf:	ee                   	out    %al,(%dx)
f01003c0:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003c5:	89 ca                	mov    %ecx,%edx
f01003c7:	ee                   	out    %al,(%dx)
f01003c8:	89 d8                	mov    %ebx,%eax
f01003ca:	89 f2                	mov    %esi,%edx
f01003cc:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003d0:	5b                   	pop    %ebx
f01003d1:	5e                   	pop    %esi
f01003d2:	5f                   	pop    %edi
f01003d3:	5d                   	pop    %ebp
f01003d4:	c3                   	ret    
	switch (c & 0xff) {
f01003d5:	83 f8 08             	cmp    $0x8,%eax
f01003d8:	75 70                	jne    f010044a <cons_putc+0x190>
		if (crt_pos > 0) {
f01003da:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e1:	66 85 c0             	test   %ax,%ax
f01003e4:	74 b9                	je     f010039f <cons_putc+0xe5>
			crt_pos--;
f01003e6:	83 e8 01             	sub    $0x1,%eax
f01003e9:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	66 81 e7 00 ff       	and    $0xff00,%di
f01003f7:	83 cf 20             	or     $0x20,%edi
f01003fa:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100400:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100404:	eb 8a                	jmp    f0100390 <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f0100406:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f010040d:	50 
f010040e:	e9 61 ff ff ff       	jmp    f0100374 <cons_putc+0xba>
		cons_putc(' ');
f0100413:	b8 20 00 00 00       	mov    $0x20,%eax
f0100418:	e8 9d fe ff ff       	call   f01002ba <cons_putc>
		cons_putc(' ');
f010041d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100422:	e8 93 fe ff ff       	call   f01002ba <cons_putc>
		cons_putc(' ');
f0100427:	b8 20 00 00 00       	mov    $0x20,%eax
f010042c:	e8 89 fe ff ff       	call   f01002ba <cons_putc>
		cons_putc(' ');
f0100431:	b8 20 00 00 00       	mov    $0x20,%eax
f0100436:	e8 7f fe ff ff       	call   f01002ba <cons_putc>
		cons_putc(' ');
f010043b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100440:	e8 75 fe ff ff       	call   f01002ba <cons_putc>
f0100445:	e9 46 ff ff ff       	jmp    f0100390 <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f010044a:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100451:	8d 50 01             	lea    0x1(%eax),%edx
f0100454:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010045b:	0f b7 c0             	movzwl %ax,%eax
f010045e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100464:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100468:	e9 23 ff ff ff       	jmp    f0100390 <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046d:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100472:	83 ec 04             	sub    $0x4,%esp
f0100475:	68 00 0f 00 00       	push   $0xf00
f010047a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100480:	52                   	push   %edx
f0100481:	50                   	push   %eax
f0100482:	e8 e2 0f 00 00       	call   f0101469 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100487:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f010048d:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100493:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100499:	83 c4 10             	add    $0x10,%esp
f010049c:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004a1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	39 d0                	cmp    %edx,%eax
f01004a6:	75 f4                	jne    f010049c <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f01004a8:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004af:	50 
f01004b0:	e9 ea fe ff ff       	jmp    f010039f <cons_putc+0xe5>

f01004b5 <serial_intr>:
	if (serial_exists)
f01004b5:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004bc:	75 02                	jne    f01004c0 <serial_intr+0xb>
f01004be:	f3 c3                	repz ret 
{
f01004c0:	55                   	push   %ebp
f01004c1:	89 e5                	mov    %esp,%ebp
f01004c3:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004c6:	b8 3b 01 10 f0       	mov    $0xf010013b,%eax
f01004cb:	e8 8a fc ff ff       	call   f010015a <cons_intr>
}
f01004d0:	c9                   	leave  
f01004d1:	c3                   	ret    

f01004d2 <kbd_intr>:
{
f01004d2:	55                   	push   %ebp
f01004d3:	89 e5                	mov    %esp,%ebp
f01004d5:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d8:	b8 9d 01 10 f0       	mov    $0xf010019d,%eax
f01004dd:	e8 78 fc ff ff       	call   f010015a <cons_intr>
}
f01004e2:	c9                   	leave  
f01004e3:	c3                   	ret    

f01004e4 <cons_getc>:
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004ea:	e8 c6 ff ff ff       	call   f01004b5 <serial_intr>
	kbd_intr();
f01004ef:	e8 de ff ff ff       	call   f01004d2 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004f4:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
	return 0;
f01004fa:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01004ff:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100505:	74 18                	je     f010051f <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f0100507:	8d 4a 01             	lea    0x1(%edx),%ecx
f010050a:	89 0d 20 25 11 f0    	mov    %ecx,0xf0112520
f0100510:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f0100517:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f010051d:	74 02                	je     f0100521 <cons_getc+0x3d>
}
f010051f:	c9                   	leave  
f0100520:	c3                   	ret    
			cons.rpos = 0;
f0100521:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100528:	00 00 00 
f010052b:	eb f2                	jmp    f010051f <cons_getc+0x3b>

f010052d <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	57                   	push   %edi
f0100531:	56                   	push   %esi
f0100532:	53                   	push   %ebx
f0100533:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f0100536:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010053d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100544:	5a a5 
	if (*cp != 0xA55A) {
f0100546:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010054d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100551:	0f 84 b7 00 00 00    	je     f010060e <cons_init+0xe1>
		addr_6845 = MONO_BASE;
f0100557:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010055e:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100561:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f0100566:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f010056c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100571:	89 fa                	mov    %edi,%edx
f0100573:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100574:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100577:	89 ca                	mov    %ecx,%edx
f0100579:	ec                   	in     (%dx),%al
f010057a:	0f b6 c0             	movzbl %al,%eax
f010057d:	c1 e0 08             	shl    $0x8,%eax
f0100580:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100587:	89 fa                	mov    %edi,%edx
f0100589:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058a:	89 ca                	mov    %ecx,%edx
f010058c:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010058d:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	pos |= inb(addr_6845 + 1);
f0100593:	0f b6 c0             	movzbl %al,%eax
f0100596:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f0100598:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010059e:	bb 00 00 00 00       	mov    $0x0,%ebx
f01005a3:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f01005a8:	89 d8                	mov    %ebx,%eax
f01005aa:	89 ca                	mov    %ecx,%edx
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01005b2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b7:	89 fa                	mov    %edi,%edx
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005bf:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	be f9 03 00 00       	mov    $0x3f9,%esi
f01005ca:	89 d8                	mov    %ebx,%eax
f01005cc:	89 f2                	mov    %esi,%edx
f01005ce:	ee                   	out    %al,(%dx)
f01005cf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005d4:	89 fa                	mov    %edi,%edx
f01005d6:	ee                   	out    %al,(%dx)
f01005d7:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005dc:	89 d8                	mov    %ebx,%eax
f01005de:	ee                   	out    %al,(%dx)
f01005df:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e7:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005ec:	ec                   	in     (%dx),%al
f01005ed:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005ef:	3c ff                	cmp    $0xff,%al
f01005f1:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f01005f8:	89 ca                	mov    %ecx,%edx
f01005fa:	ec                   	in     (%dx),%al
f01005fb:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100600:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100601:	80 fb ff             	cmp    $0xff,%bl
f0100604:	74 23                	je     f0100629 <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
}
f0100606:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100609:	5b                   	pop    %ebx
f010060a:	5e                   	pop    %esi
f010060b:	5f                   	pop    %edi
f010060c:	5d                   	pop    %ebp
f010060d:	c3                   	ret    
		*cp = was;
f010060e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100615:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010061c:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010061f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100624:	e9 3d ff ff ff       	jmp    f0100566 <cons_init+0x39>
		cprintf("Serial port does not exist!\n");
f0100629:	83 ec 0c             	sub    $0xc,%esp
f010062c:	68 c3 18 10 f0       	push   $0xf01018c3
f0100631:	e8 88 02 00 00       	call   f01008be <cprintf>
f0100636:	83 c4 10             	add    $0x10,%esp
}
f0100639:	eb cb                	jmp    f0100606 <cons_init+0xd9>

f010063b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010063b:	55                   	push   %ebp
f010063c:	89 e5                	mov    %esp,%ebp
f010063e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100641:	8b 45 08             	mov    0x8(%ebp),%eax
f0100644:	e8 71 fc ff ff       	call   f01002ba <cons_putc>
}
f0100649:	c9                   	leave  
f010064a:	c3                   	ret    

f010064b <getchar>:

int
getchar(void)
{
f010064b:	55                   	push   %ebp
f010064c:	89 e5                	mov    %esp,%ebp
f010064e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100651:	e8 8e fe ff ff       	call   f01004e4 <cons_getc>
f0100656:	85 c0                	test   %eax,%eax
f0100658:	74 f7                	je     f0100651 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010065a:	c9                   	leave  
f010065b:	c3                   	ret    

f010065c <iscons>:

int
iscons(int fdnum)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100664:	5d                   	pop    %ebp
f0100665:	c3                   	ret    

f0100666 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100666:	55                   	push   %ebp
f0100667:	89 e5                	mov    %esp,%ebp
f0100669:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010066c:	68 00 1b 10 f0       	push   $0xf0101b00
f0100671:	68 1e 1b 10 f0       	push   $0xf0101b1e
f0100676:	68 23 1b 10 f0       	push   $0xf0101b23
f010067b:	e8 3e 02 00 00       	call   f01008be <cprintf>
f0100680:	83 c4 0c             	add    $0xc,%esp
f0100683:	68 8c 1b 10 f0       	push   $0xf0101b8c
f0100688:	68 2c 1b 10 f0       	push   $0xf0101b2c
f010068d:	68 23 1b 10 f0       	push   $0xf0101b23
f0100692:	e8 27 02 00 00       	call   f01008be <cprintf>
	return 0;
}
f0100697:	b8 00 00 00 00       	mov    $0x0,%eax
f010069c:	c9                   	leave  
f010069d:	c3                   	ret    

f010069e <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010069e:	55                   	push   %ebp
f010069f:	89 e5                	mov    %esp,%ebp
f01006a1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a4:	68 35 1b 10 f0       	push   $0xf0101b35
f01006a9:	e8 10 02 00 00       	call   f01008be <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006ae:	83 c4 08             	add    $0x8,%esp
f01006b1:	68 0c 00 10 00       	push   $0x10000c
f01006b6:	68 b4 1b 10 f0       	push   $0xf0101bb4
f01006bb:	e8 fe 01 00 00       	call   f01008be <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c0:	83 c4 0c             	add    $0xc,%esp
f01006c3:	68 0c 00 10 00       	push   $0x10000c
f01006c8:	68 0c 00 10 f0       	push   $0xf010000c
f01006cd:	68 dc 1b 10 f0       	push   $0xf0101bdc
f01006d2:	e8 e7 01 00 00       	call   f01008be <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d7:	83 c4 0c             	add    $0xc,%esp
f01006da:	68 59 18 10 00       	push   $0x101859
f01006df:	68 59 18 10 f0       	push   $0xf0101859
f01006e4:	68 00 1c 10 f0       	push   $0xf0101c00
f01006e9:	e8 d0 01 00 00       	call   f01008be <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	83 c4 0c             	add    $0xc,%esp
f01006f1:	68 00 23 11 00       	push   $0x112300
f01006f6:	68 00 23 11 f0       	push   $0xf0112300
f01006fb:	68 24 1c 10 f0       	push   $0xf0101c24
f0100700:	e8 b9 01 00 00       	call   f01008be <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100705:	83 c4 0c             	add    $0xc,%esp
f0100708:	68 44 29 11 00       	push   $0x112944
f010070d:	68 44 29 11 f0       	push   $0xf0112944
f0100712:	68 48 1c 10 f0       	push   $0xf0101c48
f0100717:	e8 a2 01 00 00       	call   f01008be <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010071c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010071f:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100724:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100729:	c1 f8 0a             	sar    $0xa,%eax
f010072c:	50                   	push   %eax
f010072d:	68 6c 1c 10 f0       	push   $0xf0101c6c
f0100732:	e8 87 01 00 00       	call   f01008be <cprintf>
	return 0;
}
f0100737:	b8 00 00 00 00       	mov    $0x0,%eax
f010073c:	c9                   	leave  
f010073d:	c3                   	ret    

f010073e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010073e:	55                   	push   %ebp
f010073f:	89 e5                	mov    %esp,%ebp
		cprintf("+%d\n", old_eip - info.eip_fn_addr);

		ebp = old_ebp;
	}*/
	return 0;
}
f0100741:	b8 00 00 00 00       	mov    $0x0,%eax
f0100746:	5d                   	pop    %ebp
f0100747:	c3                   	ret    

f0100748 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100748:	55                   	push   %ebp
f0100749:	89 e5                	mov    %esp,%ebp
f010074b:	57                   	push   %edi
f010074c:	56                   	push   %esi
f010074d:	53                   	push   %ebx
f010074e:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100751:	68 98 1c 10 f0       	push   $0xf0101c98
f0100756:	e8 63 01 00 00       	call   f01008be <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010075b:	c7 04 24 bc 1c 10 f0 	movl   $0xf0101cbc,(%esp)
f0100762:	e8 57 01 00 00       	call   f01008be <cprintf>
f0100767:	83 c4 10             	add    $0x10,%esp
f010076a:	eb 47                	jmp    f01007b3 <monitor+0x6b>
		while (*buf && strchr(WHITESPACE, *buf))
f010076c:	83 ec 08             	sub    $0x8,%esp
f010076f:	0f be c0             	movsbl %al,%eax
f0100772:	50                   	push   %eax
f0100773:	68 52 1b 10 f0       	push   $0xf0101b52
f0100778:	e8 62 0c 00 00       	call   f01013df <strchr>
f010077d:	83 c4 10             	add    $0x10,%esp
f0100780:	85 c0                	test   %eax,%eax
f0100782:	74 0a                	je     f010078e <monitor+0x46>
			*buf++ = 0;
f0100784:	c6 03 00             	movb   $0x0,(%ebx)
f0100787:	89 f7                	mov    %esi,%edi
f0100789:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010078c:	eb 6b                	jmp    f01007f9 <monitor+0xb1>
		if (*buf == 0)
f010078e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100791:	74 73                	je     f0100806 <monitor+0xbe>
		if (argc == MAXARGS-1) {
f0100793:	83 fe 0f             	cmp    $0xf,%esi
f0100796:	74 09                	je     f01007a1 <monitor+0x59>
		argv[argc++] = buf;
f0100798:	8d 7e 01             	lea    0x1(%esi),%edi
f010079b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010079f:	eb 39                	jmp    f01007da <monitor+0x92>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007a1:	83 ec 08             	sub    $0x8,%esp
f01007a4:	6a 10                	push   $0x10
f01007a6:	68 57 1b 10 f0       	push   $0xf0101b57
f01007ab:	e8 0e 01 00 00       	call   f01008be <cprintf>
f01007b0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007b3:	83 ec 0c             	sub    $0xc,%esp
f01007b6:	68 4e 1b 10 f0       	push   $0xf0101b4e
f01007bb:	e8 02 0a 00 00       	call   f01011c2 <readline>
f01007c0:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c2:	83 c4 10             	add    $0x10,%esp
f01007c5:	85 c0                	test   %eax,%eax
f01007c7:	74 ea                	je     f01007b3 <monitor+0x6b>
	argv[argc] = 0;
f01007c9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01007d0:	be 00 00 00 00       	mov    $0x0,%esi
f01007d5:	eb 24                	jmp    f01007fb <monitor+0xb3>
			buf++;
f01007d7:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01007da:	0f b6 03             	movzbl (%ebx),%eax
f01007dd:	84 c0                	test   %al,%al
f01007df:	74 18                	je     f01007f9 <monitor+0xb1>
f01007e1:	83 ec 08             	sub    $0x8,%esp
f01007e4:	0f be c0             	movsbl %al,%eax
f01007e7:	50                   	push   %eax
f01007e8:	68 52 1b 10 f0       	push   $0xf0101b52
f01007ed:	e8 ed 0b 00 00       	call   f01013df <strchr>
f01007f2:	83 c4 10             	add    $0x10,%esp
f01007f5:	85 c0                	test   %eax,%eax
f01007f7:	74 de                	je     f01007d7 <monitor+0x8f>
			*buf++ = 0;
f01007f9:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f01007fb:	0f b6 03             	movzbl (%ebx),%eax
f01007fe:	84 c0                	test   %al,%al
f0100800:	0f 85 66 ff ff ff    	jne    f010076c <monitor+0x24>
	argv[argc] = 0;
f0100806:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010080d:	00 
	if (argc == 0)
f010080e:	85 f6                	test   %esi,%esi
f0100810:	74 a1                	je     f01007b3 <monitor+0x6b>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100812:	83 ec 08             	sub    $0x8,%esp
f0100815:	68 1e 1b 10 f0       	push   $0xf0101b1e
f010081a:	ff 75 a8             	pushl  -0x58(%ebp)
f010081d:	e8 5f 0b 00 00       	call   f0101381 <strcmp>
f0100822:	83 c4 10             	add    $0x10,%esp
f0100825:	85 c0                	test   %eax,%eax
f0100827:	74 34                	je     f010085d <monitor+0x115>
f0100829:	83 ec 08             	sub    $0x8,%esp
f010082c:	68 2c 1b 10 f0       	push   $0xf0101b2c
f0100831:	ff 75 a8             	pushl  -0x58(%ebp)
f0100834:	e8 48 0b 00 00       	call   f0101381 <strcmp>
f0100839:	83 c4 10             	add    $0x10,%esp
f010083c:	85 c0                	test   %eax,%eax
f010083e:	74 18                	je     f0100858 <monitor+0x110>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100840:	83 ec 08             	sub    $0x8,%esp
f0100843:	ff 75 a8             	pushl  -0x58(%ebp)
f0100846:	68 74 1b 10 f0       	push   $0xf0101b74
f010084b:	e8 6e 00 00 00       	call   f01008be <cprintf>
f0100850:	83 c4 10             	add    $0x10,%esp
f0100853:	e9 5b ff ff ff       	jmp    f01007b3 <monitor+0x6b>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100858:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f010085d:	83 ec 04             	sub    $0x4,%esp
f0100860:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100863:	ff 75 08             	pushl  0x8(%ebp)
f0100866:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100869:	52                   	push   %edx
f010086a:	56                   	push   %esi
f010086b:	ff 14 85 ec 1c 10 f0 	call   *-0xfefe314(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100872:	83 c4 10             	add    $0x10,%esp
f0100875:	85 c0                	test   %eax,%eax
f0100877:	0f 89 36 ff ff ff    	jns    f01007b3 <monitor+0x6b>
				break;
	}
}
f010087d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100880:	5b                   	pop    %ebx
f0100881:	5e                   	pop    %esi
f0100882:	5f                   	pop    %edi
f0100883:	5d                   	pop    %ebp
f0100884:	c3                   	ret    

f0100885 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100885:	55                   	push   %ebp
f0100886:	89 e5                	mov    %esp,%ebp
f0100888:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010088b:	ff 75 08             	pushl  0x8(%ebp)
f010088e:	e8 a8 fd ff ff       	call   f010063b <cputchar>
	*cnt++;
}
f0100893:	83 c4 10             	add    $0x10,%esp
f0100896:	c9                   	leave  
f0100897:	c3                   	ret    

f0100898 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100898:	55                   	push   %ebp
f0100899:	89 e5                	mov    %esp,%ebp
f010089b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010089e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008a5:	ff 75 0c             	pushl  0xc(%ebp)
f01008a8:	ff 75 08             	pushl  0x8(%ebp)
f01008ab:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008ae:	50                   	push   %eax
f01008af:	68 85 08 10 f0       	push   $0xf0100885
f01008b4:	e8 1e 04 00 00       	call   f0100cd7 <vprintfmt>
	return cnt;
}
f01008b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008bc:	c9                   	leave  
f01008bd:	c3                   	ret    

f01008be <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008be:	55                   	push   %ebp
f01008bf:	89 e5                	mov    %esp,%ebp
f01008c1:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008c4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008c7:	50                   	push   %eax
f01008c8:	ff 75 08             	pushl  0x8(%ebp)
f01008cb:	e8 c8 ff ff ff       	call   f0100898 <vcprintf>
	va_end(ap);

	return cnt;
}
f01008d0:	c9                   	leave  
f01008d1:	c3                   	ret    

f01008d2 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008d2:	55                   	push   %ebp
f01008d3:	89 e5                	mov    %esp,%ebp
f01008d5:	57                   	push   %edi
f01008d6:	56                   	push   %esi
f01008d7:	53                   	push   %ebx
f01008d8:	83 ec 14             	sub    $0x14,%esp
f01008db:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01008de:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01008e1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01008e4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01008e7:	8b 32                	mov    (%edx),%esi
f01008e9:	8b 01                	mov    (%ecx),%eax
f01008eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01008ee:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01008f5:	eb 2f                	jmp    f0100926 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01008f7:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01008fa:	39 c6                	cmp    %eax,%esi
f01008fc:	7f 49                	jg     f0100947 <stab_binsearch+0x75>
f01008fe:	0f b6 0a             	movzbl (%edx),%ecx
f0100901:	83 ea 0c             	sub    $0xc,%edx
f0100904:	39 f9                	cmp    %edi,%ecx
f0100906:	75 ef                	jne    f01008f7 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100908:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010090b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010090e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100912:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100915:	73 35                	jae    f010094c <stab_binsearch+0x7a>
			*region_left = m;
f0100917:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010091a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010091c:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010091f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100926:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100929:	7f 4e                	jg     f0100979 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f010092b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010092e:	01 f0                	add    %esi,%eax
f0100930:	89 c3                	mov    %eax,%ebx
f0100932:	c1 eb 1f             	shr    $0x1f,%ebx
f0100935:	01 c3                	add    %eax,%ebx
f0100937:	d1 fb                	sar    %ebx
f0100939:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010093c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010093f:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100943:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100945:	eb b3                	jmp    f01008fa <stab_binsearch+0x28>
			l = true_m + 1;
f0100947:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f010094a:	eb da                	jmp    f0100926 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f010094c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010094f:	76 14                	jbe    f0100965 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100951:	83 e8 01             	sub    $0x1,%eax
f0100954:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100957:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010095a:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f010095c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100963:	eb c1                	jmp    f0100926 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100965:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100968:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010096a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010096e:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100970:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100977:	eb ad                	jmp    f0100926 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100979:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010097d:	74 16                	je     f0100995 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010097f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100982:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100984:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100987:	8b 0e                	mov    (%esi),%ecx
f0100989:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010098c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010098f:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100993:	eb 12                	jmp    f01009a7 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100995:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100998:	8b 00                	mov    (%eax),%eax
f010099a:	83 e8 01             	sub    $0x1,%eax
f010099d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01009a0:	89 07                	mov    %eax,(%edi)
f01009a2:	eb 16                	jmp    f01009ba <stab_binsearch+0xe8>
		     l--)
f01009a4:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01009a7:	39 c1                	cmp    %eax,%ecx
f01009a9:	7d 0a                	jge    f01009b5 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01009ab:	0f b6 1a             	movzbl (%edx),%ebx
f01009ae:	83 ea 0c             	sub    $0xc,%edx
f01009b1:	39 fb                	cmp    %edi,%ebx
f01009b3:	75 ef                	jne    f01009a4 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01009b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009b8:	89 07                	mov    %eax,(%edi)
	}
}
f01009ba:	83 c4 14             	add    $0x14,%esp
f01009bd:	5b                   	pop    %ebx
f01009be:	5e                   	pop    %esi
f01009bf:	5f                   	pop    %edi
f01009c0:	5d                   	pop    %ebp
f01009c1:	c3                   	ret    

f01009c2 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009c2:	55                   	push   %ebp
f01009c3:	89 e5                	mov    %esp,%ebp
f01009c5:	57                   	push   %edi
f01009c6:	56                   	push   %esi
f01009c7:	53                   	push   %ebx
f01009c8:	83 ec 3c             	sub    $0x3c,%esp
f01009cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01009ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01009d1:	c7 03 fc 1c 10 f0    	movl   $0xf0101cfc,(%ebx)
	info->eip_line = 0;
f01009d7:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01009de:	c7 43 08 fc 1c 10 f0 	movl   $0xf0101cfc,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01009e5:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01009ec:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01009ef:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01009f6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01009fc:	0f 86 22 01 00 00    	jbe    f0100b24 <debuginfo_eip+0x162>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a02:	b8 60 75 10 f0       	mov    $0xf0107560,%eax
f0100a07:	3d c5 5b 10 f0       	cmp    $0xf0105bc5,%eax
f0100a0c:	0f 86 ba 01 00 00    	jbe    f0100bcc <debuginfo_eip+0x20a>
f0100a12:	80 3d 5f 75 10 f0 00 	cmpb   $0x0,0xf010755f
f0100a19:	0f 85 b4 01 00 00    	jne    f0100bd3 <debuginfo_eip+0x211>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a1f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a26:	b8 c4 5b 10 f0       	mov    $0xf0105bc4,%eax
f0100a2b:	2d 34 1f 10 f0       	sub    $0xf0101f34,%eax
f0100a30:	c1 f8 02             	sar    $0x2,%eax
f0100a33:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a39:	83 e8 01             	sub    $0x1,%eax
f0100a3c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a3f:	83 ec 08             	sub    $0x8,%esp
f0100a42:	56                   	push   %esi
f0100a43:	6a 64                	push   $0x64
f0100a45:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a48:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a4b:	b8 34 1f 10 f0       	mov    $0xf0101f34,%eax
f0100a50:	e8 7d fe ff ff       	call   f01008d2 <stab_binsearch>
	if (lfile == 0)
f0100a55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a58:	83 c4 10             	add    $0x10,%esp
f0100a5b:	85 c0                	test   %eax,%eax
f0100a5d:	0f 84 77 01 00 00    	je     f0100bda <debuginfo_eip+0x218>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a63:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100a66:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a69:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100a6c:	83 ec 08             	sub    $0x8,%esp
f0100a6f:	56                   	push   %esi
f0100a70:	6a 24                	push   $0x24
f0100a72:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100a75:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a78:	b8 34 1f 10 f0       	mov    $0xf0101f34,%eax
f0100a7d:	e8 50 fe ff ff       	call   f01008d2 <stab_binsearch>

	if (lfun <= rfun) {
f0100a82:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100a85:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100a88:	83 c4 10             	add    $0x10,%esp
f0100a8b:	39 d0                	cmp    %edx,%eax
f0100a8d:	0f 8f a5 00 00 00    	jg     f0100b38 <debuginfo_eip+0x176>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100a93:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100a96:	c1 e1 02             	shl    $0x2,%ecx
f0100a99:	8d b9 34 1f 10 f0    	lea    -0xfefe0cc(%ecx),%edi
f0100a9f:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100aa2:	8b b9 34 1f 10 f0    	mov    -0xfefe0cc(%ecx),%edi
f0100aa8:	b9 60 75 10 f0       	mov    $0xf0107560,%ecx
f0100aad:	81 e9 c5 5b 10 f0    	sub    $0xf0105bc5,%ecx
f0100ab3:	39 cf                	cmp    %ecx,%edi
f0100ab5:	73 09                	jae    f0100ac0 <debuginfo_eip+0xfe>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ab7:	81 c7 c5 5b 10 f0    	add    $0xf0105bc5,%edi
f0100abd:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ac0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ac3:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100ac6:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ac9:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100acb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ace:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ad1:	83 ec 08             	sub    $0x8,%esp
f0100ad4:	6a 3a                	push   $0x3a
f0100ad6:	ff 73 08             	pushl  0x8(%ebx)
f0100ad9:	e8 22 09 00 00       	call   f0101400 <strfind>
f0100ade:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ae1:	89 43 0c             	mov    %eax,0xc(%ebx)


	// Search within [lline, rline] for the line number stab.
	// If found, set info->eip_line to the right line number.
	// If not found, return -1.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ae4:	83 c4 08             	add    $0x8,%esp
f0100ae7:	56                   	push   %esi
f0100ae8:	6a 44                	push   $0x44
f0100aea:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100aed:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100af0:	b8 34 1f 10 f0       	mov    $0xf0101f34,%eax
f0100af5:	e8 d8 fd ff ff       	call   f01008d2 <stab_binsearch>
	if (lline <= rline) {
f0100afa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100afd:	83 c4 10             	add    $0x10,%esp
f0100b00:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100b03:	7f 44                	jg     f0100b49 <debuginfo_eip+0x187>
	  info->eip_line = stabs[lline].n_desc;
f0100b05:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b08:	0f b7 14 95 3a 1f 10 	movzwl -0xfefe0c6(,%edx,4),%edx
f0100b0f:	f0 
f0100b10:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b16:	89 c2                	mov    %eax,%edx
f0100b18:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100b1b:	8d 04 85 38 1f 10 f0 	lea    -0xfefe0c8(,%eax,4),%eax
f0100b22:	eb 34                	jmp    f0100b58 <debuginfo_eip+0x196>
  	        panic("User address");
f0100b24:	83 ec 04             	sub    $0x4,%esp
f0100b27:	68 06 1d 10 f0       	push   $0xf0101d06
f0100b2c:	6a 7f                	push   $0x7f
f0100b2e:	68 13 1d 10 f0       	push   $0xf0101d13
f0100b33:	e8 70 f5 ff ff       	call   f01000a8 <_panic>
		info->eip_fn_addr = addr;
f0100b38:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b3e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100b41:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b44:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100b47:	eb 88                	jmp    f0100ad1 <debuginfo_eip+0x10f>
	  info->eip_line = -1;
f0100b49:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
f0100b50:	eb c1                	jmp    f0100b13 <debuginfo_eip+0x151>
f0100b52:	83 ea 01             	sub    $0x1,%edx
f0100b55:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100b58:	39 d7                	cmp    %edx,%edi
f0100b5a:	7f 33                	jg     f0100b8f <debuginfo_eip+0x1cd>
	       && stabs[lline].n_type != N_SOL
f0100b5c:	0f b6 08             	movzbl (%eax),%ecx
f0100b5f:	80 f9 84             	cmp    $0x84,%cl
f0100b62:	74 0b                	je     f0100b6f <debuginfo_eip+0x1ad>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b64:	80 f9 64             	cmp    $0x64,%cl
f0100b67:	75 e9                	jne    f0100b52 <debuginfo_eip+0x190>
f0100b69:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100b6d:	74 e3                	je     f0100b52 <debuginfo_eip+0x190>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b6f:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100b72:	8b 14 85 34 1f 10 f0 	mov    -0xfefe0cc(,%eax,4),%edx
f0100b79:	b8 60 75 10 f0       	mov    $0xf0107560,%eax
f0100b7e:	2d c5 5b 10 f0       	sub    $0xf0105bc5,%eax
f0100b83:	39 c2                	cmp    %eax,%edx
f0100b85:	73 08                	jae    f0100b8f <debuginfo_eip+0x1cd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b87:	81 c2 c5 5b 10 f0    	add    $0xf0105bc5,%edx
f0100b8d:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b8f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b92:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b95:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100b9a:	39 f2                	cmp    %esi,%edx
f0100b9c:	7d 48                	jge    f0100be6 <debuginfo_eip+0x224>
		for (lline = lfun + 1;
f0100b9e:	83 c2 01             	add    $0x1,%edx
f0100ba1:	89 d0                	mov    %edx,%eax
f0100ba3:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100ba6:	8d 14 95 38 1f 10 f0 	lea    -0xfefe0c8(,%edx,4),%edx
f0100bad:	eb 04                	jmp    f0100bb3 <debuginfo_eip+0x1f1>
			info->eip_fn_narg++;
f0100baf:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0100bb3:	39 c6                	cmp    %eax,%esi
f0100bb5:	7e 2a                	jle    f0100be1 <debuginfo_eip+0x21f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bb7:	0f b6 0a             	movzbl (%edx),%ecx
f0100bba:	83 c0 01             	add    $0x1,%eax
f0100bbd:	83 c2 0c             	add    $0xc,%edx
f0100bc0:	80 f9 a0             	cmp    $0xa0,%cl
f0100bc3:	74 ea                	je     f0100baf <debuginfo_eip+0x1ed>
	return 0;
f0100bc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bca:	eb 1a                	jmp    f0100be6 <debuginfo_eip+0x224>
		return -1;
f0100bcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bd1:	eb 13                	jmp    f0100be6 <debuginfo_eip+0x224>
f0100bd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bd8:	eb 0c                	jmp    f0100be6 <debuginfo_eip+0x224>
		return -1;
f0100bda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bdf:	eb 05                	jmp    f0100be6 <debuginfo_eip+0x224>
	return 0;
f0100be1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100be6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100be9:	5b                   	pop    %ebx
f0100bea:	5e                   	pop    %esi
f0100beb:	5f                   	pop    %edi
f0100bec:	5d                   	pop    %ebp
f0100bed:	c3                   	ret    

f0100bee <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bee:	55                   	push   %ebp
f0100bef:	89 e5                	mov    %esp,%ebp
f0100bf1:	57                   	push   %edi
f0100bf2:	56                   	push   %esi
f0100bf3:	53                   	push   %ebx
f0100bf4:	83 ec 1c             	sub    $0x1c,%esp
f0100bf7:	89 c7                	mov    %eax,%edi
f0100bf9:	89 d6                	mov    %edx,%esi
f0100bfb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bfe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c01:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c04:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c07:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c0a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c0f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c12:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c15:	39 d3                	cmp    %edx,%ebx
f0100c17:	72 05                	jb     f0100c1e <printnum+0x30>
f0100c19:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c1c:	77 7a                	ja     f0100c98 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c1e:	83 ec 0c             	sub    $0xc,%esp
f0100c21:	ff 75 18             	pushl  0x18(%ebp)
f0100c24:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c27:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c2a:	53                   	push   %ebx
f0100c2b:	ff 75 10             	pushl  0x10(%ebp)
f0100c2e:	83 ec 08             	sub    $0x8,%esp
f0100c31:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c34:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c37:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c3a:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c3d:	e8 de 09 00 00       	call   f0101620 <__udivdi3>
f0100c42:	83 c4 18             	add    $0x18,%esp
f0100c45:	52                   	push   %edx
f0100c46:	50                   	push   %eax
f0100c47:	89 f2                	mov    %esi,%edx
f0100c49:	89 f8                	mov    %edi,%eax
f0100c4b:	e8 9e ff ff ff       	call   f0100bee <printnum>
f0100c50:	83 c4 20             	add    $0x20,%esp
f0100c53:	eb 13                	jmp    f0100c68 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c55:	83 ec 08             	sub    $0x8,%esp
f0100c58:	56                   	push   %esi
f0100c59:	ff 75 18             	pushl  0x18(%ebp)
f0100c5c:	ff d7                	call   *%edi
f0100c5e:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100c61:	83 eb 01             	sub    $0x1,%ebx
f0100c64:	85 db                	test   %ebx,%ebx
f0100c66:	7f ed                	jg     f0100c55 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c68:	83 ec 08             	sub    $0x8,%esp
f0100c6b:	56                   	push   %esi
f0100c6c:	83 ec 04             	sub    $0x4,%esp
f0100c6f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c72:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c75:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c78:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c7b:	e8 c0 0a 00 00       	call   f0101740 <__umoddi3>
f0100c80:	83 c4 14             	add    $0x14,%esp
f0100c83:	0f be 80 21 1d 10 f0 	movsbl -0xfefe2df(%eax),%eax
f0100c8a:	50                   	push   %eax
f0100c8b:	ff d7                	call   *%edi
}
f0100c8d:	83 c4 10             	add    $0x10,%esp
f0100c90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c93:	5b                   	pop    %ebx
f0100c94:	5e                   	pop    %esi
f0100c95:	5f                   	pop    %edi
f0100c96:	5d                   	pop    %ebp
f0100c97:	c3                   	ret    
f0100c98:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100c9b:	eb c4                	jmp    f0100c61 <printnum+0x73>

f0100c9d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100c9d:	55                   	push   %ebp
f0100c9e:	89 e5                	mov    %esp,%ebp
f0100ca0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ca3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ca7:	8b 10                	mov    (%eax),%edx
f0100ca9:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cac:	73 0a                	jae    f0100cb8 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100cae:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100cb1:	89 08                	mov    %ecx,(%eax)
f0100cb3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cb6:	88 02                	mov    %al,(%edx)
}
f0100cb8:	5d                   	pop    %ebp
f0100cb9:	c3                   	ret    

f0100cba <printfmt>:
{
f0100cba:	55                   	push   %ebp
f0100cbb:	89 e5                	mov    %esp,%ebp
f0100cbd:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100cc0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100cc3:	50                   	push   %eax
f0100cc4:	ff 75 10             	pushl  0x10(%ebp)
f0100cc7:	ff 75 0c             	pushl  0xc(%ebp)
f0100cca:	ff 75 08             	pushl  0x8(%ebp)
f0100ccd:	e8 05 00 00 00       	call   f0100cd7 <vprintfmt>
}
f0100cd2:	83 c4 10             	add    $0x10,%esp
f0100cd5:	c9                   	leave  
f0100cd6:	c3                   	ret    

f0100cd7 <vprintfmt>:
{
f0100cd7:	55                   	push   %ebp
f0100cd8:	89 e5                	mov    %esp,%ebp
f0100cda:	57                   	push   %edi
f0100cdb:	56                   	push   %esi
f0100cdc:	53                   	push   %ebx
f0100cdd:	83 ec 2c             	sub    $0x2c,%esp
f0100ce0:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ce3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ce6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ce9:	e9 c1 03 00 00       	jmp    f01010af <vprintfmt+0x3d8>
		padc = ' ';
f0100cee:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100cf2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100cf9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0100d00:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100d07:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0100d0c:	8d 47 01             	lea    0x1(%edi),%eax
f0100d0f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d12:	0f b6 17             	movzbl (%edi),%edx
f0100d15:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100d18:	3c 55                	cmp    $0x55,%al
f0100d1a:	0f 87 12 04 00 00    	ja     f0101132 <vprintfmt+0x45b>
f0100d20:	0f b6 c0             	movzbl %al,%eax
f0100d23:	ff 24 85 b0 1d 10 f0 	jmp    *-0xfefe250(,%eax,4)
f0100d2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100d2d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100d31:	eb d9                	jmp    f0100d0c <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0100d33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100d36:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d3a:	eb d0                	jmp    f0100d0c <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0100d3c:	0f b6 d2             	movzbl %dl,%edx
f0100d3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100d42:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d47:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0100d4a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d4d:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100d51:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d54:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d57:	83 f9 09             	cmp    $0x9,%ecx
f0100d5a:	77 55                	ja     f0100db1 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f0100d5c:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100d5f:	eb e9                	jmp    f0100d4a <vprintfmt+0x73>
			precision = va_arg(ap, int);
f0100d61:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d64:	8b 00                	mov    (%eax),%eax
f0100d66:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d69:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d6c:	8d 40 04             	lea    0x4(%eax),%eax
f0100d6f:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100d72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100d75:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100d79:	79 91                	jns    f0100d0c <vprintfmt+0x35>
				width = precision, precision = -1;
f0100d7b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d7e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d81:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d88:	eb 82                	jmp    f0100d0c <vprintfmt+0x35>
f0100d8a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d8d:	85 c0                	test   %eax,%eax
f0100d8f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d94:	0f 49 d0             	cmovns %eax,%edx
f0100d97:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100d9a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d9d:	e9 6a ff ff ff       	jmp    f0100d0c <vprintfmt+0x35>
f0100da2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100da5:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100dac:	e9 5b ff ff ff       	jmp    f0100d0c <vprintfmt+0x35>
f0100db1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100db4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100db7:	eb bc                	jmp    f0100d75 <vprintfmt+0x9e>
			lflag++;
f0100db9:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0100dbc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0100dbf:	e9 48 ff ff ff       	jmp    f0100d0c <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0100dc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dc7:	8d 78 04             	lea    0x4(%eax),%edi
f0100dca:	83 ec 08             	sub    $0x8,%esp
f0100dcd:	53                   	push   %ebx
f0100dce:	ff 30                	pushl  (%eax)
f0100dd0:	ff d6                	call   *%esi
			break;
f0100dd2:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100dd5:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100dd8:	e9 cf 02 00 00       	jmp    f01010ac <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f0100ddd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100de0:	8d 78 04             	lea    0x4(%eax),%edi
f0100de3:	8b 00                	mov    (%eax),%eax
f0100de5:	99                   	cltd   
f0100de6:	31 d0                	xor    %edx,%eax
f0100de8:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100dea:	83 f8 06             	cmp    $0x6,%eax
f0100ded:	7f 23                	jg     f0100e12 <vprintfmt+0x13b>
f0100def:	8b 14 85 08 1f 10 f0 	mov    -0xfefe0f8(,%eax,4),%edx
f0100df6:	85 d2                	test   %edx,%edx
f0100df8:	74 18                	je     f0100e12 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f0100dfa:	52                   	push   %edx
f0100dfb:	68 42 1d 10 f0       	push   $0xf0101d42
f0100e00:	53                   	push   %ebx
f0100e01:	56                   	push   %esi
f0100e02:	e8 b3 fe ff ff       	call   f0100cba <printfmt>
f0100e07:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100e0a:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100e0d:	e9 9a 02 00 00       	jmp    f01010ac <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f0100e12:	50                   	push   %eax
f0100e13:	68 39 1d 10 f0       	push   $0xf0101d39
f0100e18:	53                   	push   %ebx
f0100e19:	56                   	push   %esi
f0100e1a:	e8 9b fe ff ff       	call   f0100cba <printfmt>
f0100e1f:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100e22:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100e25:	e9 82 02 00 00       	jmp    f01010ac <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f0100e2a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e2d:	83 c0 04             	add    $0x4,%eax
f0100e30:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100e33:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e36:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100e38:	85 ff                	test   %edi,%edi
f0100e3a:	b8 32 1d 10 f0       	mov    $0xf0101d32,%eax
f0100e3f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100e42:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e46:	0f 8e bd 00 00 00    	jle    f0100f09 <vprintfmt+0x232>
f0100e4c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e50:	75 0e                	jne    f0100e60 <vprintfmt+0x189>
f0100e52:	89 75 08             	mov    %esi,0x8(%ebp)
f0100e55:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100e58:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100e5b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100e5e:	eb 6d                	jmp    f0100ecd <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e60:	83 ec 08             	sub    $0x8,%esp
f0100e63:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e66:	57                   	push   %edi
f0100e67:	e8 50 04 00 00       	call   f01012bc <strnlen>
f0100e6c:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e6f:	29 c1                	sub    %eax,%ecx
f0100e71:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100e74:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100e77:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100e7b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e7e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e81:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e83:	eb 0f                	jmp    f0100e94 <vprintfmt+0x1bd>
					putch(padc, putdat);
f0100e85:	83 ec 08             	sub    $0x8,%esp
f0100e88:	53                   	push   %ebx
f0100e89:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e8c:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e8e:	83 ef 01             	sub    $0x1,%edi
f0100e91:	83 c4 10             	add    $0x10,%esp
f0100e94:	85 ff                	test   %edi,%edi
f0100e96:	7f ed                	jg     f0100e85 <vprintfmt+0x1ae>
f0100e98:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e9b:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100e9e:	85 c9                	test   %ecx,%ecx
f0100ea0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea5:	0f 49 c1             	cmovns %ecx,%eax
f0100ea8:	29 c1                	sub    %eax,%ecx
f0100eaa:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ead:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100eb0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100eb3:	89 cb                	mov    %ecx,%ebx
f0100eb5:	eb 16                	jmp    f0100ecd <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f0100eb7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ebb:	75 31                	jne    f0100eee <vprintfmt+0x217>
					putch(ch, putdat);
f0100ebd:	83 ec 08             	sub    $0x8,%esp
f0100ec0:	ff 75 0c             	pushl  0xc(%ebp)
f0100ec3:	50                   	push   %eax
f0100ec4:	ff 55 08             	call   *0x8(%ebp)
f0100ec7:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100eca:	83 eb 01             	sub    $0x1,%ebx
f0100ecd:	83 c7 01             	add    $0x1,%edi
f0100ed0:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0100ed4:	0f be c2             	movsbl %dl,%eax
f0100ed7:	85 c0                	test   %eax,%eax
f0100ed9:	74 59                	je     f0100f34 <vprintfmt+0x25d>
f0100edb:	85 f6                	test   %esi,%esi
f0100edd:	78 d8                	js     f0100eb7 <vprintfmt+0x1e0>
f0100edf:	83 ee 01             	sub    $0x1,%esi
f0100ee2:	79 d3                	jns    f0100eb7 <vprintfmt+0x1e0>
f0100ee4:	89 df                	mov    %ebx,%edi
f0100ee6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ee9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100eec:	eb 37                	jmp    f0100f25 <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f0100eee:	0f be d2             	movsbl %dl,%edx
f0100ef1:	83 ea 20             	sub    $0x20,%edx
f0100ef4:	83 fa 5e             	cmp    $0x5e,%edx
f0100ef7:	76 c4                	jbe    f0100ebd <vprintfmt+0x1e6>
					putch('?', putdat);
f0100ef9:	83 ec 08             	sub    $0x8,%esp
f0100efc:	ff 75 0c             	pushl  0xc(%ebp)
f0100eff:	6a 3f                	push   $0x3f
f0100f01:	ff 55 08             	call   *0x8(%ebp)
f0100f04:	83 c4 10             	add    $0x10,%esp
f0100f07:	eb c1                	jmp    f0100eca <vprintfmt+0x1f3>
f0100f09:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f0c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f0f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f12:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f15:	eb b6                	jmp    f0100ecd <vprintfmt+0x1f6>
				putch(' ', putdat);
f0100f17:	83 ec 08             	sub    $0x8,%esp
f0100f1a:	53                   	push   %ebx
f0100f1b:	6a 20                	push   $0x20
f0100f1d:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0100f1f:	83 ef 01             	sub    $0x1,%edi
f0100f22:	83 c4 10             	add    $0x10,%esp
f0100f25:	85 ff                	test   %edi,%edi
f0100f27:	7f ee                	jg     f0100f17 <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f0100f29:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100f2c:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f2f:	e9 78 01 00 00       	jmp    f01010ac <vprintfmt+0x3d5>
f0100f34:	89 df                	mov    %ebx,%edi
f0100f36:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f39:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f3c:	eb e7                	jmp    f0100f25 <vprintfmt+0x24e>
	if (lflag >= 2)
f0100f3e:	83 f9 01             	cmp    $0x1,%ecx
f0100f41:	7e 3f                	jle    f0100f82 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f0100f43:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f46:	8b 50 04             	mov    0x4(%eax),%edx
f0100f49:	8b 00                	mov    (%eax),%eax
f0100f4b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f4e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f51:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f54:	8d 40 08             	lea    0x8(%eax),%eax
f0100f57:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0100f5a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f5e:	79 5c                	jns    f0100fbc <vprintfmt+0x2e5>
				putch('-', putdat);
f0100f60:	83 ec 08             	sub    $0x8,%esp
f0100f63:	53                   	push   %ebx
f0100f64:	6a 2d                	push   $0x2d
f0100f66:	ff d6                	call   *%esi
				num = -(long long) num;
f0100f68:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f6b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f6e:	f7 da                	neg    %edx
f0100f70:	83 d1 00             	adc    $0x0,%ecx
f0100f73:	f7 d9                	neg    %ecx
f0100f75:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0100f78:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100f7d:	e9 10 01 00 00       	jmp    f0101092 <vprintfmt+0x3bb>
	else if (lflag)
f0100f82:	85 c9                	test   %ecx,%ecx
f0100f84:	75 1b                	jne    f0100fa1 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f0100f86:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f89:	8b 00                	mov    (%eax),%eax
f0100f8b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f8e:	89 c1                	mov    %eax,%ecx
f0100f90:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f93:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f96:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f99:	8d 40 04             	lea    0x4(%eax),%eax
f0100f9c:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f9f:	eb b9                	jmp    f0100f5a <vprintfmt+0x283>
		return va_arg(*ap, long);
f0100fa1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa4:	8b 00                	mov    (%eax),%eax
f0100fa6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fa9:	89 c1                	mov    %eax,%ecx
f0100fab:	c1 f9 1f             	sar    $0x1f,%ecx
f0100fae:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb4:	8d 40 04             	lea    0x4(%eax),%eax
f0100fb7:	89 45 14             	mov    %eax,0x14(%ebp)
f0100fba:	eb 9e                	jmp    f0100f5a <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0100fbc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100fbf:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0100fc2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fc7:	e9 c6 00 00 00       	jmp    f0101092 <vprintfmt+0x3bb>
	if (lflag >= 2)
f0100fcc:	83 f9 01             	cmp    $0x1,%ecx
f0100fcf:	7e 18                	jle    f0100fe9 <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f0100fd1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd4:	8b 10                	mov    (%eax),%edx
f0100fd6:	8b 48 04             	mov    0x4(%eax),%ecx
f0100fd9:	8d 40 08             	lea    0x8(%eax),%eax
f0100fdc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0100fdf:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fe4:	e9 a9 00 00 00       	jmp    f0101092 <vprintfmt+0x3bb>
	else if (lflag)
f0100fe9:	85 c9                	test   %ecx,%ecx
f0100feb:	75 1a                	jne    f0101007 <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f0100fed:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff0:	8b 10                	mov    (%eax),%edx
f0100ff2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ff7:	8d 40 04             	lea    0x4(%eax),%eax
f0100ffa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0100ffd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101002:	e9 8b 00 00 00       	jmp    f0101092 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0101007:	8b 45 14             	mov    0x14(%ebp),%eax
f010100a:	8b 10                	mov    (%eax),%edx
f010100c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101011:	8d 40 04             	lea    0x4(%eax),%eax
f0101014:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101017:	b8 0a 00 00 00       	mov    $0xa,%eax
f010101c:	eb 74                	jmp    f0101092 <vprintfmt+0x3bb>
	if (lflag >= 2)
f010101e:	83 f9 01             	cmp    $0x1,%ecx
f0101021:	7e 15                	jle    f0101038 <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f0101023:	8b 45 14             	mov    0x14(%ebp),%eax
f0101026:	8b 10                	mov    (%eax),%edx
f0101028:	8b 48 04             	mov    0x4(%eax),%ecx
f010102b:	8d 40 08             	lea    0x8(%eax),%eax
f010102e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101031:	b8 08 00 00 00       	mov    $0x8,%eax
f0101036:	eb 5a                	jmp    f0101092 <vprintfmt+0x3bb>
	else if (lflag)
f0101038:	85 c9                	test   %ecx,%ecx
f010103a:	75 17                	jne    f0101053 <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f010103c:	8b 45 14             	mov    0x14(%ebp),%eax
f010103f:	8b 10                	mov    (%eax),%edx
f0101041:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101046:	8d 40 04             	lea    0x4(%eax),%eax
f0101049:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010104c:	b8 08 00 00 00       	mov    $0x8,%eax
f0101051:	eb 3f                	jmp    f0101092 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0101053:	8b 45 14             	mov    0x14(%ebp),%eax
f0101056:	8b 10                	mov    (%eax),%edx
f0101058:	b9 00 00 00 00       	mov    $0x0,%ecx
f010105d:	8d 40 04             	lea    0x4(%eax),%eax
f0101060:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101063:	b8 08 00 00 00       	mov    $0x8,%eax
f0101068:	eb 28                	jmp    f0101092 <vprintfmt+0x3bb>
			putch('0', putdat);
f010106a:	83 ec 08             	sub    $0x8,%esp
f010106d:	53                   	push   %ebx
f010106e:	6a 30                	push   $0x30
f0101070:	ff d6                	call   *%esi
			putch('x', putdat);
f0101072:	83 c4 08             	add    $0x8,%esp
f0101075:	53                   	push   %ebx
f0101076:	6a 78                	push   $0x78
f0101078:	ff d6                	call   *%esi
			num = (unsigned long long)
f010107a:	8b 45 14             	mov    0x14(%ebp),%eax
f010107d:	8b 10                	mov    (%eax),%edx
f010107f:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101084:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101087:	8d 40 04             	lea    0x4(%eax),%eax
f010108a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010108d:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101092:	83 ec 0c             	sub    $0xc,%esp
f0101095:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101099:	57                   	push   %edi
f010109a:	ff 75 e0             	pushl  -0x20(%ebp)
f010109d:	50                   	push   %eax
f010109e:	51                   	push   %ecx
f010109f:	52                   	push   %edx
f01010a0:	89 da                	mov    %ebx,%edx
f01010a2:	89 f0                	mov    %esi,%eax
f01010a4:	e8 45 fb ff ff       	call   f0100bee <printnum>
			break;
f01010a9:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01010ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01010af:	83 c7 01             	add    $0x1,%edi
f01010b2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01010b6:	83 f8 25             	cmp    $0x25,%eax
f01010b9:	0f 84 2f fc ff ff    	je     f0100cee <vprintfmt+0x17>
			if (ch == '\0')
f01010bf:	85 c0                	test   %eax,%eax
f01010c1:	0f 84 8b 00 00 00    	je     f0101152 <vprintfmt+0x47b>
			putch(ch, putdat);
f01010c7:	83 ec 08             	sub    $0x8,%esp
f01010ca:	53                   	push   %ebx
f01010cb:	50                   	push   %eax
f01010cc:	ff d6                	call   *%esi
f01010ce:	83 c4 10             	add    $0x10,%esp
f01010d1:	eb dc                	jmp    f01010af <vprintfmt+0x3d8>
	if (lflag >= 2)
f01010d3:	83 f9 01             	cmp    $0x1,%ecx
f01010d6:	7e 15                	jle    f01010ed <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f01010d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010db:	8b 10                	mov    (%eax),%edx
f01010dd:	8b 48 04             	mov    0x4(%eax),%ecx
f01010e0:	8d 40 08             	lea    0x8(%eax),%eax
f01010e3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01010e6:	b8 10 00 00 00       	mov    $0x10,%eax
f01010eb:	eb a5                	jmp    f0101092 <vprintfmt+0x3bb>
	else if (lflag)
f01010ed:	85 c9                	test   %ecx,%ecx
f01010ef:	75 17                	jne    f0101108 <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f01010f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f4:	8b 10                	mov    (%eax),%edx
f01010f6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010fb:	8d 40 04             	lea    0x4(%eax),%eax
f01010fe:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101101:	b8 10 00 00 00       	mov    $0x10,%eax
f0101106:	eb 8a                	jmp    f0101092 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0101108:	8b 45 14             	mov    0x14(%ebp),%eax
f010110b:	8b 10                	mov    (%eax),%edx
f010110d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101112:	8d 40 04             	lea    0x4(%eax),%eax
f0101115:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101118:	b8 10 00 00 00       	mov    $0x10,%eax
f010111d:	e9 70 ff ff ff       	jmp    f0101092 <vprintfmt+0x3bb>
			putch(ch, putdat);
f0101122:	83 ec 08             	sub    $0x8,%esp
f0101125:	53                   	push   %ebx
f0101126:	6a 25                	push   $0x25
f0101128:	ff d6                	call   *%esi
			break;
f010112a:	83 c4 10             	add    $0x10,%esp
f010112d:	e9 7a ff ff ff       	jmp    f01010ac <vprintfmt+0x3d5>
			putch('%', putdat);
f0101132:	83 ec 08             	sub    $0x8,%esp
f0101135:	53                   	push   %ebx
f0101136:	6a 25                	push   $0x25
f0101138:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010113a:	83 c4 10             	add    $0x10,%esp
f010113d:	89 f8                	mov    %edi,%eax
f010113f:	eb 03                	jmp    f0101144 <vprintfmt+0x46d>
f0101141:	83 e8 01             	sub    $0x1,%eax
f0101144:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101148:	75 f7                	jne    f0101141 <vprintfmt+0x46a>
f010114a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010114d:	e9 5a ff ff ff       	jmp    f01010ac <vprintfmt+0x3d5>
}
f0101152:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101155:	5b                   	pop    %ebx
f0101156:	5e                   	pop    %esi
f0101157:	5f                   	pop    %edi
f0101158:	5d                   	pop    %ebp
f0101159:	c3                   	ret    

f010115a <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010115a:	55                   	push   %ebp
f010115b:	89 e5                	mov    %esp,%ebp
f010115d:	83 ec 18             	sub    $0x18,%esp
f0101160:	8b 45 08             	mov    0x8(%ebp),%eax
f0101163:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101166:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101169:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010116d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101170:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101177:	85 c0                	test   %eax,%eax
f0101179:	74 26                	je     f01011a1 <vsnprintf+0x47>
f010117b:	85 d2                	test   %edx,%edx
f010117d:	7e 22                	jle    f01011a1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010117f:	ff 75 14             	pushl  0x14(%ebp)
f0101182:	ff 75 10             	pushl  0x10(%ebp)
f0101185:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101188:	50                   	push   %eax
f0101189:	68 9d 0c 10 f0       	push   $0xf0100c9d
f010118e:	e8 44 fb ff ff       	call   f0100cd7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101193:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101196:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101199:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010119c:	83 c4 10             	add    $0x10,%esp
}
f010119f:	c9                   	leave  
f01011a0:	c3                   	ret    
		return -E_INVAL;
f01011a1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01011a6:	eb f7                	jmp    f010119f <vsnprintf+0x45>

f01011a8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011a8:	55                   	push   %ebp
f01011a9:	89 e5                	mov    %esp,%ebp
f01011ab:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011ae:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011b1:	50                   	push   %eax
f01011b2:	ff 75 10             	pushl  0x10(%ebp)
f01011b5:	ff 75 0c             	pushl  0xc(%ebp)
f01011b8:	ff 75 08             	pushl  0x8(%ebp)
f01011bb:	e8 9a ff ff ff       	call   f010115a <vsnprintf>
	va_end(ap);

	return rc;
}
f01011c0:	c9                   	leave  
f01011c1:	c3                   	ret    

f01011c2 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011c2:	55                   	push   %ebp
f01011c3:	89 e5                	mov    %esp,%ebp
f01011c5:	57                   	push   %edi
f01011c6:	56                   	push   %esi
f01011c7:	53                   	push   %ebx
f01011c8:	83 ec 0c             	sub    $0xc,%esp
f01011cb:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011ce:	85 c0                	test   %eax,%eax
f01011d0:	74 11                	je     f01011e3 <readline+0x21>
		cprintf("%s", prompt);
f01011d2:	83 ec 08             	sub    $0x8,%esp
f01011d5:	50                   	push   %eax
f01011d6:	68 42 1d 10 f0       	push   $0xf0101d42
f01011db:	e8 de f6 ff ff       	call   f01008be <cprintf>
f01011e0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011e3:	83 ec 0c             	sub    $0xc,%esp
f01011e6:	6a 00                	push   $0x0
f01011e8:	e8 6f f4 ff ff       	call   f010065c <iscons>
f01011ed:	89 c7                	mov    %eax,%edi
f01011ef:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01011f2:	be 00 00 00 00       	mov    $0x0,%esi
f01011f7:	eb 3f                	jmp    f0101238 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01011f9:	83 ec 08             	sub    $0x8,%esp
f01011fc:	50                   	push   %eax
f01011fd:	68 24 1f 10 f0       	push   $0xf0101f24
f0101202:	e8 b7 f6 ff ff       	call   f01008be <cprintf>
			return NULL;
f0101207:	83 c4 10             	add    $0x10,%esp
f010120a:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010120f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101212:	5b                   	pop    %ebx
f0101213:	5e                   	pop    %esi
f0101214:	5f                   	pop    %edi
f0101215:	5d                   	pop    %ebp
f0101216:	c3                   	ret    
			if (echoing)
f0101217:	85 ff                	test   %edi,%edi
f0101219:	75 05                	jne    f0101220 <readline+0x5e>
			i--;
f010121b:	83 ee 01             	sub    $0x1,%esi
f010121e:	eb 18                	jmp    f0101238 <readline+0x76>
				cputchar('\b');
f0101220:	83 ec 0c             	sub    $0xc,%esp
f0101223:	6a 08                	push   $0x8
f0101225:	e8 11 f4 ff ff       	call   f010063b <cputchar>
f010122a:	83 c4 10             	add    $0x10,%esp
f010122d:	eb ec                	jmp    f010121b <readline+0x59>
			buf[i++] = c;
f010122f:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101235:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0101238:	e8 0e f4 ff ff       	call   f010064b <getchar>
f010123d:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010123f:	85 c0                	test   %eax,%eax
f0101241:	78 b6                	js     f01011f9 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101243:	83 f8 08             	cmp    $0x8,%eax
f0101246:	0f 94 c2             	sete   %dl
f0101249:	83 f8 7f             	cmp    $0x7f,%eax
f010124c:	0f 94 c0             	sete   %al
f010124f:	08 c2                	or     %al,%dl
f0101251:	74 04                	je     f0101257 <readline+0x95>
f0101253:	85 f6                	test   %esi,%esi
f0101255:	7f c0                	jg     f0101217 <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101257:	83 fb 1f             	cmp    $0x1f,%ebx
f010125a:	7e 1a                	jle    f0101276 <readline+0xb4>
f010125c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101262:	7f 12                	jg     f0101276 <readline+0xb4>
			if (echoing)
f0101264:	85 ff                	test   %edi,%edi
f0101266:	74 c7                	je     f010122f <readline+0x6d>
				cputchar(c);
f0101268:	83 ec 0c             	sub    $0xc,%esp
f010126b:	53                   	push   %ebx
f010126c:	e8 ca f3 ff ff       	call   f010063b <cputchar>
f0101271:	83 c4 10             	add    $0x10,%esp
f0101274:	eb b9                	jmp    f010122f <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f0101276:	83 fb 0a             	cmp    $0xa,%ebx
f0101279:	74 05                	je     f0101280 <readline+0xbe>
f010127b:	83 fb 0d             	cmp    $0xd,%ebx
f010127e:	75 b8                	jne    f0101238 <readline+0x76>
			if (echoing)
f0101280:	85 ff                	test   %edi,%edi
f0101282:	75 11                	jne    f0101295 <readline+0xd3>
			buf[i] = 0;
f0101284:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010128b:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
f0101290:	e9 7a ff ff ff       	jmp    f010120f <readline+0x4d>
				cputchar('\n');
f0101295:	83 ec 0c             	sub    $0xc,%esp
f0101298:	6a 0a                	push   $0xa
f010129a:	e8 9c f3 ff ff       	call   f010063b <cputchar>
f010129f:	83 c4 10             	add    $0x10,%esp
f01012a2:	eb e0                	jmp    f0101284 <readline+0xc2>

f01012a4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012a4:	55                   	push   %ebp
f01012a5:	89 e5                	mov    %esp,%ebp
f01012a7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01012af:	eb 03                	jmp    f01012b4 <strlen+0x10>
		n++;
f01012b1:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01012b4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012b8:	75 f7                	jne    f01012b1 <strlen+0xd>
	return n;
}
f01012ba:	5d                   	pop    %ebp
f01012bb:	c3                   	ret    

f01012bc <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012bc:	55                   	push   %ebp
f01012bd:	89 e5                	mov    %esp,%ebp
f01012bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012c2:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01012ca:	eb 03                	jmp    f01012cf <strnlen+0x13>
		n++;
f01012cc:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012cf:	39 d0                	cmp    %edx,%eax
f01012d1:	74 06                	je     f01012d9 <strnlen+0x1d>
f01012d3:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01012d7:	75 f3                	jne    f01012cc <strnlen+0x10>
	return n;
}
f01012d9:	5d                   	pop    %ebp
f01012da:	c3                   	ret    

f01012db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012db:	55                   	push   %ebp
f01012dc:	89 e5                	mov    %esp,%ebp
f01012de:	53                   	push   %ebx
f01012df:	8b 45 08             	mov    0x8(%ebp),%eax
f01012e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012e5:	89 c2                	mov    %eax,%edx
f01012e7:	83 c1 01             	add    $0x1,%ecx
f01012ea:	83 c2 01             	add    $0x1,%edx
f01012ed:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012f1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012f4:	84 db                	test   %bl,%bl
f01012f6:	75 ef                	jne    f01012e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012f8:	5b                   	pop    %ebx
f01012f9:	5d                   	pop    %ebp
f01012fa:	c3                   	ret    

f01012fb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012fb:	55                   	push   %ebp
f01012fc:	89 e5                	mov    %esp,%ebp
f01012fe:	53                   	push   %ebx
f01012ff:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101302:	53                   	push   %ebx
f0101303:	e8 9c ff ff ff       	call   f01012a4 <strlen>
f0101308:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010130b:	ff 75 0c             	pushl  0xc(%ebp)
f010130e:	01 d8                	add    %ebx,%eax
f0101310:	50                   	push   %eax
f0101311:	e8 c5 ff ff ff       	call   f01012db <strcpy>
	return dst;
}
f0101316:	89 d8                	mov    %ebx,%eax
f0101318:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010131b:	c9                   	leave  
f010131c:	c3                   	ret    

f010131d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010131d:	55                   	push   %ebp
f010131e:	89 e5                	mov    %esp,%ebp
f0101320:	56                   	push   %esi
f0101321:	53                   	push   %ebx
f0101322:	8b 75 08             	mov    0x8(%ebp),%esi
f0101325:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101328:	89 f3                	mov    %esi,%ebx
f010132a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010132d:	89 f2                	mov    %esi,%edx
f010132f:	eb 0f                	jmp    f0101340 <strncpy+0x23>
		*dst++ = *src;
f0101331:	83 c2 01             	add    $0x1,%edx
f0101334:	0f b6 01             	movzbl (%ecx),%eax
f0101337:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010133a:	80 39 01             	cmpb   $0x1,(%ecx)
f010133d:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101340:	39 da                	cmp    %ebx,%edx
f0101342:	75 ed                	jne    f0101331 <strncpy+0x14>
	}
	return ret;
}
f0101344:	89 f0                	mov    %esi,%eax
f0101346:	5b                   	pop    %ebx
f0101347:	5e                   	pop    %esi
f0101348:	5d                   	pop    %ebp
f0101349:	c3                   	ret    

f010134a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010134a:	55                   	push   %ebp
f010134b:	89 e5                	mov    %esp,%ebp
f010134d:	56                   	push   %esi
f010134e:	53                   	push   %ebx
f010134f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101352:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101355:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101358:	89 f0                	mov    %esi,%eax
f010135a:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010135e:	85 c9                	test   %ecx,%ecx
f0101360:	75 0b                	jne    f010136d <strlcpy+0x23>
f0101362:	eb 17                	jmp    f010137b <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101364:	83 c2 01             	add    $0x1,%edx
f0101367:	83 c0 01             	add    $0x1,%eax
f010136a:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f010136d:	39 d8                	cmp    %ebx,%eax
f010136f:	74 07                	je     f0101378 <strlcpy+0x2e>
f0101371:	0f b6 0a             	movzbl (%edx),%ecx
f0101374:	84 c9                	test   %cl,%cl
f0101376:	75 ec                	jne    f0101364 <strlcpy+0x1a>
		*dst = '\0';
f0101378:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010137b:	29 f0                	sub    %esi,%eax
}
f010137d:	5b                   	pop    %ebx
f010137e:	5e                   	pop    %esi
f010137f:	5d                   	pop    %ebp
f0101380:	c3                   	ret    

f0101381 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101381:	55                   	push   %ebp
f0101382:	89 e5                	mov    %esp,%ebp
f0101384:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101387:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010138a:	eb 06                	jmp    f0101392 <strcmp+0x11>
		p++, q++;
f010138c:	83 c1 01             	add    $0x1,%ecx
f010138f:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101392:	0f b6 01             	movzbl (%ecx),%eax
f0101395:	84 c0                	test   %al,%al
f0101397:	74 04                	je     f010139d <strcmp+0x1c>
f0101399:	3a 02                	cmp    (%edx),%al
f010139b:	74 ef                	je     f010138c <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010139d:	0f b6 c0             	movzbl %al,%eax
f01013a0:	0f b6 12             	movzbl (%edx),%edx
f01013a3:	29 d0                	sub    %edx,%eax
}
f01013a5:	5d                   	pop    %ebp
f01013a6:	c3                   	ret    

f01013a7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	53                   	push   %ebx
f01013ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ae:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013b1:	89 c3                	mov    %eax,%ebx
f01013b3:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013b6:	eb 06                	jmp    f01013be <strncmp+0x17>
		n--, p++, q++;
f01013b8:	83 c0 01             	add    $0x1,%eax
f01013bb:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01013be:	39 d8                	cmp    %ebx,%eax
f01013c0:	74 16                	je     f01013d8 <strncmp+0x31>
f01013c2:	0f b6 08             	movzbl (%eax),%ecx
f01013c5:	84 c9                	test   %cl,%cl
f01013c7:	74 04                	je     f01013cd <strncmp+0x26>
f01013c9:	3a 0a                	cmp    (%edx),%cl
f01013cb:	74 eb                	je     f01013b8 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013cd:	0f b6 00             	movzbl (%eax),%eax
f01013d0:	0f b6 12             	movzbl (%edx),%edx
f01013d3:	29 d0                	sub    %edx,%eax
}
f01013d5:	5b                   	pop    %ebx
f01013d6:	5d                   	pop    %ebp
f01013d7:	c3                   	ret    
		return 0;
f01013d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01013dd:	eb f6                	jmp    f01013d5 <strncmp+0x2e>

f01013df <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013df:	55                   	push   %ebp
f01013e0:	89 e5                	mov    %esp,%ebp
f01013e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013e9:	0f b6 10             	movzbl (%eax),%edx
f01013ec:	84 d2                	test   %dl,%dl
f01013ee:	74 09                	je     f01013f9 <strchr+0x1a>
		if (*s == c)
f01013f0:	38 ca                	cmp    %cl,%dl
f01013f2:	74 0a                	je     f01013fe <strchr+0x1f>
	for (; *s; s++)
f01013f4:	83 c0 01             	add    $0x1,%eax
f01013f7:	eb f0                	jmp    f01013e9 <strchr+0xa>
			return (char *) s;
	return 0;
f01013f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013fe:	5d                   	pop    %ebp
f01013ff:	c3                   	ret    

f0101400 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101400:	55                   	push   %ebp
f0101401:	89 e5                	mov    %esp,%ebp
f0101403:	8b 45 08             	mov    0x8(%ebp),%eax
f0101406:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010140a:	eb 03                	jmp    f010140f <strfind+0xf>
f010140c:	83 c0 01             	add    $0x1,%eax
f010140f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101412:	38 ca                	cmp    %cl,%dl
f0101414:	74 04                	je     f010141a <strfind+0x1a>
f0101416:	84 d2                	test   %dl,%dl
f0101418:	75 f2                	jne    f010140c <strfind+0xc>
			break;
	return (char *) s;
}
f010141a:	5d                   	pop    %ebp
f010141b:	c3                   	ret    

f010141c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010141c:	55                   	push   %ebp
f010141d:	89 e5                	mov    %esp,%ebp
f010141f:	57                   	push   %edi
f0101420:	56                   	push   %esi
f0101421:	53                   	push   %ebx
f0101422:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101425:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101428:	85 c9                	test   %ecx,%ecx
f010142a:	74 13                	je     f010143f <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010142c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101432:	75 05                	jne    f0101439 <memset+0x1d>
f0101434:	f6 c1 03             	test   $0x3,%cl
f0101437:	74 0d                	je     f0101446 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101439:	8b 45 0c             	mov    0xc(%ebp),%eax
f010143c:	fc                   	cld    
f010143d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010143f:	89 f8                	mov    %edi,%eax
f0101441:	5b                   	pop    %ebx
f0101442:	5e                   	pop    %esi
f0101443:	5f                   	pop    %edi
f0101444:	5d                   	pop    %ebp
f0101445:	c3                   	ret    
		c &= 0xFF;
f0101446:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010144a:	89 d3                	mov    %edx,%ebx
f010144c:	c1 e3 08             	shl    $0x8,%ebx
f010144f:	89 d0                	mov    %edx,%eax
f0101451:	c1 e0 18             	shl    $0x18,%eax
f0101454:	89 d6                	mov    %edx,%esi
f0101456:	c1 e6 10             	shl    $0x10,%esi
f0101459:	09 f0                	or     %esi,%eax
f010145b:	09 c2                	or     %eax,%edx
f010145d:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f010145f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101462:	89 d0                	mov    %edx,%eax
f0101464:	fc                   	cld    
f0101465:	f3 ab                	rep stos %eax,%es:(%edi)
f0101467:	eb d6                	jmp    f010143f <memset+0x23>

f0101469 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101469:	55                   	push   %ebp
f010146a:	89 e5                	mov    %esp,%ebp
f010146c:	57                   	push   %edi
f010146d:	56                   	push   %esi
f010146e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101471:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101474:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101477:	39 c6                	cmp    %eax,%esi
f0101479:	73 35                	jae    f01014b0 <memmove+0x47>
f010147b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010147e:	39 c2                	cmp    %eax,%edx
f0101480:	76 2e                	jbe    f01014b0 <memmove+0x47>
		s += n;
		d += n;
f0101482:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101485:	89 d6                	mov    %edx,%esi
f0101487:	09 fe                	or     %edi,%esi
f0101489:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010148f:	74 0c                	je     f010149d <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101491:	83 ef 01             	sub    $0x1,%edi
f0101494:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101497:	fd                   	std    
f0101498:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010149a:	fc                   	cld    
f010149b:	eb 21                	jmp    f01014be <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010149d:	f6 c1 03             	test   $0x3,%cl
f01014a0:	75 ef                	jne    f0101491 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01014a2:	83 ef 04             	sub    $0x4,%edi
f01014a5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014a8:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01014ab:	fd                   	std    
f01014ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014ae:	eb ea                	jmp    f010149a <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014b0:	89 f2                	mov    %esi,%edx
f01014b2:	09 c2                	or     %eax,%edx
f01014b4:	f6 c2 03             	test   $0x3,%dl
f01014b7:	74 09                	je     f01014c2 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014b9:	89 c7                	mov    %eax,%edi
f01014bb:	fc                   	cld    
f01014bc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014be:	5e                   	pop    %esi
f01014bf:	5f                   	pop    %edi
f01014c0:	5d                   	pop    %ebp
f01014c1:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014c2:	f6 c1 03             	test   $0x3,%cl
f01014c5:	75 f2                	jne    f01014b9 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01014c7:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01014ca:	89 c7                	mov    %eax,%edi
f01014cc:	fc                   	cld    
f01014cd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014cf:	eb ed                	jmp    f01014be <memmove+0x55>

f01014d1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014d1:	55                   	push   %ebp
f01014d2:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014d4:	ff 75 10             	pushl  0x10(%ebp)
f01014d7:	ff 75 0c             	pushl  0xc(%ebp)
f01014da:	ff 75 08             	pushl  0x8(%ebp)
f01014dd:	e8 87 ff ff ff       	call   f0101469 <memmove>
}
f01014e2:	c9                   	leave  
f01014e3:	c3                   	ret    

f01014e4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014e4:	55                   	push   %ebp
f01014e5:	89 e5                	mov    %esp,%ebp
f01014e7:	56                   	push   %esi
f01014e8:	53                   	push   %ebx
f01014e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ec:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ef:	89 c6                	mov    %eax,%esi
f01014f1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014f4:	39 f0                	cmp    %esi,%eax
f01014f6:	74 1c                	je     f0101514 <memcmp+0x30>
		if (*s1 != *s2)
f01014f8:	0f b6 08             	movzbl (%eax),%ecx
f01014fb:	0f b6 1a             	movzbl (%edx),%ebx
f01014fe:	38 d9                	cmp    %bl,%cl
f0101500:	75 08                	jne    f010150a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101502:	83 c0 01             	add    $0x1,%eax
f0101505:	83 c2 01             	add    $0x1,%edx
f0101508:	eb ea                	jmp    f01014f4 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f010150a:	0f b6 c1             	movzbl %cl,%eax
f010150d:	0f b6 db             	movzbl %bl,%ebx
f0101510:	29 d8                	sub    %ebx,%eax
f0101512:	eb 05                	jmp    f0101519 <memcmp+0x35>
	}

	return 0;
f0101514:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101519:	5b                   	pop    %ebx
f010151a:	5e                   	pop    %esi
f010151b:	5d                   	pop    %ebp
f010151c:	c3                   	ret    

f010151d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010151d:	55                   	push   %ebp
f010151e:	89 e5                	mov    %esp,%ebp
f0101520:	8b 45 08             	mov    0x8(%ebp),%eax
f0101523:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101526:	89 c2                	mov    %eax,%edx
f0101528:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010152b:	39 d0                	cmp    %edx,%eax
f010152d:	73 09                	jae    f0101538 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f010152f:	38 08                	cmp    %cl,(%eax)
f0101531:	74 05                	je     f0101538 <memfind+0x1b>
	for (; s < ends; s++)
f0101533:	83 c0 01             	add    $0x1,%eax
f0101536:	eb f3                	jmp    f010152b <memfind+0xe>
			break;
	return (void *) s;
}
f0101538:	5d                   	pop    %ebp
f0101539:	c3                   	ret    

f010153a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010153a:	55                   	push   %ebp
f010153b:	89 e5                	mov    %esp,%ebp
f010153d:	57                   	push   %edi
f010153e:	56                   	push   %esi
f010153f:	53                   	push   %ebx
f0101540:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101543:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101546:	eb 03                	jmp    f010154b <strtol+0x11>
		s++;
f0101548:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010154b:	0f b6 01             	movzbl (%ecx),%eax
f010154e:	3c 20                	cmp    $0x20,%al
f0101550:	74 f6                	je     f0101548 <strtol+0xe>
f0101552:	3c 09                	cmp    $0x9,%al
f0101554:	74 f2                	je     f0101548 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101556:	3c 2b                	cmp    $0x2b,%al
f0101558:	74 2e                	je     f0101588 <strtol+0x4e>
	int neg = 0;
f010155a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010155f:	3c 2d                	cmp    $0x2d,%al
f0101561:	74 2f                	je     f0101592 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101563:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101569:	75 05                	jne    f0101570 <strtol+0x36>
f010156b:	80 39 30             	cmpb   $0x30,(%ecx)
f010156e:	74 2c                	je     f010159c <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101570:	85 db                	test   %ebx,%ebx
f0101572:	75 0a                	jne    f010157e <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101574:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101579:	80 39 30             	cmpb   $0x30,(%ecx)
f010157c:	74 28                	je     f01015a6 <strtol+0x6c>
		base = 10;
f010157e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101583:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101586:	eb 50                	jmp    f01015d8 <strtol+0x9e>
		s++;
f0101588:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010158b:	bf 00 00 00 00       	mov    $0x0,%edi
f0101590:	eb d1                	jmp    f0101563 <strtol+0x29>
		s++, neg = 1;
f0101592:	83 c1 01             	add    $0x1,%ecx
f0101595:	bf 01 00 00 00       	mov    $0x1,%edi
f010159a:	eb c7                	jmp    f0101563 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010159c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015a0:	74 0e                	je     f01015b0 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01015a2:	85 db                	test   %ebx,%ebx
f01015a4:	75 d8                	jne    f010157e <strtol+0x44>
		s++, base = 8;
f01015a6:	83 c1 01             	add    $0x1,%ecx
f01015a9:	bb 08 00 00 00       	mov    $0x8,%ebx
f01015ae:	eb ce                	jmp    f010157e <strtol+0x44>
		s += 2, base = 16;
f01015b0:	83 c1 02             	add    $0x2,%ecx
f01015b3:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015b8:	eb c4                	jmp    f010157e <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01015ba:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015bd:	89 f3                	mov    %esi,%ebx
f01015bf:	80 fb 19             	cmp    $0x19,%bl
f01015c2:	77 29                	ja     f01015ed <strtol+0xb3>
			dig = *s - 'a' + 10;
f01015c4:	0f be d2             	movsbl %dl,%edx
f01015c7:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01015ca:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015cd:	7d 30                	jge    f01015ff <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01015cf:	83 c1 01             	add    $0x1,%ecx
f01015d2:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015d6:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01015d8:	0f b6 11             	movzbl (%ecx),%edx
f01015db:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015de:	89 f3                	mov    %esi,%ebx
f01015e0:	80 fb 09             	cmp    $0x9,%bl
f01015e3:	77 d5                	ja     f01015ba <strtol+0x80>
			dig = *s - '0';
f01015e5:	0f be d2             	movsbl %dl,%edx
f01015e8:	83 ea 30             	sub    $0x30,%edx
f01015eb:	eb dd                	jmp    f01015ca <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01015ed:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015f0:	89 f3                	mov    %esi,%ebx
f01015f2:	80 fb 19             	cmp    $0x19,%bl
f01015f5:	77 08                	ja     f01015ff <strtol+0xc5>
			dig = *s - 'A' + 10;
f01015f7:	0f be d2             	movsbl %dl,%edx
f01015fa:	83 ea 37             	sub    $0x37,%edx
f01015fd:	eb cb                	jmp    f01015ca <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01015ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101603:	74 05                	je     f010160a <strtol+0xd0>
		*endptr = (char *) s;
f0101605:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101608:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010160a:	89 c2                	mov    %eax,%edx
f010160c:	f7 da                	neg    %edx
f010160e:	85 ff                	test   %edi,%edi
f0101610:	0f 45 c2             	cmovne %edx,%eax
}
f0101613:	5b                   	pop    %ebx
f0101614:	5e                   	pop    %esi
f0101615:	5f                   	pop    %edi
f0101616:	5d                   	pop    %ebp
f0101617:	c3                   	ret    
f0101618:	66 90                	xchg   %ax,%ax
f010161a:	66 90                	xchg   %ax,%ax
f010161c:	66 90                	xchg   %ax,%ax
f010161e:	66 90                	xchg   %ax,%ax

f0101620 <__udivdi3>:
f0101620:	55                   	push   %ebp
f0101621:	57                   	push   %edi
f0101622:	56                   	push   %esi
f0101623:	53                   	push   %ebx
f0101624:	83 ec 1c             	sub    $0x1c,%esp
f0101627:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010162b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010162f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101633:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101637:	85 d2                	test   %edx,%edx
f0101639:	75 35                	jne    f0101670 <__udivdi3+0x50>
f010163b:	39 f3                	cmp    %esi,%ebx
f010163d:	0f 87 bd 00 00 00    	ja     f0101700 <__udivdi3+0xe0>
f0101643:	85 db                	test   %ebx,%ebx
f0101645:	89 d9                	mov    %ebx,%ecx
f0101647:	75 0b                	jne    f0101654 <__udivdi3+0x34>
f0101649:	b8 01 00 00 00       	mov    $0x1,%eax
f010164e:	31 d2                	xor    %edx,%edx
f0101650:	f7 f3                	div    %ebx
f0101652:	89 c1                	mov    %eax,%ecx
f0101654:	31 d2                	xor    %edx,%edx
f0101656:	89 f0                	mov    %esi,%eax
f0101658:	f7 f1                	div    %ecx
f010165a:	89 c6                	mov    %eax,%esi
f010165c:	89 e8                	mov    %ebp,%eax
f010165e:	89 f7                	mov    %esi,%edi
f0101660:	f7 f1                	div    %ecx
f0101662:	89 fa                	mov    %edi,%edx
f0101664:	83 c4 1c             	add    $0x1c,%esp
f0101667:	5b                   	pop    %ebx
f0101668:	5e                   	pop    %esi
f0101669:	5f                   	pop    %edi
f010166a:	5d                   	pop    %ebp
f010166b:	c3                   	ret    
f010166c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101670:	39 f2                	cmp    %esi,%edx
f0101672:	77 7c                	ja     f01016f0 <__udivdi3+0xd0>
f0101674:	0f bd fa             	bsr    %edx,%edi
f0101677:	83 f7 1f             	xor    $0x1f,%edi
f010167a:	0f 84 98 00 00 00    	je     f0101718 <__udivdi3+0xf8>
f0101680:	89 f9                	mov    %edi,%ecx
f0101682:	b8 20 00 00 00       	mov    $0x20,%eax
f0101687:	29 f8                	sub    %edi,%eax
f0101689:	d3 e2                	shl    %cl,%edx
f010168b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010168f:	89 c1                	mov    %eax,%ecx
f0101691:	89 da                	mov    %ebx,%edx
f0101693:	d3 ea                	shr    %cl,%edx
f0101695:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101699:	09 d1                	or     %edx,%ecx
f010169b:	89 f2                	mov    %esi,%edx
f010169d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01016a1:	89 f9                	mov    %edi,%ecx
f01016a3:	d3 e3                	shl    %cl,%ebx
f01016a5:	89 c1                	mov    %eax,%ecx
f01016a7:	d3 ea                	shr    %cl,%edx
f01016a9:	89 f9                	mov    %edi,%ecx
f01016ab:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01016af:	d3 e6                	shl    %cl,%esi
f01016b1:	89 eb                	mov    %ebp,%ebx
f01016b3:	89 c1                	mov    %eax,%ecx
f01016b5:	d3 eb                	shr    %cl,%ebx
f01016b7:	09 de                	or     %ebx,%esi
f01016b9:	89 f0                	mov    %esi,%eax
f01016bb:	f7 74 24 08          	divl   0x8(%esp)
f01016bf:	89 d6                	mov    %edx,%esi
f01016c1:	89 c3                	mov    %eax,%ebx
f01016c3:	f7 64 24 0c          	mull   0xc(%esp)
f01016c7:	39 d6                	cmp    %edx,%esi
f01016c9:	72 0c                	jb     f01016d7 <__udivdi3+0xb7>
f01016cb:	89 f9                	mov    %edi,%ecx
f01016cd:	d3 e5                	shl    %cl,%ebp
f01016cf:	39 c5                	cmp    %eax,%ebp
f01016d1:	73 5d                	jae    f0101730 <__udivdi3+0x110>
f01016d3:	39 d6                	cmp    %edx,%esi
f01016d5:	75 59                	jne    f0101730 <__udivdi3+0x110>
f01016d7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01016da:	31 ff                	xor    %edi,%edi
f01016dc:	89 fa                	mov    %edi,%edx
f01016de:	83 c4 1c             	add    $0x1c,%esp
f01016e1:	5b                   	pop    %ebx
f01016e2:	5e                   	pop    %esi
f01016e3:	5f                   	pop    %edi
f01016e4:	5d                   	pop    %ebp
f01016e5:	c3                   	ret    
f01016e6:	8d 76 00             	lea    0x0(%esi),%esi
f01016e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01016f0:	31 ff                	xor    %edi,%edi
f01016f2:	31 c0                	xor    %eax,%eax
f01016f4:	89 fa                	mov    %edi,%edx
f01016f6:	83 c4 1c             	add    $0x1c,%esp
f01016f9:	5b                   	pop    %ebx
f01016fa:	5e                   	pop    %esi
f01016fb:	5f                   	pop    %edi
f01016fc:	5d                   	pop    %ebp
f01016fd:	c3                   	ret    
f01016fe:	66 90                	xchg   %ax,%ax
f0101700:	31 ff                	xor    %edi,%edi
f0101702:	89 e8                	mov    %ebp,%eax
f0101704:	89 f2                	mov    %esi,%edx
f0101706:	f7 f3                	div    %ebx
f0101708:	89 fa                	mov    %edi,%edx
f010170a:	83 c4 1c             	add    $0x1c,%esp
f010170d:	5b                   	pop    %ebx
f010170e:	5e                   	pop    %esi
f010170f:	5f                   	pop    %edi
f0101710:	5d                   	pop    %ebp
f0101711:	c3                   	ret    
f0101712:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101718:	39 f2                	cmp    %esi,%edx
f010171a:	72 06                	jb     f0101722 <__udivdi3+0x102>
f010171c:	31 c0                	xor    %eax,%eax
f010171e:	39 eb                	cmp    %ebp,%ebx
f0101720:	77 d2                	ja     f01016f4 <__udivdi3+0xd4>
f0101722:	b8 01 00 00 00       	mov    $0x1,%eax
f0101727:	eb cb                	jmp    f01016f4 <__udivdi3+0xd4>
f0101729:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101730:	89 d8                	mov    %ebx,%eax
f0101732:	31 ff                	xor    %edi,%edi
f0101734:	eb be                	jmp    f01016f4 <__udivdi3+0xd4>
f0101736:	66 90                	xchg   %ax,%ax
f0101738:	66 90                	xchg   %ax,%ax
f010173a:	66 90                	xchg   %ax,%ax
f010173c:	66 90                	xchg   %ax,%ax
f010173e:	66 90                	xchg   %ax,%ax

f0101740 <__umoddi3>:
f0101740:	55                   	push   %ebp
f0101741:	57                   	push   %edi
f0101742:	56                   	push   %esi
f0101743:	53                   	push   %ebx
f0101744:	83 ec 1c             	sub    $0x1c,%esp
f0101747:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010174b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010174f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101753:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101757:	85 ed                	test   %ebp,%ebp
f0101759:	89 f0                	mov    %esi,%eax
f010175b:	89 da                	mov    %ebx,%edx
f010175d:	75 19                	jne    f0101778 <__umoddi3+0x38>
f010175f:	39 df                	cmp    %ebx,%edi
f0101761:	0f 86 b1 00 00 00    	jbe    f0101818 <__umoddi3+0xd8>
f0101767:	f7 f7                	div    %edi
f0101769:	89 d0                	mov    %edx,%eax
f010176b:	31 d2                	xor    %edx,%edx
f010176d:	83 c4 1c             	add    $0x1c,%esp
f0101770:	5b                   	pop    %ebx
f0101771:	5e                   	pop    %esi
f0101772:	5f                   	pop    %edi
f0101773:	5d                   	pop    %ebp
f0101774:	c3                   	ret    
f0101775:	8d 76 00             	lea    0x0(%esi),%esi
f0101778:	39 dd                	cmp    %ebx,%ebp
f010177a:	77 f1                	ja     f010176d <__umoddi3+0x2d>
f010177c:	0f bd cd             	bsr    %ebp,%ecx
f010177f:	83 f1 1f             	xor    $0x1f,%ecx
f0101782:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101786:	0f 84 b4 00 00 00    	je     f0101840 <__umoddi3+0x100>
f010178c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101791:	89 c2                	mov    %eax,%edx
f0101793:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101797:	29 c2                	sub    %eax,%edx
f0101799:	89 c1                	mov    %eax,%ecx
f010179b:	89 f8                	mov    %edi,%eax
f010179d:	d3 e5                	shl    %cl,%ebp
f010179f:	89 d1                	mov    %edx,%ecx
f01017a1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01017a5:	d3 e8                	shr    %cl,%eax
f01017a7:	09 c5                	or     %eax,%ebp
f01017a9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01017ad:	89 c1                	mov    %eax,%ecx
f01017af:	d3 e7                	shl    %cl,%edi
f01017b1:	89 d1                	mov    %edx,%ecx
f01017b3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017b7:	89 df                	mov    %ebx,%edi
f01017b9:	d3 ef                	shr    %cl,%edi
f01017bb:	89 c1                	mov    %eax,%ecx
f01017bd:	89 f0                	mov    %esi,%eax
f01017bf:	d3 e3                	shl    %cl,%ebx
f01017c1:	89 d1                	mov    %edx,%ecx
f01017c3:	89 fa                	mov    %edi,%edx
f01017c5:	d3 e8                	shr    %cl,%eax
f01017c7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017cc:	09 d8                	or     %ebx,%eax
f01017ce:	f7 f5                	div    %ebp
f01017d0:	d3 e6                	shl    %cl,%esi
f01017d2:	89 d1                	mov    %edx,%ecx
f01017d4:	f7 64 24 08          	mull   0x8(%esp)
f01017d8:	39 d1                	cmp    %edx,%ecx
f01017da:	89 c3                	mov    %eax,%ebx
f01017dc:	89 d7                	mov    %edx,%edi
f01017de:	72 06                	jb     f01017e6 <__umoddi3+0xa6>
f01017e0:	75 0e                	jne    f01017f0 <__umoddi3+0xb0>
f01017e2:	39 c6                	cmp    %eax,%esi
f01017e4:	73 0a                	jae    f01017f0 <__umoddi3+0xb0>
f01017e6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01017ea:	19 ea                	sbb    %ebp,%edx
f01017ec:	89 d7                	mov    %edx,%edi
f01017ee:	89 c3                	mov    %eax,%ebx
f01017f0:	89 ca                	mov    %ecx,%edx
f01017f2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01017f7:	29 de                	sub    %ebx,%esi
f01017f9:	19 fa                	sbb    %edi,%edx
f01017fb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01017ff:	89 d0                	mov    %edx,%eax
f0101801:	d3 e0                	shl    %cl,%eax
f0101803:	89 d9                	mov    %ebx,%ecx
f0101805:	d3 ee                	shr    %cl,%esi
f0101807:	d3 ea                	shr    %cl,%edx
f0101809:	09 f0                	or     %esi,%eax
f010180b:	83 c4 1c             	add    $0x1c,%esp
f010180e:	5b                   	pop    %ebx
f010180f:	5e                   	pop    %esi
f0101810:	5f                   	pop    %edi
f0101811:	5d                   	pop    %ebp
f0101812:	c3                   	ret    
f0101813:	90                   	nop
f0101814:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101818:	85 ff                	test   %edi,%edi
f010181a:	89 f9                	mov    %edi,%ecx
f010181c:	75 0b                	jne    f0101829 <__umoddi3+0xe9>
f010181e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101823:	31 d2                	xor    %edx,%edx
f0101825:	f7 f7                	div    %edi
f0101827:	89 c1                	mov    %eax,%ecx
f0101829:	89 d8                	mov    %ebx,%eax
f010182b:	31 d2                	xor    %edx,%edx
f010182d:	f7 f1                	div    %ecx
f010182f:	89 f0                	mov    %esi,%eax
f0101831:	f7 f1                	div    %ecx
f0101833:	e9 31 ff ff ff       	jmp    f0101769 <__umoddi3+0x29>
f0101838:	90                   	nop
f0101839:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101840:	39 dd                	cmp    %ebx,%ebp
f0101842:	72 08                	jb     f010184c <__umoddi3+0x10c>
f0101844:	39 f7                	cmp    %esi,%edi
f0101846:	0f 87 21 ff ff ff    	ja     f010176d <__umoddi3+0x2d>
f010184c:	89 da                	mov    %ebx,%edx
f010184e:	89 f0                	mov    %esi,%eax
f0101850:	29 f8                	sub    %edi,%eax
f0101852:	19 ea                	sbb    %ebp,%edx
f0101854:	e9 14 ff ff ff       	jmp    f010176d <__umoddi3+0x2d>
