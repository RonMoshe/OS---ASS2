
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	97013103          	ld	sp,-1680(sp) # 80008970 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	1ac78793          	addi	a5,a5,428 # 80006210 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	b44080e7          	jalr	-1212(ra) # 80001c70 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	744080e7          	jalr	1860(ra) # 80001908 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	eae080e7          	jalr	-338(ra) # 80002082 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	a0a080e7          	jalr	-1526(ra) # 80001c1a <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	9d4080e7          	jalr	-1580(ra) # 80001cc6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	446080e7          	jalr	1094(ra) # 8000288c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	8b078793          	addi	a5,a5,-1872 # 80021d28 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	fec080e7          	jalr	-20(ra) # 8000288c <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	756080e7          	jalr	1878(ra) # 80002082 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	d66080e7          	jalr	-666(ra) # 800018e4 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	d34080e7          	jalr	-716(ra) # 800018e4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	d28080e7          	jalr	-728(ra) # 800018e4 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	d10080e7          	jalr	-752(ra) # 800018e4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	cd0080e7          	jalr	-816(ra) # 800018e4 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ca4080e7          	jalr	-860(ra) # 800018e4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	a3e080e7          	jalr	-1474(ra) # 800018d4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	a22080e7          	jalr	-1502(ra) # 800018d4 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	ddc080e7          	jalr	-548(ra) # 80002cb0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	374080e7          	jalr	884(ra) # 80006250 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	2ba080e7          	jalr	698(ra) # 8000219e <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	f82080e7          	jalr	-126(ra) # 80001ec6 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	d3c080e7          	jalr	-708(ra) # 80002c88 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	d5c080e7          	jalr	-676(ra) # 80002cb0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	2de080e7          	jalr	734(ra) # 8000623a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	2ec080e7          	jalr	748(ra) # 80006250 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	4d0080e7          	jalr	1232(ra) # 8000343c <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	b60080e7          	jalr	-1184(ra) # 80003ad4 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	b0a080e7          	jalr	-1270(ra) # 80004a86 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	3ee080e7          	jalr	1006(ra) # 80006372 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	5da080e7          	jalr	1498(ra) # 80002566 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	07448493          	addi	s1,s1,116 # 800118c8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	25aa0a13          	addi	s4,s4,602 # 80017ac8 <cpus_lock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	18848493          	addi	s1,s1,392
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018d4:	1141                	addi	sp,sp,-16
    800018d6:	e422                	sd	s0,8(sp)
    800018d8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018da:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018dc:	2501                	sext.w	a0,a0
    800018de:	6422                	ld	s0,8(sp)
    800018e0:	0141                	addi	sp,sp,16
    800018e2:	8082                	ret

00000000800018e4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800018e4:	1141                	addi	sp,sp,-16
    800018e6:	e422                	sd	s0,8(sp)
    800018e8:	0800                	addi	s0,sp,16
    800018ea:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018ec:	0007851b          	sext.w	a0,a5
    800018f0:	00451793          	slli	a5,a0,0x4
    800018f4:	97aa                	add	a5,a5,a0
    800018f6:	078e                	slli	a5,a5,0x3
  return c;
}
    800018f8:	00010517          	auipc	a0,0x10
    800018fc:	9a850513          	addi	a0,a0,-1624 # 800112a0 <cpus>
    80001900:	953e                	add	a0,a0,a5
    80001902:	6422                	ld	s0,8(sp)
    80001904:	0141                	addi	sp,sp,16
    80001906:	8082                	ret

0000000080001908 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001908:	1101                	addi	sp,sp,-32
    8000190a:	ec06                	sd	ra,24(sp)
    8000190c:	e822                	sd	s0,16(sp)
    8000190e:	e426                	sd	s1,8(sp)
    80001910:	1000                	addi	s0,sp,32
  push_off();
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	286080e7          	jalr	646(ra) # 80000b98 <push_off>
    8000191a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000191c:	0007871b          	sext.w	a4,a5
    80001920:	00471793          	slli	a5,a4,0x4
    80001924:	97ba                	add	a5,a5,a4
    80001926:	078e                	slli	a5,a5,0x3
    80001928:	00010717          	auipc	a4,0x10
    8000192c:	97870713          	addi	a4,a4,-1672 # 800112a0 <cpus>
    80001930:	97ba                	add	a5,a5,a4
    80001932:	6384                	ld	s1,0(a5)
  pop_off();
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	304080e7          	jalr	772(ra) # 80000c38 <pop_off>
  return p;
}
    8000193c:	8526                	mv	a0,s1
    8000193e:	60e2                	ld	ra,24(sp)
    80001940:	6442                	ld	s0,16(sp)
    80001942:	64a2                	ld	s1,8(sp)
    80001944:	6105                	addi	sp,sp,32
    80001946:	8082                	ret

0000000080001948 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001948:	1141                	addi	sp,sp,-16
    8000194a:	e406                	sd	ra,8(sp)
    8000194c:	e022                	sd	s0,0(sp)
    8000194e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001950:	00000097          	auipc	ra,0x0
    80001954:	fb8080e7          	jalr	-72(ra) # 80001908 <myproc>
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	340080e7          	jalr	832(ra) # 80000c98 <release>

  if (first) {
    80001960:	00007797          	auipc	a5,0x7
    80001964:	fc07a783          	lw	a5,-64(a5) # 80008920 <first.1716>
    80001968:	eb89                	bnez	a5,8000197a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000196a:	00001097          	auipc	ra,0x1
    8000196e:	35e080e7          	jalr	862(ra) # 80002cc8 <usertrapret>
}
    80001972:	60a2                	ld	ra,8(sp)
    80001974:	6402                	ld	s0,0(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret
    first = 0;
    8000197a:	00007797          	auipc	a5,0x7
    8000197e:	fa07a323          	sw	zero,-90(a5) # 80008920 <first.1716>
    fsinit(ROOTDEV);
    80001982:	4505                	li	a0,1
    80001984:	00002097          	auipc	ra,0x2
    80001988:	0d0080e7          	jalr	208(ra) # 80003a54 <fsinit>
    8000198c:	bff9                	j	8000196a <forkret+0x22>

000000008000198e <allocpid>:
{
    8000198e:	1101                	addi	sp,sp,-32
    80001990:	ec06                	sd	ra,24(sp)
    80001992:	e822                	sd	s0,16(sp)
    80001994:	e426                	sd	s1,8(sp)
    80001996:	e04a                	sd	s2,0(sp)
    80001998:	1000                	addi	s0,sp,32
    expected = nextpid;
    8000199a:	00007917          	auipc	s2,0x7
    8000199e:	f8a90913          	addi	s2,s2,-118 # 80008924 <nextpid>
    800019a2:	00092483          	lw	s1,0(s2)
    800019a6:	2481                	sext.w	s1,s1
    new_val = nextpid + 1;
    800019a8:	00092603          	lw	a2,0(s2)
  } while (cas(&nextpid, expected, new_val));
    800019ac:	2605                	addiw	a2,a2,1
    800019ae:	85a6                	mv	a1,s1
    800019b0:	854a                	mv	a0,s2
    800019b2:	00005097          	auipc	ra,0x5
    800019b6:	ea4080e7          	jalr	-348(ra) # 80006856 <cas>
    800019ba:	f565                	bnez	a0,800019a2 <allocpid+0x14>
}
    800019bc:	8526                	mv	a0,s1
    800019be:	60e2                	ld	ra,24(sp)
    800019c0:	6442                	ld	s0,16(sp)
    800019c2:	64a2                	ld	s1,8(sp)
    800019c4:	6902                	ld	s2,0(sp)
    800019c6:	6105                	addi	sp,sp,32
    800019c8:	8082                	ret

00000000800019ca <proc_pagetable>:
{
    800019ca:	1101                	addi	sp,sp,-32
    800019cc:	ec06                	sd	ra,24(sp)
    800019ce:	e822                	sd	s0,16(sp)
    800019d0:	e426                	sd	s1,8(sp)
    800019d2:	e04a                	sd	s2,0(sp)
    800019d4:	1000                	addi	s0,sp,32
    800019d6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019d8:	00000097          	auipc	ra,0x0
    800019dc:	962080e7          	jalr	-1694(ra) # 8000133a <uvmcreate>
    800019e0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019e2:	c121                	beqz	a0,80001a22 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019e4:	4729                	li	a4,10
    800019e6:	00005697          	auipc	a3,0x5
    800019ea:	61a68693          	addi	a3,a3,1562 # 80007000 <_trampoline>
    800019ee:	6605                	lui	a2,0x1
    800019f0:	040005b7          	lui	a1,0x4000
    800019f4:	15fd                	addi	a1,a1,-1
    800019f6:	05b2                	slli	a1,a1,0xc
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	6b8080e7          	jalr	1720(ra) # 800010b0 <mappages>
    80001a00:	02054863          	bltz	a0,80001a30 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a04:	4719                	li	a4,6
    80001a06:	07893683          	ld	a3,120(s2)
    80001a0a:	6605                	lui	a2,0x1
    80001a0c:	020005b7          	lui	a1,0x2000
    80001a10:	15fd                	addi	a1,a1,-1
    80001a12:	05b6                	slli	a1,a1,0xd
    80001a14:	8526                	mv	a0,s1
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	69a080e7          	jalr	1690(ra) # 800010b0 <mappages>
    80001a1e:	02054163          	bltz	a0,80001a40 <proc_pagetable+0x76>
}
    80001a22:	8526                	mv	a0,s1
    80001a24:	60e2                	ld	ra,24(sp)
    80001a26:	6442                	ld	s0,16(sp)
    80001a28:	64a2                	ld	s1,8(sp)
    80001a2a:	6902                	ld	s2,0(sp)
    80001a2c:	6105                	addi	sp,sp,32
    80001a2e:	8082                	ret
    uvmfree(pagetable, 0);
    80001a30:	4581                	li	a1,0
    80001a32:	8526                	mv	a0,s1
    80001a34:	00000097          	auipc	ra,0x0
    80001a38:	b02080e7          	jalr	-1278(ra) # 80001536 <uvmfree>
    return 0;
    80001a3c:	4481                	li	s1,0
    80001a3e:	b7d5                	j	80001a22 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a40:	4681                	li	a3,0
    80001a42:	4605                	li	a2,1
    80001a44:	040005b7          	lui	a1,0x4000
    80001a48:	15fd                	addi	a1,a1,-1
    80001a4a:	05b2                	slli	a1,a1,0xc
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	00000097          	auipc	ra,0x0
    80001a52:	828080e7          	jalr	-2008(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a56:	4581                	li	a1,0
    80001a58:	8526                	mv	a0,s1
    80001a5a:	00000097          	auipc	ra,0x0
    80001a5e:	adc080e7          	jalr	-1316(ra) # 80001536 <uvmfree>
    return 0;
    80001a62:	4481                	li	s1,0
    80001a64:	bf7d                	j	80001a22 <proc_pagetable+0x58>

0000000080001a66 <proc_freepagetable>:
{
    80001a66:	1101                	addi	sp,sp,-32
    80001a68:	ec06                	sd	ra,24(sp)
    80001a6a:	e822                	sd	s0,16(sp)
    80001a6c:	e426                	sd	s1,8(sp)
    80001a6e:	e04a                	sd	s2,0(sp)
    80001a70:	1000                	addi	s0,sp,32
    80001a72:	84aa                	mv	s1,a0
    80001a74:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a76:	4681                	li	a3,0
    80001a78:	4605                	li	a2,1
    80001a7a:	040005b7          	lui	a1,0x4000
    80001a7e:	15fd                	addi	a1,a1,-1
    80001a80:	05b2                	slli	a1,a1,0xc
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	7f4080e7          	jalr	2036(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a8a:	4681                	li	a3,0
    80001a8c:	4605                	li	a2,1
    80001a8e:	020005b7          	lui	a1,0x2000
    80001a92:	15fd                	addi	a1,a1,-1
    80001a94:	05b6                	slli	a1,a1,0xd
    80001a96:	8526                	mv	a0,s1
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	7de080e7          	jalr	2014(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001aa0:	85ca                	mv	a1,s2
    80001aa2:	8526                	mv	a0,s1
    80001aa4:	00000097          	auipc	ra,0x0
    80001aa8:	a92080e7          	jalr	-1390(ra) # 80001536 <uvmfree>
}
    80001aac:	60e2                	ld	ra,24(sp)
    80001aae:	6442                	ld	s0,16(sp)
    80001ab0:	64a2                	ld	s1,8(sp)
    80001ab2:	6902                	ld	s2,0(sp)
    80001ab4:	6105                	addi	sp,sp,32
    80001ab6:	8082                	ret

0000000080001ab8 <growproc>:
{
    80001ab8:	1101                	addi	sp,sp,-32
    80001aba:	ec06                	sd	ra,24(sp)
    80001abc:	e822                	sd	s0,16(sp)
    80001abe:	e426                	sd	s1,8(sp)
    80001ac0:	e04a                	sd	s2,0(sp)
    80001ac2:	1000                	addi	s0,sp,32
    80001ac4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ac6:	00000097          	auipc	ra,0x0
    80001aca:	e42080e7          	jalr	-446(ra) # 80001908 <myproc>
    80001ace:	892a                	mv	s2,a0
  sz = p->sz;
    80001ad0:	752c                	ld	a1,104(a0)
    80001ad2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ad6:	00904f63          	bgtz	s1,80001af4 <growproc+0x3c>
  } else if(n < 0){
    80001ada:	0204cc63          	bltz	s1,80001b12 <growproc+0x5a>
  p->sz = sz;
    80001ade:	1602                	slli	a2,a2,0x20
    80001ae0:	9201                	srli	a2,a2,0x20
    80001ae2:	06c93423          	sd	a2,104(s2)
  return 0;
    80001ae6:	4501                	li	a0,0
}
    80001ae8:	60e2                	ld	ra,24(sp)
    80001aea:	6442                	ld	s0,16(sp)
    80001aec:	64a2                	ld	s1,8(sp)
    80001aee:	6902                	ld	s2,0(sp)
    80001af0:	6105                	addi	sp,sp,32
    80001af2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001af4:	9e25                	addw	a2,a2,s1
    80001af6:	1602                	slli	a2,a2,0x20
    80001af8:	9201                	srli	a2,a2,0x20
    80001afa:	1582                	slli	a1,a1,0x20
    80001afc:	9181                	srli	a1,a1,0x20
    80001afe:	7928                	ld	a0,112(a0)
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	922080e7          	jalr	-1758(ra) # 80001422 <uvmalloc>
    80001b08:	0005061b          	sext.w	a2,a0
    80001b0c:	fa69                	bnez	a2,80001ade <growproc+0x26>
      return -1;
    80001b0e:	557d                	li	a0,-1
    80001b10:	bfe1                	j	80001ae8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b12:	9e25                	addw	a2,a2,s1
    80001b14:	1602                	slli	a2,a2,0x20
    80001b16:	9201                	srli	a2,a2,0x20
    80001b18:	1582                	slli	a1,a1,0x20
    80001b1a:	9181                	srli	a1,a1,0x20
    80001b1c:	7928                	ld	a0,112(a0)
    80001b1e:	00000097          	auipc	ra,0x0
    80001b22:	8bc080e7          	jalr	-1860(ra) # 800013da <uvmdealloc>
    80001b26:	0005061b          	sext.w	a2,a0
    80001b2a:	bf55                	j	80001ade <growproc+0x26>

0000000080001b2c <sched>:
{
    80001b2c:	7179                	addi	sp,sp,-48
    80001b2e:	f406                	sd	ra,40(sp)
    80001b30:	f022                	sd	s0,32(sp)
    80001b32:	ec26                	sd	s1,24(sp)
    80001b34:	e84a                	sd	s2,16(sp)
    80001b36:	e44e                	sd	s3,8(sp)
    80001b38:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001b3a:	00000097          	auipc	ra,0x0
    80001b3e:	dce080e7          	jalr	-562(ra) # 80001908 <myproc>
    80001b42:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	026080e7          	jalr	38(ra) # 80000b6a <holding>
    80001b4c:	c559                	beqz	a0,80001bda <sched+0xae>
    80001b4e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001b50:	0007871b          	sext.w	a4,a5
    80001b54:	00471793          	slli	a5,a4,0x4
    80001b58:	97ba                	add	a5,a5,a4
    80001b5a:	078e                	slli	a5,a5,0x3
    80001b5c:	0000f717          	auipc	a4,0xf
    80001b60:	74470713          	addi	a4,a4,1860 # 800112a0 <cpus>
    80001b64:	97ba                	add	a5,a5,a4
    80001b66:	5fb8                	lw	a4,120(a5)
    80001b68:	4785                	li	a5,1
    80001b6a:	08f71063          	bne	a4,a5,80001bea <sched+0xbe>
  if(p->state == RUNNING)
    80001b6e:	4c98                	lw	a4,24(s1)
    80001b70:	4791                	li	a5,4
    80001b72:	08f70463          	beq	a4,a5,80001bfa <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b76:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001b7a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001b7c:	e7d9                	bnez	a5,80001c0a <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b7e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001b80:	0000f917          	auipc	s2,0xf
    80001b84:	72090913          	addi	s2,s2,1824 # 800112a0 <cpus>
    80001b88:	0007871b          	sext.w	a4,a5
    80001b8c:	00471793          	slli	a5,a4,0x4
    80001b90:	97ba                	add	a5,a5,a4
    80001b92:	078e                	slli	a5,a5,0x3
    80001b94:	97ca                	add	a5,a5,s2
    80001b96:	07c7a983          	lw	s3,124(a5)
    80001b9a:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80001b9c:	0005879b          	sext.w	a5,a1
    80001ba0:	00479593          	slli	a1,a5,0x4
    80001ba4:	95be                	add	a1,a1,a5
    80001ba6:	058e                	slli	a1,a1,0x3
    80001ba8:	05a1                	addi	a1,a1,8
    80001baa:	95ca                	add	a1,a1,s2
    80001bac:	08048513          	addi	a0,s1,128
    80001bb0:	00001097          	auipc	ra,0x1
    80001bb4:	06e080e7          	jalr	110(ra) # 80002c1e <swtch>
    80001bb8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001bba:	0007871b          	sext.w	a4,a5
    80001bbe:	00471793          	slli	a5,a4,0x4
    80001bc2:	97ba                	add	a5,a5,a4
    80001bc4:	078e                	slli	a5,a5,0x3
    80001bc6:	993e                	add	s2,s2,a5
    80001bc8:	07392e23          	sw	s3,124(s2)
}
    80001bcc:	70a2                	ld	ra,40(sp)
    80001bce:	7402                	ld	s0,32(sp)
    80001bd0:	64e2                	ld	s1,24(sp)
    80001bd2:	6942                	ld	s2,16(sp)
    80001bd4:	69a2                	ld	s3,8(sp)
    80001bd6:	6145                	addi	sp,sp,48
    80001bd8:	8082                	ret
    panic("sched p->lock");
    80001bda:	00006517          	auipc	a0,0x6
    80001bde:	60650513          	addi	a0,a0,1542 # 800081e0 <digits+0x1a0>
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	95c080e7          	jalr	-1700(ra) # 8000053e <panic>
    panic("sched locks");
    80001bea:	00006517          	auipc	a0,0x6
    80001bee:	60650513          	addi	a0,a0,1542 # 800081f0 <digits+0x1b0>
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	94c080e7          	jalr	-1716(ra) # 8000053e <panic>
    panic("sched running");
    80001bfa:	00006517          	auipc	a0,0x6
    80001bfe:	60650513          	addi	a0,a0,1542 # 80008200 <digits+0x1c0>
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	93c080e7          	jalr	-1732(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001c0a:	00006517          	auipc	a0,0x6
    80001c0e:	60650513          	addi	a0,a0,1542 # 80008210 <digits+0x1d0>
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	92c080e7          	jalr	-1748(ra) # 8000053e <panic>

0000000080001c1a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001c1a:	7179                	addi	sp,sp,-48
    80001c1c:	f406                	sd	ra,40(sp)
    80001c1e:	f022                	sd	s0,32(sp)
    80001c20:	ec26                	sd	s1,24(sp)
    80001c22:	e84a                	sd	s2,16(sp)
    80001c24:	e44e                	sd	s3,8(sp)
    80001c26:	e052                	sd	s4,0(sp)
    80001c28:	1800                	addi	s0,sp,48
    80001c2a:	84aa                	mv	s1,a0
    80001c2c:	892e                	mv	s2,a1
    80001c2e:	89b2                	mv	s3,a2
    80001c30:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	cd6080e7          	jalr	-810(ra) # 80001908 <myproc>
  if(user_dst){
    80001c3a:	c08d                	beqz	s1,80001c5c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80001c3c:	86d2                	mv	a3,s4
    80001c3e:	864e                	mv	a2,s3
    80001c40:	85ca                	mv	a1,s2
    80001c42:	7928                	ld	a0,112(a0)
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	a2e080e7          	jalr	-1490(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80001c4c:	70a2                	ld	ra,40(sp)
    80001c4e:	7402                	ld	s0,32(sp)
    80001c50:	64e2                	ld	s1,24(sp)
    80001c52:	6942                	ld	s2,16(sp)
    80001c54:	69a2                	ld	s3,8(sp)
    80001c56:	6a02                	ld	s4,0(sp)
    80001c58:	6145                	addi	sp,sp,48
    80001c5a:	8082                	ret
    memmove((char *)dst, src, len);
    80001c5c:	000a061b          	sext.w	a2,s4
    80001c60:	85ce                	mv	a1,s3
    80001c62:	854a                	mv	a0,s2
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	0dc080e7          	jalr	220(ra) # 80000d40 <memmove>
    return 0;
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	bff9                	j	80001c4c <either_copyout+0x32>

0000000080001c70 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80001c70:	7179                	addi	sp,sp,-48
    80001c72:	f406                	sd	ra,40(sp)
    80001c74:	f022                	sd	s0,32(sp)
    80001c76:	ec26                	sd	s1,24(sp)
    80001c78:	e84a                	sd	s2,16(sp)
    80001c7a:	e44e                	sd	s3,8(sp)
    80001c7c:	e052                	sd	s4,0(sp)
    80001c7e:	1800                	addi	s0,sp,48
    80001c80:	892a                	mv	s2,a0
    80001c82:	84ae                	mv	s1,a1
    80001c84:	89b2                	mv	s3,a2
    80001c86:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	c80080e7          	jalr	-896(ra) # 80001908 <myproc>
  if(user_src){
    80001c90:	c08d                	beqz	s1,80001cb2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80001c92:	86d2                	mv	a3,s4
    80001c94:	864e                	mv	a2,s3
    80001c96:	85ca                	mv	a1,s2
    80001c98:	7928                	ld	a0,112(a0)
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	a64080e7          	jalr	-1436(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80001ca2:	70a2                	ld	ra,40(sp)
    80001ca4:	7402                	ld	s0,32(sp)
    80001ca6:	64e2                	ld	s1,24(sp)
    80001ca8:	6942                	ld	s2,16(sp)
    80001caa:	69a2                	ld	s3,8(sp)
    80001cac:	6a02                	ld	s4,0(sp)
    80001cae:	6145                	addi	sp,sp,48
    80001cb0:	8082                	ret
    memmove(dst, (char*)src, len);
    80001cb2:	000a061b          	sext.w	a2,s4
    80001cb6:	85ce                	mv	a1,s3
    80001cb8:	854a                	mv	a0,s2
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	086080e7          	jalr	134(ra) # 80000d40 <memmove>
    return 0;
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	bff9                	j	80001ca2 <either_copyin+0x32>

0000000080001cc6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80001cc6:	715d                	addi	sp,sp,-80
    80001cc8:	e486                	sd	ra,72(sp)
    80001cca:	e0a2                	sd	s0,64(sp)
    80001ccc:	fc26                	sd	s1,56(sp)
    80001cce:	f84a                	sd	s2,48(sp)
    80001cd0:	f44e                	sd	s3,40(sp)
    80001cd2:	f052                	sd	s4,32(sp)
    80001cd4:	ec56                	sd	s5,24(sp)
    80001cd6:	e85a                	sd	s6,16(sp)
    80001cd8:	e45e                	sd	s7,8(sp)
    80001cda:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80001cdc:	00006517          	auipc	a0,0x6
    80001ce0:	3ec50513          	addi	a0,a0,1004 # 800080c8 <digits+0x88>
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	8a4080e7          	jalr	-1884(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001cec:	00010497          	auipc	s1,0x10
    80001cf0:	d5448493          	addi	s1,s1,-684 # 80011a40 <proc+0x178>
    80001cf4:	00016917          	auipc	s2,0x16
    80001cf8:	f4c90913          	addi	s2,s2,-180 # 80017c40 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001cfc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80001cfe:	00006997          	auipc	s3,0x6
    80001d02:	52a98993          	addi	s3,s3,1322 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    80001d06:	00006a97          	auipc	s5,0x6
    80001d0a:	52aa8a93          	addi	s5,s5,1322 # 80008230 <digits+0x1f0>
    printf("\n");
    80001d0e:	00006a17          	auipc	s4,0x6
    80001d12:	3baa0a13          	addi	s4,s4,954 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d16:	00006b97          	auipc	s7,0x6
    80001d1a:	662b8b93          	addi	s7,s7,1634 # 80008378 <states.1755>
    80001d1e:	a00d                	j	80001d40 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80001d20:	eb86a583          	lw	a1,-328(a3)
    80001d24:	8556                	mv	a0,s5
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	862080e7          	jalr	-1950(ra) # 80000588 <printf>
    printf("\n");
    80001d2e:	8552                	mv	a0,s4
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	858080e7          	jalr	-1960(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001d38:	18848493          	addi	s1,s1,392
    80001d3c:	03248163          	beq	s1,s2,80001d5e <procdump+0x98>
    if(p->state == UNUSED)
    80001d40:	86a6                	mv	a3,s1
    80001d42:	ea04a783          	lw	a5,-352(s1)
    80001d46:	dbed                	beqz	a5,80001d38 <procdump+0x72>
      state = "???";
    80001d48:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d4a:	fcfb6be3          	bltu	s6,a5,80001d20 <procdump+0x5a>
    80001d4e:	1782                	slli	a5,a5,0x20
    80001d50:	9381                	srli	a5,a5,0x20
    80001d52:	078e                	slli	a5,a5,0x3
    80001d54:	97de                	add	a5,a5,s7
    80001d56:	6390                	ld	a2,0(a5)
    80001d58:	f661                	bnez	a2,80001d20 <procdump+0x5a>
      state = "???";
    80001d5a:	864e                	mv	a2,s3
    80001d5c:	b7d1                	j	80001d20 <procdump+0x5a>
  }
}
    80001d5e:	60a6                	ld	ra,72(sp)
    80001d60:	6406                	ld	s0,64(sp)
    80001d62:	74e2                	ld	s1,56(sp)
    80001d64:	7942                	ld	s2,48(sp)
    80001d66:	79a2                	ld	s3,40(sp)
    80001d68:	7a02                	ld	s4,32(sp)
    80001d6a:	6ae2                	ld	s5,24(sp)
    80001d6c:	6b42                	ld	s6,16(sp)
    80001d6e:	6ba2                	ld	s7,8(sp)
    80001d70:	6161                	addi	sp,sp,80
    80001d72:	8082                	ret

0000000080001d74 <init_list>:

void 
init_list(struct sentinel* list, char* list_name)
{
    80001d74:	1141                	addi	sp,sp,-16
    80001d76:	e406                	sd	ra,8(sp)
    80001d78:	e022                	sd	s0,0(sp)
    80001d7a:	0800                	addi	s0,sp,16
  // printf("enter init_list\n");
  list->name = list_name;
    80001d7c:	f10c                	sd	a1,32(a0)
  list->next = END;
    80001d7e:	57fd                	li	a5,-1
    80001d80:	c11c                	sw	a5,0(a0)
  initlock(&list->lock, list_name);
    80001d82:	0521                	addi	a0,a0,8
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	dd0080e7          	jalr	-560(ra) # 80000b54 <initlock>
}
    80001d8c:	60a2                	ld	ra,8(sp)
    80001d8e:	6402                	ld	s0,0(sp)
    80001d90:	0141                	addi	sp,sp,16
    80001d92:	8082                	ret

0000000080001d94 <enqueue>:

void 
enqueue(struct sentinel* list, process_entry_t pentry)
{
    80001d94:	711d                	addi	sp,sp,-96
    80001d96:	ec86                	sd	ra,88(sp)
    80001d98:	e8a2                	sd	s0,80(sp)
    80001d9a:	e4a6                	sd	s1,72(sp)
    80001d9c:	e0ca                	sd	s2,64(sp)
    80001d9e:	fc4e                	sd	s3,56(sp)
    80001da0:	f852                	sd	s4,48(sp)
    80001da2:	f456                	sd	s5,40(sp)
    80001da4:	f05a                	sd	s6,32(sp)
    80001da6:	ec5e                	sd	s7,24(sp)
    80001da8:	e862                	sd	s8,16(sp)
    80001daa:	e466                	sd	s9,8(sp)
    80001dac:	1080                	addi	s0,sp,96
    80001dae:	892a                	mv	s2,a0
    80001db0:	8b2e                	mv	s6,a1
  process_entry_t prev, curr;
  struct spinlock *prev_lock, *curr_lock, *p_lock;
  struct proc* p;

  // first element in the list
  prev = list->next; 
    80001db2:	00052a83          	lw	s5,0(a0)
  prev_lock = &list->lock; 
    80001db6:	00850493          	addi	s1,a0,8
  // inserted process
  p = &proc[pentry]; 
  p_lock = &p->list_lock;
    80001dba:	18800b93          	li	s7,392
    80001dbe:	03758bb3          	mul	s7,a1,s7
    80001dc2:	00010797          	auipc	a5,0x10
    80001dc6:	b3e78793          	addi	a5,a5,-1218 # 80011900 <proc+0x38>
    80001dca:	9bbe                	add	s7,s7,a5

  acquire(prev_lock);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	e16080e7          	jalr	-490(ra) # 80000be4 <acquire>
  if(prev == END) // empty list
    80001dd6:	57fd                	li	a5,-1
    80001dd8:	0afa8a63          	beq	s5,a5,80001e8c <enqueue+0xf8>
    release(prev_lock);
    return;
  }

  // Iterate over the list until prev is the last element
  curr = proc[prev].next;
    80001ddc:	18800793          	li	a5,392
    80001de0:	02fa8733          	mul	a4,s5,a5
    80001de4:	00010797          	auipc	a5,0x10
    80001de8:	ae478793          	addi	a5,a5,-1308 # 800118c8 <proc>
    80001dec:	97ba                	add	a5,a5,a4
    80001dee:	0347a983          	lw	s3,52(a5)
  while(curr != END)
    80001df2:	57fd                	li	a5,-1
    80001df4:	02f98f63          	beq	s3,a5,80001e32 <enqueue+0x9e>
  {
    curr_lock = &proc[curr].list_lock;
    80001df8:	18800c93          	li	s9,392
    80001dfc:	00010a17          	auipc	s4,0x10
    80001e00:	acca0a13          	addi	s4,s4,-1332 # 800118c8 <proc>
  while(curr != END)
    80001e04:	5c7d                	li	s8,-1
    curr_lock = &proc[curr].list_lock;
    80001e06:	8aa6                	mv	s5,s1
    80001e08:	03998933          	mul	s2,s3,s9
    80001e0c:	03890493          	addi	s1,s2,56
    80001e10:	94d2                	add	s1,s1,s4
    acquire(curr_lock); 
    80001e12:	8526                	mv	a0,s1
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	dd0080e7          	jalr	-560(ra) # 80000be4 <acquire>
    release(prev_lock);
    80001e1c:	8556                	mv	a0,s5
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	e7a080e7          	jalr	-390(ra) # 80000c98 <release>
    prev = curr;
    prev_lock = curr_lock;
    curr = proc[curr].next;
    80001e26:	8ace                	mv	s5,s3
    80001e28:	9952                	add	s2,s2,s4
    80001e2a:	03492983          	lw	s3,52(s2)
  while(curr != END)
    80001e2e:	fd899ce3          	bne	s3,s8,80001e06 <enqueue+0x72>
  }

  acquire(p_lock);
    80001e32:	855e                	mv	a0,s7
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	db0080e7          	jalr	-592(ra) # 80000be4 <acquire>
  // At this point we are holding both plock, prev_lock
  proc[prev].next = pentry;
    80001e3c:	00010797          	auipc	a5,0x10
    80001e40:	a8c78793          	addi	a5,a5,-1396 # 800118c8 <proc>
    80001e44:	18800593          	li	a1,392
    80001e48:	02ba8ab3          	mul	s5,s5,a1
    80001e4c:	9abe                	add	s5,s5,a5
    80001e4e:	036aaa23          	sw	s6,52(s5)
  p->next = END;
    80001e52:	02bb0b33          	mul	s6,s6,a1
    80001e56:	9b3e                	add	s6,s6,a5
    80001e58:	57fd                	li	a5,-1
    80001e5a:	02fb2a23          	sw	a5,52(s6) # 1034 <_entry-0x7fffefcc>
  release(p_lock);
    80001e5e:	855e                	mv	a0,s7
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e38080e7          	jalr	-456(ra) # 80000c98 <release>
  release(prev_lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
}
    80001e72:	60e6                	ld	ra,88(sp)
    80001e74:	6446                	ld	s0,80(sp)
    80001e76:	64a6                	ld	s1,72(sp)
    80001e78:	6906                	ld	s2,64(sp)
    80001e7a:	79e2                	ld	s3,56(sp)
    80001e7c:	7a42                	ld	s4,48(sp)
    80001e7e:	7aa2                	ld	s5,40(sp)
    80001e80:	7b02                	ld	s6,32(sp)
    80001e82:	6be2                	ld	s7,24(sp)
    80001e84:	6c42                	ld	s8,16(sp)
    80001e86:	6ca2                	ld	s9,8(sp)
    80001e88:	6125                	addi	sp,sp,96
    80001e8a:	8082                	ret
    list->next = pentry;
    80001e8c:	01692023          	sw	s6,0(s2)
    acquire(p_lock);
    80001e90:	855e                	mv	a0,s7
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d52080e7          	jalr	-686(ra) # 80000be4 <acquire>
    p->next = END;
    80001e9a:	18800793          	li	a5,392
    80001e9e:	02fb0b33          	mul	s6,s6,a5
    80001ea2:	00010797          	auipc	a5,0x10
    80001ea6:	a2678793          	addi	a5,a5,-1498 # 800118c8 <proc>
    80001eaa:	97da                	add	a5,a5,s6
    80001eac:	577d                	li	a4,-1
    80001eae:	dbd8                	sw	a4,52(a5)
    release(p_lock);
    80001eb0:	855e                	mv	a0,s7
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
    release(prev_lock);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	ddc080e7          	jalr	-548(ra) # 80000c98 <release>
    return;
    80001ec4:	b77d                	j	80001e72 <enqueue+0xde>

0000000080001ec6 <procinit>:
{
    80001ec6:	711d                	addi	sp,sp,-96
    80001ec8:	ec86                	sd	ra,88(sp)
    80001eca:	e8a2                	sd	s0,80(sp)
    80001ecc:	e4a6                	sd	s1,72(sp)
    80001ece:	e0ca                	sd	s2,64(sp)
    80001ed0:	fc4e                	sd	s3,56(sp)
    80001ed2:	f852                	sd	s4,48(sp)
    80001ed4:	f456                	sd	s5,40(sp)
    80001ed6:	f05a                	sd	s6,32(sp)
    80001ed8:	ec5e                	sd	s7,24(sp)
    80001eda:	e862                	sd	s8,16(sp)
    80001edc:	e466                	sd	s9,8(sp)
    80001ede:	1080                	addi	s0,sp,96
  initlock(&pid_lock, "nextpid");
    80001ee0:	00006597          	auipc	a1,0x6
    80001ee4:	36058593          	addi	a1,a1,864 # 80008240 <digits+0x200>
    80001ee8:	0000f517          	auipc	a0,0xf
    80001eec:	7f850513          	addi	a0,a0,2040 # 800116e0 <pid_lock>
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	c64080e7          	jalr	-924(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ef8:	00006597          	auipc	a1,0x6
    80001efc:	35058593          	addi	a1,a1,848 # 80008248 <digits+0x208>
    80001f00:	0000f517          	auipc	a0,0xf
    80001f04:	7f850513          	addi	a0,a0,2040 # 800116f8 <wait_lock>
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	c4c080e7          	jalr	-948(ra) # 80000b54 <initlock>
  init_list(&unused_list, "Unused List");
    80001f10:	00006597          	auipc	a1,0x6
    80001f14:	34858593          	addi	a1,a1,840 # 80008258 <digits+0x218>
    80001f18:	0000f517          	auipc	a0,0xf
    80001f1c:	7f850513          	addi	a0,a0,2040 # 80011710 <unused_list>
    80001f20:	00000097          	auipc	ra,0x0
    80001f24:	e54080e7          	jalr	-428(ra) # 80001d74 <init_list>
  init_list(&sleeping_list, "Sleeping List");
    80001f28:	00006597          	auipc	a1,0x6
    80001f2c:	34058593          	addi	a1,a1,832 # 80008268 <digits+0x228>
    80001f30:	00010517          	auipc	a0,0x10
    80001f34:	80850513          	addi	a0,a0,-2040 # 80011738 <sleeping_list>
    80001f38:	00000097          	auipc	ra,0x0
    80001f3c:	e3c080e7          	jalr	-452(ra) # 80001d74 <init_list>
  init_list(&zombie_list, "Zombie List");
    80001f40:	00006597          	auipc	a1,0x6
    80001f44:	33858593          	addi	a1,a1,824 # 80008278 <digits+0x238>
    80001f48:	00010517          	auipc	a0,0x10
    80001f4c:	81850513          	addi	a0,a0,-2024 # 80011760 <zombie_list>
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	e24080e7          	jalr	-476(ra) # 80001d74 <init_list>
  for(i = 0, p = proc; p < &proc[NPROC]; p++, i++) {
    80001f58:	4901                	li	s2,0
    80001f5a:	00010497          	auipc	s1,0x10
    80001f5e:	96e48493          	addi	s1,s1,-1682 # 800118c8 <proc>
      initlock(&p->lock, "proc");
    80001f62:	00006c97          	auipc	s9,0x6
    80001f66:	326c8c93          	addi	s9,s9,806 # 80008288 <digits+0x248>
      initlock(&p->list_lock, "proc list lock");
    80001f6a:	00006c17          	auipc	s8,0x6
    80001f6e:	326c0c13          	addi	s8,s8,806 # 80008290 <digits+0x250>
      p->kstack = KSTACK((int) (p - proc));
    80001f72:	8ba6                	mv	s7,s1
    80001f74:	00006b17          	auipc	s6,0x6
    80001f78:	08cb0b13          	addi	s6,s6,140 # 80008000 <etext>
    80001f7c:	040009b7          	lui	s3,0x4000
    80001f80:	19fd                	addi	s3,s3,-1
    80001f82:	09b2                	slli	s3,s3,0xc
      enqueue(&unused_list, i);
    80001f84:	0000fa97          	auipc	s5,0xf
    80001f88:	78ca8a93          	addi	s5,s5,1932 # 80011710 <unused_list>
  for(i = 0, p = proc; p < &proc[NPROC]; p++, i++) {
    80001f8c:	00016a17          	auipc	s4,0x16
    80001f90:	b3ca0a13          	addi	s4,s4,-1220 # 80017ac8 <cpus_lock>
      initlock(&p->lock, "proc");
    80001f94:	85e6                	mv	a1,s9
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	bbc080e7          	jalr	-1092(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "proc list lock");
    80001fa0:	85e2                	mv	a1,s8
    80001fa2:	03848513          	addi	a0,s1,56
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	bae080e7          	jalr	-1106(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001fae:	417487b3          	sub	a5,s1,s7
    80001fb2:	878d                	srai	a5,a5,0x3
    80001fb4:	000b3703          	ld	a4,0(s6)
    80001fb8:	02e787b3          	mul	a5,a5,a4
    80001fbc:	2785                	addiw	a5,a5,1
    80001fbe:	00d7979b          	slliw	a5,a5,0xd
    80001fc2:	40f987b3          	sub	a5,s3,a5
    80001fc6:	f0bc                	sd	a5,96(s1)
      enqueue(&unused_list, i);
    80001fc8:	85ca                	mv	a1,s2
    80001fca:	8556                	mv	a0,s5
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	dc8080e7          	jalr	-568(ra) # 80001d94 <enqueue>
  for(i = 0, p = proc; p < &proc[NPROC]; p++, i++) {
    80001fd4:	18848493          	addi	s1,s1,392
    80001fd8:	2905                	addiw	s2,s2,1
    80001fda:	fb449de3          	bne	s1,s4,80001f94 <procinit+0xce>
    80001fde:	00006917          	auipc	s2,0x6
    80001fe2:	3ca90913          	addi	s2,s2,970 # 800083a8 <cpu_runnable_list_names.1607>
    80001fe6:	0000f497          	auipc	s1,0xf
    80001fea:	7a248493          	addi	s1,s1,1954 # 80011788 <cpu_runnable_list>
    80001fee:	00010997          	auipc	s3,0x10
    80001ff2:	8da98993          	addi	s3,s3,-1830 # 800118c8 <proc>
    init_list(&cpu_runnable_list[i], cpu_runnable_list_names[i]);
    80001ff6:	00093583          	ld	a1,0(s2)
    80001ffa:	8526                	mv	a0,s1
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	d78080e7          	jalr	-648(ra) # 80001d74 <init_list>
  for(i = 0; i<NCPU; i++)
    80002004:	0921                	addi	s2,s2,8
    80002006:	02848493          	addi	s1,s1,40
    8000200a:	ff3496e3          	bne	s1,s3,80001ff6 <procinit+0x130>
}
    8000200e:	60e6                	ld	ra,88(sp)
    80002010:	6446                	ld	s0,80(sp)
    80002012:	64a6                	ld	s1,72(sp)
    80002014:	6906                	ld	s2,64(sp)
    80002016:	79e2                	ld	s3,56(sp)
    80002018:	7a42                	ld	s4,48(sp)
    8000201a:	7aa2                	ld	s5,40(sp)
    8000201c:	7b02                	ld	s6,32(sp)
    8000201e:	6be2                	ld	s7,24(sp)
    80002020:	6c42                	ld	s8,16(sp)
    80002022:	6ca2                	ld	s9,8(sp)
    80002024:	6125                	addi	sp,sp,96
    80002026:	8082                	ret

0000000080002028 <yield>:
{
    80002028:	1101                	addi	sp,sp,-32
    8000202a:	ec06                	sd	ra,24(sp)
    8000202c:	e822                	sd	s0,16(sp)
    8000202e:	e426                	sd	s1,8(sp)
    80002030:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	8d6080e7          	jalr	-1834(ra) # 80001908 <myproc>
    8000203a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	ba8080e7          	jalr	-1112(ra) # 80000be4 <acquire>
  enqueue(&cpu_runnable_list[p->affiliated_cpu], p->entry);
    80002044:	48a8                	lw	a0,80(s1)
    80002046:	00251793          	slli	a5,a0,0x2
    8000204a:	97aa                	add	a5,a5,a0
    8000204c:	078e                	slli	a5,a5,0x3
    8000204e:	48ec                	lw	a1,84(s1)
    80002050:	0000f517          	auipc	a0,0xf
    80002054:	73850513          	addi	a0,a0,1848 # 80011788 <cpu_runnable_list>
    80002058:	953e                	add	a0,a0,a5
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	d3a080e7          	jalr	-710(ra) # 80001d94 <enqueue>
  p->state = RUNNABLE;
    80002062:	478d                	li	a5,3
    80002064:	cc9c                	sw	a5,24(s1)
  sched();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	ac6080e7          	jalr	-1338(ra) # 80001b2c <sched>
  release(&p->lock);
    8000206e:	8526                	mv	a0,s1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c28080e7          	jalr	-984(ra) # 80000c98 <release>
}
    80002078:	60e2                	ld	ra,24(sp)
    8000207a:	6442                	ld	s0,16(sp)
    8000207c:	64a2                	ld	s1,8(sp)
    8000207e:	6105                	addi	sp,sp,32
    80002080:	8082                	ret

0000000080002082 <sleep>:
{
    80002082:	7179                	addi	sp,sp,-48
    80002084:	f406                	sd	ra,40(sp)
    80002086:	f022                	sd	s0,32(sp)
    80002088:	ec26                	sd	s1,24(sp)
    8000208a:	e84a                	sd	s2,16(sp)
    8000208c:	e44e                	sd	s3,8(sp)
    8000208e:	1800                	addi	s0,sp,48
    80002090:	89aa                	mv	s3,a0
    80002092:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	874080e7          	jalr	-1932(ra) # 80001908 <myproc>
    8000209c:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
  enqueue(&sleeping_list, p->entry);
    800020a6:	48ec                	lw	a1,84(s1)
    800020a8:	0000f517          	auipc	a0,0xf
    800020ac:	69050513          	addi	a0,a0,1680 # 80011738 <sleeping_list>
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	ce4080e7          	jalr	-796(ra) # 80001d94 <enqueue>
  p->state = SLEEPING;
    800020b8:	4789                	li	a5,2
    800020ba:	cc9c                	sw	a5,24(s1)
  p->chan = chan;
    800020bc:	0334b023          	sd	s3,32(s1)
  release(lk);
    800020c0:	854a                	mv	a0,s2
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	bd6080e7          	jalr	-1066(ra) # 80000c98 <release>
  sched();
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	a62080e7          	jalr	-1438(ra) # 80001b2c <sched>
  p->chan = 0;
    800020d2:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
  acquire(lk);
    800020e0:	854a                	mv	a0,s2
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
}
    800020ea:	70a2                	ld	ra,40(sp)
    800020ec:	7402                	ld	s0,32(sp)
    800020ee:	64e2                	ld	s1,24(sp)
    800020f0:	6942                	ld	s2,16(sp)
    800020f2:	69a2                	ld	s3,8(sp)
    800020f4:	6145                	addi	sp,sp,48
    800020f6:	8082                	ret

00000000800020f8 <dequeue>:

void 
dequeue(struct sentinel* list, process_entry_t* res)
{
    800020f8:	715d                	addi	sp,sp,-80
    800020fa:	e486                	sd	ra,72(sp)
    800020fc:	e0a2                	sd	s0,64(sp)
    800020fe:	fc26                	sd	s1,56(sp)
    80002100:	f84a                	sd	s2,48(sp)
    80002102:	f44e                	sd	s3,40(sp)
    80002104:	f052                	sd	s4,32(sp)
    80002106:	ec56                	sd	s5,24(sp)
    80002108:	e85a                	sd	s6,16(sp)
    8000210a:	e45e                	sd	s7,8(sp)
    8000210c:	0880                	addi	s0,sp,80
    8000210e:	84aa                	mv	s1,a0
    80002110:	8aae                	mv	s5,a1
  struct spinlock *list_lock, *first_lock;
  process_entry_t first, next;

  list_lock = &list->lock;
    80002112:	00850b93          	addi	s7,a0,8
  acquire(list_lock);
    80002116:	855e                	mv	a0,s7
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	acc080e7          	jalr	-1332(ra) # 80000be4 <acquire>
  first = list->next;
    80002120:	0004ab03          	lw	s6,0(s1)

  if(first == END)
    80002124:	57fd                	li	a5,-1
    80002126:	06fb0063          	beq	s6,a5,80002186 <dequeue+0x8e>
    *res = NO_ELEMENT;
    release(list_lock);
    return;
  }

  first_lock = &proc[first].list_lock;
    8000212a:	18800913          	li	s2,392
    8000212e:	032b0a33          	mul	s4,s6,s2
    80002132:	038a0993          	addi	s3,s4,56
    80002136:	0000f917          	auipc	s2,0xf
    8000213a:	79290913          	addi	s2,s2,1938 # 800118c8 <proc>
    8000213e:	99ca                	add	s3,s3,s2
  acquire(first_lock);
    80002140:	854e                	mv	a0,s3
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	aa2080e7          	jalr	-1374(ra) # 80000be4 <acquire>
  // At this point we are holding both list_lock, first_lock 
  next = proc[first].next;
    8000214a:	9952                	add	s2,s2,s4
    8000214c:	03492783          	lw	a5,52(s2)
  *res = first;
    80002150:	016aa023          	sw	s6,0(s5)
  list->next = next;
    80002154:	c09c                	sw	a5,0(s1)
  proc[first].next = END;
    80002156:	57fd                	li	a5,-1
    80002158:	02f92a23          	sw	a5,52(s2)
  release(first_lock);
    8000215c:	854e                	mv	a0,s3
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	b3a080e7          	jalr	-1222(ra) # 80000c98 <release>
  release(list_lock);
    80002166:	855e                	mv	a0,s7
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b30080e7          	jalr	-1232(ra) # 80000c98 <release>
}
    80002170:	60a6                	ld	ra,72(sp)
    80002172:	6406                	ld	s0,64(sp)
    80002174:	74e2                	ld	s1,56(sp)
    80002176:	7942                	ld	s2,48(sp)
    80002178:	79a2                	ld	s3,40(sp)
    8000217a:	7a02                	ld	s4,32(sp)
    8000217c:	6ae2                	ld	s5,24(sp)
    8000217e:	6b42                	ld	s6,16(sp)
    80002180:	6ba2                	ld	s7,8(sp)
    80002182:	6161                	addi	sp,sp,80
    80002184:	8082                	ret
    *res = NO_ELEMENT;
    80002186:	800007b7          	lui	a5,0x80000
    8000218a:	fff7c793          	not	a5,a5
    8000218e:	00faa023          	sw	a5,0(s5)
    release(list_lock);
    80002192:	855e                	mv	a0,s7
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b04080e7          	jalr	-1276(ra) # 80000c98 <release>
    return;
    8000219c:	bfd1                	j	80002170 <dequeue+0x78>

000000008000219e <scheduler>:
{
    8000219e:	7159                	addi	sp,sp,-112
    800021a0:	f486                	sd	ra,104(sp)
    800021a2:	f0a2                	sd	s0,96(sp)
    800021a4:	eca6                	sd	s1,88(sp)
    800021a6:	e8ca                	sd	s2,80(sp)
    800021a8:	e4ce                	sd	s3,72(sp)
    800021aa:	e0d2                	sd	s4,64(sp)
    800021ac:	fc56                	sd	s5,56(sp)
    800021ae:	f85a                	sd	s6,48(sp)
    800021b0:	f45e                	sd	s7,40(sp)
    800021b2:	f062                	sd	s8,32(sp)
    800021b4:	ec66                	sd	s9,24(sp)
    800021b6:	1880                	addi	s0,sp,112
    800021b8:	8712                	mv	a4,tp
  int id = r_tp();
    800021ba:	2701                	sext.w	a4,a4
    800021bc:	8792                	mv	a5,tp
  struct sentinel* cpu_list = &cpu_runnable_list[cpu_id];
    800021be:	0000fb17          	auipc	s6,0xf
    800021c2:	0e2b0b13          	addi	s6,s6,226 # 800112a0 <cpus>
    800021c6:	0007869b          	sext.w	a3,a5
    800021ca:	00269793          	slli	a5,a3,0x2
    800021ce:	97b6                	add	a5,a5,a3
    800021d0:	078e                	slli	a5,a5,0x3
    800021d2:	0000f997          	auipc	s3,0xf
    800021d6:	5b698993          	addi	s3,s3,1462 # 80011788 <cpu_runnable_list>
    800021da:	99be                	add	s3,s3,a5
  c->proc = 0;
    800021dc:	00471793          	slli	a5,a4,0x4
    800021e0:	00e786b3          	add	a3,a5,a4
    800021e4:	068e                	slli	a3,a3,0x3
    800021e6:	96da                	add	a3,a3,s6
    800021e8:	0006b023          	sd	zero,0(a3)
    swtch(&c->context, &p->context);
    800021ec:	97ba                	add	a5,a5,a4
    800021ee:	078e                	slli	a5,a5,0x3
    800021f0:	07a1                	addi	a5,a5,8
    800021f2:	9b3e                	add	s6,s6,a5
    if(pentry == NO_ELEMENT)
    800021f4:	80000937          	lui	s2,0x80000
    800021f8:	fff94913          	not	s2,s2
    800021fc:	18800c13          	li	s8,392
    p = &proc[pentry];
    80002200:	0000fa97          	auipc	s5,0xf
    80002204:	6c8a8a93          	addi	s5,s5,1736 # 800118c8 <proc>
    p->state = RUNNING;
    80002208:	4b91                	li	s7,4
    c->proc = p;
    8000220a:	8a36                	mv	s4,a3
    8000220c:	a82d                	j	80002246 <scheduler+0xa8>
    p = &proc[pentry];
    8000220e:	038584b3          	mul	s1,a1,s8
    80002212:	01548cb3          	add	s9,s1,s5
    acquire(&p->lock);
    80002216:	8566                	mv	a0,s9
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9cc080e7          	jalr	-1588(ra) # 80000be4 <acquire>
    p->state = RUNNING;
    80002220:	017cac23          	sw	s7,24(s9)
    c->proc = p;
    80002224:	019a3023          	sd	s9,0(s4)
    swtch(&c->context, &p->context);
    80002228:	08048593          	addi	a1,s1,128
    8000222c:	95d6                	add	a1,a1,s5
    8000222e:	855a                	mv	a0,s6
    80002230:	00001097          	auipc	ra,0x1
    80002234:	9ee080e7          	jalr	-1554(ra) # 80002c1e <swtch>
    c->proc = 0;
    80002238:	000a3023          	sd	zero,0(s4)
    release(&p->lock);
    8000223c:	8566                	mv	a0,s9
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002246:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000224a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000224e:	10079073          	csrw	sstatus,a5
    dequeue(cpu_list, &pentry);
    80002252:	f9c40593          	addi	a1,s0,-100
    80002256:	854e                	mv	a0,s3
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	ea0080e7          	jalr	-352(ra) # 800020f8 <dequeue>
    if(pentry == NO_ELEMENT)
    80002260:	f9c42583          	lw	a1,-100(s0)
    80002264:	ff2581e3          	beq	a1,s2,80002246 <scheduler+0xa8>
    80002268:	b75d                	j	8000220e <scheduler+0x70>

000000008000226a <remove>:

void 
remove(struct sentinel* list, process_entry_t target)
{
    8000226a:	711d                	addi	sp,sp,-96
    8000226c:	ec86                	sd	ra,88(sp)
    8000226e:	e8a2                	sd	s0,80(sp)
    80002270:	e4a6                	sd	s1,72(sp)
    80002272:	e0ca                	sd	s2,64(sp)
    80002274:	fc4e                	sd	s3,56(sp)
    80002276:	f852                	sd	s4,48(sp)
    80002278:	f456                	sd	s5,40(sp)
    8000227a:	f05a                	sd	s6,32(sp)
    8000227c:	ec5e                	sd	s7,24(sp)
    8000227e:	e862                	sd	s8,16(sp)
    80002280:	e466                	sd	s9,8(sp)
    80002282:	1080                	addi	s0,sp,96
    80002284:	892a                	mv	s2,a0
    80002286:	8aae                	mv	s5,a1
  process_entry_t prev, curr;
  struct spinlock *prev_lock, *curr_lock, *p_lock;
  struct proc* p;

  // first element in the list
  prev = list->next; 
    80002288:	00052a03          	lw	s4,0(a0)
  prev_lock = &list->lock; 
    8000228c:	00850493          	addi	s1,a0,8
  // removed process
  p = &proc[target]; 
  p_lock = &p->list_lock;
    80002290:	18800c93          	li	s9,392
    80002294:	03958cb3          	mul	s9,a1,s9
    80002298:	0000f797          	auipc	a5,0xf
    8000229c:	66878793          	addi	a5,a5,1640 # 80011900 <proc+0x38>
    800022a0:	9cbe                	add	s9,s9,a5

  acquire(prev_lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	940080e7          	jalr	-1728(ra) # 80000be4 <acquire>
  if(prev == END) // empty list
    800022ac:	57fd                	li	a5,-1
    800022ae:	08fa0b63          	beq	s4,a5,80002344 <remove+0xda>
  {
    release(prev_lock);
    return;
  }

  if(prev == target) // head = target
    800022b2:	095a0f63          	beq	s4,s5,80002350 <remove+0xe6>
    release(prev_lock);
    return;
  }

  // Iterate over the list until prev points to target
  curr = proc[prev].next;
    800022b6:	18800793          	li	a5,392
    800022ba:	02fa0733          	mul	a4,s4,a5
    800022be:	0000f797          	auipc	a5,0xf
    800022c2:	60a78793          	addi	a5,a5,1546 # 800118c8 <proc>
    800022c6:	97ba                	add	a5,a5,a4
    800022c8:	0347a903          	lw	s2,52(a5)
  while(curr != END &&  curr != target)
    800022cc:	57fd                	li	a5,-1
    800022ce:	0af90f63          	beq	s2,a5,8000238c <remove+0x122>
    800022d2:	052a8163          	beq	s5,s2,80002314 <remove+0xaa>
  {
    curr_lock = &proc[curr].list_lock;
    800022d6:	18800c13          	li	s8,392
    800022da:	0000fb17          	auipc	s6,0xf
    800022de:	5eeb0b13          	addi	s6,s6,1518 # 800118c8 <proc>
  while(curr != END &&  curr != target)
    800022e2:	5bfd                	li	s7,-1
    curr_lock = &proc[curr].list_lock;
    800022e4:	8a26                	mv	s4,s1
    800022e6:	038909b3          	mul	s3,s2,s8
    800022ea:	03898493          	addi	s1,s3,56
    800022ee:	94da                	add	s1,s1,s6
    acquire(curr_lock); 
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8f2080e7          	jalr	-1806(ra) # 80000be4 <acquire>
    release(prev_lock);
    800022fa:	8552                	mv	a0,s4
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	99c080e7          	jalr	-1636(ra) # 80000c98 <release>
    prev = curr;
    prev_lock = curr_lock;
    curr = proc[curr].next;
    80002304:	8a4a                	mv	s4,s2
    80002306:	99da                	add	s3,s3,s6
    80002308:	0349a903          	lw	s2,52(s3)
  while(curr != END &&  curr != target)
    8000230c:	09790063          	beq	s2,s7,8000238c <remove+0x122>
    80002310:	fd2a9ae3          	bne	s5,s2,800022e4 <remove+0x7a>
  }

  acquire(p_lock);
    80002314:	8566                	mv	a0,s9
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	8ce080e7          	jalr	-1842(ra) # 80000be4 <acquire>
  // At this point we are holding both p_lock, prev_lock
  if(curr == target) // curr might be equal to END, if other process already remove target
  {
    proc[prev].next = p->next;
    8000231e:	0000f797          	auipc	a5,0xf
    80002322:	5aa78793          	addi	a5,a5,1450 # 800118c8 <proc>
    80002326:	18800713          	li	a4,392
    8000232a:	02ea8ab3          	mul	s5,s5,a4
    8000232e:	9abe                	add	s5,s5,a5
    80002330:	034aa683          	lw	a3,52(s5)
    80002334:	02ea0a33          	mul	s4,s4,a4
    80002338:	97d2                	add	a5,a5,s4
    8000233a:	dbd4                	sw	a3,52(a5)
    p->next = END;
    8000233c:	57fd                	li	a5,-1
    8000233e:	02faaa23          	sw	a5,52(s5)
    80002342:	a8a9                	j	8000239c <remove+0x132>
    release(prev_lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	952080e7          	jalr	-1710(ra) # 80000c98 <release>
    return;
    8000234e:	a08d                	j	800023b0 <remove+0x146>
    acquire(p_lock);
    80002350:	8566                	mv	a0,s9
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	892080e7          	jalr	-1902(ra) # 80000be4 <acquire>
    list->next = p->next;
    8000235a:	18800793          	li	a5,392
    8000235e:	02fa8ab3          	mul	s5,s5,a5
    80002362:	0000f797          	auipc	a5,0xf
    80002366:	56678793          	addi	a5,a5,1382 # 800118c8 <proc>
    8000236a:	97d6                	add	a5,a5,s5
    8000236c:	5bd8                	lw	a4,52(a5)
    8000236e:	00e92023          	sw	a4,0(s2) # ffffffff80000000 <end+0xfffffffefffda000>
    p->next = END;
    80002372:	577d                	li	a4,-1
    80002374:	dbd8                	sw	a4,52(a5)
    release(p_lock);
    80002376:	8566                	mv	a0,s9
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
    release(prev_lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	916080e7          	jalr	-1770(ra) # 80000c98 <release>
    return;
    8000238a:	a01d                	j	800023b0 <remove+0x146>
  acquire(p_lock);
    8000238c:	8566                	mv	a0,s9
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	856080e7          	jalr	-1962(ra) # 80000be4 <acquire>
  if(curr == target) // curr might be equal to END, if other process already remove target
    80002396:	57fd                	li	a5,-1
    80002398:	f8fa83e3          	beq	s5,a5,8000231e <remove+0xb4>
  }
  release(p_lock);
    8000239c:	8566                	mv	a0,s9
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>
  release(prev_lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8f0080e7          	jalr	-1808(ra) # 80000c98 <release>
}
    800023b0:	60e6                	ld	ra,88(sp)
    800023b2:	6446                	ld	s0,80(sp)
    800023b4:	64a6                	ld	s1,72(sp)
    800023b6:	6906                	ld	s2,64(sp)
    800023b8:	79e2                	ld	s3,56(sp)
    800023ba:	7a42                	ld	s4,48(sp)
    800023bc:	7aa2                	ld	s5,40(sp)
    800023be:	7b02                	ld	s6,32(sp)
    800023c0:	6be2                	ld	s7,24(sp)
    800023c2:	6c42                	ld	s8,16(sp)
    800023c4:	6ca2                	ld	s9,8(sp)
    800023c6:	6125                	addi	sp,sp,96
    800023c8:	8082                	ret

00000000800023ca <freeproc>:
{
    800023ca:	1101                	addi	sp,sp,-32
    800023cc:	ec06                	sd	ra,24(sp)
    800023ce:	e822                	sd	s0,16(sp)
    800023d0:	e426                	sd	s1,8(sp)
    800023d2:	e04a                	sd	s2,0(sp)
    800023d4:	1000                	addi	s0,sp,32
    800023d6:	84aa                	mv	s1,a0
  if(p->trapframe)
    800023d8:	7d28                	ld	a0,120(a0)
    800023da:	c509                	beqz	a0,800023e4 <freeproc+0x1a>
    kfree((void*)p->trapframe);
    800023dc:	ffffe097          	auipc	ra,0xffffe
    800023e0:	61c080e7          	jalr	1564(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    800023e4:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    800023e8:	78a8                	ld	a0,112(s1)
    800023ea:	c511                	beqz	a0,800023f6 <freeproc+0x2c>
    proc_freepagetable(p->pagetable, p->sz);
    800023ec:	74ac                	ld	a1,104(s1)
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	678080e7          	jalr	1656(ra) # 80001a66 <proc_freepagetable>
  p->pagetable = 0;
    800023f6:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    800023fa:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    800023fe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002402:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002406:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    8000240a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000240e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002412:	0204a623          	sw	zero,44(s1)
  pentry = p->entry;
    80002416:	0544a903          	lw	s2,84(s1)
  remove(&zombie_list, pentry);
    8000241a:	85ca                	mv	a1,s2
    8000241c:	0000f517          	auipc	a0,0xf
    80002420:	34450513          	addi	a0,a0,836 # 80011760 <zombie_list>
    80002424:	00000097          	auipc	ra,0x0
    80002428:	e46080e7          	jalr	-442(ra) # 8000226a <remove>
  enqueue(&unused_list, pentry);
    8000242c:	85ca                	mv	a1,s2
    8000242e:	0000f517          	auipc	a0,0xf
    80002432:	2e250513          	addi	a0,a0,738 # 80011710 <unused_list>
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	95e080e7          	jalr	-1698(ra) # 80001d94 <enqueue>
  p->state = UNUSED;
    8000243e:	0004ac23          	sw	zero,24(s1)
}
    80002442:	60e2                	ld	ra,24(sp)
    80002444:	6442                	ld	s0,16(sp)
    80002446:	64a2                	ld	s1,8(sp)
    80002448:	6902                	ld	s2,0(sp)
    8000244a:	6105                	addi	sp,sp,32
    8000244c:	8082                	ret

000000008000244e <allocproc>:
{
    8000244e:	7139                	addi	sp,sp,-64
    80002450:	fc06                	sd	ra,56(sp)
    80002452:	f822                	sd	s0,48(sp)
    80002454:	f426                	sd	s1,40(sp)
    80002456:	f04a                	sd	s2,32(sp)
    80002458:	ec4e                	sd	s3,24(sp)
    8000245a:	e852                	sd	s4,16(sp)
    8000245c:	0080                	addi	s0,sp,64
  dequeue(&unused_list, &pentry);
    8000245e:	fcc40593          	addi	a1,s0,-52
    80002462:	0000f517          	auipc	a0,0xf
    80002466:	2ae50513          	addi	a0,a0,686 # 80011710 <unused_list>
    8000246a:	00000097          	auipc	ra,0x0
    8000246e:	c8e080e7          	jalr	-882(ra) # 800020f8 <dequeue>
  if(pentry != NO_ELEMENT)
    80002472:	fcc42903          	lw	s2,-52(s0)
    80002476:	800007b7          	lui	a5,0x80000
    8000247a:	fff7c793          	not	a5,a5
    8000247e:	0ef90263          	beq	s2,a5,80002562 <allocproc+0x114>
    p = &proc[pentry];
    80002482:	18800993          	li	s3,392
    80002486:	033909b3          	mul	s3,s2,s3
    8000248a:	0000f497          	auipc	s1,0xf
    8000248e:	43e48493          	addi	s1,s1,1086 # 800118c8 <proc>
    80002492:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	74e080e7          	jalr	1870(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	4f0080e7          	jalr	1264(ra) # 8000198e <allocpid>
    800024a6:	d888                	sw	a0,48(s1)
  p->state = USED;
    800024a8:	4785                	li	a5,1
    800024aa:	cc9c                	sw	a5,24(s1)
  p->entry = pentry;
    800024ac:	fcc42783          	lw	a5,-52(s0)
    800024b0:	c8fc                	sw	a5,84(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	642080e7          	jalr	1602(ra) # 80000af4 <kalloc>
    800024ba:	8a2a                	mv	s4,a0
    800024bc:	fca8                	sd	a0,120(s1)
    800024be:	c935                	beqz	a0,80002532 <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	508080e7          	jalr	1288(ra) # 800019ca <proc_pagetable>
    800024ca:	8a2a                	mv	s4,a0
    800024cc:	18800793          	li	a5,392
    800024d0:	02f90733          	mul	a4,s2,a5
    800024d4:	0000f797          	auipc	a5,0xf
    800024d8:	3f478793          	addi	a5,a5,1012 # 800118c8 <proc>
    800024dc:	97ba                	add	a5,a5,a4
    800024de:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800024e0:	c52d                	beqz	a0,8000254a <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    800024e2:	08098513          	addi	a0,s3,128
    800024e6:	0000fa17          	auipc	s4,0xf
    800024ea:	3e2a0a13          	addi	s4,s4,994 # 800118c8 <proc>
    800024ee:	07000613          	li	a2,112
    800024f2:	4581                	li	a1,0
    800024f4:	9552                	add	a0,a0,s4
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7ea080e7          	jalr	2026(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    800024fe:	18800793          	li	a5,392
    80002502:	02f90933          	mul	s2,s2,a5
    80002506:	9952                	add	s2,s2,s4
    80002508:	fffff797          	auipc	a5,0xfffff
    8000250c:	44078793          	addi	a5,a5,1088 # 80001948 <forkret>
    80002510:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002514:	06093783          	ld	a5,96(s2)
    80002518:	6705                	lui	a4,0x1
    8000251a:	97ba                	add	a5,a5,a4
    8000251c:	08f93423          	sd	a5,136(s2)
}
    80002520:	8526                	mv	a0,s1
    80002522:	70e2                	ld	ra,56(sp)
    80002524:	7442                	ld	s0,48(sp)
    80002526:	74a2                	ld	s1,40(sp)
    80002528:	7902                	ld	s2,32(sp)
    8000252a:	69e2                	ld	s3,24(sp)
    8000252c:	6a42                	ld	s4,16(sp)
    8000252e:	6121                	addi	sp,sp,64
    80002530:	8082                	ret
    freeproc(p);
    80002532:	8526                	mv	a0,s1
    80002534:	00000097          	auipc	ra,0x0
    80002538:	e96080e7          	jalr	-362(ra) # 800023ca <freeproc>
    release(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	75a080e7          	jalr	1882(ra) # 80000c98 <release>
    return 0;
    80002546:	84d2                	mv	s1,s4
    80002548:	bfe1                	j	80002520 <allocproc+0xd2>
    freeproc(p);
    8000254a:	8526                	mv	a0,s1
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	e7e080e7          	jalr	-386(ra) # 800023ca <freeproc>
    release(&p->lock);
    80002554:	8526                	mv	a0,s1
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	742080e7          	jalr	1858(ra) # 80000c98 <release>
    return 0;
    8000255e:	84d2                	mv	s1,s4
    80002560:	b7c1                	j	80002520 <allocproc+0xd2>
    return 0;
    80002562:	4481                	li	s1,0
    80002564:	bf75                	j	80002520 <allocproc+0xd2>

0000000080002566 <userinit>:
{
    80002566:	1101                	addi	sp,sp,-32
    80002568:	ec06                	sd	ra,24(sp)
    8000256a:	e822                	sd	s0,16(sp)
    8000256c:	e426                	sd	s1,8(sp)
    8000256e:	1000                	addi	s0,sp,32
  p = allocproc();
    80002570:	00000097          	auipc	ra,0x0
    80002574:	ede080e7          	jalr	-290(ra) # 8000244e <allocproc>
    80002578:	84aa                	mv	s1,a0
  initproc = p;
    8000257a:	00007797          	auipc	a5,0x7
    8000257e:	aaa7b723          	sd	a0,-1362(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002582:	03400613          	li	a2,52
    80002586:	00006597          	auipc	a1,0x6
    8000258a:	3aa58593          	addi	a1,a1,938 # 80008930 <initcode>
    8000258e:	7928                	ld	a0,112(a0)
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	dd8080e7          	jalr	-552(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002598:	6785                	lui	a5,0x1
    8000259a:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    8000259c:	7cb8                	ld	a4,120(s1)
    8000259e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800025a2:	7cb8                	ld	a4,120(s1)
    800025a4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800025a6:	4641                	li	a2,16
    800025a8:	00006597          	auipc	a1,0x6
    800025ac:	cf858593          	addi	a1,a1,-776 # 800082a0 <digits+0x260>
    800025b0:	17848513          	addi	a0,s1,376
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	87e080e7          	jalr	-1922(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800025bc:	00006517          	auipc	a0,0x6
    800025c0:	cf450513          	addi	a0,a0,-780 # 800082b0 <digits+0x270>
    800025c4:	00002097          	auipc	ra,0x2
    800025c8:	ebe080e7          	jalr	-322(ra) # 80004482 <namei>
    800025cc:	16a4b823          	sd	a0,368(s1)
  p->affiliated_cpu = FIRST_CPU;
    800025d0:	0404a823          	sw	zero,80(s1)
  enqueue(&cpu_runnable_list[FIRST_CPU], p->entry);
    800025d4:	48ec                	lw	a1,84(s1)
    800025d6:	0000f517          	auipc	a0,0xf
    800025da:	1b250513          	addi	a0,a0,434 # 80011788 <cpu_runnable_list>
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	7b6080e7          	jalr	1974(ra) # 80001d94 <enqueue>
  p->state = RUNNABLE;
    800025e6:	478d                	li	a5,3
    800025e8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800025ea:	8526                	mv	a0,s1
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	6ac080e7          	jalr	1708(ra) # 80000c98 <release>
}
    800025f4:	60e2                	ld	ra,24(sp)
    800025f6:	6442                	ld	s0,16(sp)
    800025f8:	64a2                	ld	s1,8(sp)
    800025fa:	6105                	addi	sp,sp,32
    800025fc:	8082                	ret

00000000800025fe <fork>:
{
    800025fe:	7179                	addi	sp,sp,-48
    80002600:	f406                	sd	ra,40(sp)
    80002602:	f022                	sd	s0,32(sp)
    80002604:	ec26                	sd	s1,24(sp)
    80002606:	e84a                	sd	s2,16(sp)
    80002608:	e44e                	sd	s3,8(sp)
    8000260a:	e052                	sd	s4,0(sp)
    8000260c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	2fa080e7          	jalr	762(ra) # 80001908 <myproc>
    80002616:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002618:	00000097          	auipc	ra,0x0
    8000261c:	e36080e7          	jalr	-458(ra) # 8000244e <allocproc>
    80002620:	14050063          	beqz	a0,80002760 <fork+0x162>
    80002624:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002626:	0689b603          	ld	a2,104(s3)
    8000262a:	792c                	ld	a1,112(a0)
    8000262c:	0709b503          	ld	a0,112(s3)
    80002630:	fffff097          	auipc	ra,0xfffff
    80002634:	f3e080e7          	jalr	-194(ra) # 8000156e <uvmcopy>
    80002638:	04054663          	bltz	a0,80002684 <fork+0x86>
  np->sz = p->sz;
    8000263c:	0689b783          	ld	a5,104(s3)
    80002640:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    80002644:	0789b683          	ld	a3,120(s3)
    80002648:	87b6                	mv	a5,a3
    8000264a:	07893703          	ld	a4,120(s2)
    8000264e:	12068693          	addi	a3,a3,288
    80002652:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002656:	6788                	ld	a0,8(a5)
    80002658:	6b8c                	ld	a1,16(a5)
    8000265a:	6f90                	ld	a2,24(a5)
    8000265c:	01073023          	sd	a6,0(a4)
    80002660:	e708                	sd	a0,8(a4)
    80002662:	eb0c                	sd	a1,16(a4)
    80002664:	ef10                	sd	a2,24(a4)
    80002666:	02078793          	addi	a5,a5,32
    8000266a:	02070713          	addi	a4,a4,32
    8000266e:	fed792e3          	bne	a5,a3,80002652 <fork+0x54>
  np->trapframe->a0 = 0;
    80002672:	07893783          	ld	a5,120(s2)
    80002676:	0607b823          	sd	zero,112(a5)
    8000267a:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000267e:	17000a13          	li	s4,368
    80002682:	a03d                	j	800026b0 <fork+0xb2>
    freeproc(np);
    80002684:	854a                	mv	a0,s2
    80002686:	00000097          	auipc	ra,0x0
    8000268a:	d44080e7          	jalr	-700(ra) # 800023ca <freeproc>
    release(&np->lock);
    8000268e:	854a                	mv	a0,s2
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	608080e7          	jalr	1544(ra) # 80000c98 <release>
    return -1;
    80002698:	5a7d                	li	s4,-1
    8000269a:	a855                	j	8000274e <fork+0x150>
      np->ofile[i] = filedup(p->ofile[i]);
    8000269c:	00002097          	auipc	ra,0x2
    800026a0:	47c080e7          	jalr	1148(ra) # 80004b18 <filedup>
    800026a4:	009907b3          	add	a5,s2,s1
    800026a8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800026aa:	04a1                	addi	s1,s1,8
    800026ac:	01448763          	beq	s1,s4,800026ba <fork+0xbc>
    if(p->ofile[i])
    800026b0:	009987b3          	add	a5,s3,s1
    800026b4:	6388                	ld	a0,0(a5)
    800026b6:	f17d                	bnez	a0,8000269c <fork+0x9e>
    800026b8:	bfcd                	j	800026aa <fork+0xac>
  np->cwd = idup(p->cwd);
    800026ba:	1709b503          	ld	a0,368(s3)
    800026be:	00001097          	auipc	ra,0x1
    800026c2:	5d0080e7          	jalr	1488(ra) # 80003c8e <idup>
    800026c6:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800026ca:	4641                	li	a2,16
    800026cc:	17898593          	addi	a1,s3,376
    800026d0:	17890513          	addi	a0,s2,376
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	75e080e7          	jalr	1886(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800026dc:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    800026e0:	854a                	mv	a0,s2
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5b6080e7          	jalr	1462(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800026ea:	0000f497          	auipc	s1,0xf
    800026ee:	00e48493          	addi	s1,s1,14 # 800116f8 <wait_lock>
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4f0080e7          	jalr	1264(ra) # 80000be4 <acquire>
  np->parent = p;
    800026fc:	05393c23          	sd	s3,88(s2)
  np->affiliated_cpu = p->affiliated_cpu;
    80002700:	0509a783          	lw	a5,80(s3)
    80002704:	04f92823          	sw	a5,80(s2)
  release(&wait_lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	58e080e7          	jalr	1422(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002712:	854a                	mv	a0,s2
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	4d0080e7          	jalr	1232(ra) # 80000be4 <acquire>
  enqueue(&cpu_runnable_list[np->affiliated_cpu], np->entry);
    8000271c:	05092503          	lw	a0,80(s2)
    80002720:	00251793          	slli	a5,a0,0x2
    80002724:	97aa                	add	a5,a5,a0
    80002726:	078e                	slli	a5,a5,0x3
    80002728:	05492583          	lw	a1,84(s2)
    8000272c:	0000f517          	auipc	a0,0xf
    80002730:	05c50513          	addi	a0,a0,92 # 80011788 <cpu_runnable_list>
    80002734:	953e                	add	a0,a0,a5
    80002736:	fffff097          	auipc	ra,0xfffff
    8000273a:	65e080e7          	jalr	1630(ra) # 80001d94 <enqueue>
  np->state = RUNNABLE;
    8000273e:	478d                	li	a5,3
    80002740:	00f92c23          	sw	a5,24(s2)
  release(&np->lock);
    80002744:	854a                	mv	a0,s2
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	552080e7          	jalr	1362(ra) # 80000c98 <release>
}
    8000274e:	8552                	mv	a0,s4
    80002750:	70a2                	ld	ra,40(sp)
    80002752:	7402                	ld	s0,32(sp)
    80002754:	64e2                	ld	s1,24(sp)
    80002756:	6942                	ld	s2,16(sp)
    80002758:	69a2                	ld	s3,8(sp)
    8000275a:	6a02                	ld	s4,0(sp)
    8000275c:	6145                	addi	sp,sp,48
    8000275e:	8082                	ret
    return -1;
    80002760:	5a7d                	li	s4,-1
    80002762:	b7f5                	j	8000274e <fork+0x150>

0000000080002764 <wait>:
{
    80002764:	715d                	addi	sp,sp,-80
    80002766:	e486                	sd	ra,72(sp)
    80002768:	e0a2                	sd	s0,64(sp)
    8000276a:	fc26                	sd	s1,56(sp)
    8000276c:	f84a                	sd	s2,48(sp)
    8000276e:	f44e                	sd	s3,40(sp)
    80002770:	f052                	sd	s4,32(sp)
    80002772:	ec56                	sd	s5,24(sp)
    80002774:	e85a                	sd	s6,16(sp)
    80002776:	e45e                	sd	s7,8(sp)
    80002778:	e062                	sd	s8,0(sp)
    8000277a:	0880                	addi	s0,sp,80
    8000277c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000277e:	fffff097          	auipc	ra,0xfffff
    80002782:	18a080e7          	jalr	394(ra) # 80001908 <myproc>
    80002786:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002788:	0000f517          	auipc	a0,0xf
    8000278c:	f7050513          	addi	a0,a0,-144 # 800116f8 <wait_lock>
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	454080e7          	jalr	1108(ra) # 80000be4 <acquire>
    havekids = 0;
    80002798:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000279a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000279c:	00015997          	auipc	s3,0x15
    800027a0:	32c98993          	addi	s3,s3,812 # 80017ac8 <cpus_lock>
        havekids = 1;
    800027a4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027a6:	0000fc17          	auipc	s8,0xf
    800027aa:	f52c0c13          	addi	s8,s8,-174 # 800116f8 <wait_lock>
    havekids = 0;
    800027ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027b0:	0000f497          	auipc	s1,0xf
    800027b4:	11848493          	addi	s1,s1,280 # 800118c8 <proc>
    800027b8:	a0bd                	j	80002826 <wait+0xc2>
          pid = np->pid;
    800027ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027be:	000b0e63          	beqz	s6,800027da <wait+0x76>
    800027c2:	4691                	li	a3,4
    800027c4:	02c48613          	addi	a2,s1,44
    800027c8:	85da                	mv	a1,s6
    800027ca:	07093503          	ld	a0,112(s2)
    800027ce:	fffff097          	auipc	ra,0xfffff
    800027d2:	ea4080e7          	jalr	-348(ra) # 80001672 <copyout>
    800027d6:	02054563          	bltz	a0,80002800 <wait+0x9c>
          freeproc(np);
    800027da:	8526                	mv	a0,s1
    800027dc:	00000097          	auipc	ra,0x0
    800027e0:	bee080e7          	jalr	-1042(ra) # 800023ca <freeproc>
          release(&np->lock);
    800027e4:	8526                	mv	a0,s1
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	4b2080e7          	jalr	1202(ra) # 80000c98 <release>
          release(&wait_lock);
    800027ee:	0000f517          	auipc	a0,0xf
    800027f2:	f0a50513          	addi	a0,a0,-246 # 800116f8 <wait_lock>
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	4a2080e7          	jalr	1186(ra) # 80000c98 <release>
          return pid;
    800027fe:	a09d                	j	80002864 <wait+0x100>
            release(&np->lock);
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	496080e7          	jalr	1174(ra) # 80000c98 <release>
            release(&wait_lock);
    8000280a:	0000f517          	auipc	a0,0xf
    8000280e:	eee50513          	addi	a0,a0,-274 # 800116f8 <wait_lock>
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
            return -1;
    8000281a:	59fd                	li	s3,-1
    8000281c:	a0a1                	j	80002864 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000281e:	18848493          	addi	s1,s1,392
    80002822:	03348463          	beq	s1,s3,8000284a <wait+0xe6>
      if(np->parent == p){
    80002826:	6cbc                	ld	a5,88(s1)
    80002828:	ff279be3          	bne	a5,s2,8000281e <wait+0xba>
        acquire(&np->lock);
    8000282c:	8526                	mv	a0,s1
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	3b6080e7          	jalr	950(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002836:	4c9c                	lw	a5,24(s1)
    80002838:	f94781e3          	beq	a5,s4,800027ba <wait+0x56>
        release(&np->lock);
    8000283c:	8526                	mv	a0,s1
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	45a080e7          	jalr	1114(ra) # 80000c98 <release>
        havekids = 1;
    80002846:	8756                	mv	a4,s5
    80002848:	bfd9                	j	8000281e <wait+0xba>
    if(!havekids || p->killed){
    8000284a:	c701                	beqz	a4,80002852 <wait+0xee>
    8000284c:	02892783          	lw	a5,40(s2)
    80002850:	c79d                	beqz	a5,8000287e <wait+0x11a>
      release(&wait_lock);
    80002852:	0000f517          	auipc	a0,0xf
    80002856:	ea650513          	addi	a0,a0,-346 # 800116f8 <wait_lock>
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	43e080e7          	jalr	1086(ra) # 80000c98 <release>
      return -1;
    80002862:	59fd                	li	s3,-1
}
    80002864:	854e                	mv	a0,s3
    80002866:	60a6                	ld	ra,72(sp)
    80002868:	6406                	ld	s0,64(sp)
    8000286a:	74e2                	ld	s1,56(sp)
    8000286c:	7942                	ld	s2,48(sp)
    8000286e:	79a2                	ld	s3,40(sp)
    80002870:	7a02                	ld	s4,32(sp)
    80002872:	6ae2                	ld	s5,24(sp)
    80002874:	6b42                	ld	s6,16(sp)
    80002876:	6ba2                	ld	s7,8(sp)
    80002878:	6c02                	ld	s8,0(sp)
    8000287a:	6161                	addi	sp,sp,80
    8000287c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000287e:	85e2                	mv	a1,s8
    80002880:	854a                	mv	a0,s2
    80002882:	00000097          	auipc	ra,0x0
    80002886:	800080e7          	jalr	-2048(ra) # 80002082 <sleep>
    havekids = 0;
    8000288a:	b715                	j	800027ae <wait+0x4a>

000000008000288c <wakeup>:
{
    8000288c:	7159                	addi	sp,sp,-112
    8000288e:	f486                	sd	ra,104(sp)
    80002890:	f0a2                	sd	s0,96(sp)
    80002892:	eca6                	sd	s1,88(sp)
    80002894:	e8ca                	sd	s2,80(sp)
    80002896:	e4ce                	sd	s3,72(sp)
    80002898:	e0d2                	sd	s4,64(sp)
    8000289a:	fc56                	sd	s5,56(sp)
    8000289c:	f85a                	sd	s6,48(sp)
    8000289e:	f45e                	sd	s7,40(sp)
    800028a0:	f062                	sd	s8,32(sp)
    800028a2:	ec66                	sd	s9,24(sp)
    800028a4:	e86a                	sd	s10,16(sp)
    800028a6:	e46e                	sd	s11,8(sp)
    800028a8:	1880                	addi	s0,sp,112
  process_entry_t pentry = sleeping_list.next;
    800028aa:	0000f497          	auipc	s1,0xf
    800028ae:	e8e4a483          	lw	s1,-370(s1) # 80011738 <sleeping_list>
  while(pentry != END)
    800028b2:	57fd                	li	a5,-1
    800028b4:	08f48b63          	beq	s1,a5,8000294a <wakeup+0xbe>
    800028b8:	8b2a                	mv	s6,a0
    p = &proc[pentry];
    800028ba:	18800993          	li	s3,392
    800028be:	0000f917          	auipc	s2,0xf
    800028c2:	00a90913          	addi	s2,s2,10 # 800118c8 <proc>
      if(p->state == SLEEPING && p->chan == chan) 
    800028c6:	4a89                	li	s5,2
        remove(&sleeping_list, pentry);
    800028c8:	0000fc97          	auipc	s9,0xf
    800028cc:	e70c8c93          	addi	s9,s9,-400 # 80011738 <sleeping_list>
        enqueue(&cpu_runnable_list[p->affiliated_cpu], pentry);
    800028d0:	0000fc17          	auipc	s8,0xf
    800028d4:	eb8c0c13          	addi	s8,s8,-328 # 80011788 <cpu_runnable_list>
        p->state = RUNNABLE;
    800028d8:	4b8d                	li	s7,3
  while(pentry != END)
    800028da:	5a7d                	li	s4,-1
    800028dc:	a821                	j	800028f4 <wakeup+0x68>
      release(&p->lock);
    800028de:	856a                	mv	a0,s10
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	3b8080e7          	jalr	952(ra) # 80000c98 <release>
    pentry = proc[pentry].next;
    800028e8:	033484b3          	mul	s1,s1,s3
    800028ec:	94ca                	add	s1,s1,s2
    800028ee:	58c4                	lw	s1,52(s1)
  while(pentry != END)
    800028f0:	05448d63          	beq	s1,s4,8000294a <wakeup+0xbe>
    p = &proc[pentry];
    800028f4:	03348d33          	mul	s10,s1,s3
    800028f8:	9d4a                	add	s10,s10,s2
    if(p != myproc())
    800028fa:	fffff097          	auipc	ra,0xfffff
    800028fe:	00e080e7          	jalr	14(ra) # 80001908 <myproc>
    80002902:	fead03e3          	beq	s10,a0,800028e8 <wakeup+0x5c>
      acquire(&p->lock);
    80002906:	856a                	mv	a0,s10
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	2dc080e7          	jalr	732(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) 
    80002910:	018d2783          	lw	a5,24(s10)
    80002914:	fd5795e3          	bne	a5,s5,800028de <wakeup+0x52>
    80002918:	020d3783          	ld	a5,32(s10)
    8000291c:	fd6791e3          	bne	a5,s6,800028de <wakeup+0x52>
        remove(&sleeping_list, pentry);
    80002920:	85a6                	mv	a1,s1
    80002922:	8566                	mv	a0,s9
    80002924:	00000097          	auipc	ra,0x0
    80002928:	946080e7          	jalr	-1722(ra) # 8000226a <remove>
        enqueue(&cpu_runnable_list[p->affiliated_cpu], pentry);
    8000292c:	050d2783          	lw	a5,80(s10)
    80002930:	00279513          	slli	a0,a5,0x2
    80002934:	953e                	add	a0,a0,a5
    80002936:	050e                	slli	a0,a0,0x3
    80002938:	85a6                	mv	a1,s1
    8000293a:	9562                	add	a0,a0,s8
    8000293c:	fffff097          	auipc	ra,0xfffff
    80002940:	458080e7          	jalr	1112(ra) # 80001d94 <enqueue>
        p->state = RUNNABLE;
    80002944:	017d2c23          	sw	s7,24(s10)
    80002948:	bf59                	j	800028de <wakeup+0x52>
}
    8000294a:	70a6                	ld	ra,104(sp)
    8000294c:	7406                	ld	s0,96(sp)
    8000294e:	64e6                	ld	s1,88(sp)
    80002950:	6946                	ld	s2,80(sp)
    80002952:	69a6                	ld	s3,72(sp)
    80002954:	6a06                	ld	s4,64(sp)
    80002956:	7ae2                	ld	s5,56(sp)
    80002958:	7b42                	ld	s6,48(sp)
    8000295a:	7ba2                	ld	s7,40(sp)
    8000295c:	7c02                	ld	s8,32(sp)
    8000295e:	6ce2                	ld	s9,24(sp)
    80002960:	6d42                	ld	s10,16(sp)
    80002962:	6da2                	ld	s11,8(sp)
    80002964:	6165                	addi	sp,sp,112
    80002966:	8082                	ret

0000000080002968 <reparent>:
{
    80002968:	7179                	addi	sp,sp,-48
    8000296a:	f406                	sd	ra,40(sp)
    8000296c:	f022                	sd	s0,32(sp)
    8000296e:	ec26                	sd	s1,24(sp)
    80002970:	e84a                	sd	s2,16(sp)
    80002972:	e44e                	sd	s3,8(sp)
    80002974:	e052                	sd	s4,0(sp)
    80002976:	1800                	addi	s0,sp,48
    80002978:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000297a:	0000f497          	auipc	s1,0xf
    8000297e:	f4e48493          	addi	s1,s1,-178 # 800118c8 <proc>
      pp->parent = initproc;
    80002982:	00006a17          	auipc	s4,0x6
    80002986:	6a6a0a13          	addi	s4,s4,1702 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000298a:	00015997          	auipc	s3,0x15
    8000298e:	13e98993          	addi	s3,s3,318 # 80017ac8 <cpus_lock>
    80002992:	a029                	j	8000299c <reparent+0x34>
    80002994:	18848493          	addi	s1,s1,392
    80002998:	01348d63          	beq	s1,s3,800029b2 <reparent+0x4a>
    if(pp->parent == p){
    8000299c:	6cbc                	ld	a5,88(s1)
    8000299e:	ff279be3          	bne	a5,s2,80002994 <reparent+0x2c>
      pp->parent = initproc;
    800029a2:	000a3503          	ld	a0,0(s4)
    800029a6:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	ee4080e7          	jalr	-284(ra) # 8000288c <wakeup>
    800029b0:	b7d5                	j	80002994 <reparent+0x2c>
}
    800029b2:	70a2                	ld	ra,40(sp)
    800029b4:	7402                	ld	s0,32(sp)
    800029b6:	64e2                	ld	s1,24(sp)
    800029b8:	6942                	ld	s2,16(sp)
    800029ba:	69a2                	ld	s3,8(sp)
    800029bc:	6a02                	ld	s4,0(sp)
    800029be:	6145                	addi	sp,sp,48
    800029c0:	8082                	ret

00000000800029c2 <exit>:
{
    800029c2:	7179                	addi	sp,sp,-48
    800029c4:	f406                	sd	ra,40(sp)
    800029c6:	f022                	sd	s0,32(sp)
    800029c8:	ec26                	sd	s1,24(sp)
    800029ca:	e84a                	sd	s2,16(sp)
    800029cc:	e44e                	sd	s3,8(sp)
    800029ce:	e052                	sd	s4,0(sp)
    800029d0:	1800                	addi	s0,sp,48
    800029d2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	f34080e7          	jalr	-204(ra) # 80001908 <myproc>
    800029dc:	89aa                	mv	s3,a0
  if(p == initproc)
    800029de:	00006797          	auipc	a5,0x6
    800029e2:	64a7b783          	ld	a5,1610(a5) # 80009028 <initproc>
    800029e6:	0f050493          	addi	s1,a0,240
    800029ea:	17050913          	addi	s2,a0,368
    800029ee:	02a79363          	bne	a5,a0,80002a14 <exit+0x52>
    panic("init exiting");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	8c650513          	addi	a0,a0,-1850 # 800082b8 <digits+0x278>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b44080e7          	jalr	-1212(ra) # 8000053e <panic>
      fileclose(f);
    80002a02:	00002097          	auipc	ra,0x2
    80002a06:	168080e7          	jalr	360(ra) # 80004b6a <fileclose>
      p->ofile[fd] = 0;
    80002a0a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a0e:	04a1                	addi	s1,s1,8
    80002a10:	01248563          	beq	s1,s2,80002a1a <exit+0x58>
    if(p->ofile[fd]){
    80002a14:	6088                	ld	a0,0(s1)
    80002a16:	f575                	bnez	a0,80002a02 <exit+0x40>
    80002a18:	bfdd                	j	80002a0e <exit+0x4c>
  begin_op();
    80002a1a:	00002097          	auipc	ra,0x2
    80002a1e:	c84080e7          	jalr	-892(ra) # 8000469e <begin_op>
  iput(p->cwd);
    80002a22:	1709b503          	ld	a0,368(s3)
    80002a26:	00001097          	auipc	ra,0x1
    80002a2a:	460080e7          	jalr	1120(ra) # 80003e86 <iput>
  end_op();
    80002a2e:	00002097          	auipc	ra,0x2
    80002a32:	cf0080e7          	jalr	-784(ra) # 8000471e <end_op>
  p->cwd = 0;
    80002a36:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002a3a:	0000f497          	auipc	s1,0xf
    80002a3e:	cbe48493          	addi	s1,s1,-834 # 800116f8 <wait_lock>
    80002a42:	8526                	mv	a0,s1
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  reparent(p);
    80002a4c:	854e                	mv	a0,s3
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	f1a080e7          	jalr	-230(ra) # 80002968 <reparent>
  wakeup(p->parent);
    80002a56:	0589b503          	ld	a0,88(s3)
    80002a5a:	00000097          	auipc	ra,0x0
    80002a5e:	e32080e7          	jalr	-462(ra) # 8000288c <wakeup>
  acquire(&p->lock);
    80002a62:	854e                	mv	a0,s3
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	180080e7          	jalr	384(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a6c:	0349a623          	sw	s4,44(s3)
  enqueue(&zombie_list, p->entry);
    80002a70:	0549a583          	lw	a1,84(s3)
    80002a74:	0000f517          	auipc	a0,0xf
    80002a78:	cec50513          	addi	a0,a0,-788 # 80011760 <zombie_list>
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	318080e7          	jalr	792(ra) # 80001d94 <enqueue>
  p->state = ZOMBIE;
    80002a84:	4795                	li	a5,5
    80002a86:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	20c080e7          	jalr	524(ra) # 80000c98 <release>
  sched();
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	098080e7          	jalr	152(ra) # 80001b2c <sched>
  panic("zombie exit");
    80002a9c:	00006517          	auipc	a0,0x6
    80002aa0:	82c50513          	addi	a0,a0,-2004 # 800082c8 <digits+0x288>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	a9a080e7          	jalr	-1382(ra) # 8000053e <panic>

0000000080002aac <kill>:
{
    80002aac:	7179                	addi	sp,sp,-48
    80002aae:	f406                	sd	ra,40(sp)
    80002ab0:	f022                	sd	s0,32(sp)
    80002ab2:	ec26                	sd	s1,24(sp)
    80002ab4:	e84a                	sd	s2,16(sp)
    80002ab6:	e44e                	sd	s3,8(sp)
    80002ab8:	1800                	addi	s0,sp,48
    80002aba:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002abc:	0000f497          	auipc	s1,0xf
    80002ac0:	e0c48493          	addi	s1,s1,-500 # 800118c8 <proc>
    80002ac4:	00015997          	auipc	s3,0x15
    80002ac8:	00498993          	addi	s3,s3,4 # 80017ac8 <cpus_lock>
    acquire(&p->lock);
    80002acc:	8526                	mv	a0,s1
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	116080e7          	jalr	278(ra) # 80000be4 <acquire>
    if(p->pid == pid)
    80002ad6:	589c                	lw	a5,48(s1)
    80002ad8:	01278d63          	beq	a5,s2,80002af2 <kill+0x46>
    release(&p->lock);
    80002adc:	8526                	mv	a0,s1
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	1ba080e7          	jalr	442(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ae6:	18848493          	addi	s1,s1,392
    80002aea:	ff3491e3          	bne	s1,s3,80002acc <kill+0x20>
  return -1;
    80002aee:	557d                	li	a0,-1
    80002af0:	a829                	j	80002b0a <kill+0x5e>
      p->killed = 1;
    80002af2:	4785                	li	a5,1
    80002af4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002af6:	4c98                	lw	a4,24(s1)
    80002af8:	4789                	li	a5,2
    80002afa:	00f70f63          	beq	a4,a5,80002b18 <kill+0x6c>
      release(&p->lock);
    80002afe:	8526                	mv	a0,s1
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
      return 0;
    80002b08:	4501                	li	a0,0
}
    80002b0a:	70a2                	ld	ra,40(sp)
    80002b0c:	7402                	ld	s0,32(sp)
    80002b0e:	64e2                	ld	s1,24(sp)
    80002b10:	6942                	ld	s2,16(sp)
    80002b12:	69a2                	ld	s3,8(sp)
    80002b14:	6145                	addi	sp,sp,48
    80002b16:	8082                	ret
        pentry = p->entry;
    80002b18:	0544a903          	lw	s2,84(s1)
        remove(&sleeping_list, pentry);
    80002b1c:	85ca                	mv	a1,s2
    80002b1e:	0000f517          	auipc	a0,0xf
    80002b22:	c1a50513          	addi	a0,a0,-998 # 80011738 <sleeping_list>
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	744080e7          	jalr	1860(ra) # 8000226a <remove>
        enqueue(&cpu_runnable_list[p->affiliated_cpu], pentry);
    80002b2e:	48b8                	lw	a4,80(s1)
    80002b30:	00271793          	slli	a5,a4,0x2
    80002b34:	97ba                	add	a5,a5,a4
    80002b36:	078e                	slli	a5,a5,0x3
    80002b38:	85ca                	mv	a1,s2
    80002b3a:	0000f517          	auipc	a0,0xf
    80002b3e:	c4e50513          	addi	a0,a0,-946 # 80011788 <cpu_runnable_list>
    80002b42:	953e                	add	a0,a0,a5
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	250080e7          	jalr	592(ra) # 80001d94 <enqueue>
        p->state = RUNNABLE;
    80002b4c:	478d                	li	a5,3
    80002b4e:	cc9c                	sw	a5,24(s1)
    80002b50:	b77d                	j	80002afe <kill+0x52>

0000000080002b52 <print_list>:

void
print_list(struct sentinel* list)
{
    80002b52:	7139                	addi	sp,sp,-64
    80002b54:	fc06                	sd	ra,56(sp)
    80002b56:	f822                	sd	s0,48(sp)
    80002b58:	f426                	sd	s1,40(sp)
    80002b5a:	f04a                	sd	s2,32(sp)
    80002b5c:	ec4e                	sd	s3,24(sp)
    80002b5e:	e852                	sd	s4,16(sp)
    80002b60:	e456                	sd	s5,8(sp)
    80002b62:	0080                	addi	s0,sp,64
    80002b64:	84aa                	mv	s1,a0
  printf("%s\n", list->name);
    80002b66:	710c                	ld	a1,32(a0)
    80002b68:	00005517          	auipc	a0,0x5
    80002b6c:	77050513          	addi	a0,a0,1904 # 800082d8 <digits+0x298>
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	a18080e7          	jalr	-1512(ra) # 80000588 <printf>
  struct proc* p;
  int pid, next;
  process_entry_t pentry = list->next;
    80002b78:	4084                	lw	s1,0(s1)

  while(pentry != END)
    80002b7a:	57fd                	li	a5,-1
    80002b7c:	02f48b63          	beq	s1,a5,80002bb2 <print_list+0x60>
  {
    p = &proc[pentry];
    pid = p->pid;
    80002b80:	0000fa97          	auipc	s5,0xf
    80002b84:	d48a8a93          	addi	s5,s5,-696 # 800118c8 <proc>
    80002b88:	18800a13          	li	s4,392
    next = p->next;
    printf("proc[%d], with pid %d, points to proc[%d]\n", pentry, pid, next);
    80002b8c:	00005997          	auipc	s3,0x5
    80002b90:	75498993          	addi	s3,s3,1876 # 800082e0 <digits+0x2a0>
  while(pentry != END)
    80002b94:	597d                	li	s2,-1
    pid = p->pid;
    80002b96:	034487b3          	mul	a5,s1,s4
    80002b9a:	97d6                	add	a5,a5,s5
    next = p->next;
    80002b9c:	85a6                	mv	a1,s1
    80002b9e:	5bc4                	lw	s1,52(a5)
    printf("proc[%d], with pid %d, points to proc[%d]\n", pentry, pid, next);
    80002ba0:	86a6                	mv	a3,s1
    80002ba2:	5b90                	lw	a2,48(a5)
    80002ba4:	854e                	mv	a0,s3
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9e2080e7          	jalr	-1566(ra) # 80000588 <printf>
  while(pentry != END)
    80002bae:	ff2494e3          	bne	s1,s2,80002b96 <print_list+0x44>
    pentry = next;
  }
}
    80002bb2:	70e2                	ld	ra,56(sp)
    80002bb4:	7442                	ld	s0,48(sp)
    80002bb6:	74a2                	ld	s1,40(sp)
    80002bb8:	7902                	ld	s2,32(sp)
    80002bba:	69e2                	ld	s3,24(sp)
    80002bbc:	6a42                	ld	s4,16(sp)
    80002bbe:	6aa2                	ld	s5,8(sp)
    80002bc0:	6121                	addi	sp,sp,64
    80002bc2:	8082                	ret

0000000080002bc4 <set_cpu>:

int
set_cpu(int cpu_num)
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	e04a                	sd	s2,0(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	d36080e7          	jalr	-714(ra) # 80001908 <myproc>
    80002bda:	892a                	mv	s2,a0
  p->affiliated_cpu = cpu_num;
    80002bdc:	c924                	sw	s1,80(a0)
  yield();
    80002bde:	fffff097          	auipc	ra,0xfffff
    80002be2:	44a080e7          	jalr	1098(ra) # 80002028 <yield>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002be6:	8792                	mv	a5,tp
  return cpuid() == p->affiliated_cpu ? cpu_num : -1;
    80002be8:	05092703          	lw	a4,80(s2)
    80002bec:	2781                	sext.w	a5,a5
    80002bee:	00f71963          	bne	a4,a5,80002c00 <set_cpu+0x3c>
}
    80002bf2:	8526                	mv	a0,s1
    80002bf4:	60e2                	ld	ra,24(sp)
    80002bf6:	6442                	ld	s0,16(sp)
    80002bf8:	64a2                	ld	s1,8(sp)
    80002bfa:	6902                	ld	s2,0(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret
  return cpuid() == p->affiliated_cpu ? cpu_num : -1;
    80002c00:	54fd                	li	s1,-1
    80002c02:	bfc5                	j	80002bf2 <set_cpu+0x2e>

0000000080002c04 <get_cpu>:

int
get_cpu(void)
{
    80002c04:	1141                	addi	sp,sp,-16
    80002c06:	e406                	sd	ra,8(sp)
    80002c08:	e022                	sd	s0,0(sp)
    80002c0a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	cfc080e7          	jalr	-772(ra) # 80001908 <myproc>
  return p->affiliated_cpu;
    80002c14:	4928                	lw	a0,80(a0)
    80002c16:	60a2                	ld	ra,8(sp)
    80002c18:	6402                	ld	s0,0(sp)
    80002c1a:	0141                	addi	sp,sp,16
    80002c1c:	8082                	ret

0000000080002c1e <swtch>:
    80002c1e:	00153023          	sd	ra,0(a0)
    80002c22:	00253423          	sd	sp,8(a0)
    80002c26:	e900                	sd	s0,16(a0)
    80002c28:	ed04                	sd	s1,24(a0)
    80002c2a:	03253023          	sd	s2,32(a0)
    80002c2e:	03353423          	sd	s3,40(a0)
    80002c32:	03453823          	sd	s4,48(a0)
    80002c36:	03553c23          	sd	s5,56(a0)
    80002c3a:	05653023          	sd	s6,64(a0)
    80002c3e:	05753423          	sd	s7,72(a0)
    80002c42:	05853823          	sd	s8,80(a0)
    80002c46:	05953c23          	sd	s9,88(a0)
    80002c4a:	07a53023          	sd	s10,96(a0)
    80002c4e:	07b53423          	sd	s11,104(a0)
    80002c52:	0005b083          	ld	ra,0(a1)
    80002c56:	0085b103          	ld	sp,8(a1)
    80002c5a:	6980                	ld	s0,16(a1)
    80002c5c:	6d84                	ld	s1,24(a1)
    80002c5e:	0205b903          	ld	s2,32(a1)
    80002c62:	0285b983          	ld	s3,40(a1)
    80002c66:	0305ba03          	ld	s4,48(a1)
    80002c6a:	0385ba83          	ld	s5,56(a1)
    80002c6e:	0405bb03          	ld	s6,64(a1)
    80002c72:	0485bb83          	ld	s7,72(a1)
    80002c76:	0505bc03          	ld	s8,80(a1)
    80002c7a:	0585bc83          	ld	s9,88(a1)
    80002c7e:	0605bd03          	ld	s10,96(a1)
    80002c82:	0685bd83          	ld	s11,104(a1)
    80002c86:	8082                	ret

0000000080002c88 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c88:	1141                	addi	sp,sp,-16
    80002c8a:	e406                	sd	ra,8(sp)
    80002c8c:	e022                	sd	s0,0(sp)
    80002c8e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c90:	00005597          	auipc	a1,0x5
    80002c94:	75858593          	addi	a1,a1,1880 # 800083e8 <cpu_runnable_list_names.1607+0x40>
    80002c98:	00015517          	auipc	a0,0x15
    80002c9c:	e4850513          	addi	a0,a0,-440 # 80017ae0 <tickslock>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	eb4080e7          	jalr	-332(ra) # 80000b54 <initlock>
}
    80002ca8:	60a2                	ld	ra,8(sp)
    80002caa:	6402                	ld	s0,0(sp)
    80002cac:	0141                	addi	sp,sp,16
    80002cae:	8082                	ret

0000000080002cb0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cb0:	1141                	addi	sp,sp,-16
    80002cb2:	e422                	sd	s0,8(sp)
    80002cb4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cb6:	00003797          	auipc	a5,0x3
    80002cba:	4ca78793          	addi	a5,a5,1226 # 80006180 <kernelvec>
    80002cbe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cc2:	6422                	ld	s0,8(sp)
    80002cc4:	0141                	addi	sp,sp,16
    80002cc6:	8082                	ret

0000000080002cc8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cc8:	1141                	addi	sp,sp,-16
    80002cca:	e406                	sd	ra,8(sp)
    80002ccc:	e022                	sd	s0,0(sp)
    80002cce:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	c38080e7          	jalr	-968(ra) # 80001908 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cdc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cde:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ce2:	00004617          	auipc	a2,0x4
    80002ce6:	31e60613          	addi	a2,a2,798 # 80007000 <_trampoline>
    80002cea:	00004697          	auipc	a3,0x4
    80002cee:	31668693          	addi	a3,a3,790 # 80007000 <_trampoline>
    80002cf2:	8e91                	sub	a3,a3,a2
    80002cf4:	040007b7          	lui	a5,0x4000
    80002cf8:	17fd                	addi	a5,a5,-1
    80002cfa:	07b2                	slli	a5,a5,0xc
    80002cfc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cfe:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d02:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d04:	180026f3          	csrr	a3,satp
    80002d08:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d0a:	7d38                	ld	a4,120(a0)
    80002d0c:	7134                	ld	a3,96(a0)
    80002d0e:	6585                	lui	a1,0x1
    80002d10:	96ae                	add	a3,a3,a1
    80002d12:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d14:	7d38                	ld	a4,120(a0)
    80002d16:	00000697          	auipc	a3,0x0
    80002d1a:	13868693          	addi	a3,a3,312 # 80002e4e <usertrap>
    80002d1e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d20:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d22:	8692                	mv	a3,tp
    80002d24:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d26:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d2a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d2e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d32:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d36:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d38:	6f18                	ld	a4,24(a4)
    80002d3a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d3e:	792c                	ld	a1,112(a0)
    80002d40:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d42:	00004717          	auipc	a4,0x4
    80002d46:	34e70713          	addi	a4,a4,846 # 80007090 <userret>
    80002d4a:	8f11                	sub	a4,a4,a2
    80002d4c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d4e:	577d                	li	a4,-1
    80002d50:	177e                	slli	a4,a4,0x3f
    80002d52:	8dd9                	or	a1,a1,a4
    80002d54:	02000537          	lui	a0,0x2000
    80002d58:	157d                	addi	a0,a0,-1
    80002d5a:	0536                	slli	a0,a0,0xd
    80002d5c:	9782                	jalr	a5
}
    80002d5e:	60a2                	ld	ra,8(sp)
    80002d60:	6402                	ld	s0,0(sp)
    80002d62:	0141                	addi	sp,sp,16
    80002d64:	8082                	ret

0000000080002d66 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	e426                	sd	s1,8(sp)
    80002d6e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d70:	00015497          	auipc	s1,0x15
    80002d74:	d7048493          	addi	s1,s1,-656 # 80017ae0 <tickslock>
    80002d78:	8526                	mv	a0,s1
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	e6a080e7          	jalr	-406(ra) # 80000be4 <acquire>
  ticks++;
    80002d82:	00006517          	auipc	a0,0x6
    80002d86:	2ae50513          	addi	a0,a0,686 # 80009030 <ticks>
    80002d8a:	411c                	lw	a5,0(a0)
    80002d8c:	2785                	addiw	a5,a5,1
    80002d8e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	afc080e7          	jalr	-1284(ra) # 8000288c <wakeup>
  release(&tickslock);
    80002d98:	8526                	mv	a0,s1
    80002d9a:	ffffe097          	auipc	ra,0xffffe
    80002d9e:	efe080e7          	jalr	-258(ra) # 80000c98 <release>
}
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	64a2                	ld	s1,8(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret

0000000080002dac <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	e426                	sd	s1,8(sp)
    80002db4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002dba:	00074d63          	bltz	a4,80002dd4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002dbe:	57fd                	li	a5,-1
    80002dc0:	17fe                	slli	a5,a5,0x3f
    80002dc2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dc4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dc6:	06f70363          	beq	a4,a5,80002e2c <devintr+0x80>
  }
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret
     (scause & 0xff) == 9){
    80002dd4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002dd8:	46a5                	li	a3,9
    80002dda:	fed792e3          	bne	a5,a3,80002dbe <devintr+0x12>
    int irq = plic_claim();
    80002dde:	00003097          	auipc	ra,0x3
    80002de2:	4aa080e7          	jalr	1194(ra) # 80006288 <plic_claim>
    80002de6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002de8:	47a9                	li	a5,10
    80002dea:	02f50763          	beq	a0,a5,80002e18 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002dee:	4785                	li	a5,1
    80002df0:	02f50963          	beq	a0,a5,80002e22 <devintr+0x76>
    return 1;
    80002df4:	4505                	li	a0,1
    } else if(irq){
    80002df6:	d8f1                	beqz	s1,80002dca <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002df8:	85a6                	mv	a1,s1
    80002dfa:	00005517          	auipc	a0,0x5
    80002dfe:	5f650513          	addi	a0,a0,1526 # 800083f0 <cpu_runnable_list_names.1607+0x48>
    80002e02:	ffffd097          	auipc	ra,0xffffd
    80002e06:	786080e7          	jalr	1926(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e0a:	8526                	mv	a0,s1
    80002e0c:	00003097          	auipc	ra,0x3
    80002e10:	4a0080e7          	jalr	1184(ra) # 800062ac <plic_complete>
    return 1;
    80002e14:	4505                	li	a0,1
    80002e16:	bf55                	j	80002dca <devintr+0x1e>
      uartintr();
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	b90080e7          	jalr	-1136(ra) # 800009a8 <uartintr>
    80002e20:	b7ed                	j	80002e0a <devintr+0x5e>
      virtio_disk_intr();
    80002e22:	00004097          	auipc	ra,0x4
    80002e26:	96a080e7          	jalr	-1686(ra) # 8000678c <virtio_disk_intr>
    80002e2a:	b7c5                	j	80002e0a <devintr+0x5e>
    if(cpuid() == 0){
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	aa8080e7          	jalr	-1368(ra) # 800018d4 <cpuid>
    80002e34:	c901                	beqz	a0,80002e44 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e36:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e3a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e3c:	14479073          	csrw	sip,a5
    return 2;
    80002e40:	4509                	li	a0,2
    80002e42:	b761                	j	80002dca <devintr+0x1e>
      clockintr();
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	f22080e7          	jalr	-222(ra) # 80002d66 <clockintr>
    80002e4c:	b7ed                	j	80002e36 <devintr+0x8a>

0000000080002e4e <usertrap>:
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	e04a                	sd	s2,0(sp)
    80002e58:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e5a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e5e:	1007f793          	andi	a5,a5,256
    80002e62:	e3ad                	bnez	a5,80002ec4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e64:	00003797          	auipc	a5,0x3
    80002e68:	31c78793          	addi	a5,a5,796 # 80006180 <kernelvec>
    80002e6c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	a98080e7          	jalr	-1384(ra) # 80001908 <myproc>
    80002e78:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e7a:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e7c:	14102773          	csrr	a4,sepc
    80002e80:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e82:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e86:	47a1                	li	a5,8
    80002e88:	04f71c63          	bne	a4,a5,80002ee0 <usertrap+0x92>
    if(p->killed)
    80002e8c:	551c                	lw	a5,40(a0)
    80002e8e:	e3b9                	bnez	a5,80002ed4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e90:	7cb8                	ld	a4,120(s1)
    80002e92:	6f1c                	ld	a5,24(a4)
    80002e94:	0791                	addi	a5,a5,4
    80002e96:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e9c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ea0:	10079073          	csrw	sstatus,a5
    syscall();
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	2e0080e7          	jalr	736(ra) # 80003184 <syscall>
  if(p->killed)
    80002eac:	549c                	lw	a5,40(s1)
    80002eae:	ebc1                	bnez	a5,80002f3e <usertrap+0xf0>
  usertrapret();
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	e18080e7          	jalr	-488(ra) # 80002cc8 <usertrapret>
}
    80002eb8:	60e2                	ld	ra,24(sp)
    80002eba:	6442                	ld	s0,16(sp)
    80002ebc:	64a2                	ld	s1,8(sp)
    80002ebe:	6902                	ld	s2,0(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret
    panic("usertrap: not from user mode");
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	54c50513          	addi	a0,a0,1356 # 80008410 <cpu_runnable_list_names.1607+0x68>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	672080e7          	jalr	1650(ra) # 8000053e <panic>
      exit(-1);
    80002ed4:	557d                	li	a0,-1
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	aec080e7          	jalr	-1300(ra) # 800029c2 <exit>
    80002ede:	bf4d                	j	80002e90 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	ecc080e7          	jalr	-308(ra) # 80002dac <devintr>
    80002ee8:	892a                	mv	s2,a0
    80002eea:	c501                	beqz	a0,80002ef2 <usertrap+0xa4>
  if(p->killed)
    80002eec:	549c                	lw	a5,40(s1)
    80002eee:	c3a1                	beqz	a5,80002f2e <usertrap+0xe0>
    80002ef0:	a815                	j	80002f24 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ef2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ef6:	5890                	lw	a2,48(s1)
    80002ef8:	00005517          	auipc	a0,0x5
    80002efc:	53850513          	addi	a0,a0,1336 # 80008430 <cpu_runnable_list_names.1607+0x88>
    80002f00:	ffffd097          	auipc	ra,0xffffd
    80002f04:	688080e7          	jalr	1672(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f08:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f0c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f10:	00005517          	auipc	a0,0x5
    80002f14:	55050513          	addi	a0,a0,1360 # 80008460 <cpu_runnable_list_names.1607+0xb8>
    80002f18:	ffffd097          	auipc	ra,0xffffd
    80002f1c:	670080e7          	jalr	1648(ra) # 80000588 <printf>
    p->killed = 1;
    80002f20:	4785                	li	a5,1
    80002f22:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f24:	557d                	li	a0,-1
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	a9c080e7          	jalr	-1380(ra) # 800029c2 <exit>
  if(which_dev == 2)
    80002f2e:	4789                	li	a5,2
    80002f30:	f8f910e3          	bne	s2,a5,80002eb0 <usertrap+0x62>
    yield();
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	0f4080e7          	jalr	244(ra) # 80002028 <yield>
    80002f3c:	bf95                	j	80002eb0 <usertrap+0x62>
  int which_dev = 0;
    80002f3e:	4901                	li	s2,0
    80002f40:	b7d5                	j	80002f24 <usertrap+0xd6>

0000000080002f42 <kerneltrap>:
{
    80002f42:	7179                	addi	sp,sp,-48
    80002f44:	f406                	sd	ra,40(sp)
    80002f46:	f022                	sd	s0,32(sp)
    80002f48:	ec26                	sd	s1,24(sp)
    80002f4a:	e84a                	sd	s2,16(sp)
    80002f4c:	e44e                	sd	s3,8(sp)
    80002f4e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f50:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f54:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f58:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f5c:	1004f793          	andi	a5,s1,256
    80002f60:	cb85                	beqz	a5,80002f90 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f66:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f68:	ef85                	bnez	a5,80002fa0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	e42080e7          	jalr	-446(ra) # 80002dac <devintr>
    80002f72:	cd1d                	beqz	a0,80002fb0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f74:	4789                	li	a5,2
    80002f76:	06f50a63          	beq	a0,a5,80002fea <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f7a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f7e:	10049073          	csrw	sstatus,s1
}
    80002f82:	70a2                	ld	ra,40(sp)
    80002f84:	7402                	ld	s0,32(sp)
    80002f86:	64e2                	ld	s1,24(sp)
    80002f88:	6942                	ld	s2,16(sp)
    80002f8a:	69a2                	ld	s3,8(sp)
    80002f8c:	6145                	addi	sp,sp,48
    80002f8e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f90:	00005517          	auipc	a0,0x5
    80002f94:	4f050513          	addi	a0,a0,1264 # 80008480 <cpu_runnable_list_names.1607+0xd8>
    80002f98:	ffffd097          	auipc	ra,0xffffd
    80002f9c:	5a6080e7          	jalr	1446(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002fa0:	00005517          	auipc	a0,0x5
    80002fa4:	50850513          	addi	a0,a0,1288 # 800084a8 <cpu_runnable_list_names.1607+0x100>
    80002fa8:	ffffd097          	auipc	ra,0xffffd
    80002fac:	596080e7          	jalr	1430(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002fb0:	85ce                	mv	a1,s3
    80002fb2:	00005517          	auipc	a0,0x5
    80002fb6:	51650513          	addi	a0,a0,1302 # 800084c8 <cpu_runnable_list_names.1607+0x120>
    80002fba:	ffffd097          	auipc	ra,0xffffd
    80002fbe:	5ce080e7          	jalr	1486(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fc2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fc6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fca:	00005517          	auipc	a0,0x5
    80002fce:	50e50513          	addi	a0,a0,1294 # 800084d8 <cpu_runnable_list_names.1607+0x130>
    80002fd2:	ffffd097          	auipc	ra,0xffffd
    80002fd6:	5b6080e7          	jalr	1462(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002fda:	00005517          	auipc	a0,0x5
    80002fde:	51650513          	addi	a0,a0,1302 # 800084f0 <cpu_runnable_list_names.1607+0x148>
    80002fe2:	ffffd097          	auipc	ra,0xffffd
    80002fe6:	55c080e7          	jalr	1372(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	91e080e7          	jalr	-1762(ra) # 80001908 <myproc>
    80002ff2:	d541                	beqz	a0,80002f7a <kerneltrap+0x38>
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	914080e7          	jalr	-1772(ra) # 80001908 <myproc>
    80002ffc:	4d18                	lw	a4,24(a0)
    80002ffe:	4791                	li	a5,4
    80003000:	f6f71de3          	bne	a4,a5,80002f7a <kerneltrap+0x38>
    yield();
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	024080e7          	jalr	36(ra) # 80002028 <yield>
    8000300c:	b7bd                	j	80002f7a <kerneltrap+0x38>

000000008000300e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000300e:	1101                	addi	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	e426                	sd	s1,8(sp)
    80003016:	1000                	addi	s0,sp,32
    80003018:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	8ee080e7          	jalr	-1810(ra) # 80001908 <myproc>
  switch (n) {
    80003022:	4795                	li	a5,5
    80003024:	0497e163          	bltu	a5,s1,80003066 <argraw+0x58>
    80003028:	048a                	slli	s1,s1,0x2
    8000302a:	00005717          	auipc	a4,0x5
    8000302e:	4fe70713          	addi	a4,a4,1278 # 80008528 <cpu_runnable_list_names.1607+0x180>
    80003032:	94ba                	add	s1,s1,a4
    80003034:	409c                	lw	a5,0(s1)
    80003036:	97ba                	add	a5,a5,a4
    80003038:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000303a:	7d3c                	ld	a5,120(a0)
    8000303c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret
    return p->trapframe->a1;
    80003048:	7d3c                	ld	a5,120(a0)
    8000304a:	7fa8                	ld	a0,120(a5)
    8000304c:	bfcd                	j	8000303e <argraw+0x30>
    return p->trapframe->a2;
    8000304e:	7d3c                	ld	a5,120(a0)
    80003050:	63c8                	ld	a0,128(a5)
    80003052:	b7f5                	j	8000303e <argraw+0x30>
    return p->trapframe->a3;
    80003054:	7d3c                	ld	a5,120(a0)
    80003056:	67c8                	ld	a0,136(a5)
    80003058:	b7dd                	j	8000303e <argraw+0x30>
    return p->trapframe->a4;
    8000305a:	7d3c                	ld	a5,120(a0)
    8000305c:	6bc8                	ld	a0,144(a5)
    8000305e:	b7c5                	j	8000303e <argraw+0x30>
    return p->trapframe->a5;
    80003060:	7d3c                	ld	a5,120(a0)
    80003062:	6fc8                	ld	a0,152(a5)
    80003064:	bfe9                	j	8000303e <argraw+0x30>
  panic("argraw");
    80003066:	00005517          	auipc	a0,0x5
    8000306a:	49a50513          	addi	a0,a0,1178 # 80008500 <cpu_runnable_list_names.1607+0x158>
    8000306e:	ffffd097          	auipc	ra,0xffffd
    80003072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>

0000000080003076 <fetchaddr>:
{
    80003076:	1101                	addi	sp,sp,-32
    80003078:	ec06                	sd	ra,24(sp)
    8000307a:	e822                	sd	s0,16(sp)
    8000307c:	e426                	sd	s1,8(sp)
    8000307e:	e04a                	sd	s2,0(sp)
    80003080:	1000                	addi	s0,sp,32
    80003082:	84aa                	mv	s1,a0
    80003084:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	882080e7          	jalr	-1918(ra) # 80001908 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000308e:	753c                	ld	a5,104(a0)
    80003090:	02f4f863          	bgeu	s1,a5,800030c0 <fetchaddr+0x4a>
    80003094:	00848713          	addi	a4,s1,8
    80003098:	02e7e663          	bltu	a5,a4,800030c4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000309c:	46a1                	li	a3,8
    8000309e:	8626                	mv	a2,s1
    800030a0:	85ca                	mv	a1,s2
    800030a2:	7928                	ld	a0,112(a0)
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	65a080e7          	jalr	1626(ra) # 800016fe <copyin>
    800030ac:	00a03533          	snez	a0,a0
    800030b0:	40a00533          	neg	a0,a0
}
    800030b4:	60e2                	ld	ra,24(sp)
    800030b6:	6442                	ld	s0,16(sp)
    800030b8:	64a2                	ld	s1,8(sp)
    800030ba:	6902                	ld	s2,0(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret
    return -1;
    800030c0:	557d                	li	a0,-1
    800030c2:	bfcd                	j	800030b4 <fetchaddr+0x3e>
    800030c4:	557d                	li	a0,-1
    800030c6:	b7fd                	j	800030b4 <fetchaddr+0x3e>

00000000800030c8 <fetchstr>:
{
    800030c8:	7179                	addi	sp,sp,-48
    800030ca:	f406                	sd	ra,40(sp)
    800030cc:	f022                	sd	s0,32(sp)
    800030ce:	ec26                	sd	s1,24(sp)
    800030d0:	e84a                	sd	s2,16(sp)
    800030d2:	e44e                	sd	s3,8(sp)
    800030d4:	1800                	addi	s0,sp,48
    800030d6:	892a                	mv	s2,a0
    800030d8:	84ae                	mv	s1,a1
    800030da:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	82c080e7          	jalr	-2004(ra) # 80001908 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800030e4:	86ce                	mv	a3,s3
    800030e6:	864a                	mv	a2,s2
    800030e8:	85a6                	mv	a1,s1
    800030ea:	7928                	ld	a0,112(a0)
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	69e080e7          	jalr	1694(ra) # 8000178a <copyinstr>
  if(err < 0)
    800030f4:	00054763          	bltz	a0,80003102 <fetchstr+0x3a>
  return strlen(buf);
    800030f8:	8526                	mv	a0,s1
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	d6a080e7          	jalr	-662(ra) # 80000e64 <strlen>
}
    80003102:	70a2                	ld	ra,40(sp)
    80003104:	7402                	ld	s0,32(sp)
    80003106:	64e2                	ld	s1,24(sp)
    80003108:	6942                	ld	s2,16(sp)
    8000310a:	69a2                	ld	s3,8(sp)
    8000310c:	6145                	addi	sp,sp,48
    8000310e:	8082                	ret

0000000080003110 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003110:	1101                	addi	sp,sp,-32
    80003112:	ec06                	sd	ra,24(sp)
    80003114:	e822                	sd	s0,16(sp)
    80003116:	e426                	sd	s1,8(sp)
    80003118:	1000                	addi	s0,sp,32
    8000311a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	ef2080e7          	jalr	-270(ra) # 8000300e <argraw>
    80003124:	c088                	sw	a0,0(s1)
  return 0;
}
    80003126:	4501                	li	a0,0
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	64a2                	ld	s1,8(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret

0000000080003132 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	e426                	sd	s1,8(sp)
    8000313a:	1000                	addi	s0,sp,32
    8000313c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000313e:	00000097          	auipc	ra,0x0
    80003142:	ed0080e7          	jalr	-304(ra) # 8000300e <argraw>
    80003146:	e088                	sd	a0,0(s1)
  return 0;
}
    80003148:	4501                	li	a0,0
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret

0000000080003154 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	e426                	sd	s1,8(sp)
    8000315c:	e04a                	sd	s2,0(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84ae                	mv	s1,a1
    80003162:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003164:	00000097          	auipc	ra,0x0
    80003168:	eaa080e7          	jalr	-342(ra) # 8000300e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000316c:	864a                	mv	a2,s2
    8000316e:	85a6                	mv	a1,s1
    80003170:	00000097          	auipc	ra,0x0
    80003174:	f58080e7          	jalr	-168(ra) # 800030c8 <fetchstr>
}
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	64a2                	ld	s1,8(sp)
    8000317e:	6902                	ld	s2,0(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret

0000000080003184 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	e04a                	sd	s2,0(sp)
    8000318e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	778080e7          	jalr	1912(ra) # 80001908 <myproc>
    80003198:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000319a:	07853903          	ld	s2,120(a0)
    8000319e:	0a893783          	ld	a5,168(s2)
    800031a2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031a6:	37fd                	addiw	a5,a5,-1
    800031a8:	4759                	li	a4,22
    800031aa:	00f76f63          	bltu	a4,a5,800031c8 <syscall+0x44>
    800031ae:	00369713          	slli	a4,a3,0x3
    800031b2:	00005797          	auipc	a5,0x5
    800031b6:	38e78793          	addi	a5,a5,910 # 80008540 <syscalls>
    800031ba:	97ba                	add	a5,a5,a4
    800031bc:	639c                	ld	a5,0(a5)
    800031be:	c789                	beqz	a5,800031c8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031c0:	9782                	jalr	a5
    800031c2:	06a93823          	sd	a0,112(s2)
    800031c6:	a839                	j	800031e4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031c8:	17848613          	addi	a2,s1,376
    800031cc:	588c                	lw	a1,48(s1)
    800031ce:	00005517          	auipc	a0,0x5
    800031d2:	33a50513          	addi	a0,a0,826 # 80008508 <cpu_runnable_list_names.1607+0x160>
    800031d6:	ffffd097          	auipc	ra,0xffffd
    800031da:	3b2080e7          	jalr	946(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031de:	7cbc                	ld	a5,120(s1)
    800031e0:	577d                	li	a4,-1
    800031e2:	fbb8                	sd	a4,112(a5)
  }
}
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	64a2                	ld	s1,8(sp)
    800031ea:	6902                	ld	s2,0(sp)
    800031ec:	6105                	addi	sp,sp,32
    800031ee:	8082                	ret

00000000800031f0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031f0:	1101                	addi	sp,sp,-32
    800031f2:	ec06                	sd	ra,24(sp)
    800031f4:	e822                	sd	s0,16(sp)
    800031f6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800031f8:	fec40593          	addi	a1,s0,-20
    800031fc:	4501                	li	a0,0
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	f12080e7          	jalr	-238(ra) # 80003110 <argint>
    return -1;
    80003206:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003208:	00054963          	bltz	a0,8000321a <sys_exit+0x2a>
  exit(n);
    8000320c:	fec42503          	lw	a0,-20(s0)
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	7b2080e7          	jalr	1970(ra) # 800029c2 <exit>
  return 0;  // not reached
    80003218:	4781                	li	a5,0
}
    8000321a:	853e                	mv	a0,a5
    8000321c:	60e2                	ld	ra,24(sp)
    8000321e:	6442                	ld	s0,16(sp)
    80003220:	6105                	addi	sp,sp,32
    80003222:	8082                	ret

0000000080003224 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003224:	1141                	addi	sp,sp,-16
    80003226:	e406                	sd	ra,8(sp)
    80003228:	e022                	sd	s0,0(sp)
    8000322a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	6dc080e7          	jalr	1756(ra) # 80001908 <myproc>
}
    80003234:	5908                	lw	a0,48(a0)
    80003236:	60a2                	ld	ra,8(sp)
    80003238:	6402                	ld	s0,0(sp)
    8000323a:	0141                	addi	sp,sp,16
    8000323c:	8082                	ret

000000008000323e <sys_fork>:

uint64
sys_fork(void)
{
    8000323e:	1141                	addi	sp,sp,-16
    80003240:	e406                	sd	ra,8(sp)
    80003242:	e022                	sd	s0,0(sp)
    80003244:	0800                	addi	s0,sp,16
  return fork();
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	3b8080e7          	jalr	952(ra) # 800025fe <fork>
}
    8000324e:	60a2                	ld	ra,8(sp)
    80003250:	6402                	ld	s0,0(sp)
    80003252:	0141                	addi	sp,sp,16
    80003254:	8082                	ret

0000000080003256 <sys_wait>:

uint64
sys_wait(void)
{
    80003256:	1101                	addi	sp,sp,-32
    80003258:	ec06                	sd	ra,24(sp)
    8000325a:	e822                	sd	s0,16(sp)
    8000325c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000325e:	fe840593          	addi	a1,s0,-24
    80003262:	4501                	li	a0,0
    80003264:	00000097          	auipc	ra,0x0
    80003268:	ece080e7          	jalr	-306(ra) # 80003132 <argaddr>
    8000326c:	87aa                	mv	a5,a0
    return -1;
    8000326e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003270:	0007c863          	bltz	a5,80003280 <sys_wait+0x2a>
  return wait(p);
    80003274:	fe843503          	ld	a0,-24(s0)
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	4ec080e7          	jalr	1260(ra) # 80002764 <wait>
}
    80003280:	60e2                	ld	ra,24(sp)
    80003282:	6442                	ld	s0,16(sp)
    80003284:	6105                	addi	sp,sp,32
    80003286:	8082                	ret

0000000080003288 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003288:	7179                	addi	sp,sp,-48
    8000328a:	f406                	sd	ra,40(sp)
    8000328c:	f022                	sd	s0,32(sp)
    8000328e:	ec26                	sd	s1,24(sp)
    80003290:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003292:	fdc40593          	addi	a1,s0,-36
    80003296:	4501                	li	a0,0
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	e78080e7          	jalr	-392(ra) # 80003110 <argint>
    800032a0:	87aa                	mv	a5,a0
    return -1;
    800032a2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032a4:	0207c063          	bltz	a5,800032c4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	660080e7          	jalr	1632(ra) # 80001908 <myproc>
    800032b0:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800032b2:	fdc42503          	lw	a0,-36(s0)
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	802080e7          	jalr	-2046(ra) # 80001ab8 <growproc>
    800032be:	00054863          	bltz	a0,800032ce <sys_sbrk+0x46>
    return -1;
  return addr;
    800032c2:	8526                	mv	a0,s1
}
    800032c4:	70a2                	ld	ra,40(sp)
    800032c6:	7402                	ld	s0,32(sp)
    800032c8:	64e2                	ld	s1,24(sp)
    800032ca:	6145                	addi	sp,sp,48
    800032cc:	8082                	ret
    return -1;
    800032ce:	557d                	li	a0,-1
    800032d0:	bfd5                	j	800032c4 <sys_sbrk+0x3c>

00000000800032d2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032d2:	7139                	addi	sp,sp,-64
    800032d4:	fc06                	sd	ra,56(sp)
    800032d6:	f822                	sd	s0,48(sp)
    800032d8:	f426                	sd	s1,40(sp)
    800032da:	f04a                	sd	s2,32(sp)
    800032dc:	ec4e                	sd	s3,24(sp)
    800032de:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800032e0:	fcc40593          	addi	a1,s0,-52
    800032e4:	4501                	li	a0,0
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	e2a080e7          	jalr	-470(ra) # 80003110 <argint>
    return -1;
    800032ee:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032f0:	06054563          	bltz	a0,8000335a <sys_sleep+0x88>
  acquire(&tickslock);
    800032f4:	00014517          	auipc	a0,0x14
    800032f8:	7ec50513          	addi	a0,a0,2028 # 80017ae0 <tickslock>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	8e8080e7          	jalr	-1816(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003304:	00006917          	auipc	s2,0x6
    80003308:	d2c92903          	lw	s2,-724(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000330c:	fcc42783          	lw	a5,-52(s0)
    80003310:	cf85                	beqz	a5,80003348 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003312:	00014997          	auipc	s3,0x14
    80003316:	7ce98993          	addi	s3,s3,1998 # 80017ae0 <tickslock>
    8000331a:	00006497          	auipc	s1,0x6
    8000331e:	d1648493          	addi	s1,s1,-746 # 80009030 <ticks>
    if(myproc()->killed){
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	5e6080e7          	jalr	1510(ra) # 80001908 <myproc>
    8000332a:	551c                	lw	a5,40(a0)
    8000332c:	ef9d                	bnez	a5,8000336a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000332e:	85ce                	mv	a1,s3
    80003330:	8526                	mv	a0,s1
    80003332:	fffff097          	auipc	ra,0xfffff
    80003336:	d50080e7          	jalr	-688(ra) # 80002082 <sleep>
  while(ticks - ticks0 < n){
    8000333a:	409c                	lw	a5,0(s1)
    8000333c:	412787bb          	subw	a5,a5,s2
    80003340:	fcc42703          	lw	a4,-52(s0)
    80003344:	fce7efe3          	bltu	a5,a4,80003322 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003348:	00014517          	auipc	a0,0x14
    8000334c:	79850513          	addi	a0,a0,1944 # 80017ae0 <tickslock>
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	948080e7          	jalr	-1720(ra) # 80000c98 <release>
  return 0;
    80003358:	4781                	li	a5,0
}
    8000335a:	853e                	mv	a0,a5
    8000335c:	70e2                	ld	ra,56(sp)
    8000335e:	7442                	ld	s0,48(sp)
    80003360:	74a2                	ld	s1,40(sp)
    80003362:	7902                	ld	s2,32(sp)
    80003364:	69e2                	ld	s3,24(sp)
    80003366:	6121                	addi	sp,sp,64
    80003368:	8082                	ret
      release(&tickslock);
    8000336a:	00014517          	auipc	a0,0x14
    8000336e:	77650513          	addi	a0,a0,1910 # 80017ae0 <tickslock>
    80003372:	ffffe097          	auipc	ra,0xffffe
    80003376:	926080e7          	jalr	-1754(ra) # 80000c98 <release>
      return -1;
    8000337a:	57fd                	li	a5,-1
    8000337c:	bff9                	j	8000335a <sys_sleep+0x88>

000000008000337e <sys_kill>:

uint64
sys_kill(void)
{
    8000337e:	1101                	addi	sp,sp,-32
    80003380:	ec06                	sd	ra,24(sp)
    80003382:	e822                	sd	s0,16(sp)
    80003384:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003386:	fec40593          	addi	a1,s0,-20
    8000338a:	4501                	li	a0,0
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	d84080e7          	jalr	-636(ra) # 80003110 <argint>
    80003394:	87aa                	mv	a5,a0
    return -1;
    80003396:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003398:	0007c863          	bltz	a5,800033a8 <sys_kill+0x2a>
  return kill(pid);
    8000339c:	fec42503          	lw	a0,-20(s0)
    800033a0:	fffff097          	auipc	ra,0xfffff
    800033a4:	70c080e7          	jalr	1804(ra) # 80002aac <kill>
}
    800033a8:	60e2                	ld	ra,24(sp)
    800033aa:	6442                	ld	s0,16(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033ba:	00014517          	auipc	a0,0x14
    800033be:	72650513          	addi	a0,a0,1830 # 80017ae0 <tickslock>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	822080e7          	jalr	-2014(ra) # 80000be4 <acquire>
  xticks = ticks;
    800033ca:	00006497          	auipc	s1,0x6
    800033ce:	c664a483          	lw	s1,-922(s1) # 80009030 <ticks>
  release(&tickslock);
    800033d2:	00014517          	auipc	a0,0x14
    800033d6:	70e50513          	addi	a0,a0,1806 # 80017ae0 <tickslock>
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	8be080e7          	jalr	-1858(ra) # 80000c98 <release>
  return xticks;
}
    800033e2:	02049513          	slli	a0,s1,0x20
    800033e6:	9101                	srli	a0,a0,0x20
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret

00000000800033f2 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    800033fa:	fec40593          	addi	a1,s0,-20
    800033fe:	4501                	li	a0,0
    80003400:	00000097          	auipc	ra,0x0
    80003404:	d10080e7          	jalr	-752(ra) # 80003110 <argint>
    80003408:	87aa                	mv	a5,a0
    return -1;
    8000340a:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    8000340c:	0007c863          	bltz	a5,8000341c <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    80003410:	fec42503          	lw	a0,-20(s0)
    80003414:	fffff097          	auipc	ra,0xfffff
    80003418:	7b0080e7          	jalr	1968(ra) # 80002bc4 <set_cpu>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	6105                	addi	sp,sp,32
    80003422:	8082                	ret

0000000080003424 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003424:	1141                	addi	sp,sp,-16
    80003426:	e406                	sd	ra,8(sp)
    80003428:	e022                	sd	s0,0(sp)
    8000342a:	0800                	addi	s0,sp,16
  return get_cpu();
    8000342c:	fffff097          	auipc	ra,0xfffff
    80003430:	7d8080e7          	jalr	2008(ra) # 80002c04 <get_cpu>
}
    80003434:	60a2                	ld	ra,8(sp)
    80003436:	6402                	ld	s0,0(sp)
    80003438:	0141                	addi	sp,sp,16
    8000343a:	8082                	ret

000000008000343c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000343c:	7179                	addi	sp,sp,-48
    8000343e:	f406                	sd	ra,40(sp)
    80003440:	f022                	sd	s0,32(sp)
    80003442:	ec26                	sd	s1,24(sp)
    80003444:	e84a                	sd	s2,16(sp)
    80003446:	e44e                	sd	s3,8(sp)
    80003448:	e052                	sd	s4,0(sp)
    8000344a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000344c:	00005597          	auipc	a1,0x5
    80003450:	1b458593          	addi	a1,a1,436 # 80008600 <syscalls+0xc0>
    80003454:	00014517          	auipc	a0,0x14
    80003458:	6a450513          	addi	a0,a0,1700 # 80017af8 <bcache>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	6f8080e7          	jalr	1784(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003464:	0001c797          	auipc	a5,0x1c
    80003468:	69478793          	addi	a5,a5,1684 # 8001faf8 <bcache+0x8000>
    8000346c:	0001d717          	auipc	a4,0x1d
    80003470:	8f470713          	addi	a4,a4,-1804 # 8001fd60 <bcache+0x8268>
    80003474:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003478:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000347c:	00014497          	auipc	s1,0x14
    80003480:	69448493          	addi	s1,s1,1684 # 80017b10 <bcache+0x18>
    b->next = bcache.head.next;
    80003484:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003486:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003488:	00005a17          	auipc	s4,0x5
    8000348c:	180a0a13          	addi	s4,s4,384 # 80008608 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003490:	2b893783          	ld	a5,696(s2)
    80003494:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003496:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000349a:	85d2                	mv	a1,s4
    8000349c:	01048513          	addi	a0,s1,16
    800034a0:	00001097          	auipc	ra,0x1
    800034a4:	4bc080e7          	jalr	1212(ra) # 8000495c <initsleeplock>
    bcache.head.next->prev = b;
    800034a8:	2b893783          	ld	a5,696(s2)
    800034ac:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034ae:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034b2:	45848493          	addi	s1,s1,1112
    800034b6:	fd349de3          	bne	s1,s3,80003490 <binit+0x54>
  }
}
    800034ba:	70a2                	ld	ra,40(sp)
    800034bc:	7402                	ld	s0,32(sp)
    800034be:	64e2                	ld	s1,24(sp)
    800034c0:	6942                	ld	s2,16(sp)
    800034c2:	69a2                	ld	s3,8(sp)
    800034c4:	6a02                	ld	s4,0(sp)
    800034c6:	6145                	addi	sp,sp,48
    800034c8:	8082                	ret

00000000800034ca <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034ca:	7179                	addi	sp,sp,-48
    800034cc:	f406                	sd	ra,40(sp)
    800034ce:	f022                	sd	s0,32(sp)
    800034d0:	ec26                	sd	s1,24(sp)
    800034d2:	e84a                	sd	s2,16(sp)
    800034d4:	e44e                	sd	s3,8(sp)
    800034d6:	1800                	addi	s0,sp,48
    800034d8:	89aa                	mv	s3,a0
    800034da:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800034dc:	00014517          	auipc	a0,0x14
    800034e0:	61c50513          	addi	a0,a0,1564 # 80017af8 <bcache>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	700080e7          	jalr	1792(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034ec:	0001d497          	auipc	s1,0x1d
    800034f0:	8c44b483          	ld	s1,-1852(s1) # 8001fdb0 <bcache+0x82b8>
    800034f4:	0001d797          	auipc	a5,0x1d
    800034f8:	86c78793          	addi	a5,a5,-1940 # 8001fd60 <bcache+0x8268>
    800034fc:	02f48f63          	beq	s1,a5,8000353a <bread+0x70>
    80003500:	873e                	mv	a4,a5
    80003502:	a021                	j	8000350a <bread+0x40>
    80003504:	68a4                	ld	s1,80(s1)
    80003506:	02e48a63          	beq	s1,a4,8000353a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000350a:	449c                	lw	a5,8(s1)
    8000350c:	ff379ce3          	bne	a5,s3,80003504 <bread+0x3a>
    80003510:	44dc                	lw	a5,12(s1)
    80003512:	ff2799e3          	bne	a5,s2,80003504 <bread+0x3a>
      b->refcnt++;
    80003516:	40bc                	lw	a5,64(s1)
    80003518:	2785                	addiw	a5,a5,1
    8000351a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000351c:	00014517          	auipc	a0,0x14
    80003520:	5dc50513          	addi	a0,a0,1500 # 80017af8 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	774080e7          	jalr	1908(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000352c:	01048513          	addi	a0,s1,16
    80003530:	00001097          	auipc	ra,0x1
    80003534:	466080e7          	jalr	1126(ra) # 80004996 <acquiresleep>
      return b;
    80003538:	a8b9                	j	80003596 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000353a:	0001d497          	auipc	s1,0x1d
    8000353e:	86e4b483          	ld	s1,-1938(s1) # 8001fda8 <bcache+0x82b0>
    80003542:	0001d797          	auipc	a5,0x1d
    80003546:	81e78793          	addi	a5,a5,-2018 # 8001fd60 <bcache+0x8268>
    8000354a:	00f48863          	beq	s1,a5,8000355a <bread+0x90>
    8000354e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003550:	40bc                	lw	a5,64(s1)
    80003552:	cf81                	beqz	a5,8000356a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003554:	64a4                	ld	s1,72(s1)
    80003556:	fee49de3          	bne	s1,a4,80003550 <bread+0x86>
  panic("bget: no buffers");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	0b650513          	addi	a0,a0,182 # 80008610 <syscalls+0xd0>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	fdc080e7          	jalr	-36(ra) # 8000053e <panic>
      b->dev = dev;
    8000356a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000356e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003572:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003576:	4785                	li	a5,1
    80003578:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000357a:	00014517          	auipc	a0,0x14
    8000357e:	57e50513          	addi	a0,a0,1406 # 80017af8 <bcache>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	716080e7          	jalr	1814(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000358a:	01048513          	addi	a0,s1,16
    8000358e:	00001097          	auipc	ra,0x1
    80003592:	408080e7          	jalr	1032(ra) # 80004996 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003596:	409c                	lw	a5,0(s1)
    80003598:	cb89                	beqz	a5,800035aa <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000359a:	8526                	mv	a0,s1
    8000359c:	70a2                	ld	ra,40(sp)
    8000359e:	7402                	ld	s0,32(sp)
    800035a0:	64e2                	ld	s1,24(sp)
    800035a2:	6942                	ld	s2,16(sp)
    800035a4:	69a2                	ld	s3,8(sp)
    800035a6:	6145                	addi	sp,sp,48
    800035a8:	8082                	ret
    virtio_disk_rw(b, 0);
    800035aa:	4581                	li	a1,0
    800035ac:	8526                	mv	a0,s1
    800035ae:	00003097          	auipc	ra,0x3
    800035b2:	f08080e7          	jalr	-248(ra) # 800064b6 <virtio_disk_rw>
    b->valid = 1;
    800035b6:	4785                	li	a5,1
    800035b8:	c09c                	sw	a5,0(s1)
  return b;
    800035ba:	b7c5                	j	8000359a <bread+0xd0>

00000000800035bc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035bc:	1101                	addi	sp,sp,-32
    800035be:	ec06                	sd	ra,24(sp)
    800035c0:	e822                	sd	s0,16(sp)
    800035c2:	e426                	sd	s1,8(sp)
    800035c4:	1000                	addi	s0,sp,32
    800035c6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035c8:	0541                	addi	a0,a0,16
    800035ca:	00001097          	auipc	ra,0x1
    800035ce:	466080e7          	jalr	1126(ra) # 80004a30 <holdingsleep>
    800035d2:	cd01                	beqz	a0,800035ea <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035d4:	4585                	li	a1,1
    800035d6:	8526                	mv	a0,s1
    800035d8:	00003097          	auipc	ra,0x3
    800035dc:	ede080e7          	jalr	-290(ra) # 800064b6 <virtio_disk_rw>
}
    800035e0:	60e2                	ld	ra,24(sp)
    800035e2:	6442                	ld	s0,16(sp)
    800035e4:	64a2                	ld	s1,8(sp)
    800035e6:	6105                	addi	sp,sp,32
    800035e8:	8082                	ret
    panic("bwrite");
    800035ea:	00005517          	auipc	a0,0x5
    800035ee:	03e50513          	addi	a0,a0,62 # 80008628 <syscalls+0xe8>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	f4c080e7          	jalr	-180(ra) # 8000053e <panic>

00000000800035fa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	e426                	sd	s1,8(sp)
    80003602:	e04a                	sd	s2,0(sp)
    80003604:	1000                	addi	s0,sp,32
    80003606:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003608:	01050913          	addi	s2,a0,16
    8000360c:	854a                	mv	a0,s2
    8000360e:	00001097          	auipc	ra,0x1
    80003612:	422080e7          	jalr	1058(ra) # 80004a30 <holdingsleep>
    80003616:	c92d                	beqz	a0,80003688 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003618:	854a                	mv	a0,s2
    8000361a:	00001097          	auipc	ra,0x1
    8000361e:	3d2080e7          	jalr	978(ra) # 800049ec <releasesleep>

  acquire(&bcache.lock);
    80003622:	00014517          	auipc	a0,0x14
    80003626:	4d650513          	addi	a0,a0,1238 # 80017af8 <bcache>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	5ba080e7          	jalr	1466(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003632:	40bc                	lw	a5,64(s1)
    80003634:	37fd                	addiw	a5,a5,-1
    80003636:	0007871b          	sext.w	a4,a5
    8000363a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000363c:	eb05                	bnez	a4,8000366c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000363e:	68bc                	ld	a5,80(s1)
    80003640:	64b8                	ld	a4,72(s1)
    80003642:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003644:	64bc                	ld	a5,72(s1)
    80003646:	68b8                	ld	a4,80(s1)
    80003648:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000364a:	0001c797          	auipc	a5,0x1c
    8000364e:	4ae78793          	addi	a5,a5,1198 # 8001faf8 <bcache+0x8000>
    80003652:	2b87b703          	ld	a4,696(a5)
    80003656:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003658:	0001c717          	auipc	a4,0x1c
    8000365c:	70870713          	addi	a4,a4,1800 # 8001fd60 <bcache+0x8268>
    80003660:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003662:	2b87b703          	ld	a4,696(a5)
    80003666:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003668:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000366c:	00014517          	auipc	a0,0x14
    80003670:	48c50513          	addi	a0,a0,1164 # 80017af8 <bcache>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	624080e7          	jalr	1572(ra) # 80000c98 <release>
}
    8000367c:	60e2                	ld	ra,24(sp)
    8000367e:	6442                	ld	s0,16(sp)
    80003680:	64a2                	ld	s1,8(sp)
    80003682:	6902                	ld	s2,0(sp)
    80003684:	6105                	addi	sp,sp,32
    80003686:	8082                	ret
    panic("brelse");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	fa850513          	addi	a0,a0,-88 # 80008630 <syscalls+0xf0>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	eae080e7          	jalr	-338(ra) # 8000053e <panic>

0000000080003698 <bpin>:

void
bpin(struct buf *b) {
    80003698:	1101                	addi	sp,sp,-32
    8000369a:	ec06                	sd	ra,24(sp)
    8000369c:	e822                	sd	s0,16(sp)
    8000369e:	e426                	sd	s1,8(sp)
    800036a0:	1000                	addi	s0,sp,32
    800036a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036a4:	00014517          	auipc	a0,0x14
    800036a8:	45450513          	addi	a0,a0,1108 # 80017af8 <bcache>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  b->refcnt++;
    800036b4:	40bc                	lw	a5,64(s1)
    800036b6:	2785                	addiw	a5,a5,1
    800036b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036ba:	00014517          	auipc	a0,0x14
    800036be:	43e50513          	addi	a0,a0,1086 # 80017af8 <bcache>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
}
    800036ca:	60e2                	ld	ra,24(sp)
    800036cc:	6442                	ld	s0,16(sp)
    800036ce:	64a2                	ld	s1,8(sp)
    800036d0:	6105                	addi	sp,sp,32
    800036d2:	8082                	ret

00000000800036d4 <bunpin>:

void
bunpin(struct buf *b) {
    800036d4:	1101                	addi	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	e426                	sd	s1,8(sp)
    800036dc:	1000                	addi	s0,sp,32
    800036de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e0:	00014517          	auipc	a0,0x14
    800036e4:	41850513          	addi	a0,a0,1048 # 80017af8 <bcache>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	4fc080e7          	jalr	1276(ra) # 80000be4 <acquire>
  b->refcnt--;
    800036f0:	40bc                	lw	a5,64(s1)
    800036f2:	37fd                	addiw	a5,a5,-1
    800036f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036f6:	00014517          	auipc	a0,0x14
    800036fa:	40250513          	addi	a0,a0,1026 # 80017af8 <bcache>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	59a080e7          	jalr	1434(ra) # 80000c98 <release>
}
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6105                	addi	sp,sp,32
    8000370e:	8082                	ret

0000000080003710 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	e04a                	sd	s2,0(sp)
    8000371a:	1000                	addi	s0,sp,32
    8000371c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000371e:	00d5d59b          	srliw	a1,a1,0xd
    80003722:	0001d797          	auipc	a5,0x1d
    80003726:	ab27a783          	lw	a5,-1358(a5) # 800201d4 <sb+0x1c>
    8000372a:	9dbd                	addw	a1,a1,a5
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	d9e080e7          	jalr	-610(ra) # 800034ca <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003734:	0074f713          	andi	a4,s1,7
    80003738:	4785                	li	a5,1
    8000373a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000373e:	14ce                	slli	s1,s1,0x33
    80003740:	90d9                	srli	s1,s1,0x36
    80003742:	00950733          	add	a4,a0,s1
    80003746:	05874703          	lbu	a4,88(a4)
    8000374a:	00e7f6b3          	and	a3,a5,a4
    8000374e:	c69d                	beqz	a3,8000377c <bfree+0x6c>
    80003750:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003752:	94aa                	add	s1,s1,a0
    80003754:	fff7c793          	not	a5,a5
    80003758:	8ff9                	and	a5,a5,a4
    8000375a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000375e:	00001097          	auipc	ra,0x1
    80003762:	118080e7          	jalr	280(ra) # 80004876 <log_write>
  brelse(bp);
    80003766:	854a                	mv	a0,s2
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	e92080e7          	jalr	-366(ra) # 800035fa <brelse>
}
    80003770:	60e2                	ld	ra,24(sp)
    80003772:	6442                	ld	s0,16(sp)
    80003774:	64a2                	ld	s1,8(sp)
    80003776:	6902                	ld	s2,0(sp)
    80003778:	6105                	addi	sp,sp,32
    8000377a:	8082                	ret
    panic("freeing free block");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	ebc50513          	addi	a0,a0,-324 # 80008638 <syscalls+0xf8>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	dba080e7          	jalr	-582(ra) # 8000053e <panic>

000000008000378c <balloc>:
{
    8000378c:	711d                	addi	sp,sp,-96
    8000378e:	ec86                	sd	ra,88(sp)
    80003790:	e8a2                	sd	s0,80(sp)
    80003792:	e4a6                	sd	s1,72(sp)
    80003794:	e0ca                	sd	s2,64(sp)
    80003796:	fc4e                	sd	s3,56(sp)
    80003798:	f852                	sd	s4,48(sp)
    8000379a:	f456                	sd	s5,40(sp)
    8000379c:	f05a                	sd	s6,32(sp)
    8000379e:	ec5e                	sd	s7,24(sp)
    800037a0:	e862                	sd	s8,16(sp)
    800037a2:	e466                	sd	s9,8(sp)
    800037a4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037a6:	0001d797          	auipc	a5,0x1d
    800037aa:	a167a783          	lw	a5,-1514(a5) # 800201bc <sb+0x4>
    800037ae:	cbd1                	beqz	a5,80003842 <balloc+0xb6>
    800037b0:	8baa                	mv	s7,a0
    800037b2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037b4:	0001db17          	auipc	s6,0x1d
    800037b8:	a04b0b13          	addi	s6,s6,-1532 # 800201b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037bc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037be:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037c2:	6c89                	lui	s9,0x2
    800037c4:	a831                	j	800037e0 <balloc+0x54>
    brelse(bp);
    800037c6:	854a                	mv	a0,s2
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	e32080e7          	jalr	-462(ra) # 800035fa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037d0:	015c87bb          	addw	a5,s9,s5
    800037d4:	00078a9b          	sext.w	s5,a5
    800037d8:	004b2703          	lw	a4,4(s6)
    800037dc:	06eaf363          	bgeu	s5,a4,80003842 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037e0:	41fad79b          	sraiw	a5,s5,0x1f
    800037e4:	0137d79b          	srliw	a5,a5,0x13
    800037e8:	015787bb          	addw	a5,a5,s5
    800037ec:	40d7d79b          	sraiw	a5,a5,0xd
    800037f0:	01cb2583          	lw	a1,28(s6)
    800037f4:	9dbd                	addw	a1,a1,a5
    800037f6:	855e                	mv	a0,s7
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	cd2080e7          	jalr	-814(ra) # 800034ca <bread>
    80003800:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003802:	004b2503          	lw	a0,4(s6)
    80003806:	000a849b          	sext.w	s1,s5
    8000380a:	8662                	mv	a2,s8
    8000380c:	faa4fde3          	bgeu	s1,a0,800037c6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003810:	41f6579b          	sraiw	a5,a2,0x1f
    80003814:	01d7d69b          	srliw	a3,a5,0x1d
    80003818:	00c6873b          	addw	a4,a3,a2
    8000381c:	00777793          	andi	a5,a4,7
    80003820:	9f95                	subw	a5,a5,a3
    80003822:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003826:	4037571b          	sraiw	a4,a4,0x3
    8000382a:	00e906b3          	add	a3,s2,a4
    8000382e:	0586c683          	lbu	a3,88(a3)
    80003832:	00d7f5b3          	and	a1,a5,a3
    80003836:	cd91                	beqz	a1,80003852 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003838:	2605                	addiw	a2,a2,1
    8000383a:	2485                	addiw	s1,s1,1
    8000383c:	fd4618e3          	bne	a2,s4,8000380c <balloc+0x80>
    80003840:	b759                	j	800037c6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003842:	00005517          	auipc	a0,0x5
    80003846:	e0e50513          	addi	a0,a0,-498 # 80008650 <syscalls+0x110>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	cf4080e7          	jalr	-780(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003852:	974a                	add	a4,a4,s2
    80003854:	8fd5                	or	a5,a5,a3
    80003856:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	01a080e7          	jalr	26(ra) # 80004876 <log_write>
        brelse(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	d94080e7          	jalr	-620(ra) # 800035fa <brelse>
  bp = bread(dev, bno);
    8000386e:	85a6                	mv	a1,s1
    80003870:	855e                	mv	a0,s7
    80003872:	00000097          	auipc	ra,0x0
    80003876:	c58080e7          	jalr	-936(ra) # 800034ca <bread>
    8000387a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000387c:	40000613          	li	a2,1024
    80003880:	4581                	li	a1,0
    80003882:	05850513          	addi	a0,a0,88
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	45a080e7          	jalr	1114(ra) # 80000ce0 <memset>
  log_write(bp);
    8000388e:	854a                	mv	a0,s2
    80003890:	00001097          	auipc	ra,0x1
    80003894:	fe6080e7          	jalr	-26(ra) # 80004876 <log_write>
  brelse(bp);
    80003898:	854a                	mv	a0,s2
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	d60080e7          	jalr	-672(ra) # 800035fa <brelse>
}
    800038a2:	8526                	mv	a0,s1
    800038a4:	60e6                	ld	ra,88(sp)
    800038a6:	6446                	ld	s0,80(sp)
    800038a8:	64a6                	ld	s1,72(sp)
    800038aa:	6906                	ld	s2,64(sp)
    800038ac:	79e2                	ld	s3,56(sp)
    800038ae:	7a42                	ld	s4,48(sp)
    800038b0:	7aa2                	ld	s5,40(sp)
    800038b2:	7b02                	ld	s6,32(sp)
    800038b4:	6be2                	ld	s7,24(sp)
    800038b6:	6c42                	ld	s8,16(sp)
    800038b8:	6ca2                	ld	s9,8(sp)
    800038ba:	6125                	addi	sp,sp,96
    800038bc:	8082                	ret

00000000800038be <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038be:	7179                	addi	sp,sp,-48
    800038c0:	f406                	sd	ra,40(sp)
    800038c2:	f022                	sd	s0,32(sp)
    800038c4:	ec26                	sd	s1,24(sp)
    800038c6:	e84a                	sd	s2,16(sp)
    800038c8:	e44e                	sd	s3,8(sp)
    800038ca:	e052                	sd	s4,0(sp)
    800038cc:	1800                	addi	s0,sp,48
    800038ce:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038d0:	47ad                	li	a5,11
    800038d2:	04b7fe63          	bgeu	a5,a1,8000392e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038d6:	ff45849b          	addiw	s1,a1,-12
    800038da:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038de:	0ff00793          	li	a5,255
    800038e2:	0ae7e363          	bltu	a5,a4,80003988 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038e6:	08052583          	lw	a1,128(a0)
    800038ea:	c5ad                	beqz	a1,80003954 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038ec:	00092503          	lw	a0,0(s2)
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	bda080e7          	jalr	-1062(ra) # 800034ca <bread>
    800038f8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038fa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038fe:	02049593          	slli	a1,s1,0x20
    80003902:	9181                	srli	a1,a1,0x20
    80003904:	058a                	slli	a1,a1,0x2
    80003906:	00b784b3          	add	s1,a5,a1
    8000390a:	0004a983          	lw	s3,0(s1)
    8000390e:	04098d63          	beqz	s3,80003968 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003912:	8552                	mv	a0,s4
    80003914:	00000097          	auipc	ra,0x0
    80003918:	ce6080e7          	jalr	-794(ra) # 800035fa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000391c:	854e                	mv	a0,s3
    8000391e:	70a2                	ld	ra,40(sp)
    80003920:	7402                	ld	s0,32(sp)
    80003922:	64e2                	ld	s1,24(sp)
    80003924:	6942                	ld	s2,16(sp)
    80003926:	69a2                	ld	s3,8(sp)
    80003928:	6a02                	ld	s4,0(sp)
    8000392a:	6145                	addi	sp,sp,48
    8000392c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000392e:	02059493          	slli	s1,a1,0x20
    80003932:	9081                	srli	s1,s1,0x20
    80003934:	048a                	slli	s1,s1,0x2
    80003936:	94aa                	add	s1,s1,a0
    80003938:	0504a983          	lw	s3,80(s1)
    8000393c:	fe0990e3          	bnez	s3,8000391c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003940:	4108                	lw	a0,0(a0)
    80003942:	00000097          	auipc	ra,0x0
    80003946:	e4a080e7          	jalr	-438(ra) # 8000378c <balloc>
    8000394a:	0005099b          	sext.w	s3,a0
    8000394e:	0534a823          	sw	s3,80(s1)
    80003952:	b7e9                	j	8000391c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003954:	4108                	lw	a0,0(a0)
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	e36080e7          	jalr	-458(ra) # 8000378c <balloc>
    8000395e:	0005059b          	sext.w	a1,a0
    80003962:	08b92023          	sw	a1,128(s2)
    80003966:	b759                	j	800038ec <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003968:	00092503          	lw	a0,0(s2)
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	e20080e7          	jalr	-480(ra) # 8000378c <balloc>
    80003974:	0005099b          	sext.w	s3,a0
    80003978:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000397c:	8552                	mv	a0,s4
    8000397e:	00001097          	auipc	ra,0x1
    80003982:	ef8080e7          	jalr	-264(ra) # 80004876 <log_write>
    80003986:	b771                	j	80003912 <bmap+0x54>
  panic("bmap: out of range");
    80003988:	00005517          	auipc	a0,0x5
    8000398c:	ce050513          	addi	a0,a0,-800 # 80008668 <syscalls+0x128>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	bae080e7          	jalr	-1106(ra) # 8000053e <panic>

0000000080003998 <iget>:
{
    80003998:	7179                	addi	sp,sp,-48
    8000399a:	f406                	sd	ra,40(sp)
    8000399c:	f022                	sd	s0,32(sp)
    8000399e:	ec26                	sd	s1,24(sp)
    800039a0:	e84a                	sd	s2,16(sp)
    800039a2:	e44e                	sd	s3,8(sp)
    800039a4:	e052                	sd	s4,0(sp)
    800039a6:	1800                	addi	s0,sp,48
    800039a8:	89aa                	mv	s3,a0
    800039aa:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039ac:	0001d517          	auipc	a0,0x1d
    800039b0:	82c50513          	addi	a0,a0,-2004 # 800201d8 <itable>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	230080e7          	jalr	560(ra) # 80000be4 <acquire>
  empty = 0;
    800039bc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039be:	0001d497          	auipc	s1,0x1d
    800039c2:	83248493          	addi	s1,s1,-1998 # 800201f0 <itable+0x18>
    800039c6:	0001e697          	auipc	a3,0x1e
    800039ca:	2ba68693          	addi	a3,a3,698 # 80021c80 <log>
    800039ce:	a039                	j	800039dc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039d0:	02090b63          	beqz	s2,80003a06 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039d4:	08848493          	addi	s1,s1,136
    800039d8:	02d48a63          	beq	s1,a3,80003a0c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039dc:	449c                	lw	a5,8(s1)
    800039de:	fef059e3          	blez	a5,800039d0 <iget+0x38>
    800039e2:	4098                	lw	a4,0(s1)
    800039e4:	ff3716e3          	bne	a4,s3,800039d0 <iget+0x38>
    800039e8:	40d8                	lw	a4,4(s1)
    800039ea:	ff4713e3          	bne	a4,s4,800039d0 <iget+0x38>
      ip->ref++;
    800039ee:	2785                	addiw	a5,a5,1
    800039f0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039f2:	0001c517          	auipc	a0,0x1c
    800039f6:	7e650513          	addi	a0,a0,2022 # 800201d8 <itable>
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	29e080e7          	jalr	670(ra) # 80000c98 <release>
      return ip;
    80003a02:	8926                	mv	s2,s1
    80003a04:	a03d                	j	80003a32 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a06:	f7f9                	bnez	a5,800039d4 <iget+0x3c>
    80003a08:	8926                	mv	s2,s1
    80003a0a:	b7e9                	j	800039d4 <iget+0x3c>
  if(empty == 0)
    80003a0c:	02090c63          	beqz	s2,80003a44 <iget+0xac>
  ip->dev = dev;
    80003a10:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a14:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a18:	4785                	li	a5,1
    80003a1a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a1e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a22:	0001c517          	auipc	a0,0x1c
    80003a26:	7b650513          	addi	a0,a0,1974 # 800201d8 <itable>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	26e080e7          	jalr	622(ra) # 80000c98 <release>
}
    80003a32:	854a                	mv	a0,s2
    80003a34:	70a2                	ld	ra,40(sp)
    80003a36:	7402                	ld	s0,32(sp)
    80003a38:	64e2                	ld	s1,24(sp)
    80003a3a:	6942                	ld	s2,16(sp)
    80003a3c:	69a2                	ld	s3,8(sp)
    80003a3e:	6a02                	ld	s4,0(sp)
    80003a40:	6145                	addi	sp,sp,48
    80003a42:	8082                	ret
    panic("iget: no inodes");
    80003a44:	00005517          	auipc	a0,0x5
    80003a48:	c3c50513          	addi	a0,a0,-964 # 80008680 <syscalls+0x140>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	af2080e7          	jalr	-1294(ra) # 8000053e <panic>

0000000080003a54 <fsinit>:
fsinit(int dev) {
    80003a54:	7179                	addi	sp,sp,-48
    80003a56:	f406                	sd	ra,40(sp)
    80003a58:	f022                	sd	s0,32(sp)
    80003a5a:	ec26                	sd	s1,24(sp)
    80003a5c:	e84a                	sd	s2,16(sp)
    80003a5e:	e44e                	sd	s3,8(sp)
    80003a60:	1800                	addi	s0,sp,48
    80003a62:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a64:	4585                	li	a1,1
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	a64080e7          	jalr	-1436(ra) # 800034ca <bread>
    80003a6e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a70:	0001c997          	auipc	s3,0x1c
    80003a74:	74898993          	addi	s3,s3,1864 # 800201b8 <sb>
    80003a78:	02000613          	li	a2,32
    80003a7c:	05850593          	addi	a1,a0,88
    80003a80:	854e                	mv	a0,s3
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	2be080e7          	jalr	702(ra) # 80000d40 <memmove>
  brelse(bp);
    80003a8a:	8526                	mv	a0,s1
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	b6e080e7          	jalr	-1170(ra) # 800035fa <brelse>
  if(sb.magic != FSMAGIC)
    80003a94:	0009a703          	lw	a4,0(s3)
    80003a98:	102037b7          	lui	a5,0x10203
    80003a9c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003aa0:	02f71263          	bne	a4,a5,80003ac4 <fsinit+0x70>
  initlog(dev, &sb);
    80003aa4:	0001c597          	auipc	a1,0x1c
    80003aa8:	71458593          	addi	a1,a1,1812 # 800201b8 <sb>
    80003aac:	854a                	mv	a0,s2
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	b4c080e7          	jalr	-1204(ra) # 800045fa <initlog>
}
    80003ab6:	70a2                	ld	ra,40(sp)
    80003ab8:	7402                	ld	s0,32(sp)
    80003aba:	64e2                	ld	s1,24(sp)
    80003abc:	6942                	ld	s2,16(sp)
    80003abe:	69a2                	ld	s3,8(sp)
    80003ac0:	6145                	addi	sp,sp,48
    80003ac2:	8082                	ret
    panic("invalid file system");
    80003ac4:	00005517          	auipc	a0,0x5
    80003ac8:	bcc50513          	addi	a0,a0,-1076 # 80008690 <syscalls+0x150>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	a72080e7          	jalr	-1422(ra) # 8000053e <panic>

0000000080003ad4 <iinit>:
{
    80003ad4:	7179                	addi	sp,sp,-48
    80003ad6:	f406                	sd	ra,40(sp)
    80003ad8:	f022                	sd	s0,32(sp)
    80003ada:	ec26                	sd	s1,24(sp)
    80003adc:	e84a                	sd	s2,16(sp)
    80003ade:	e44e                	sd	s3,8(sp)
    80003ae0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ae2:	00005597          	auipc	a1,0x5
    80003ae6:	bc658593          	addi	a1,a1,-1082 # 800086a8 <syscalls+0x168>
    80003aea:	0001c517          	auipc	a0,0x1c
    80003aee:	6ee50513          	addi	a0,a0,1774 # 800201d8 <itable>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	062080e7          	jalr	98(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003afa:	0001c497          	auipc	s1,0x1c
    80003afe:	70648493          	addi	s1,s1,1798 # 80020200 <itable+0x28>
    80003b02:	0001e997          	auipc	s3,0x1e
    80003b06:	18e98993          	addi	s3,s3,398 # 80021c90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b0a:	00005917          	auipc	s2,0x5
    80003b0e:	ba690913          	addi	s2,s2,-1114 # 800086b0 <syscalls+0x170>
    80003b12:	85ca                	mv	a1,s2
    80003b14:	8526                	mv	a0,s1
    80003b16:	00001097          	auipc	ra,0x1
    80003b1a:	e46080e7          	jalr	-442(ra) # 8000495c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b1e:	08848493          	addi	s1,s1,136
    80003b22:	ff3498e3          	bne	s1,s3,80003b12 <iinit+0x3e>
}
    80003b26:	70a2                	ld	ra,40(sp)
    80003b28:	7402                	ld	s0,32(sp)
    80003b2a:	64e2                	ld	s1,24(sp)
    80003b2c:	6942                	ld	s2,16(sp)
    80003b2e:	69a2                	ld	s3,8(sp)
    80003b30:	6145                	addi	sp,sp,48
    80003b32:	8082                	ret

0000000080003b34 <ialloc>:
{
    80003b34:	715d                	addi	sp,sp,-80
    80003b36:	e486                	sd	ra,72(sp)
    80003b38:	e0a2                	sd	s0,64(sp)
    80003b3a:	fc26                	sd	s1,56(sp)
    80003b3c:	f84a                	sd	s2,48(sp)
    80003b3e:	f44e                	sd	s3,40(sp)
    80003b40:	f052                	sd	s4,32(sp)
    80003b42:	ec56                	sd	s5,24(sp)
    80003b44:	e85a                	sd	s6,16(sp)
    80003b46:	e45e                	sd	s7,8(sp)
    80003b48:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b4a:	0001c717          	auipc	a4,0x1c
    80003b4e:	67a72703          	lw	a4,1658(a4) # 800201c4 <sb+0xc>
    80003b52:	4785                	li	a5,1
    80003b54:	04e7fa63          	bgeu	a5,a4,80003ba8 <ialloc+0x74>
    80003b58:	8aaa                	mv	s5,a0
    80003b5a:	8bae                	mv	s7,a1
    80003b5c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b5e:	0001ca17          	auipc	s4,0x1c
    80003b62:	65aa0a13          	addi	s4,s4,1626 # 800201b8 <sb>
    80003b66:	00048b1b          	sext.w	s6,s1
    80003b6a:	0044d593          	srli	a1,s1,0x4
    80003b6e:	018a2783          	lw	a5,24(s4)
    80003b72:	9dbd                	addw	a1,a1,a5
    80003b74:	8556                	mv	a0,s5
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	954080e7          	jalr	-1708(ra) # 800034ca <bread>
    80003b7e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b80:	05850993          	addi	s3,a0,88
    80003b84:	00f4f793          	andi	a5,s1,15
    80003b88:	079a                	slli	a5,a5,0x6
    80003b8a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b8c:	00099783          	lh	a5,0(s3)
    80003b90:	c785                	beqz	a5,80003bb8 <ialloc+0x84>
    brelse(bp);
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	a68080e7          	jalr	-1432(ra) # 800035fa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b9a:	0485                	addi	s1,s1,1
    80003b9c:	00ca2703          	lw	a4,12(s4)
    80003ba0:	0004879b          	sext.w	a5,s1
    80003ba4:	fce7e1e3          	bltu	a5,a4,80003b66 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ba8:	00005517          	auipc	a0,0x5
    80003bac:	b1050513          	addi	a0,a0,-1264 # 800086b8 <syscalls+0x178>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003bb8:	04000613          	li	a2,64
    80003bbc:	4581                	li	a1,0
    80003bbe:	854e                	mv	a0,s3
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	120080e7          	jalr	288(ra) # 80000ce0 <memset>
      dip->type = type;
    80003bc8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bcc:	854a                	mv	a0,s2
    80003bce:	00001097          	auipc	ra,0x1
    80003bd2:	ca8080e7          	jalr	-856(ra) # 80004876 <log_write>
      brelse(bp);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	a22080e7          	jalr	-1502(ra) # 800035fa <brelse>
      return iget(dev, inum);
    80003be0:	85da                	mv	a1,s6
    80003be2:	8556                	mv	a0,s5
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	db4080e7          	jalr	-588(ra) # 80003998 <iget>
}
    80003bec:	60a6                	ld	ra,72(sp)
    80003bee:	6406                	ld	s0,64(sp)
    80003bf0:	74e2                	ld	s1,56(sp)
    80003bf2:	7942                	ld	s2,48(sp)
    80003bf4:	79a2                	ld	s3,40(sp)
    80003bf6:	7a02                	ld	s4,32(sp)
    80003bf8:	6ae2                	ld	s5,24(sp)
    80003bfa:	6b42                	ld	s6,16(sp)
    80003bfc:	6ba2                	ld	s7,8(sp)
    80003bfe:	6161                	addi	sp,sp,80
    80003c00:	8082                	ret

0000000080003c02 <iupdate>:
{
    80003c02:	1101                	addi	sp,sp,-32
    80003c04:	ec06                	sd	ra,24(sp)
    80003c06:	e822                	sd	s0,16(sp)
    80003c08:	e426                	sd	s1,8(sp)
    80003c0a:	e04a                	sd	s2,0(sp)
    80003c0c:	1000                	addi	s0,sp,32
    80003c0e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c10:	415c                	lw	a5,4(a0)
    80003c12:	0047d79b          	srliw	a5,a5,0x4
    80003c16:	0001c597          	auipc	a1,0x1c
    80003c1a:	5ba5a583          	lw	a1,1466(a1) # 800201d0 <sb+0x18>
    80003c1e:	9dbd                	addw	a1,a1,a5
    80003c20:	4108                	lw	a0,0(a0)
    80003c22:	00000097          	auipc	ra,0x0
    80003c26:	8a8080e7          	jalr	-1880(ra) # 800034ca <bread>
    80003c2a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c2c:	05850793          	addi	a5,a0,88
    80003c30:	40c8                	lw	a0,4(s1)
    80003c32:	893d                	andi	a0,a0,15
    80003c34:	051a                	slli	a0,a0,0x6
    80003c36:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c38:	04449703          	lh	a4,68(s1)
    80003c3c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c40:	04649703          	lh	a4,70(s1)
    80003c44:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c48:	04849703          	lh	a4,72(s1)
    80003c4c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c50:	04a49703          	lh	a4,74(s1)
    80003c54:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c58:	44f8                	lw	a4,76(s1)
    80003c5a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c5c:	03400613          	li	a2,52
    80003c60:	05048593          	addi	a1,s1,80
    80003c64:	0531                	addi	a0,a0,12
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	0da080e7          	jalr	218(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c6e:	854a                	mv	a0,s2
    80003c70:	00001097          	auipc	ra,0x1
    80003c74:	c06080e7          	jalr	-1018(ra) # 80004876 <log_write>
  brelse(bp);
    80003c78:	854a                	mv	a0,s2
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	980080e7          	jalr	-1664(ra) # 800035fa <brelse>
}
    80003c82:	60e2                	ld	ra,24(sp)
    80003c84:	6442                	ld	s0,16(sp)
    80003c86:	64a2                	ld	s1,8(sp)
    80003c88:	6902                	ld	s2,0(sp)
    80003c8a:	6105                	addi	sp,sp,32
    80003c8c:	8082                	ret

0000000080003c8e <idup>:
{
    80003c8e:	1101                	addi	sp,sp,-32
    80003c90:	ec06                	sd	ra,24(sp)
    80003c92:	e822                	sd	s0,16(sp)
    80003c94:	e426                	sd	s1,8(sp)
    80003c96:	1000                	addi	s0,sp,32
    80003c98:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c9a:	0001c517          	auipc	a0,0x1c
    80003c9e:	53e50513          	addi	a0,a0,1342 # 800201d8 <itable>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	f42080e7          	jalr	-190(ra) # 80000be4 <acquire>
  ip->ref++;
    80003caa:	449c                	lw	a5,8(s1)
    80003cac:	2785                	addiw	a5,a5,1
    80003cae:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cb0:	0001c517          	auipc	a0,0x1c
    80003cb4:	52850513          	addi	a0,a0,1320 # 800201d8 <itable>
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	fe0080e7          	jalr	-32(ra) # 80000c98 <release>
}
    80003cc0:	8526                	mv	a0,s1
    80003cc2:	60e2                	ld	ra,24(sp)
    80003cc4:	6442                	ld	s0,16(sp)
    80003cc6:	64a2                	ld	s1,8(sp)
    80003cc8:	6105                	addi	sp,sp,32
    80003cca:	8082                	ret

0000000080003ccc <ilock>:
{
    80003ccc:	1101                	addi	sp,sp,-32
    80003cce:	ec06                	sd	ra,24(sp)
    80003cd0:	e822                	sd	s0,16(sp)
    80003cd2:	e426                	sd	s1,8(sp)
    80003cd4:	e04a                	sd	s2,0(sp)
    80003cd6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cd8:	c115                	beqz	a0,80003cfc <ilock+0x30>
    80003cda:	84aa                	mv	s1,a0
    80003cdc:	451c                	lw	a5,8(a0)
    80003cde:	00f05f63          	blez	a5,80003cfc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ce2:	0541                	addi	a0,a0,16
    80003ce4:	00001097          	auipc	ra,0x1
    80003ce8:	cb2080e7          	jalr	-846(ra) # 80004996 <acquiresleep>
  if(ip->valid == 0){
    80003cec:	40bc                	lw	a5,64(s1)
    80003cee:	cf99                	beqz	a5,80003d0c <ilock+0x40>
}
    80003cf0:	60e2                	ld	ra,24(sp)
    80003cf2:	6442                	ld	s0,16(sp)
    80003cf4:	64a2                	ld	s1,8(sp)
    80003cf6:	6902                	ld	s2,0(sp)
    80003cf8:	6105                	addi	sp,sp,32
    80003cfa:	8082                	ret
    panic("ilock");
    80003cfc:	00005517          	auipc	a0,0x5
    80003d00:	9d450513          	addi	a0,a0,-1580 # 800086d0 <syscalls+0x190>
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	83a080e7          	jalr	-1990(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d0c:	40dc                	lw	a5,4(s1)
    80003d0e:	0047d79b          	srliw	a5,a5,0x4
    80003d12:	0001c597          	auipc	a1,0x1c
    80003d16:	4be5a583          	lw	a1,1214(a1) # 800201d0 <sb+0x18>
    80003d1a:	9dbd                	addw	a1,a1,a5
    80003d1c:	4088                	lw	a0,0(s1)
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	7ac080e7          	jalr	1964(ra) # 800034ca <bread>
    80003d26:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d28:	05850593          	addi	a1,a0,88
    80003d2c:	40dc                	lw	a5,4(s1)
    80003d2e:	8bbd                	andi	a5,a5,15
    80003d30:	079a                	slli	a5,a5,0x6
    80003d32:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d34:	00059783          	lh	a5,0(a1)
    80003d38:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d3c:	00259783          	lh	a5,2(a1)
    80003d40:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d44:	00459783          	lh	a5,4(a1)
    80003d48:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d4c:	00659783          	lh	a5,6(a1)
    80003d50:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d54:	459c                	lw	a5,8(a1)
    80003d56:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d58:	03400613          	li	a2,52
    80003d5c:	05b1                	addi	a1,a1,12
    80003d5e:	05048513          	addi	a0,s1,80
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	fde080e7          	jalr	-34(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d6a:	854a                	mv	a0,s2
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	88e080e7          	jalr	-1906(ra) # 800035fa <brelse>
    ip->valid = 1;
    80003d74:	4785                	li	a5,1
    80003d76:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d78:	04449783          	lh	a5,68(s1)
    80003d7c:	fbb5                	bnez	a5,80003cf0 <ilock+0x24>
      panic("ilock: no type");
    80003d7e:	00005517          	auipc	a0,0x5
    80003d82:	95a50513          	addi	a0,a0,-1702 # 800086d8 <syscalls+0x198>
    80003d86:	ffffc097          	auipc	ra,0xffffc
    80003d8a:	7b8080e7          	jalr	1976(ra) # 8000053e <panic>

0000000080003d8e <iunlock>:
{
    80003d8e:	1101                	addi	sp,sp,-32
    80003d90:	ec06                	sd	ra,24(sp)
    80003d92:	e822                	sd	s0,16(sp)
    80003d94:	e426                	sd	s1,8(sp)
    80003d96:	e04a                	sd	s2,0(sp)
    80003d98:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d9a:	c905                	beqz	a0,80003dca <iunlock+0x3c>
    80003d9c:	84aa                	mv	s1,a0
    80003d9e:	01050913          	addi	s2,a0,16
    80003da2:	854a                	mv	a0,s2
    80003da4:	00001097          	auipc	ra,0x1
    80003da8:	c8c080e7          	jalr	-884(ra) # 80004a30 <holdingsleep>
    80003dac:	cd19                	beqz	a0,80003dca <iunlock+0x3c>
    80003dae:	449c                	lw	a5,8(s1)
    80003db0:	00f05d63          	blez	a5,80003dca <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003db4:	854a                	mv	a0,s2
    80003db6:	00001097          	auipc	ra,0x1
    80003dba:	c36080e7          	jalr	-970(ra) # 800049ec <releasesleep>
}
    80003dbe:	60e2                	ld	ra,24(sp)
    80003dc0:	6442                	ld	s0,16(sp)
    80003dc2:	64a2                	ld	s1,8(sp)
    80003dc4:	6902                	ld	s2,0(sp)
    80003dc6:	6105                	addi	sp,sp,32
    80003dc8:	8082                	ret
    panic("iunlock");
    80003dca:	00005517          	auipc	a0,0x5
    80003dce:	91e50513          	addi	a0,a0,-1762 # 800086e8 <syscalls+0x1a8>
    80003dd2:	ffffc097          	auipc	ra,0xffffc
    80003dd6:	76c080e7          	jalr	1900(ra) # 8000053e <panic>

0000000080003dda <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003dda:	7179                	addi	sp,sp,-48
    80003ddc:	f406                	sd	ra,40(sp)
    80003dde:	f022                	sd	s0,32(sp)
    80003de0:	ec26                	sd	s1,24(sp)
    80003de2:	e84a                	sd	s2,16(sp)
    80003de4:	e44e                	sd	s3,8(sp)
    80003de6:	e052                	sd	s4,0(sp)
    80003de8:	1800                	addi	s0,sp,48
    80003dea:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dec:	05050493          	addi	s1,a0,80
    80003df0:	08050913          	addi	s2,a0,128
    80003df4:	a021                	j	80003dfc <itrunc+0x22>
    80003df6:	0491                	addi	s1,s1,4
    80003df8:	01248d63          	beq	s1,s2,80003e12 <itrunc+0x38>
    if(ip->addrs[i]){
    80003dfc:	408c                	lw	a1,0(s1)
    80003dfe:	dde5                	beqz	a1,80003df6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e00:	0009a503          	lw	a0,0(s3)
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	90c080e7          	jalr	-1780(ra) # 80003710 <bfree>
      ip->addrs[i] = 0;
    80003e0c:	0004a023          	sw	zero,0(s1)
    80003e10:	b7dd                	j	80003df6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e12:	0809a583          	lw	a1,128(s3)
    80003e16:	e185                	bnez	a1,80003e36 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e18:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e1c:	854e                	mv	a0,s3
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	de4080e7          	jalr	-540(ra) # 80003c02 <iupdate>
}
    80003e26:	70a2                	ld	ra,40(sp)
    80003e28:	7402                	ld	s0,32(sp)
    80003e2a:	64e2                	ld	s1,24(sp)
    80003e2c:	6942                	ld	s2,16(sp)
    80003e2e:	69a2                	ld	s3,8(sp)
    80003e30:	6a02                	ld	s4,0(sp)
    80003e32:	6145                	addi	sp,sp,48
    80003e34:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e36:	0009a503          	lw	a0,0(s3)
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	690080e7          	jalr	1680(ra) # 800034ca <bread>
    80003e42:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e44:	05850493          	addi	s1,a0,88
    80003e48:	45850913          	addi	s2,a0,1112
    80003e4c:	a811                	j	80003e60 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e4e:	0009a503          	lw	a0,0(s3)
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	8be080e7          	jalr	-1858(ra) # 80003710 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e5a:	0491                	addi	s1,s1,4
    80003e5c:	01248563          	beq	s1,s2,80003e66 <itrunc+0x8c>
      if(a[j])
    80003e60:	408c                	lw	a1,0(s1)
    80003e62:	dde5                	beqz	a1,80003e5a <itrunc+0x80>
    80003e64:	b7ed                	j	80003e4e <itrunc+0x74>
    brelse(bp);
    80003e66:	8552                	mv	a0,s4
    80003e68:	fffff097          	auipc	ra,0xfffff
    80003e6c:	792080e7          	jalr	1938(ra) # 800035fa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e70:	0809a583          	lw	a1,128(s3)
    80003e74:	0009a503          	lw	a0,0(s3)
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	898080e7          	jalr	-1896(ra) # 80003710 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e80:	0809a023          	sw	zero,128(s3)
    80003e84:	bf51                	j	80003e18 <itrunc+0x3e>

0000000080003e86 <iput>:
{
    80003e86:	1101                	addi	sp,sp,-32
    80003e88:	ec06                	sd	ra,24(sp)
    80003e8a:	e822                	sd	s0,16(sp)
    80003e8c:	e426                	sd	s1,8(sp)
    80003e8e:	e04a                	sd	s2,0(sp)
    80003e90:	1000                	addi	s0,sp,32
    80003e92:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e94:	0001c517          	auipc	a0,0x1c
    80003e98:	34450513          	addi	a0,a0,836 # 800201d8 <itable>
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	d48080e7          	jalr	-696(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ea4:	4498                	lw	a4,8(s1)
    80003ea6:	4785                	li	a5,1
    80003ea8:	02f70363          	beq	a4,a5,80003ece <iput+0x48>
  ip->ref--;
    80003eac:	449c                	lw	a5,8(s1)
    80003eae:	37fd                	addiw	a5,a5,-1
    80003eb0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eb2:	0001c517          	auipc	a0,0x1c
    80003eb6:	32650513          	addi	a0,a0,806 # 800201d8 <itable>
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	dde080e7          	jalr	-546(ra) # 80000c98 <release>
}
    80003ec2:	60e2                	ld	ra,24(sp)
    80003ec4:	6442                	ld	s0,16(sp)
    80003ec6:	64a2                	ld	s1,8(sp)
    80003ec8:	6902                	ld	s2,0(sp)
    80003eca:	6105                	addi	sp,sp,32
    80003ecc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ece:	40bc                	lw	a5,64(s1)
    80003ed0:	dff1                	beqz	a5,80003eac <iput+0x26>
    80003ed2:	04a49783          	lh	a5,74(s1)
    80003ed6:	fbf9                	bnez	a5,80003eac <iput+0x26>
    acquiresleep(&ip->lock);
    80003ed8:	01048913          	addi	s2,s1,16
    80003edc:	854a                	mv	a0,s2
    80003ede:	00001097          	auipc	ra,0x1
    80003ee2:	ab8080e7          	jalr	-1352(ra) # 80004996 <acquiresleep>
    release(&itable.lock);
    80003ee6:	0001c517          	auipc	a0,0x1c
    80003eea:	2f250513          	addi	a0,a0,754 # 800201d8 <itable>
    80003eee:	ffffd097          	auipc	ra,0xffffd
    80003ef2:	daa080e7          	jalr	-598(ra) # 80000c98 <release>
    itrunc(ip);
    80003ef6:	8526                	mv	a0,s1
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	ee2080e7          	jalr	-286(ra) # 80003dda <itrunc>
    ip->type = 0;
    80003f00:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f04:	8526                	mv	a0,s1
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	cfc080e7          	jalr	-772(ra) # 80003c02 <iupdate>
    ip->valid = 0;
    80003f0e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f12:	854a                	mv	a0,s2
    80003f14:	00001097          	auipc	ra,0x1
    80003f18:	ad8080e7          	jalr	-1320(ra) # 800049ec <releasesleep>
    acquire(&itable.lock);
    80003f1c:	0001c517          	auipc	a0,0x1c
    80003f20:	2bc50513          	addi	a0,a0,700 # 800201d8 <itable>
    80003f24:	ffffd097          	auipc	ra,0xffffd
    80003f28:	cc0080e7          	jalr	-832(ra) # 80000be4 <acquire>
    80003f2c:	b741                	j	80003eac <iput+0x26>

0000000080003f2e <iunlockput>:
{
    80003f2e:	1101                	addi	sp,sp,-32
    80003f30:	ec06                	sd	ra,24(sp)
    80003f32:	e822                	sd	s0,16(sp)
    80003f34:	e426                	sd	s1,8(sp)
    80003f36:	1000                	addi	s0,sp,32
    80003f38:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	e54080e7          	jalr	-428(ra) # 80003d8e <iunlock>
  iput(ip);
    80003f42:	8526                	mv	a0,s1
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	f42080e7          	jalr	-190(ra) # 80003e86 <iput>
}
    80003f4c:	60e2                	ld	ra,24(sp)
    80003f4e:	6442                	ld	s0,16(sp)
    80003f50:	64a2                	ld	s1,8(sp)
    80003f52:	6105                	addi	sp,sp,32
    80003f54:	8082                	ret

0000000080003f56 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f56:	1141                	addi	sp,sp,-16
    80003f58:	e422                	sd	s0,8(sp)
    80003f5a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f5c:	411c                	lw	a5,0(a0)
    80003f5e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f60:	415c                	lw	a5,4(a0)
    80003f62:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f64:	04451783          	lh	a5,68(a0)
    80003f68:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f6c:	04a51783          	lh	a5,74(a0)
    80003f70:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f74:	04c56783          	lwu	a5,76(a0)
    80003f78:	e99c                	sd	a5,16(a1)
}
    80003f7a:	6422                	ld	s0,8(sp)
    80003f7c:	0141                	addi	sp,sp,16
    80003f7e:	8082                	ret

0000000080003f80 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f80:	457c                	lw	a5,76(a0)
    80003f82:	0ed7e963          	bltu	a5,a3,80004074 <readi+0xf4>
{
    80003f86:	7159                	addi	sp,sp,-112
    80003f88:	f486                	sd	ra,104(sp)
    80003f8a:	f0a2                	sd	s0,96(sp)
    80003f8c:	eca6                	sd	s1,88(sp)
    80003f8e:	e8ca                	sd	s2,80(sp)
    80003f90:	e4ce                	sd	s3,72(sp)
    80003f92:	e0d2                	sd	s4,64(sp)
    80003f94:	fc56                	sd	s5,56(sp)
    80003f96:	f85a                	sd	s6,48(sp)
    80003f98:	f45e                	sd	s7,40(sp)
    80003f9a:	f062                	sd	s8,32(sp)
    80003f9c:	ec66                	sd	s9,24(sp)
    80003f9e:	e86a                	sd	s10,16(sp)
    80003fa0:	e46e                	sd	s11,8(sp)
    80003fa2:	1880                	addi	s0,sp,112
    80003fa4:	8baa                	mv	s7,a0
    80003fa6:	8c2e                	mv	s8,a1
    80003fa8:	8ab2                	mv	s5,a2
    80003faa:	84b6                	mv	s1,a3
    80003fac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fae:	9f35                	addw	a4,a4,a3
    return 0;
    80003fb0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fb2:	0ad76063          	bltu	a4,a3,80004052 <readi+0xd2>
  if(off + n > ip->size)
    80003fb6:	00e7f463          	bgeu	a5,a4,80003fbe <readi+0x3e>
    n = ip->size - off;
    80003fba:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fbe:	0a0b0963          	beqz	s6,80004070 <readi+0xf0>
    80003fc2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fc8:	5cfd                	li	s9,-1
    80003fca:	a82d                	j	80004004 <readi+0x84>
    80003fcc:	020a1d93          	slli	s11,s4,0x20
    80003fd0:	020ddd93          	srli	s11,s11,0x20
    80003fd4:	05890613          	addi	a2,s2,88
    80003fd8:	86ee                	mv	a3,s11
    80003fda:	963a                	add	a2,a2,a4
    80003fdc:	85d6                	mv	a1,s5
    80003fde:	8562                	mv	a0,s8
    80003fe0:	ffffe097          	auipc	ra,0xffffe
    80003fe4:	c3a080e7          	jalr	-966(ra) # 80001c1a <either_copyout>
    80003fe8:	05950d63          	beq	a0,s9,80004042 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fec:	854a                	mv	a0,s2
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	60c080e7          	jalr	1548(ra) # 800035fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ff6:	013a09bb          	addw	s3,s4,s3
    80003ffa:	009a04bb          	addw	s1,s4,s1
    80003ffe:	9aee                	add	s5,s5,s11
    80004000:	0569f763          	bgeu	s3,s6,8000404e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004004:	000ba903          	lw	s2,0(s7)
    80004008:	00a4d59b          	srliw	a1,s1,0xa
    8000400c:	855e                	mv	a0,s7
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	8b0080e7          	jalr	-1872(ra) # 800038be <bmap>
    80004016:	0005059b          	sext.w	a1,a0
    8000401a:	854a                	mv	a0,s2
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	4ae080e7          	jalr	1198(ra) # 800034ca <bread>
    80004024:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004026:	3ff4f713          	andi	a4,s1,1023
    8000402a:	40ed07bb          	subw	a5,s10,a4
    8000402e:	413b06bb          	subw	a3,s6,s3
    80004032:	8a3e                	mv	s4,a5
    80004034:	2781                	sext.w	a5,a5
    80004036:	0006861b          	sext.w	a2,a3
    8000403a:	f8f679e3          	bgeu	a2,a5,80003fcc <readi+0x4c>
    8000403e:	8a36                	mv	s4,a3
    80004040:	b771                	j	80003fcc <readi+0x4c>
      brelse(bp);
    80004042:	854a                	mv	a0,s2
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	5b6080e7          	jalr	1462(ra) # 800035fa <brelse>
      tot = -1;
    8000404c:	59fd                	li	s3,-1
  }
  return tot;
    8000404e:	0009851b          	sext.w	a0,s3
}
    80004052:	70a6                	ld	ra,104(sp)
    80004054:	7406                	ld	s0,96(sp)
    80004056:	64e6                	ld	s1,88(sp)
    80004058:	6946                	ld	s2,80(sp)
    8000405a:	69a6                	ld	s3,72(sp)
    8000405c:	6a06                	ld	s4,64(sp)
    8000405e:	7ae2                	ld	s5,56(sp)
    80004060:	7b42                	ld	s6,48(sp)
    80004062:	7ba2                	ld	s7,40(sp)
    80004064:	7c02                	ld	s8,32(sp)
    80004066:	6ce2                	ld	s9,24(sp)
    80004068:	6d42                	ld	s10,16(sp)
    8000406a:	6da2                	ld	s11,8(sp)
    8000406c:	6165                	addi	sp,sp,112
    8000406e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004070:	89da                	mv	s3,s6
    80004072:	bff1                	j	8000404e <readi+0xce>
    return 0;
    80004074:	4501                	li	a0,0
}
    80004076:	8082                	ret

0000000080004078 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004078:	457c                	lw	a5,76(a0)
    8000407a:	10d7e863          	bltu	a5,a3,8000418a <writei+0x112>
{
    8000407e:	7159                	addi	sp,sp,-112
    80004080:	f486                	sd	ra,104(sp)
    80004082:	f0a2                	sd	s0,96(sp)
    80004084:	eca6                	sd	s1,88(sp)
    80004086:	e8ca                	sd	s2,80(sp)
    80004088:	e4ce                	sd	s3,72(sp)
    8000408a:	e0d2                	sd	s4,64(sp)
    8000408c:	fc56                	sd	s5,56(sp)
    8000408e:	f85a                	sd	s6,48(sp)
    80004090:	f45e                	sd	s7,40(sp)
    80004092:	f062                	sd	s8,32(sp)
    80004094:	ec66                	sd	s9,24(sp)
    80004096:	e86a                	sd	s10,16(sp)
    80004098:	e46e                	sd	s11,8(sp)
    8000409a:	1880                	addi	s0,sp,112
    8000409c:	8b2a                	mv	s6,a0
    8000409e:	8c2e                	mv	s8,a1
    800040a0:	8ab2                	mv	s5,a2
    800040a2:	8936                	mv	s2,a3
    800040a4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040a6:	00e687bb          	addw	a5,a3,a4
    800040aa:	0ed7e263          	bltu	a5,a3,8000418e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040ae:	00043737          	lui	a4,0x43
    800040b2:	0ef76063          	bltu	a4,a5,80004192 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040b6:	0c0b8863          	beqz	s7,80004186 <writei+0x10e>
    800040ba:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040bc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040c0:	5cfd                	li	s9,-1
    800040c2:	a091                	j	80004106 <writei+0x8e>
    800040c4:	02099d93          	slli	s11,s3,0x20
    800040c8:	020ddd93          	srli	s11,s11,0x20
    800040cc:	05848513          	addi	a0,s1,88
    800040d0:	86ee                	mv	a3,s11
    800040d2:	8656                	mv	a2,s5
    800040d4:	85e2                	mv	a1,s8
    800040d6:	953a                	add	a0,a0,a4
    800040d8:	ffffe097          	auipc	ra,0xffffe
    800040dc:	b98080e7          	jalr	-1128(ra) # 80001c70 <either_copyin>
    800040e0:	07950263          	beq	a0,s9,80004144 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040e4:	8526                	mv	a0,s1
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	790080e7          	jalr	1936(ra) # 80004876 <log_write>
    brelse(bp);
    800040ee:	8526                	mv	a0,s1
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	50a080e7          	jalr	1290(ra) # 800035fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f8:	01498a3b          	addw	s4,s3,s4
    800040fc:	0129893b          	addw	s2,s3,s2
    80004100:	9aee                	add	s5,s5,s11
    80004102:	057a7663          	bgeu	s4,s7,8000414e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004106:	000b2483          	lw	s1,0(s6)
    8000410a:	00a9559b          	srliw	a1,s2,0xa
    8000410e:	855a                	mv	a0,s6
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	7ae080e7          	jalr	1966(ra) # 800038be <bmap>
    80004118:	0005059b          	sext.w	a1,a0
    8000411c:	8526                	mv	a0,s1
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	3ac080e7          	jalr	940(ra) # 800034ca <bread>
    80004126:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004128:	3ff97713          	andi	a4,s2,1023
    8000412c:	40ed07bb          	subw	a5,s10,a4
    80004130:	414b86bb          	subw	a3,s7,s4
    80004134:	89be                	mv	s3,a5
    80004136:	2781                	sext.w	a5,a5
    80004138:	0006861b          	sext.w	a2,a3
    8000413c:	f8f674e3          	bgeu	a2,a5,800040c4 <writei+0x4c>
    80004140:	89b6                	mv	s3,a3
    80004142:	b749                	j	800040c4 <writei+0x4c>
      brelse(bp);
    80004144:	8526                	mv	a0,s1
    80004146:	fffff097          	auipc	ra,0xfffff
    8000414a:	4b4080e7          	jalr	1204(ra) # 800035fa <brelse>
  }

  if(off > ip->size)
    8000414e:	04cb2783          	lw	a5,76(s6)
    80004152:	0127f463          	bgeu	a5,s2,8000415a <writei+0xe2>
    ip->size = off;
    80004156:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000415a:	855a                	mv	a0,s6
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	aa6080e7          	jalr	-1370(ra) # 80003c02 <iupdate>

  return tot;
    80004164:	000a051b          	sext.w	a0,s4
}
    80004168:	70a6                	ld	ra,104(sp)
    8000416a:	7406                	ld	s0,96(sp)
    8000416c:	64e6                	ld	s1,88(sp)
    8000416e:	6946                	ld	s2,80(sp)
    80004170:	69a6                	ld	s3,72(sp)
    80004172:	6a06                	ld	s4,64(sp)
    80004174:	7ae2                	ld	s5,56(sp)
    80004176:	7b42                	ld	s6,48(sp)
    80004178:	7ba2                	ld	s7,40(sp)
    8000417a:	7c02                	ld	s8,32(sp)
    8000417c:	6ce2                	ld	s9,24(sp)
    8000417e:	6d42                	ld	s10,16(sp)
    80004180:	6da2                	ld	s11,8(sp)
    80004182:	6165                	addi	sp,sp,112
    80004184:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004186:	8a5e                	mv	s4,s7
    80004188:	bfc9                	j	8000415a <writei+0xe2>
    return -1;
    8000418a:	557d                	li	a0,-1
}
    8000418c:	8082                	ret
    return -1;
    8000418e:	557d                	li	a0,-1
    80004190:	bfe1                	j	80004168 <writei+0xf0>
    return -1;
    80004192:	557d                	li	a0,-1
    80004194:	bfd1                	j	80004168 <writei+0xf0>

0000000080004196 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004196:	1141                	addi	sp,sp,-16
    80004198:	e406                	sd	ra,8(sp)
    8000419a:	e022                	sd	s0,0(sp)
    8000419c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000419e:	4639                	li	a2,14
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	c18080e7          	jalr	-1000(ra) # 80000db8 <strncmp>
}
    800041a8:	60a2                	ld	ra,8(sp)
    800041aa:	6402                	ld	s0,0(sp)
    800041ac:	0141                	addi	sp,sp,16
    800041ae:	8082                	ret

00000000800041b0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041b0:	7139                	addi	sp,sp,-64
    800041b2:	fc06                	sd	ra,56(sp)
    800041b4:	f822                	sd	s0,48(sp)
    800041b6:	f426                	sd	s1,40(sp)
    800041b8:	f04a                	sd	s2,32(sp)
    800041ba:	ec4e                	sd	s3,24(sp)
    800041bc:	e852                	sd	s4,16(sp)
    800041be:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041c0:	04451703          	lh	a4,68(a0)
    800041c4:	4785                	li	a5,1
    800041c6:	00f71a63          	bne	a4,a5,800041da <dirlookup+0x2a>
    800041ca:	892a                	mv	s2,a0
    800041cc:	89ae                	mv	s3,a1
    800041ce:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d0:	457c                	lw	a5,76(a0)
    800041d2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041d4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d6:	e79d                	bnez	a5,80004204 <dirlookup+0x54>
    800041d8:	a8a5                	j	80004250 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041da:	00004517          	auipc	a0,0x4
    800041de:	51650513          	addi	a0,a0,1302 # 800086f0 <syscalls+0x1b0>
    800041e2:	ffffc097          	auipc	ra,0xffffc
    800041e6:	35c080e7          	jalr	860(ra) # 8000053e <panic>
      panic("dirlookup read");
    800041ea:	00004517          	auipc	a0,0x4
    800041ee:	51e50513          	addi	a0,a0,1310 # 80008708 <syscalls+0x1c8>
    800041f2:	ffffc097          	auipc	ra,0xffffc
    800041f6:	34c080e7          	jalr	844(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041fa:	24c1                	addiw	s1,s1,16
    800041fc:	04c92783          	lw	a5,76(s2)
    80004200:	04f4f763          	bgeu	s1,a5,8000424e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004204:	4741                	li	a4,16
    80004206:	86a6                	mv	a3,s1
    80004208:	fc040613          	addi	a2,s0,-64
    8000420c:	4581                	li	a1,0
    8000420e:	854a                	mv	a0,s2
    80004210:	00000097          	auipc	ra,0x0
    80004214:	d70080e7          	jalr	-656(ra) # 80003f80 <readi>
    80004218:	47c1                	li	a5,16
    8000421a:	fcf518e3          	bne	a0,a5,800041ea <dirlookup+0x3a>
    if(de.inum == 0)
    8000421e:	fc045783          	lhu	a5,-64(s0)
    80004222:	dfe1                	beqz	a5,800041fa <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004224:	fc240593          	addi	a1,s0,-62
    80004228:	854e                	mv	a0,s3
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	f6c080e7          	jalr	-148(ra) # 80004196 <namecmp>
    80004232:	f561                	bnez	a0,800041fa <dirlookup+0x4a>
      if(poff)
    80004234:	000a0463          	beqz	s4,8000423c <dirlookup+0x8c>
        *poff = off;
    80004238:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000423c:	fc045583          	lhu	a1,-64(s0)
    80004240:	00092503          	lw	a0,0(s2)
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	754080e7          	jalr	1876(ra) # 80003998 <iget>
    8000424c:	a011                	j	80004250 <dirlookup+0xa0>
  return 0;
    8000424e:	4501                	li	a0,0
}
    80004250:	70e2                	ld	ra,56(sp)
    80004252:	7442                	ld	s0,48(sp)
    80004254:	74a2                	ld	s1,40(sp)
    80004256:	7902                	ld	s2,32(sp)
    80004258:	69e2                	ld	s3,24(sp)
    8000425a:	6a42                	ld	s4,16(sp)
    8000425c:	6121                	addi	sp,sp,64
    8000425e:	8082                	ret

0000000080004260 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004260:	711d                	addi	sp,sp,-96
    80004262:	ec86                	sd	ra,88(sp)
    80004264:	e8a2                	sd	s0,80(sp)
    80004266:	e4a6                	sd	s1,72(sp)
    80004268:	e0ca                	sd	s2,64(sp)
    8000426a:	fc4e                	sd	s3,56(sp)
    8000426c:	f852                	sd	s4,48(sp)
    8000426e:	f456                	sd	s5,40(sp)
    80004270:	f05a                	sd	s6,32(sp)
    80004272:	ec5e                	sd	s7,24(sp)
    80004274:	e862                	sd	s8,16(sp)
    80004276:	e466                	sd	s9,8(sp)
    80004278:	1080                	addi	s0,sp,96
    8000427a:	84aa                	mv	s1,a0
    8000427c:	8b2e                	mv	s6,a1
    8000427e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004280:	00054703          	lbu	a4,0(a0)
    80004284:	02f00793          	li	a5,47
    80004288:	02f70363          	beq	a4,a5,800042ae <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	67c080e7          	jalr	1660(ra) # 80001908 <myproc>
    80004294:	17053503          	ld	a0,368(a0)
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	9f6080e7          	jalr	-1546(ra) # 80003c8e <idup>
    800042a0:	89aa                	mv	s3,a0
  while(*path == '/')
    800042a2:	02f00913          	li	s2,47
  len = path - s;
    800042a6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042a8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042aa:	4c05                	li	s8,1
    800042ac:	a865                	j	80004364 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042ae:	4585                	li	a1,1
    800042b0:	4505                	li	a0,1
    800042b2:	fffff097          	auipc	ra,0xfffff
    800042b6:	6e6080e7          	jalr	1766(ra) # 80003998 <iget>
    800042ba:	89aa                	mv	s3,a0
    800042bc:	b7dd                	j	800042a2 <namex+0x42>
      iunlockput(ip);
    800042be:	854e                	mv	a0,s3
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	c6e080e7          	jalr	-914(ra) # 80003f2e <iunlockput>
      return 0;
    800042c8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042ca:	854e                	mv	a0,s3
    800042cc:	60e6                	ld	ra,88(sp)
    800042ce:	6446                	ld	s0,80(sp)
    800042d0:	64a6                	ld	s1,72(sp)
    800042d2:	6906                	ld	s2,64(sp)
    800042d4:	79e2                	ld	s3,56(sp)
    800042d6:	7a42                	ld	s4,48(sp)
    800042d8:	7aa2                	ld	s5,40(sp)
    800042da:	7b02                	ld	s6,32(sp)
    800042dc:	6be2                	ld	s7,24(sp)
    800042de:	6c42                	ld	s8,16(sp)
    800042e0:	6ca2                	ld	s9,8(sp)
    800042e2:	6125                	addi	sp,sp,96
    800042e4:	8082                	ret
      iunlock(ip);
    800042e6:	854e                	mv	a0,s3
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	aa6080e7          	jalr	-1370(ra) # 80003d8e <iunlock>
      return ip;
    800042f0:	bfe9                	j	800042ca <namex+0x6a>
      iunlockput(ip);
    800042f2:	854e                	mv	a0,s3
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	c3a080e7          	jalr	-966(ra) # 80003f2e <iunlockput>
      return 0;
    800042fc:	89d2                	mv	s3,s4
    800042fe:	b7f1                	j	800042ca <namex+0x6a>
  len = path - s;
    80004300:	40b48633          	sub	a2,s1,a1
    80004304:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004308:	094cd463          	bge	s9,s4,80004390 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000430c:	4639                	li	a2,14
    8000430e:	8556                	mv	a0,s5
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	a30080e7          	jalr	-1488(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004318:	0004c783          	lbu	a5,0(s1)
    8000431c:	01279763          	bne	a5,s2,8000432a <namex+0xca>
    path++;
    80004320:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004322:	0004c783          	lbu	a5,0(s1)
    80004326:	ff278de3          	beq	a5,s2,80004320 <namex+0xc0>
    ilock(ip);
    8000432a:	854e                	mv	a0,s3
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	9a0080e7          	jalr	-1632(ra) # 80003ccc <ilock>
    if(ip->type != T_DIR){
    80004334:	04499783          	lh	a5,68(s3)
    80004338:	f98793e3          	bne	a5,s8,800042be <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000433c:	000b0563          	beqz	s6,80004346 <namex+0xe6>
    80004340:	0004c783          	lbu	a5,0(s1)
    80004344:	d3cd                	beqz	a5,800042e6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004346:	865e                	mv	a2,s7
    80004348:	85d6                	mv	a1,s5
    8000434a:	854e                	mv	a0,s3
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	e64080e7          	jalr	-412(ra) # 800041b0 <dirlookup>
    80004354:	8a2a                	mv	s4,a0
    80004356:	dd51                	beqz	a0,800042f2 <namex+0x92>
    iunlockput(ip);
    80004358:	854e                	mv	a0,s3
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	bd4080e7          	jalr	-1068(ra) # 80003f2e <iunlockput>
    ip = next;
    80004362:	89d2                	mv	s3,s4
  while(*path == '/')
    80004364:	0004c783          	lbu	a5,0(s1)
    80004368:	05279763          	bne	a5,s2,800043b6 <namex+0x156>
    path++;
    8000436c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000436e:	0004c783          	lbu	a5,0(s1)
    80004372:	ff278de3          	beq	a5,s2,8000436c <namex+0x10c>
  if(*path == 0)
    80004376:	c79d                	beqz	a5,800043a4 <namex+0x144>
    path++;
    80004378:	85a6                	mv	a1,s1
  len = path - s;
    8000437a:	8a5e                	mv	s4,s7
    8000437c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000437e:	01278963          	beq	a5,s2,80004390 <namex+0x130>
    80004382:	dfbd                	beqz	a5,80004300 <namex+0xa0>
    path++;
    80004384:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004386:	0004c783          	lbu	a5,0(s1)
    8000438a:	ff279ce3          	bne	a5,s2,80004382 <namex+0x122>
    8000438e:	bf8d                	j	80004300 <namex+0xa0>
    memmove(name, s, len);
    80004390:	2601                	sext.w	a2,a2
    80004392:	8556                	mv	a0,s5
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	9ac080e7          	jalr	-1620(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000439c:	9a56                	add	s4,s4,s5
    8000439e:	000a0023          	sb	zero,0(s4)
    800043a2:	bf9d                	j	80004318 <namex+0xb8>
  if(nameiparent){
    800043a4:	f20b03e3          	beqz	s6,800042ca <namex+0x6a>
    iput(ip);
    800043a8:	854e                	mv	a0,s3
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	adc080e7          	jalr	-1316(ra) # 80003e86 <iput>
    return 0;
    800043b2:	4981                	li	s3,0
    800043b4:	bf19                	j	800042ca <namex+0x6a>
  if(*path == 0)
    800043b6:	d7fd                	beqz	a5,800043a4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043b8:	0004c783          	lbu	a5,0(s1)
    800043bc:	85a6                	mv	a1,s1
    800043be:	b7d1                	j	80004382 <namex+0x122>

00000000800043c0 <dirlink>:
{
    800043c0:	7139                	addi	sp,sp,-64
    800043c2:	fc06                	sd	ra,56(sp)
    800043c4:	f822                	sd	s0,48(sp)
    800043c6:	f426                	sd	s1,40(sp)
    800043c8:	f04a                	sd	s2,32(sp)
    800043ca:	ec4e                	sd	s3,24(sp)
    800043cc:	e852                	sd	s4,16(sp)
    800043ce:	0080                	addi	s0,sp,64
    800043d0:	892a                	mv	s2,a0
    800043d2:	8a2e                	mv	s4,a1
    800043d4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043d6:	4601                	li	a2,0
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	dd8080e7          	jalr	-552(ra) # 800041b0 <dirlookup>
    800043e0:	e93d                	bnez	a0,80004456 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e2:	04c92483          	lw	s1,76(s2)
    800043e6:	c49d                	beqz	s1,80004414 <dirlink+0x54>
    800043e8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043ea:	4741                	li	a4,16
    800043ec:	86a6                	mv	a3,s1
    800043ee:	fc040613          	addi	a2,s0,-64
    800043f2:	4581                	li	a1,0
    800043f4:	854a                	mv	a0,s2
    800043f6:	00000097          	auipc	ra,0x0
    800043fa:	b8a080e7          	jalr	-1142(ra) # 80003f80 <readi>
    800043fe:	47c1                	li	a5,16
    80004400:	06f51163          	bne	a0,a5,80004462 <dirlink+0xa2>
    if(de.inum == 0)
    80004404:	fc045783          	lhu	a5,-64(s0)
    80004408:	c791                	beqz	a5,80004414 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000440a:	24c1                	addiw	s1,s1,16
    8000440c:	04c92783          	lw	a5,76(s2)
    80004410:	fcf4ede3          	bltu	s1,a5,800043ea <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004414:	4639                	li	a2,14
    80004416:	85d2                	mv	a1,s4
    80004418:	fc240513          	addi	a0,s0,-62
    8000441c:	ffffd097          	auipc	ra,0xffffd
    80004420:	9d8080e7          	jalr	-1576(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004424:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004428:	4741                	li	a4,16
    8000442a:	86a6                	mv	a3,s1
    8000442c:	fc040613          	addi	a2,s0,-64
    80004430:	4581                	li	a1,0
    80004432:	854a                	mv	a0,s2
    80004434:	00000097          	auipc	ra,0x0
    80004438:	c44080e7          	jalr	-956(ra) # 80004078 <writei>
    8000443c:	872a                	mv	a4,a0
    8000443e:	47c1                	li	a5,16
  return 0;
    80004440:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004442:	02f71863          	bne	a4,a5,80004472 <dirlink+0xb2>
}
    80004446:	70e2                	ld	ra,56(sp)
    80004448:	7442                	ld	s0,48(sp)
    8000444a:	74a2                	ld	s1,40(sp)
    8000444c:	7902                	ld	s2,32(sp)
    8000444e:	69e2                	ld	s3,24(sp)
    80004450:	6a42                	ld	s4,16(sp)
    80004452:	6121                	addi	sp,sp,64
    80004454:	8082                	ret
    iput(ip);
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	a30080e7          	jalr	-1488(ra) # 80003e86 <iput>
    return -1;
    8000445e:	557d                	li	a0,-1
    80004460:	b7dd                	j	80004446 <dirlink+0x86>
      panic("dirlink read");
    80004462:	00004517          	auipc	a0,0x4
    80004466:	2b650513          	addi	a0,a0,694 # 80008718 <syscalls+0x1d8>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>
    panic("dirlink");
    80004472:	00004517          	auipc	a0,0x4
    80004476:	3b650513          	addi	a0,a0,950 # 80008828 <syscalls+0x2e8>
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>

0000000080004482 <namei>:

struct inode*
namei(char *path)
{
    80004482:	1101                	addi	sp,sp,-32
    80004484:	ec06                	sd	ra,24(sp)
    80004486:	e822                	sd	s0,16(sp)
    80004488:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000448a:	fe040613          	addi	a2,s0,-32
    8000448e:	4581                	li	a1,0
    80004490:	00000097          	auipc	ra,0x0
    80004494:	dd0080e7          	jalr	-560(ra) # 80004260 <namex>
}
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	6105                	addi	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044a0:	1141                	addi	sp,sp,-16
    800044a2:	e406                	sd	ra,8(sp)
    800044a4:	e022                	sd	s0,0(sp)
    800044a6:	0800                	addi	s0,sp,16
    800044a8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044aa:	4585                	li	a1,1
    800044ac:	00000097          	auipc	ra,0x0
    800044b0:	db4080e7          	jalr	-588(ra) # 80004260 <namex>
}
    800044b4:	60a2                	ld	ra,8(sp)
    800044b6:	6402                	ld	s0,0(sp)
    800044b8:	0141                	addi	sp,sp,16
    800044ba:	8082                	ret

00000000800044bc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044bc:	1101                	addi	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	e426                	sd	s1,8(sp)
    800044c4:	e04a                	sd	s2,0(sp)
    800044c6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044c8:	0001d917          	auipc	s2,0x1d
    800044cc:	7b890913          	addi	s2,s2,1976 # 80021c80 <log>
    800044d0:	01892583          	lw	a1,24(s2)
    800044d4:	02892503          	lw	a0,40(s2)
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	ff2080e7          	jalr	-14(ra) # 800034ca <bread>
    800044e0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044e2:	02c92683          	lw	a3,44(s2)
    800044e6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044e8:	02d05763          	blez	a3,80004516 <write_head+0x5a>
    800044ec:	0001d797          	auipc	a5,0x1d
    800044f0:	7c478793          	addi	a5,a5,1988 # 80021cb0 <log+0x30>
    800044f4:	05c50713          	addi	a4,a0,92
    800044f8:	36fd                	addiw	a3,a3,-1
    800044fa:	1682                	slli	a3,a3,0x20
    800044fc:	9281                	srli	a3,a3,0x20
    800044fe:	068a                	slli	a3,a3,0x2
    80004500:	0001d617          	auipc	a2,0x1d
    80004504:	7b460613          	addi	a2,a2,1972 # 80021cb4 <log+0x34>
    80004508:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000450a:	4390                	lw	a2,0(a5)
    8000450c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000450e:	0791                	addi	a5,a5,4
    80004510:	0711                	addi	a4,a4,4
    80004512:	fed79ce3          	bne	a5,a3,8000450a <write_head+0x4e>
  }
  bwrite(buf);
    80004516:	8526                	mv	a0,s1
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	0a4080e7          	jalr	164(ra) # 800035bc <bwrite>
  brelse(buf);
    80004520:	8526                	mv	a0,s1
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	0d8080e7          	jalr	216(ra) # 800035fa <brelse>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6902                	ld	s2,0(sp)
    80004532:	6105                	addi	sp,sp,32
    80004534:	8082                	ret

0000000080004536 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004536:	0001d797          	auipc	a5,0x1d
    8000453a:	7767a783          	lw	a5,1910(a5) # 80021cac <log+0x2c>
    8000453e:	0af05d63          	blez	a5,800045f8 <install_trans+0xc2>
{
    80004542:	7139                	addi	sp,sp,-64
    80004544:	fc06                	sd	ra,56(sp)
    80004546:	f822                	sd	s0,48(sp)
    80004548:	f426                	sd	s1,40(sp)
    8000454a:	f04a                	sd	s2,32(sp)
    8000454c:	ec4e                	sd	s3,24(sp)
    8000454e:	e852                	sd	s4,16(sp)
    80004550:	e456                	sd	s5,8(sp)
    80004552:	e05a                	sd	s6,0(sp)
    80004554:	0080                	addi	s0,sp,64
    80004556:	8b2a                	mv	s6,a0
    80004558:	0001da97          	auipc	s5,0x1d
    8000455c:	758a8a93          	addi	s5,s5,1880 # 80021cb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004560:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004562:	0001d997          	auipc	s3,0x1d
    80004566:	71e98993          	addi	s3,s3,1822 # 80021c80 <log>
    8000456a:	a035                	j	80004596 <install_trans+0x60>
      bunpin(dbuf);
    8000456c:	8526                	mv	a0,s1
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	166080e7          	jalr	358(ra) # 800036d4 <bunpin>
    brelse(lbuf);
    80004576:	854a                	mv	a0,s2
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	082080e7          	jalr	130(ra) # 800035fa <brelse>
    brelse(dbuf);
    80004580:	8526                	mv	a0,s1
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	078080e7          	jalr	120(ra) # 800035fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000458a:	2a05                	addiw	s4,s4,1
    8000458c:	0a91                	addi	s5,s5,4
    8000458e:	02c9a783          	lw	a5,44(s3)
    80004592:	04fa5963          	bge	s4,a5,800045e4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004596:	0189a583          	lw	a1,24(s3)
    8000459a:	014585bb          	addw	a1,a1,s4
    8000459e:	2585                	addiw	a1,a1,1
    800045a0:	0289a503          	lw	a0,40(s3)
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	f26080e7          	jalr	-218(ra) # 800034ca <bread>
    800045ac:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045ae:	000aa583          	lw	a1,0(s5)
    800045b2:	0289a503          	lw	a0,40(s3)
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	f14080e7          	jalr	-236(ra) # 800034ca <bread>
    800045be:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045c0:	40000613          	li	a2,1024
    800045c4:	05890593          	addi	a1,s2,88
    800045c8:	05850513          	addi	a0,a0,88
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	774080e7          	jalr	1908(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045d4:	8526                	mv	a0,s1
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	fe6080e7          	jalr	-26(ra) # 800035bc <bwrite>
    if(recovering == 0)
    800045de:	f80b1ce3          	bnez	s6,80004576 <install_trans+0x40>
    800045e2:	b769                	j	8000456c <install_trans+0x36>
}
    800045e4:	70e2                	ld	ra,56(sp)
    800045e6:	7442                	ld	s0,48(sp)
    800045e8:	74a2                	ld	s1,40(sp)
    800045ea:	7902                	ld	s2,32(sp)
    800045ec:	69e2                	ld	s3,24(sp)
    800045ee:	6a42                	ld	s4,16(sp)
    800045f0:	6aa2                	ld	s5,8(sp)
    800045f2:	6b02                	ld	s6,0(sp)
    800045f4:	6121                	addi	sp,sp,64
    800045f6:	8082                	ret
    800045f8:	8082                	ret

00000000800045fa <initlog>:
{
    800045fa:	7179                	addi	sp,sp,-48
    800045fc:	f406                	sd	ra,40(sp)
    800045fe:	f022                	sd	s0,32(sp)
    80004600:	ec26                	sd	s1,24(sp)
    80004602:	e84a                	sd	s2,16(sp)
    80004604:	e44e                	sd	s3,8(sp)
    80004606:	1800                	addi	s0,sp,48
    80004608:	892a                	mv	s2,a0
    8000460a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000460c:	0001d497          	auipc	s1,0x1d
    80004610:	67448493          	addi	s1,s1,1652 # 80021c80 <log>
    80004614:	00004597          	auipc	a1,0x4
    80004618:	11458593          	addi	a1,a1,276 # 80008728 <syscalls+0x1e8>
    8000461c:	8526                	mv	a0,s1
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	536080e7          	jalr	1334(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004626:	0149a583          	lw	a1,20(s3)
    8000462a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000462c:	0109a783          	lw	a5,16(s3)
    80004630:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004632:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004636:	854a                	mv	a0,s2
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	e92080e7          	jalr	-366(ra) # 800034ca <bread>
  log.lh.n = lh->n;
    80004640:	4d3c                	lw	a5,88(a0)
    80004642:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004644:	02f05563          	blez	a5,8000466e <initlog+0x74>
    80004648:	05c50713          	addi	a4,a0,92
    8000464c:	0001d697          	auipc	a3,0x1d
    80004650:	66468693          	addi	a3,a3,1636 # 80021cb0 <log+0x30>
    80004654:	37fd                	addiw	a5,a5,-1
    80004656:	1782                	slli	a5,a5,0x20
    80004658:	9381                	srli	a5,a5,0x20
    8000465a:	078a                	slli	a5,a5,0x2
    8000465c:	06050613          	addi	a2,a0,96
    80004660:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004662:	4310                	lw	a2,0(a4)
    80004664:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004666:	0711                	addi	a4,a4,4
    80004668:	0691                	addi	a3,a3,4
    8000466a:	fef71ce3          	bne	a4,a5,80004662 <initlog+0x68>
  brelse(buf);
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	f8c080e7          	jalr	-116(ra) # 800035fa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004676:	4505                	li	a0,1
    80004678:	00000097          	auipc	ra,0x0
    8000467c:	ebe080e7          	jalr	-322(ra) # 80004536 <install_trans>
  log.lh.n = 0;
    80004680:	0001d797          	auipc	a5,0x1d
    80004684:	6207a623          	sw	zero,1580(a5) # 80021cac <log+0x2c>
  write_head(); // clear the log
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	e34080e7          	jalr	-460(ra) # 800044bc <write_head>
}
    80004690:	70a2                	ld	ra,40(sp)
    80004692:	7402                	ld	s0,32(sp)
    80004694:	64e2                	ld	s1,24(sp)
    80004696:	6942                	ld	s2,16(sp)
    80004698:	69a2                	ld	s3,8(sp)
    8000469a:	6145                	addi	sp,sp,48
    8000469c:	8082                	ret

000000008000469e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000469e:	1101                	addi	sp,sp,-32
    800046a0:	ec06                	sd	ra,24(sp)
    800046a2:	e822                	sd	s0,16(sp)
    800046a4:	e426                	sd	s1,8(sp)
    800046a6:	e04a                	sd	s2,0(sp)
    800046a8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046aa:	0001d517          	auipc	a0,0x1d
    800046ae:	5d650513          	addi	a0,a0,1494 # 80021c80 <log>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	532080e7          	jalr	1330(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800046ba:	0001d497          	auipc	s1,0x1d
    800046be:	5c648493          	addi	s1,s1,1478 # 80021c80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046c2:	4979                	li	s2,30
    800046c4:	a039                	j	800046d2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046c6:	85a6                	mv	a1,s1
    800046c8:	8526                	mv	a0,s1
    800046ca:	ffffe097          	auipc	ra,0xffffe
    800046ce:	9b8080e7          	jalr	-1608(ra) # 80002082 <sleep>
    if(log.committing){
    800046d2:	50dc                	lw	a5,36(s1)
    800046d4:	fbed                	bnez	a5,800046c6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046d6:	509c                	lw	a5,32(s1)
    800046d8:	0017871b          	addiw	a4,a5,1
    800046dc:	0007069b          	sext.w	a3,a4
    800046e0:	0027179b          	slliw	a5,a4,0x2
    800046e4:	9fb9                	addw	a5,a5,a4
    800046e6:	0017979b          	slliw	a5,a5,0x1
    800046ea:	54d8                	lw	a4,44(s1)
    800046ec:	9fb9                	addw	a5,a5,a4
    800046ee:	00f95963          	bge	s2,a5,80004700 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046f2:	85a6                	mv	a1,s1
    800046f4:	8526                	mv	a0,s1
    800046f6:	ffffe097          	auipc	ra,0xffffe
    800046fa:	98c080e7          	jalr	-1652(ra) # 80002082 <sleep>
    800046fe:	bfd1                	j	800046d2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004700:	0001d517          	auipc	a0,0x1d
    80004704:	58050513          	addi	a0,a0,1408 # 80021c80 <log>
    80004708:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	58e080e7          	jalr	1422(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004712:	60e2                	ld	ra,24(sp)
    80004714:	6442                	ld	s0,16(sp)
    80004716:	64a2                	ld	s1,8(sp)
    80004718:	6902                	ld	s2,0(sp)
    8000471a:	6105                	addi	sp,sp,32
    8000471c:	8082                	ret

000000008000471e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000471e:	7139                	addi	sp,sp,-64
    80004720:	fc06                	sd	ra,56(sp)
    80004722:	f822                	sd	s0,48(sp)
    80004724:	f426                	sd	s1,40(sp)
    80004726:	f04a                	sd	s2,32(sp)
    80004728:	ec4e                	sd	s3,24(sp)
    8000472a:	e852                	sd	s4,16(sp)
    8000472c:	e456                	sd	s5,8(sp)
    8000472e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004730:	0001d497          	auipc	s1,0x1d
    80004734:	55048493          	addi	s1,s1,1360 # 80021c80 <log>
    80004738:	8526                	mv	a0,s1
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	4aa080e7          	jalr	1194(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004742:	509c                	lw	a5,32(s1)
    80004744:	37fd                	addiw	a5,a5,-1
    80004746:	0007891b          	sext.w	s2,a5
    8000474a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000474c:	50dc                	lw	a5,36(s1)
    8000474e:	efb9                	bnez	a5,800047ac <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004750:	06091663          	bnez	s2,800047bc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004754:	0001d497          	auipc	s1,0x1d
    80004758:	52c48493          	addi	s1,s1,1324 # 80021c80 <log>
    8000475c:	4785                	li	a5,1
    8000475e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004760:	8526                	mv	a0,s1
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000476a:	54dc                	lw	a5,44(s1)
    8000476c:	06f04763          	bgtz	a5,800047da <end_op+0xbc>
    acquire(&log.lock);
    80004770:	0001d497          	auipc	s1,0x1d
    80004774:	51048493          	addi	s1,s1,1296 # 80021c80 <log>
    80004778:	8526                	mv	a0,s1
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	46a080e7          	jalr	1130(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004782:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004786:	8526                	mv	a0,s1
    80004788:	ffffe097          	auipc	ra,0xffffe
    8000478c:	104080e7          	jalr	260(ra) # 8000288c <wakeup>
    release(&log.lock);
    80004790:	8526                	mv	a0,s1
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
}
    8000479a:	70e2                	ld	ra,56(sp)
    8000479c:	7442                	ld	s0,48(sp)
    8000479e:	74a2                	ld	s1,40(sp)
    800047a0:	7902                	ld	s2,32(sp)
    800047a2:	69e2                	ld	s3,24(sp)
    800047a4:	6a42                	ld	s4,16(sp)
    800047a6:	6aa2                	ld	s5,8(sp)
    800047a8:	6121                	addi	sp,sp,64
    800047aa:	8082                	ret
    panic("log.committing");
    800047ac:	00004517          	auipc	a0,0x4
    800047b0:	f8450513          	addi	a0,a0,-124 # 80008730 <syscalls+0x1f0>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
    wakeup(&log);
    800047bc:	0001d497          	auipc	s1,0x1d
    800047c0:	4c448493          	addi	s1,s1,1220 # 80021c80 <log>
    800047c4:	8526                	mv	a0,s1
    800047c6:	ffffe097          	auipc	ra,0xffffe
    800047ca:	0c6080e7          	jalr	198(ra) # 8000288c <wakeup>
  release(&log.lock);
    800047ce:	8526                	mv	a0,s1
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	4c8080e7          	jalr	1224(ra) # 80000c98 <release>
  if(do_commit){
    800047d8:	b7c9                	j	8000479a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047da:	0001da97          	auipc	s5,0x1d
    800047de:	4d6a8a93          	addi	s5,s5,1238 # 80021cb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047e2:	0001da17          	auipc	s4,0x1d
    800047e6:	49ea0a13          	addi	s4,s4,1182 # 80021c80 <log>
    800047ea:	018a2583          	lw	a1,24(s4)
    800047ee:	012585bb          	addw	a1,a1,s2
    800047f2:	2585                	addiw	a1,a1,1
    800047f4:	028a2503          	lw	a0,40(s4)
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	cd2080e7          	jalr	-814(ra) # 800034ca <bread>
    80004800:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004802:	000aa583          	lw	a1,0(s5)
    80004806:	028a2503          	lw	a0,40(s4)
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	cc0080e7          	jalr	-832(ra) # 800034ca <bread>
    80004812:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004814:	40000613          	li	a2,1024
    80004818:	05850593          	addi	a1,a0,88
    8000481c:	05848513          	addi	a0,s1,88
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	520080e7          	jalr	1312(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004828:	8526                	mv	a0,s1
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	d92080e7          	jalr	-622(ra) # 800035bc <bwrite>
    brelse(from);
    80004832:	854e                	mv	a0,s3
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	dc6080e7          	jalr	-570(ra) # 800035fa <brelse>
    brelse(to);
    8000483c:	8526                	mv	a0,s1
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	dbc080e7          	jalr	-580(ra) # 800035fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004846:	2905                	addiw	s2,s2,1
    80004848:	0a91                	addi	s5,s5,4
    8000484a:	02ca2783          	lw	a5,44(s4)
    8000484e:	f8f94ee3          	blt	s2,a5,800047ea <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004852:	00000097          	auipc	ra,0x0
    80004856:	c6a080e7          	jalr	-918(ra) # 800044bc <write_head>
    install_trans(0); // Now install writes to home locations
    8000485a:	4501                	li	a0,0
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	cda080e7          	jalr	-806(ra) # 80004536 <install_trans>
    log.lh.n = 0;
    80004864:	0001d797          	auipc	a5,0x1d
    80004868:	4407a423          	sw	zero,1096(a5) # 80021cac <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	c50080e7          	jalr	-944(ra) # 800044bc <write_head>
    80004874:	bdf5                	j	80004770 <end_op+0x52>

0000000080004876 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004876:	1101                	addi	sp,sp,-32
    80004878:	ec06                	sd	ra,24(sp)
    8000487a:	e822                	sd	s0,16(sp)
    8000487c:	e426                	sd	s1,8(sp)
    8000487e:	e04a                	sd	s2,0(sp)
    80004880:	1000                	addi	s0,sp,32
    80004882:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004884:	0001d917          	auipc	s2,0x1d
    80004888:	3fc90913          	addi	s2,s2,1020 # 80021c80 <log>
    8000488c:	854a                	mv	a0,s2
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	356080e7          	jalr	854(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004896:	02c92603          	lw	a2,44(s2)
    8000489a:	47f5                	li	a5,29
    8000489c:	06c7c563          	blt	a5,a2,80004906 <log_write+0x90>
    800048a0:	0001d797          	auipc	a5,0x1d
    800048a4:	3fc7a783          	lw	a5,1020(a5) # 80021c9c <log+0x1c>
    800048a8:	37fd                	addiw	a5,a5,-1
    800048aa:	04f65e63          	bge	a2,a5,80004906 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048ae:	0001d797          	auipc	a5,0x1d
    800048b2:	3f27a783          	lw	a5,1010(a5) # 80021ca0 <log+0x20>
    800048b6:	06f05063          	blez	a5,80004916 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048ba:	4781                	li	a5,0
    800048bc:	06c05563          	blez	a2,80004926 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048c0:	44cc                	lw	a1,12(s1)
    800048c2:	0001d717          	auipc	a4,0x1d
    800048c6:	3ee70713          	addi	a4,a4,1006 # 80021cb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048ca:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048cc:	4314                	lw	a3,0(a4)
    800048ce:	04b68c63          	beq	a3,a1,80004926 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048d2:	2785                	addiw	a5,a5,1
    800048d4:	0711                	addi	a4,a4,4
    800048d6:	fef61be3          	bne	a2,a5,800048cc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048da:	0621                	addi	a2,a2,8
    800048dc:	060a                	slli	a2,a2,0x2
    800048de:	0001d797          	auipc	a5,0x1d
    800048e2:	3a278793          	addi	a5,a5,930 # 80021c80 <log>
    800048e6:	963e                	add	a2,a2,a5
    800048e8:	44dc                	lw	a5,12(s1)
    800048ea:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048ec:	8526                	mv	a0,s1
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	daa080e7          	jalr	-598(ra) # 80003698 <bpin>
    log.lh.n++;
    800048f6:	0001d717          	auipc	a4,0x1d
    800048fa:	38a70713          	addi	a4,a4,906 # 80021c80 <log>
    800048fe:	575c                	lw	a5,44(a4)
    80004900:	2785                	addiw	a5,a5,1
    80004902:	d75c                	sw	a5,44(a4)
    80004904:	a835                	j	80004940 <log_write+0xca>
    panic("too big a transaction");
    80004906:	00004517          	auipc	a0,0x4
    8000490a:	e3a50513          	addi	a0,a0,-454 # 80008740 <syscalls+0x200>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004916:	00004517          	auipc	a0,0x4
    8000491a:	e4250513          	addi	a0,a0,-446 # 80008758 <syscalls+0x218>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	c20080e7          	jalr	-992(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004926:	00878713          	addi	a4,a5,8
    8000492a:	00271693          	slli	a3,a4,0x2
    8000492e:	0001d717          	auipc	a4,0x1d
    80004932:	35270713          	addi	a4,a4,850 # 80021c80 <log>
    80004936:	9736                	add	a4,a4,a3
    80004938:	44d4                	lw	a3,12(s1)
    8000493a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000493c:	faf608e3          	beq	a2,a5,800048ec <log_write+0x76>
  }
  release(&log.lock);
    80004940:	0001d517          	auipc	a0,0x1d
    80004944:	34050513          	addi	a0,a0,832 # 80021c80 <log>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	350080e7          	jalr	848(ra) # 80000c98 <release>
}
    80004950:	60e2                	ld	ra,24(sp)
    80004952:	6442                	ld	s0,16(sp)
    80004954:	64a2                	ld	s1,8(sp)
    80004956:	6902                	ld	s2,0(sp)
    80004958:	6105                	addi	sp,sp,32
    8000495a:	8082                	ret

000000008000495c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000495c:	1101                	addi	sp,sp,-32
    8000495e:	ec06                	sd	ra,24(sp)
    80004960:	e822                	sd	s0,16(sp)
    80004962:	e426                	sd	s1,8(sp)
    80004964:	e04a                	sd	s2,0(sp)
    80004966:	1000                	addi	s0,sp,32
    80004968:	84aa                	mv	s1,a0
    8000496a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000496c:	00004597          	auipc	a1,0x4
    80004970:	e0c58593          	addi	a1,a1,-500 # 80008778 <syscalls+0x238>
    80004974:	0521                	addi	a0,a0,8
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	1de080e7          	jalr	478(ra) # 80000b54 <initlock>
  lk->name = name;
    8000497e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004982:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004986:	0204a423          	sw	zero,40(s1)
}
    8000498a:	60e2                	ld	ra,24(sp)
    8000498c:	6442                	ld	s0,16(sp)
    8000498e:	64a2                	ld	s1,8(sp)
    80004990:	6902                	ld	s2,0(sp)
    80004992:	6105                	addi	sp,sp,32
    80004994:	8082                	ret

0000000080004996 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004996:	1101                	addi	sp,sp,-32
    80004998:	ec06                	sd	ra,24(sp)
    8000499a:	e822                	sd	s0,16(sp)
    8000499c:	e426                	sd	s1,8(sp)
    8000499e:	e04a                	sd	s2,0(sp)
    800049a0:	1000                	addi	s0,sp,32
    800049a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049a4:	00850913          	addi	s2,a0,8
    800049a8:	854a                	mv	a0,s2
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	23a080e7          	jalr	570(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800049b2:	409c                	lw	a5,0(s1)
    800049b4:	cb89                	beqz	a5,800049c6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049b6:	85ca                	mv	a1,s2
    800049b8:	8526                	mv	a0,s1
    800049ba:	ffffd097          	auipc	ra,0xffffd
    800049be:	6c8080e7          	jalr	1736(ra) # 80002082 <sleep>
  while (lk->locked) {
    800049c2:	409c                	lw	a5,0(s1)
    800049c4:	fbed                	bnez	a5,800049b6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049c6:	4785                	li	a5,1
    800049c8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049ca:	ffffd097          	auipc	ra,0xffffd
    800049ce:	f3e080e7          	jalr	-194(ra) # 80001908 <myproc>
    800049d2:	591c                	lw	a5,48(a0)
    800049d4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049d6:	854a                	mv	a0,s2
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	2c0080e7          	jalr	704(ra) # 80000c98 <release>
}
    800049e0:	60e2                	ld	ra,24(sp)
    800049e2:	6442                	ld	s0,16(sp)
    800049e4:	64a2                	ld	s1,8(sp)
    800049e6:	6902                	ld	s2,0(sp)
    800049e8:	6105                	addi	sp,sp,32
    800049ea:	8082                	ret

00000000800049ec <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049ec:	1101                	addi	sp,sp,-32
    800049ee:	ec06                	sd	ra,24(sp)
    800049f0:	e822                	sd	s0,16(sp)
    800049f2:	e426                	sd	s1,8(sp)
    800049f4:	e04a                	sd	s2,0(sp)
    800049f6:	1000                	addi	s0,sp,32
    800049f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049fa:	00850913          	addi	s2,a0,8
    800049fe:	854a                	mv	a0,s2
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	1e4080e7          	jalr	484(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a08:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a0c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a10:	8526                	mv	a0,s1
    80004a12:	ffffe097          	auipc	ra,0xffffe
    80004a16:	e7a080e7          	jalr	-390(ra) # 8000288c <wakeup>
  release(&lk->lk);
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>
}
    80004a24:	60e2                	ld	ra,24(sp)
    80004a26:	6442                	ld	s0,16(sp)
    80004a28:	64a2                	ld	s1,8(sp)
    80004a2a:	6902                	ld	s2,0(sp)
    80004a2c:	6105                	addi	sp,sp,32
    80004a2e:	8082                	ret

0000000080004a30 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a30:	7179                	addi	sp,sp,-48
    80004a32:	f406                	sd	ra,40(sp)
    80004a34:	f022                	sd	s0,32(sp)
    80004a36:	ec26                	sd	s1,24(sp)
    80004a38:	e84a                	sd	s2,16(sp)
    80004a3a:	e44e                	sd	s3,8(sp)
    80004a3c:	1800                	addi	s0,sp,48
    80004a3e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a40:	00850913          	addi	s2,a0,8
    80004a44:	854a                	mv	a0,s2
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	19e080e7          	jalr	414(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a4e:	409c                	lw	a5,0(s1)
    80004a50:	ef99                	bnez	a5,80004a6e <holdingsleep+0x3e>
    80004a52:	4481                	li	s1,0
  release(&lk->lk);
    80004a54:	854a                	mv	a0,s2
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	242080e7          	jalr	578(ra) # 80000c98 <release>
  return r;
}
    80004a5e:	8526                	mv	a0,s1
    80004a60:	70a2                	ld	ra,40(sp)
    80004a62:	7402                	ld	s0,32(sp)
    80004a64:	64e2                	ld	s1,24(sp)
    80004a66:	6942                	ld	s2,16(sp)
    80004a68:	69a2                	ld	s3,8(sp)
    80004a6a:	6145                	addi	sp,sp,48
    80004a6c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a6e:	0284a983          	lw	s3,40(s1)
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	e96080e7          	jalr	-362(ra) # 80001908 <myproc>
    80004a7a:	5904                	lw	s1,48(a0)
    80004a7c:	413484b3          	sub	s1,s1,s3
    80004a80:	0014b493          	seqz	s1,s1
    80004a84:	bfc1                	j	80004a54 <holdingsleep+0x24>

0000000080004a86 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a86:	1141                	addi	sp,sp,-16
    80004a88:	e406                	sd	ra,8(sp)
    80004a8a:	e022                	sd	s0,0(sp)
    80004a8c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a8e:	00004597          	auipc	a1,0x4
    80004a92:	cfa58593          	addi	a1,a1,-774 # 80008788 <syscalls+0x248>
    80004a96:	0001d517          	auipc	a0,0x1d
    80004a9a:	33250513          	addi	a0,a0,818 # 80021dc8 <ftable>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	0b6080e7          	jalr	182(ra) # 80000b54 <initlock>
}
    80004aa6:	60a2                	ld	ra,8(sp)
    80004aa8:	6402                	ld	s0,0(sp)
    80004aaa:	0141                	addi	sp,sp,16
    80004aac:	8082                	ret

0000000080004aae <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004aae:	1101                	addi	sp,sp,-32
    80004ab0:	ec06                	sd	ra,24(sp)
    80004ab2:	e822                	sd	s0,16(sp)
    80004ab4:	e426                	sd	s1,8(sp)
    80004ab6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ab8:	0001d517          	auipc	a0,0x1d
    80004abc:	31050513          	addi	a0,a0,784 # 80021dc8 <ftable>
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	124080e7          	jalr	292(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ac8:	0001d497          	auipc	s1,0x1d
    80004acc:	31848493          	addi	s1,s1,792 # 80021de0 <ftable+0x18>
    80004ad0:	0001e717          	auipc	a4,0x1e
    80004ad4:	2b070713          	addi	a4,a4,688 # 80022d80 <ftable+0xfb8>
    if(f->ref == 0){
    80004ad8:	40dc                	lw	a5,4(s1)
    80004ada:	cf99                	beqz	a5,80004af8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004adc:	02848493          	addi	s1,s1,40
    80004ae0:	fee49ce3          	bne	s1,a4,80004ad8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ae4:	0001d517          	auipc	a0,0x1d
    80004ae8:	2e450513          	addi	a0,a0,740 # 80021dc8 <ftable>
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	1ac080e7          	jalr	428(ra) # 80000c98 <release>
  return 0;
    80004af4:	4481                	li	s1,0
    80004af6:	a819                	j	80004b0c <filealloc+0x5e>
      f->ref = 1;
    80004af8:	4785                	li	a5,1
    80004afa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004afc:	0001d517          	auipc	a0,0x1d
    80004b00:	2cc50513          	addi	a0,a0,716 # 80021dc8 <ftable>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	194080e7          	jalr	404(ra) # 80000c98 <release>
}
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	60e2                	ld	ra,24(sp)
    80004b10:	6442                	ld	s0,16(sp)
    80004b12:	64a2                	ld	s1,8(sp)
    80004b14:	6105                	addi	sp,sp,32
    80004b16:	8082                	ret

0000000080004b18 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b18:	1101                	addi	sp,sp,-32
    80004b1a:	ec06                	sd	ra,24(sp)
    80004b1c:	e822                	sd	s0,16(sp)
    80004b1e:	e426                	sd	s1,8(sp)
    80004b20:	1000                	addi	s0,sp,32
    80004b22:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b24:	0001d517          	auipc	a0,0x1d
    80004b28:	2a450513          	addi	a0,a0,676 # 80021dc8 <ftable>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	0b8080e7          	jalr	184(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b34:	40dc                	lw	a5,4(s1)
    80004b36:	02f05263          	blez	a5,80004b5a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b3a:	2785                	addiw	a5,a5,1
    80004b3c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b3e:	0001d517          	auipc	a0,0x1d
    80004b42:	28a50513          	addi	a0,a0,650 # 80021dc8 <ftable>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	152080e7          	jalr	338(ra) # 80000c98 <release>
  return f;
}
    80004b4e:	8526                	mv	a0,s1
    80004b50:	60e2                	ld	ra,24(sp)
    80004b52:	6442                	ld	s0,16(sp)
    80004b54:	64a2                	ld	s1,8(sp)
    80004b56:	6105                	addi	sp,sp,32
    80004b58:	8082                	ret
    panic("filedup");
    80004b5a:	00004517          	auipc	a0,0x4
    80004b5e:	c3650513          	addi	a0,a0,-970 # 80008790 <syscalls+0x250>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	9dc080e7          	jalr	-1572(ra) # 8000053e <panic>

0000000080004b6a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b6a:	7139                	addi	sp,sp,-64
    80004b6c:	fc06                	sd	ra,56(sp)
    80004b6e:	f822                	sd	s0,48(sp)
    80004b70:	f426                	sd	s1,40(sp)
    80004b72:	f04a                	sd	s2,32(sp)
    80004b74:	ec4e                	sd	s3,24(sp)
    80004b76:	e852                	sd	s4,16(sp)
    80004b78:	e456                	sd	s5,8(sp)
    80004b7a:	0080                	addi	s0,sp,64
    80004b7c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b7e:	0001d517          	auipc	a0,0x1d
    80004b82:	24a50513          	addi	a0,a0,586 # 80021dc8 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	05e080e7          	jalr	94(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b8e:	40dc                	lw	a5,4(s1)
    80004b90:	06f05163          	blez	a5,80004bf2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b94:	37fd                	addiw	a5,a5,-1
    80004b96:	0007871b          	sext.w	a4,a5
    80004b9a:	c0dc                	sw	a5,4(s1)
    80004b9c:	06e04363          	bgtz	a4,80004c02 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ba0:	0004a903          	lw	s2,0(s1)
    80004ba4:	0094ca83          	lbu	s5,9(s1)
    80004ba8:	0104ba03          	ld	s4,16(s1)
    80004bac:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bb0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bb4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bb8:	0001d517          	auipc	a0,0x1d
    80004bbc:	21050513          	addi	a0,a0,528 # 80021dc8 <ftable>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	0d8080e7          	jalr	216(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004bc8:	4785                	li	a5,1
    80004bca:	04f90d63          	beq	s2,a5,80004c24 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bce:	3979                	addiw	s2,s2,-2
    80004bd0:	4785                	li	a5,1
    80004bd2:	0527e063          	bltu	a5,s2,80004c12 <fileclose+0xa8>
    begin_op();
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	ac8080e7          	jalr	-1336(ra) # 8000469e <begin_op>
    iput(ff.ip);
    80004bde:	854e                	mv	a0,s3
    80004be0:	fffff097          	auipc	ra,0xfffff
    80004be4:	2a6080e7          	jalr	678(ra) # 80003e86 <iput>
    end_op();
    80004be8:	00000097          	auipc	ra,0x0
    80004bec:	b36080e7          	jalr	-1226(ra) # 8000471e <end_op>
    80004bf0:	a00d                	j	80004c12 <fileclose+0xa8>
    panic("fileclose");
    80004bf2:	00004517          	auipc	a0,0x4
    80004bf6:	ba650513          	addi	a0,a0,-1114 # 80008798 <syscalls+0x258>
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	944080e7          	jalr	-1724(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c02:	0001d517          	auipc	a0,0x1d
    80004c06:	1c650513          	addi	a0,a0,454 # 80021dc8 <ftable>
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	08e080e7          	jalr	142(ra) # 80000c98 <release>
  }
}
    80004c12:	70e2                	ld	ra,56(sp)
    80004c14:	7442                	ld	s0,48(sp)
    80004c16:	74a2                	ld	s1,40(sp)
    80004c18:	7902                	ld	s2,32(sp)
    80004c1a:	69e2                	ld	s3,24(sp)
    80004c1c:	6a42                	ld	s4,16(sp)
    80004c1e:	6aa2                	ld	s5,8(sp)
    80004c20:	6121                	addi	sp,sp,64
    80004c22:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c24:	85d6                	mv	a1,s5
    80004c26:	8552                	mv	a0,s4
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	34c080e7          	jalr	844(ra) # 80004f74 <pipeclose>
    80004c30:	b7cd                	j	80004c12 <fileclose+0xa8>

0000000080004c32 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c32:	715d                	addi	sp,sp,-80
    80004c34:	e486                	sd	ra,72(sp)
    80004c36:	e0a2                	sd	s0,64(sp)
    80004c38:	fc26                	sd	s1,56(sp)
    80004c3a:	f84a                	sd	s2,48(sp)
    80004c3c:	f44e                	sd	s3,40(sp)
    80004c3e:	0880                	addi	s0,sp,80
    80004c40:	84aa                	mv	s1,a0
    80004c42:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	cc4080e7          	jalr	-828(ra) # 80001908 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c4c:	409c                	lw	a5,0(s1)
    80004c4e:	37f9                	addiw	a5,a5,-2
    80004c50:	4705                	li	a4,1
    80004c52:	04f76763          	bltu	a4,a5,80004ca0 <filestat+0x6e>
    80004c56:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c58:	6c88                	ld	a0,24(s1)
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	072080e7          	jalr	114(ra) # 80003ccc <ilock>
    stati(f->ip, &st);
    80004c62:	fb840593          	addi	a1,s0,-72
    80004c66:	6c88                	ld	a0,24(s1)
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	2ee080e7          	jalr	750(ra) # 80003f56 <stati>
    iunlock(f->ip);
    80004c70:	6c88                	ld	a0,24(s1)
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	11c080e7          	jalr	284(ra) # 80003d8e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c7a:	46e1                	li	a3,24
    80004c7c:	fb840613          	addi	a2,s0,-72
    80004c80:	85ce                	mv	a1,s3
    80004c82:	07093503          	ld	a0,112(s2)
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	9ec080e7          	jalr	-1556(ra) # 80001672 <copyout>
    80004c8e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c92:	60a6                	ld	ra,72(sp)
    80004c94:	6406                	ld	s0,64(sp)
    80004c96:	74e2                	ld	s1,56(sp)
    80004c98:	7942                	ld	s2,48(sp)
    80004c9a:	79a2                	ld	s3,40(sp)
    80004c9c:	6161                	addi	sp,sp,80
    80004c9e:	8082                	ret
  return -1;
    80004ca0:	557d                	li	a0,-1
    80004ca2:	bfc5                	j	80004c92 <filestat+0x60>

0000000080004ca4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ca4:	7179                	addi	sp,sp,-48
    80004ca6:	f406                	sd	ra,40(sp)
    80004ca8:	f022                	sd	s0,32(sp)
    80004caa:	ec26                	sd	s1,24(sp)
    80004cac:	e84a                	sd	s2,16(sp)
    80004cae:	e44e                	sd	s3,8(sp)
    80004cb0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cb2:	00854783          	lbu	a5,8(a0)
    80004cb6:	c3d5                	beqz	a5,80004d5a <fileread+0xb6>
    80004cb8:	84aa                	mv	s1,a0
    80004cba:	89ae                	mv	s3,a1
    80004cbc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cbe:	411c                	lw	a5,0(a0)
    80004cc0:	4705                	li	a4,1
    80004cc2:	04e78963          	beq	a5,a4,80004d14 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cc6:	470d                	li	a4,3
    80004cc8:	04e78d63          	beq	a5,a4,80004d22 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ccc:	4709                	li	a4,2
    80004cce:	06e79e63          	bne	a5,a4,80004d4a <fileread+0xa6>
    ilock(f->ip);
    80004cd2:	6d08                	ld	a0,24(a0)
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	ff8080e7          	jalr	-8(ra) # 80003ccc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cdc:	874a                	mv	a4,s2
    80004cde:	5094                	lw	a3,32(s1)
    80004ce0:	864e                	mv	a2,s3
    80004ce2:	4585                	li	a1,1
    80004ce4:	6c88                	ld	a0,24(s1)
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	29a080e7          	jalr	666(ra) # 80003f80 <readi>
    80004cee:	892a                	mv	s2,a0
    80004cf0:	00a05563          	blez	a0,80004cfa <fileread+0x56>
      f->off += r;
    80004cf4:	509c                	lw	a5,32(s1)
    80004cf6:	9fa9                	addw	a5,a5,a0
    80004cf8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cfa:	6c88                	ld	a0,24(s1)
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	092080e7          	jalr	146(ra) # 80003d8e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d04:	854a                	mv	a0,s2
    80004d06:	70a2                	ld	ra,40(sp)
    80004d08:	7402                	ld	s0,32(sp)
    80004d0a:	64e2                	ld	s1,24(sp)
    80004d0c:	6942                	ld	s2,16(sp)
    80004d0e:	69a2                	ld	s3,8(sp)
    80004d10:	6145                	addi	sp,sp,48
    80004d12:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d14:	6908                	ld	a0,16(a0)
    80004d16:	00000097          	auipc	ra,0x0
    80004d1a:	3c8080e7          	jalr	968(ra) # 800050de <piperead>
    80004d1e:	892a                	mv	s2,a0
    80004d20:	b7d5                	j	80004d04 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d22:	02451783          	lh	a5,36(a0)
    80004d26:	03079693          	slli	a3,a5,0x30
    80004d2a:	92c1                	srli	a3,a3,0x30
    80004d2c:	4725                	li	a4,9
    80004d2e:	02d76863          	bltu	a4,a3,80004d5e <fileread+0xba>
    80004d32:	0792                	slli	a5,a5,0x4
    80004d34:	0001d717          	auipc	a4,0x1d
    80004d38:	ff470713          	addi	a4,a4,-12 # 80021d28 <devsw>
    80004d3c:	97ba                	add	a5,a5,a4
    80004d3e:	639c                	ld	a5,0(a5)
    80004d40:	c38d                	beqz	a5,80004d62 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d42:	4505                	li	a0,1
    80004d44:	9782                	jalr	a5
    80004d46:	892a                	mv	s2,a0
    80004d48:	bf75                	j	80004d04 <fileread+0x60>
    panic("fileread");
    80004d4a:	00004517          	auipc	a0,0x4
    80004d4e:	a5e50513          	addi	a0,a0,-1442 # 800087a8 <syscalls+0x268>
    80004d52:	ffffb097          	auipc	ra,0xffffb
    80004d56:	7ec080e7          	jalr	2028(ra) # 8000053e <panic>
    return -1;
    80004d5a:	597d                	li	s2,-1
    80004d5c:	b765                	j	80004d04 <fileread+0x60>
      return -1;
    80004d5e:	597d                	li	s2,-1
    80004d60:	b755                	j	80004d04 <fileread+0x60>
    80004d62:	597d                	li	s2,-1
    80004d64:	b745                	j	80004d04 <fileread+0x60>

0000000080004d66 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d66:	715d                	addi	sp,sp,-80
    80004d68:	e486                	sd	ra,72(sp)
    80004d6a:	e0a2                	sd	s0,64(sp)
    80004d6c:	fc26                	sd	s1,56(sp)
    80004d6e:	f84a                	sd	s2,48(sp)
    80004d70:	f44e                	sd	s3,40(sp)
    80004d72:	f052                	sd	s4,32(sp)
    80004d74:	ec56                	sd	s5,24(sp)
    80004d76:	e85a                	sd	s6,16(sp)
    80004d78:	e45e                	sd	s7,8(sp)
    80004d7a:	e062                	sd	s8,0(sp)
    80004d7c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d7e:	00954783          	lbu	a5,9(a0)
    80004d82:	10078663          	beqz	a5,80004e8e <filewrite+0x128>
    80004d86:	892a                	mv	s2,a0
    80004d88:	8aae                	mv	s5,a1
    80004d8a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d8c:	411c                	lw	a5,0(a0)
    80004d8e:	4705                	li	a4,1
    80004d90:	02e78263          	beq	a5,a4,80004db4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d94:	470d                	li	a4,3
    80004d96:	02e78663          	beq	a5,a4,80004dc2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d9a:	4709                	li	a4,2
    80004d9c:	0ee79163          	bne	a5,a4,80004e7e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004da0:	0ac05d63          	blez	a2,80004e5a <filewrite+0xf4>
    int i = 0;
    80004da4:	4981                	li	s3,0
    80004da6:	6b05                	lui	s6,0x1
    80004da8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dac:	6b85                	lui	s7,0x1
    80004dae:	c00b8b9b          	addiw	s7,s7,-1024
    80004db2:	a861                	j	80004e4a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004db4:	6908                	ld	a0,16(a0)
    80004db6:	00000097          	auipc	ra,0x0
    80004dba:	22e080e7          	jalr	558(ra) # 80004fe4 <pipewrite>
    80004dbe:	8a2a                	mv	s4,a0
    80004dc0:	a045                	j	80004e60 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dc2:	02451783          	lh	a5,36(a0)
    80004dc6:	03079693          	slli	a3,a5,0x30
    80004dca:	92c1                	srli	a3,a3,0x30
    80004dcc:	4725                	li	a4,9
    80004dce:	0cd76263          	bltu	a4,a3,80004e92 <filewrite+0x12c>
    80004dd2:	0792                	slli	a5,a5,0x4
    80004dd4:	0001d717          	auipc	a4,0x1d
    80004dd8:	f5470713          	addi	a4,a4,-172 # 80021d28 <devsw>
    80004ddc:	97ba                	add	a5,a5,a4
    80004dde:	679c                	ld	a5,8(a5)
    80004de0:	cbdd                	beqz	a5,80004e96 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004de2:	4505                	li	a0,1
    80004de4:	9782                	jalr	a5
    80004de6:	8a2a                	mv	s4,a0
    80004de8:	a8a5                	j	80004e60 <filewrite+0xfa>
    80004dea:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004dee:	00000097          	auipc	ra,0x0
    80004df2:	8b0080e7          	jalr	-1872(ra) # 8000469e <begin_op>
      ilock(f->ip);
    80004df6:	01893503          	ld	a0,24(s2)
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	ed2080e7          	jalr	-302(ra) # 80003ccc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e02:	8762                	mv	a4,s8
    80004e04:	02092683          	lw	a3,32(s2)
    80004e08:	01598633          	add	a2,s3,s5
    80004e0c:	4585                	li	a1,1
    80004e0e:	01893503          	ld	a0,24(s2)
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	266080e7          	jalr	614(ra) # 80004078 <writei>
    80004e1a:	84aa                	mv	s1,a0
    80004e1c:	00a05763          	blez	a0,80004e2a <filewrite+0xc4>
        f->off += r;
    80004e20:	02092783          	lw	a5,32(s2)
    80004e24:	9fa9                	addw	a5,a5,a0
    80004e26:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e2a:	01893503          	ld	a0,24(s2)
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	f60080e7          	jalr	-160(ra) # 80003d8e <iunlock>
      end_op();
    80004e36:	00000097          	auipc	ra,0x0
    80004e3a:	8e8080e7          	jalr	-1816(ra) # 8000471e <end_op>

      if(r != n1){
    80004e3e:	009c1f63          	bne	s8,s1,80004e5c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e42:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e46:	0149db63          	bge	s3,s4,80004e5c <filewrite+0xf6>
      int n1 = n - i;
    80004e4a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e4e:	84be                	mv	s1,a5
    80004e50:	2781                	sext.w	a5,a5
    80004e52:	f8fb5ce3          	bge	s6,a5,80004dea <filewrite+0x84>
    80004e56:	84de                	mv	s1,s7
    80004e58:	bf49                	j	80004dea <filewrite+0x84>
    int i = 0;
    80004e5a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e5c:	013a1f63          	bne	s4,s3,80004e7a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e60:	8552                	mv	a0,s4
    80004e62:	60a6                	ld	ra,72(sp)
    80004e64:	6406                	ld	s0,64(sp)
    80004e66:	74e2                	ld	s1,56(sp)
    80004e68:	7942                	ld	s2,48(sp)
    80004e6a:	79a2                	ld	s3,40(sp)
    80004e6c:	7a02                	ld	s4,32(sp)
    80004e6e:	6ae2                	ld	s5,24(sp)
    80004e70:	6b42                	ld	s6,16(sp)
    80004e72:	6ba2                	ld	s7,8(sp)
    80004e74:	6c02                	ld	s8,0(sp)
    80004e76:	6161                	addi	sp,sp,80
    80004e78:	8082                	ret
    ret = (i == n ? n : -1);
    80004e7a:	5a7d                	li	s4,-1
    80004e7c:	b7d5                	j	80004e60 <filewrite+0xfa>
    panic("filewrite");
    80004e7e:	00004517          	auipc	a0,0x4
    80004e82:	93a50513          	addi	a0,a0,-1734 # 800087b8 <syscalls+0x278>
    80004e86:	ffffb097          	auipc	ra,0xffffb
    80004e8a:	6b8080e7          	jalr	1720(ra) # 8000053e <panic>
    return -1;
    80004e8e:	5a7d                	li	s4,-1
    80004e90:	bfc1                	j	80004e60 <filewrite+0xfa>
      return -1;
    80004e92:	5a7d                	li	s4,-1
    80004e94:	b7f1                	j	80004e60 <filewrite+0xfa>
    80004e96:	5a7d                	li	s4,-1
    80004e98:	b7e1                	j	80004e60 <filewrite+0xfa>

0000000080004e9a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e9a:	7179                	addi	sp,sp,-48
    80004e9c:	f406                	sd	ra,40(sp)
    80004e9e:	f022                	sd	s0,32(sp)
    80004ea0:	ec26                	sd	s1,24(sp)
    80004ea2:	e84a                	sd	s2,16(sp)
    80004ea4:	e44e                	sd	s3,8(sp)
    80004ea6:	e052                	sd	s4,0(sp)
    80004ea8:	1800                	addi	s0,sp,48
    80004eaa:	84aa                	mv	s1,a0
    80004eac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004eae:	0005b023          	sd	zero,0(a1)
    80004eb2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004eb6:	00000097          	auipc	ra,0x0
    80004eba:	bf8080e7          	jalr	-1032(ra) # 80004aae <filealloc>
    80004ebe:	e088                	sd	a0,0(s1)
    80004ec0:	c551                	beqz	a0,80004f4c <pipealloc+0xb2>
    80004ec2:	00000097          	auipc	ra,0x0
    80004ec6:	bec080e7          	jalr	-1044(ra) # 80004aae <filealloc>
    80004eca:	00aa3023          	sd	a0,0(s4)
    80004ece:	c92d                	beqz	a0,80004f40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	c24080e7          	jalr	-988(ra) # 80000af4 <kalloc>
    80004ed8:	892a                	mv	s2,a0
    80004eda:	c125                	beqz	a0,80004f3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004edc:	4985                	li	s3,1
    80004ede:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ee2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ee6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004eea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004eee:	00004597          	auipc	a1,0x4
    80004ef2:	8da58593          	addi	a1,a1,-1830 # 800087c8 <syscalls+0x288>
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	c5e080e7          	jalr	-930(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004efe:	609c                	ld	a5,0(s1)
    80004f00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f04:	609c                	ld	a5,0(s1)
    80004f06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f0a:	609c                	ld	a5,0(s1)
    80004f0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f10:	609c                	ld	a5,0(s1)
    80004f12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f16:	000a3783          	ld	a5,0(s4)
    80004f1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f1e:	000a3783          	ld	a5,0(s4)
    80004f22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f26:	000a3783          	ld	a5,0(s4)
    80004f2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f2e:	000a3783          	ld	a5,0(s4)
    80004f32:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f36:	4501                	li	a0,0
    80004f38:	a025                	j	80004f60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f3a:	6088                	ld	a0,0(s1)
    80004f3c:	e501                	bnez	a0,80004f44 <pipealloc+0xaa>
    80004f3e:	a039                	j	80004f4c <pipealloc+0xb2>
    80004f40:	6088                	ld	a0,0(s1)
    80004f42:	c51d                	beqz	a0,80004f70 <pipealloc+0xd6>
    fileclose(*f0);
    80004f44:	00000097          	auipc	ra,0x0
    80004f48:	c26080e7          	jalr	-986(ra) # 80004b6a <fileclose>
  if(*f1)
    80004f4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f50:	557d                	li	a0,-1
  if(*f1)
    80004f52:	c799                	beqz	a5,80004f60 <pipealloc+0xc6>
    fileclose(*f1);
    80004f54:	853e                	mv	a0,a5
    80004f56:	00000097          	auipc	ra,0x0
    80004f5a:	c14080e7          	jalr	-1004(ra) # 80004b6a <fileclose>
  return -1;
    80004f5e:	557d                	li	a0,-1
}
    80004f60:	70a2                	ld	ra,40(sp)
    80004f62:	7402                	ld	s0,32(sp)
    80004f64:	64e2                	ld	s1,24(sp)
    80004f66:	6942                	ld	s2,16(sp)
    80004f68:	69a2                	ld	s3,8(sp)
    80004f6a:	6a02                	ld	s4,0(sp)
    80004f6c:	6145                	addi	sp,sp,48
    80004f6e:	8082                	ret
  return -1;
    80004f70:	557d                	li	a0,-1
    80004f72:	b7fd                	j	80004f60 <pipealloc+0xc6>

0000000080004f74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f74:	1101                	addi	sp,sp,-32
    80004f76:	ec06                	sd	ra,24(sp)
    80004f78:	e822                	sd	s0,16(sp)
    80004f7a:	e426                	sd	s1,8(sp)
    80004f7c:	e04a                	sd	s2,0(sp)
    80004f7e:	1000                	addi	s0,sp,32
    80004f80:	84aa                	mv	s1,a0
    80004f82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	c60080e7          	jalr	-928(ra) # 80000be4 <acquire>
  if(writable){
    80004f8c:	02090d63          	beqz	s2,80004fc6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f94:	21848513          	addi	a0,s1,536
    80004f98:	ffffe097          	auipc	ra,0xffffe
    80004f9c:	8f4080e7          	jalr	-1804(ra) # 8000288c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fa0:	2204b783          	ld	a5,544(s1)
    80004fa4:	eb95                	bnez	a5,80004fd8 <pipeclose+0x64>
    release(&pi->lock);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	cf0080e7          	jalr	-784(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	a46080e7          	jalr	-1466(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004fba:	60e2                	ld	ra,24(sp)
    80004fbc:	6442                	ld	s0,16(sp)
    80004fbe:	64a2                	ld	s1,8(sp)
    80004fc0:	6902                	ld	s2,0(sp)
    80004fc2:	6105                	addi	sp,sp,32
    80004fc4:	8082                	ret
    pi->readopen = 0;
    80004fc6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fca:	21c48513          	addi	a0,s1,540
    80004fce:	ffffe097          	auipc	ra,0xffffe
    80004fd2:	8be080e7          	jalr	-1858(ra) # 8000288c <wakeup>
    80004fd6:	b7e9                	j	80004fa0 <pipeclose+0x2c>
    release(&pi->lock);
    80004fd8:	8526                	mv	a0,s1
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	cbe080e7          	jalr	-834(ra) # 80000c98 <release>
}
    80004fe2:	bfe1                	j	80004fba <pipeclose+0x46>

0000000080004fe4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fe4:	7159                	addi	sp,sp,-112
    80004fe6:	f486                	sd	ra,104(sp)
    80004fe8:	f0a2                	sd	s0,96(sp)
    80004fea:	eca6                	sd	s1,88(sp)
    80004fec:	e8ca                	sd	s2,80(sp)
    80004fee:	e4ce                	sd	s3,72(sp)
    80004ff0:	e0d2                	sd	s4,64(sp)
    80004ff2:	fc56                	sd	s5,56(sp)
    80004ff4:	f85a                	sd	s6,48(sp)
    80004ff6:	f45e                	sd	s7,40(sp)
    80004ff8:	f062                	sd	s8,32(sp)
    80004ffa:	ec66                	sd	s9,24(sp)
    80004ffc:	1880                	addi	s0,sp,112
    80004ffe:	84aa                	mv	s1,a0
    80005000:	8aae                	mv	s5,a1
    80005002:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	904080e7          	jalr	-1788(ra) # 80001908 <myproc>
    8000500c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000500e:	8526                	mv	a0,s1
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	bd4080e7          	jalr	-1068(ra) # 80000be4 <acquire>
  while(i < n){
    80005018:	0d405163          	blez	s4,800050da <pipewrite+0xf6>
    8000501c:	8ba6                	mv	s7,s1
  int i = 0;
    8000501e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005020:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005022:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005026:	21c48c13          	addi	s8,s1,540
    8000502a:	a08d                	j	8000508c <pipewrite+0xa8>
      release(&pi->lock);
    8000502c:	8526                	mv	a0,s1
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	c6a080e7          	jalr	-918(ra) # 80000c98 <release>
      return -1;
    80005036:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005038:	854a                	mv	a0,s2
    8000503a:	70a6                	ld	ra,104(sp)
    8000503c:	7406                	ld	s0,96(sp)
    8000503e:	64e6                	ld	s1,88(sp)
    80005040:	6946                	ld	s2,80(sp)
    80005042:	69a6                	ld	s3,72(sp)
    80005044:	6a06                	ld	s4,64(sp)
    80005046:	7ae2                	ld	s5,56(sp)
    80005048:	7b42                	ld	s6,48(sp)
    8000504a:	7ba2                	ld	s7,40(sp)
    8000504c:	7c02                	ld	s8,32(sp)
    8000504e:	6ce2                	ld	s9,24(sp)
    80005050:	6165                	addi	sp,sp,112
    80005052:	8082                	ret
      wakeup(&pi->nread);
    80005054:	8566                	mv	a0,s9
    80005056:	ffffe097          	auipc	ra,0xffffe
    8000505a:	836080e7          	jalr	-1994(ra) # 8000288c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000505e:	85de                	mv	a1,s7
    80005060:	8562                	mv	a0,s8
    80005062:	ffffd097          	auipc	ra,0xffffd
    80005066:	020080e7          	jalr	32(ra) # 80002082 <sleep>
    8000506a:	a839                	j	80005088 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000506c:	21c4a783          	lw	a5,540(s1)
    80005070:	0017871b          	addiw	a4,a5,1
    80005074:	20e4ae23          	sw	a4,540(s1)
    80005078:	1ff7f793          	andi	a5,a5,511
    8000507c:	97a6                	add	a5,a5,s1
    8000507e:	f9f44703          	lbu	a4,-97(s0)
    80005082:	00e78c23          	sb	a4,24(a5)
      i++;
    80005086:	2905                	addiw	s2,s2,1
  while(i < n){
    80005088:	03495d63          	bge	s2,s4,800050c2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000508c:	2204a783          	lw	a5,544(s1)
    80005090:	dfd1                	beqz	a5,8000502c <pipewrite+0x48>
    80005092:	0289a783          	lw	a5,40(s3)
    80005096:	fbd9                	bnez	a5,8000502c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005098:	2184a783          	lw	a5,536(s1)
    8000509c:	21c4a703          	lw	a4,540(s1)
    800050a0:	2007879b          	addiw	a5,a5,512
    800050a4:	faf708e3          	beq	a4,a5,80005054 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050a8:	4685                	li	a3,1
    800050aa:	01590633          	add	a2,s2,s5
    800050ae:	f9f40593          	addi	a1,s0,-97
    800050b2:	0709b503          	ld	a0,112(s3)
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	648080e7          	jalr	1608(ra) # 800016fe <copyin>
    800050be:	fb6517e3          	bne	a0,s6,8000506c <pipewrite+0x88>
  wakeup(&pi->nread);
    800050c2:	21848513          	addi	a0,s1,536
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	7c6080e7          	jalr	1990(ra) # 8000288c <wakeup>
  release(&pi->lock);
    800050ce:	8526                	mv	a0,s1
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	bc8080e7          	jalr	-1080(ra) # 80000c98 <release>
  return i;
    800050d8:	b785                	j	80005038 <pipewrite+0x54>
  int i = 0;
    800050da:	4901                	li	s2,0
    800050dc:	b7dd                	j	800050c2 <pipewrite+0xde>

00000000800050de <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050de:	715d                	addi	sp,sp,-80
    800050e0:	e486                	sd	ra,72(sp)
    800050e2:	e0a2                	sd	s0,64(sp)
    800050e4:	fc26                	sd	s1,56(sp)
    800050e6:	f84a                	sd	s2,48(sp)
    800050e8:	f44e                	sd	s3,40(sp)
    800050ea:	f052                	sd	s4,32(sp)
    800050ec:	ec56                	sd	s5,24(sp)
    800050ee:	e85a                	sd	s6,16(sp)
    800050f0:	0880                	addi	s0,sp,80
    800050f2:	84aa                	mv	s1,a0
    800050f4:	892e                	mv	s2,a1
    800050f6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050f8:	ffffd097          	auipc	ra,0xffffd
    800050fc:	810080e7          	jalr	-2032(ra) # 80001908 <myproc>
    80005100:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005102:	8b26                	mv	s6,s1
    80005104:	8526                	mv	a0,s1
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	ade080e7          	jalr	-1314(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000510e:	2184a703          	lw	a4,536(s1)
    80005112:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005116:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000511a:	02f71463          	bne	a4,a5,80005142 <piperead+0x64>
    8000511e:	2244a783          	lw	a5,548(s1)
    80005122:	c385                	beqz	a5,80005142 <piperead+0x64>
    if(pr->killed){
    80005124:	028a2783          	lw	a5,40(s4)
    80005128:	ebc1                	bnez	a5,800051b8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000512a:	85da                	mv	a1,s6
    8000512c:	854e                	mv	a0,s3
    8000512e:	ffffd097          	auipc	ra,0xffffd
    80005132:	f54080e7          	jalr	-172(ra) # 80002082 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005136:	2184a703          	lw	a4,536(s1)
    8000513a:	21c4a783          	lw	a5,540(s1)
    8000513e:	fef700e3          	beq	a4,a5,8000511e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005142:	09505263          	blez	s5,800051c6 <piperead+0xe8>
    80005146:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005148:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000514a:	2184a783          	lw	a5,536(s1)
    8000514e:	21c4a703          	lw	a4,540(s1)
    80005152:	02f70d63          	beq	a4,a5,8000518c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005156:	0017871b          	addiw	a4,a5,1
    8000515a:	20e4ac23          	sw	a4,536(s1)
    8000515e:	1ff7f793          	andi	a5,a5,511
    80005162:	97a6                	add	a5,a5,s1
    80005164:	0187c783          	lbu	a5,24(a5)
    80005168:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000516c:	4685                	li	a3,1
    8000516e:	fbf40613          	addi	a2,s0,-65
    80005172:	85ca                	mv	a1,s2
    80005174:	070a3503          	ld	a0,112(s4)
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	4fa080e7          	jalr	1274(ra) # 80001672 <copyout>
    80005180:	01650663          	beq	a0,s6,8000518c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005184:	2985                	addiw	s3,s3,1
    80005186:	0905                	addi	s2,s2,1
    80005188:	fd3a91e3          	bne	s5,s3,8000514a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000518c:	21c48513          	addi	a0,s1,540
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	6fc080e7          	jalr	1788(ra) # 8000288c <wakeup>
  release(&pi->lock);
    80005198:	8526                	mv	a0,s1
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	afe080e7          	jalr	-1282(ra) # 80000c98 <release>
  return i;
}
    800051a2:	854e                	mv	a0,s3
    800051a4:	60a6                	ld	ra,72(sp)
    800051a6:	6406                	ld	s0,64(sp)
    800051a8:	74e2                	ld	s1,56(sp)
    800051aa:	7942                	ld	s2,48(sp)
    800051ac:	79a2                	ld	s3,40(sp)
    800051ae:	7a02                	ld	s4,32(sp)
    800051b0:	6ae2                	ld	s5,24(sp)
    800051b2:	6b42                	ld	s6,16(sp)
    800051b4:	6161                	addi	sp,sp,80
    800051b6:	8082                	ret
      release(&pi->lock);
    800051b8:	8526                	mv	a0,s1
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	ade080e7          	jalr	-1314(ra) # 80000c98 <release>
      return -1;
    800051c2:	59fd                	li	s3,-1
    800051c4:	bff9                	j	800051a2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c6:	4981                	li	s3,0
    800051c8:	b7d1                	j	8000518c <piperead+0xae>

00000000800051ca <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800051ca:	df010113          	addi	sp,sp,-528
    800051ce:	20113423          	sd	ra,520(sp)
    800051d2:	20813023          	sd	s0,512(sp)
    800051d6:	ffa6                	sd	s1,504(sp)
    800051d8:	fbca                	sd	s2,496(sp)
    800051da:	f7ce                	sd	s3,488(sp)
    800051dc:	f3d2                	sd	s4,480(sp)
    800051de:	efd6                	sd	s5,472(sp)
    800051e0:	ebda                	sd	s6,464(sp)
    800051e2:	e7de                	sd	s7,456(sp)
    800051e4:	e3e2                	sd	s8,448(sp)
    800051e6:	ff66                	sd	s9,440(sp)
    800051e8:	fb6a                	sd	s10,432(sp)
    800051ea:	f76e                	sd	s11,424(sp)
    800051ec:	0c00                	addi	s0,sp,528
    800051ee:	84aa                	mv	s1,a0
    800051f0:	dea43c23          	sd	a0,-520(s0)
    800051f4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	710080e7          	jalr	1808(ra) # 80001908 <myproc>
    80005200:	892a                	mv	s2,a0

  begin_op();
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	49c080e7          	jalr	1180(ra) # 8000469e <begin_op>

  if((ip = namei(path)) == 0){
    8000520a:	8526                	mv	a0,s1
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	276080e7          	jalr	630(ra) # 80004482 <namei>
    80005214:	c92d                	beqz	a0,80005286 <exec+0xbc>
    80005216:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	ab4080e7          	jalr	-1356(ra) # 80003ccc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005220:	04000713          	li	a4,64
    80005224:	4681                	li	a3,0
    80005226:	e5040613          	addi	a2,s0,-432
    8000522a:	4581                	li	a1,0
    8000522c:	8526                	mv	a0,s1
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	d52080e7          	jalr	-686(ra) # 80003f80 <readi>
    80005236:	04000793          	li	a5,64
    8000523a:	00f51a63          	bne	a0,a5,8000524e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000523e:	e5042703          	lw	a4,-432(s0)
    80005242:	464c47b7          	lui	a5,0x464c4
    80005246:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000524a:	04f70463          	beq	a4,a5,80005292 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000524e:	8526                	mv	a0,s1
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	cde080e7          	jalr	-802(ra) # 80003f2e <iunlockput>
    end_op();
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	4c6080e7          	jalr	1222(ra) # 8000471e <end_op>
  }
  return -1;
    80005260:	557d                	li	a0,-1
}
    80005262:	20813083          	ld	ra,520(sp)
    80005266:	20013403          	ld	s0,512(sp)
    8000526a:	74fe                	ld	s1,504(sp)
    8000526c:	795e                	ld	s2,496(sp)
    8000526e:	79be                	ld	s3,488(sp)
    80005270:	7a1e                	ld	s4,480(sp)
    80005272:	6afe                	ld	s5,472(sp)
    80005274:	6b5e                	ld	s6,464(sp)
    80005276:	6bbe                	ld	s7,456(sp)
    80005278:	6c1e                	ld	s8,448(sp)
    8000527a:	7cfa                	ld	s9,440(sp)
    8000527c:	7d5a                	ld	s10,432(sp)
    8000527e:	7dba                	ld	s11,424(sp)
    80005280:	21010113          	addi	sp,sp,528
    80005284:	8082                	ret
    end_op();
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	498080e7          	jalr	1176(ra) # 8000471e <end_op>
    return -1;
    8000528e:	557d                	li	a0,-1
    80005290:	bfc9                	j	80005262 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005292:	854a                	mv	a0,s2
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	736080e7          	jalr	1846(ra) # 800019ca <proc_pagetable>
    8000529c:	8baa                	mv	s7,a0
    8000529e:	d945                	beqz	a0,8000524e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052a0:	e7042983          	lw	s3,-400(s0)
    800052a4:	e8845783          	lhu	a5,-376(s0)
    800052a8:	c7ad                	beqz	a5,80005312 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052aa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ac:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800052ae:	6c85                	lui	s9,0x1
    800052b0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052b4:	def43823          	sd	a5,-528(s0)
    800052b8:	a42d                	j	800054e2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052ba:	00003517          	auipc	a0,0x3
    800052be:	51650513          	addi	a0,a0,1302 # 800087d0 <syscalls+0x290>
    800052c2:	ffffb097          	auipc	ra,0xffffb
    800052c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052ca:	8756                	mv	a4,s5
    800052cc:	012d86bb          	addw	a3,s11,s2
    800052d0:	4581                	li	a1,0
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	cac080e7          	jalr	-852(ra) # 80003f80 <readi>
    800052dc:	2501                	sext.w	a0,a0
    800052de:	1aaa9963          	bne	s5,a0,80005490 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800052e2:	6785                	lui	a5,0x1
    800052e4:	0127893b          	addw	s2,a5,s2
    800052e8:	77fd                	lui	a5,0xfffff
    800052ea:	01478a3b          	addw	s4,a5,s4
    800052ee:	1f897163          	bgeu	s2,s8,800054d0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052f2:	02091593          	slli	a1,s2,0x20
    800052f6:	9181                	srli	a1,a1,0x20
    800052f8:	95ea                	add	a1,a1,s10
    800052fa:	855e                	mv	a0,s7
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	d72080e7          	jalr	-654(ra) # 8000106e <walkaddr>
    80005304:	862a                	mv	a2,a0
    if(pa == 0)
    80005306:	d955                	beqz	a0,800052ba <exec+0xf0>
      n = PGSIZE;
    80005308:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000530a:	fd9a70e3          	bgeu	s4,s9,800052ca <exec+0x100>
      n = sz - i;
    8000530e:	8ad2                	mv	s5,s4
    80005310:	bf6d                	j	800052ca <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005312:	4901                	li	s2,0
  iunlockput(ip);
    80005314:	8526                	mv	a0,s1
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	c18080e7          	jalr	-1000(ra) # 80003f2e <iunlockput>
  end_op();
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	400080e7          	jalr	1024(ra) # 8000471e <end_op>
  p = myproc();
    80005326:	ffffc097          	auipc	ra,0xffffc
    8000532a:	5e2080e7          	jalr	1506(ra) # 80001908 <myproc>
    8000532e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005330:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005334:	6785                	lui	a5,0x1
    80005336:	17fd                	addi	a5,a5,-1
    80005338:	993e                	add	s2,s2,a5
    8000533a:	757d                	lui	a0,0xfffff
    8000533c:	00a977b3          	and	a5,s2,a0
    80005340:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005344:	6609                	lui	a2,0x2
    80005346:	963e                	add	a2,a2,a5
    80005348:	85be                	mv	a1,a5
    8000534a:	855e                	mv	a0,s7
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	0d6080e7          	jalr	214(ra) # 80001422 <uvmalloc>
    80005354:	8b2a                	mv	s6,a0
  ip = 0;
    80005356:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005358:	12050c63          	beqz	a0,80005490 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000535c:	75f9                	lui	a1,0xffffe
    8000535e:	95aa                	add	a1,a1,a0
    80005360:	855e                	mv	a0,s7
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	2de080e7          	jalr	734(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000536a:	7c7d                	lui	s8,0xfffff
    8000536c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000536e:	e0043783          	ld	a5,-512(s0)
    80005372:	6388                	ld	a0,0(a5)
    80005374:	c535                	beqz	a0,800053e0 <exec+0x216>
    80005376:	e9040993          	addi	s3,s0,-368
    8000537a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000537e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	ae4080e7          	jalr	-1308(ra) # 80000e64 <strlen>
    80005388:	2505                	addiw	a0,a0,1
    8000538a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000538e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005392:	13896363          	bltu	s2,s8,800054b8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005396:	e0043d83          	ld	s11,-512(s0)
    8000539a:	000dba03          	ld	s4,0(s11)
    8000539e:	8552                	mv	a0,s4
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	ac4080e7          	jalr	-1340(ra) # 80000e64 <strlen>
    800053a8:	0015069b          	addiw	a3,a0,1
    800053ac:	8652                	mv	a2,s4
    800053ae:	85ca                	mv	a1,s2
    800053b0:	855e                	mv	a0,s7
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	2c0080e7          	jalr	704(ra) # 80001672 <copyout>
    800053ba:	10054363          	bltz	a0,800054c0 <exec+0x2f6>
    ustack[argc] = sp;
    800053be:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053c2:	0485                	addi	s1,s1,1
    800053c4:	008d8793          	addi	a5,s11,8
    800053c8:	e0f43023          	sd	a5,-512(s0)
    800053cc:	008db503          	ld	a0,8(s11)
    800053d0:	c911                	beqz	a0,800053e4 <exec+0x21a>
    if(argc >= MAXARG)
    800053d2:	09a1                	addi	s3,s3,8
    800053d4:	fb3c96e3          	bne	s9,s3,80005380 <exec+0x1b6>
  sz = sz1;
    800053d8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053dc:	4481                	li	s1,0
    800053de:	a84d                	j	80005490 <exec+0x2c6>
  sp = sz;
    800053e0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053e2:	4481                	li	s1,0
  ustack[argc] = 0;
    800053e4:	00349793          	slli	a5,s1,0x3
    800053e8:	f9040713          	addi	a4,s0,-112
    800053ec:	97ba                	add	a5,a5,a4
    800053ee:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053f2:	00148693          	addi	a3,s1,1
    800053f6:	068e                	slli	a3,a3,0x3
    800053f8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053fc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005400:	01897663          	bgeu	s2,s8,8000540c <exec+0x242>
  sz = sz1;
    80005404:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005408:	4481                	li	s1,0
    8000540a:	a059                	j	80005490 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000540c:	e9040613          	addi	a2,s0,-368
    80005410:	85ca                	mv	a1,s2
    80005412:	855e                	mv	a0,s7
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	25e080e7          	jalr	606(ra) # 80001672 <copyout>
    8000541c:	0a054663          	bltz	a0,800054c8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005420:	078ab783          	ld	a5,120(s5)
    80005424:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005428:	df843783          	ld	a5,-520(s0)
    8000542c:	0007c703          	lbu	a4,0(a5)
    80005430:	cf11                	beqz	a4,8000544c <exec+0x282>
    80005432:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005434:	02f00693          	li	a3,47
    80005438:	a039                	j	80005446 <exec+0x27c>
      last = s+1;
    8000543a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000543e:	0785                	addi	a5,a5,1
    80005440:	fff7c703          	lbu	a4,-1(a5)
    80005444:	c701                	beqz	a4,8000544c <exec+0x282>
    if(*s == '/')
    80005446:	fed71ce3          	bne	a4,a3,8000543e <exec+0x274>
    8000544a:	bfc5                	j	8000543a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000544c:	4641                	li	a2,16
    8000544e:	df843583          	ld	a1,-520(s0)
    80005452:	178a8513          	addi	a0,s5,376
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	9dc080e7          	jalr	-1572(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000545e:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005462:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005466:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000546a:	078ab783          	ld	a5,120(s5)
    8000546e:	e6843703          	ld	a4,-408(s0)
    80005472:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005474:	078ab783          	ld	a5,120(s5)
    80005478:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000547c:	85ea                	mv	a1,s10
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	5e8080e7          	jalr	1512(ra) # 80001a66 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005486:	0004851b          	sext.w	a0,s1
    8000548a:	bbe1                	j	80005262 <exec+0x98>
    8000548c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005490:	e0843583          	ld	a1,-504(s0)
    80005494:	855e                	mv	a0,s7
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	5d0080e7          	jalr	1488(ra) # 80001a66 <proc_freepagetable>
  if(ip){
    8000549e:	da0498e3          	bnez	s1,8000524e <exec+0x84>
  return -1;
    800054a2:	557d                	li	a0,-1
    800054a4:	bb7d                	j	80005262 <exec+0x98>
    800054a6:	e1243423          	sd	s2,-504(s0)
    800054aa:	b7dd                	j	80005490 <exec+0x2c6>
    800054ac:	e1243423          	sd	s2,-504(s0)
    800054b0:	b7c5                	j	80005490 <exec+0x2c6>
    800054b2:	e1243423          	sd	s2,-504(s0)
    800054b6:	bfe9                	j	80005490 <exec+0x2c6>
  sz = sz1;
    800054b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054bc:	4481                	li	s1,0
    800054be:	bfc9                	j	80005490 <exec+0x2c6>
  sz = sz1;
    800054c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054c4:	4481                	li	s1,0
    800054c6:	b7e9                	j	80005490 <exec+0x2c6>
  sz = sz1;
    800054c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054cc:	4481                	li	s1,0
    800054ce:	b7c9                	j	80005490 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054d0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054d4:	2b05                	addiw	s6,s6,1
    800054d6:	0389899b          	addiw	s3,s3,56
    800054da:	e8845783          	lhu	a5,-376(s0)
    800054de:	e2fb5be3          	bge	s6,a5,80005314 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054e2:	2981                	sext.w	s3,s3
    800054e4:	03800713          	li	a4,56
    800054e8:	86ce                	mv	a3,s3
    800054ea:	e1840613          	addi	a2,s0,-488
    800054ee:	4581                	li	a1,0
    800054f0:	8526                	mv	a0,s1
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	a8e080e7          	jalr	-1394(ra) # 80003f80 <readi>
    800054fa:	03800793          	li	a5,56
    800054fe:	f8f517e3          	bne	a0,a5,8000548c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005502:	e1842783          	lw	a5,-488(s0)
    80005506:	4705                	li	a4,1
    80005508:	fce796e3          	bne	a5,a4,800054d4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000550c:	e4043603          	ld	a2,-448(s0)
    80005510:	e3843783          	ld	a5,-456(s0)
    80005514:	f8f669e3          	bltu	a2,a5,800054a6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005518:	e2843783          	ld	a5,-472(s0)
    8000551c:	963e                	add	a2,a2,a5
    8000551e:	f8f667e3          	bltu	a2,a5,800054ac <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005522:	85ca                	mv	a1,s2
    80005524:	855e                	mv	a0,s7
    80005526:	ffffc097          	auipc	ra,0xffffc
    8000552a:	efc080e7          	jalr	-260(ra) # 80001422 <uvmalloc>
    8000552e:	e0a43423          	sd	a0,-504(s0)
    80005532:	d141                	beqz	a0,800054b2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005534:	e2843d03          	ld	s10,-472(s0)
    80005538:	df043783          	ld	a5,-528(s0)
    8000553c:	00fd77b3          	and	a5,s10,a5
    80005540:	fba1                	bnez	a5,80005490 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005542:	e2042d83          	lw	s11,-480(s0)
    80005546:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000554a:	f80c03e3          	beqz	s8,800054d0 <exec+0x306>
    8000554e:	8a62                	mv	s4,s8
    80005550:	4901                	li	s2,0
    80005552:	b345                	j	800052f2 <exec+0x128>

0000000080005554 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005554:	7179                	addi	sp,sp,-48
    80005556:	f406                	sd	ra,40(sp)
    80005558:	f022                	sd	s0,32(sp)
    8000555a:	ec26                	sd	s1,24(sp)
    8000555c:	e84a                	sd	s2,16(sp)
    8000555e:	1800                	addi	s0,sp,48
    80005560:	892e                	mv	s2,a1
    80005562:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005564:	fdc40593          	addi	a1,s0,-36
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	ba8080e7          	jalr	-1112(ra) # 80003110 <argint>
    80005570:	04054063          	bltz	a0,800055b0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005574:	fdc42703          	lw	a4,-36(s0)
    80005578:	47bd                	li	a5,15
    8000557a:	02e7ed63          	bltu	a5,a4,800055b4 <argfd+0x60>
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	38a080e7          	jalr	906(ra) # 80001908 <myproc>
    80005586:	fdc42703          	lw	a4,-36(s0)
    8000558a:	01e70793          	addi	a5,a4,30
    8000558e:	078e                	slli	a5,a5,0x3
    80005590:	953e                	add	a0,a0,a5
    80005592:	611c                	ld	a5,0(a0)
    80005594:	c395                	beqz	a5,800055b8 <argfd+0x64>
    return -1;
  if(pfd)
    80005596:	00090463          	beqz	s2,8000559e <argfd+0x4a>
    *pfd = fd;
    8000559a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000559e:	4501                	li	a0,0
  if(pf)
    800055a0:	c091                	beqz	s1,800055a4 <argfd+0x50>
    *pf = f;
    800055a2:	e09c                	sd	a5,0(s1)
}
    800055a4:	70a2                	ld	ra,40(sp)
    800055a6:	7402                	ld	s0,32(sp)
    800055a8:	64e2                	ld	s1,24(sp)
    800055aa:	6942                	ld	s2,16(sp)
    800055ac:	6145                	addi	sp,sp,48
    800055ae:	8082                	ret
    return -1;
    800055b0:	557d                	li	a0,-1
    800055b2:	bfcd                	j	800055a4 <argfd+0x50>
    return -1;
    800055b4:	557d                	li	a0,-1
    800055b6:	b7fd                	j	800055a4 <argfd+0x50>
    800055b8:	557d                	li	a0,-1
    800055ba:	b7ed                	j	800055a4 <argfd+0x50>

00000000800055bc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055bc:	1101                	addi	sp,sp,-32
    800055be:	ec06                	sd	ra,24(sp)
    800055c0:	e822                	sd	s0,16(sp)
    800055c2:	e426                	sd	s1,8(sp)
    800055c4:	1000                	addi	s0,sp,32
    800055c6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055c8:	ffffc097          	auipc	ra,0xffffc
    800055cc:	340080e7          	jalr	832(ra) # 80001908 <myproc>
    800055d0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055d2:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    800055d6:	4501                	li	a0,0
    800055d8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055da:	6398                	ld	a4,0(a5)
    800055dc:	cb19                	beqz	a4,800055f2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055de:	2505                	addiw	a0,a0,1
    800055e0:	07a1                	addi	a5,a5,8
    800055e2:	fed51ce3          	bne	a0,a3,800055da <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055e6:	557d                	li	a0,-1
}
    800055e8:	60e2                	ld	ra,24(sp)
    800055ea:	6442                	ld	s0,16(sp)
    800055ec:	64a2                	ld	s1,8(sp)
    800055ee:	6105                	addi	sp,sp,32
    800055f0:	8082                	ret
      p->ofile[fd] = f;
    800055f2:	01e50793          	addi	a5,a0,30
    800055f6:	078e                	slli	a5,a5,0x3
    800055f8:	963e                	add	a2,a2,a5
    800055fa:	e204                	sd	s1,0(a2)
      return fd;
    800055fc:	b7f5                	j	800055e8 <fdalloc+0x2c>

00000000800055fe <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055fe:	715d                	addi	sp,sp,-80
    80005600:	e486                	sd	ra,72(sp)
    80005602:	e0a2                	sd	s0,64(sp)
    80005604:	fc26                	sd	s1,56(sp)
    80005606:	f84a                	sd	s2,48(sp)
    80005608:	f44e                	sd	s3,40(sp)
    8000560a:	f052                	sd	s4,32(sp)
    8000560c:	ec56                	sd	s5,24(sp)
    8000560e:	0880                	addi	s0,sp,80
    80005610:	89ae                	mv	s3,a1
    80005612:	8ab2                	mv	s5,a2
    80005614:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005616:	fb040593          	addi	a1,s0,-80
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	e86080e7          	jalr	-378(ra) # 800044a0 <nameiparent>
    80005622:	892a                	mv	s2,a0
    80005624:	12050f63          	beqz	a0,80005762 <create+0x164>
    return 0;

  ilock(dp);
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	6a4080e7          	jalr	1700(ra) # 80003ccc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005630:	4601                	li	a2,0
    80005632:	fb040593          	addi	a1,s0,-80
    80005636:	854a                	mv	a0,s2
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	b78080e7          	jalr	-1160(ra) # 800041b0 <dirlookup>
    80005640:	84aa                	mv	s1,a0
    80005642:	c921                	beqz	a0,80005692 <create+0x94>
    iunlockput(dp);
    80005644:	854a                	mv	a0,s2
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	8e8080e7          	jalr	-1816(ra) # 80003f2e <iunlockput>
    ilock(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	67c080e7          	jalr	1660(ra) # 80003ccc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005658:	2981                	sext.w	s3,s3
    8000565a:	4789                	li	a5,2
    8000565c:	02f99463          	bne	s3,a5,80005684 <create+0x86>
    80005660:	0444d783          	lhu	a5,68(s1)
    80005664:	37f9                	addiw	a5,a5,-2
    80005666:	17c2                	slli	a5,a5,0x30
    80005668:	93c1                	srli	a5,a5,0x30
    8000566a:	4705                	li	a4,1
    8000566c:	00f76c63          	bltu	a4,a5,80005684 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005670:	8526                	mv	a0,s1
    80005672:	60a6                	ld	ra,72(sp)
    80005674:	6406                	ld	s0,64(sp)
    80005676:	74e2                	ld	s1,56(sp)
    80005678:	7942                	ld	s2,48(sp)
    8000567a:	79a2                	ld	s3,40(sp)
    8000567c:	7a02                	ld	s4,32(sp)
    8000567e:	6ae2                	ld	s5,24(sp)
    80005680:	6161                	addi	sp,sp,80
    80005682:	8082                	ret
    iunlockput(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	8a8080e7          	jalr	-1880(ra) # 80003f2e <iunlockput>
    return 0;
    8000568e:	4481                	li	s1,0
    80005690:	b7c5                	j	80005670 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005692:	85ce                	mv	a1,s3
    80005694:	00092503          	lw	a0,0(s2)
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	49c080e7          	jalr	1180(ra) # 80003b34 <ialloc>
    800056a0:	84aa                	mv	s1,a0
    800056a2:	c529                	beqz	a0,800056ec <create+0xee>
  ilock(ip);
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	628080e7          	jalr	1576(ra) # 80003ccc <ilock>
  ip->major = major;
    800056ac:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056b0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056b4:	4785                	li	a5,1
    800056b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	546080e7          	jalr	1350(ra) # 80003c02 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056c4:	2981                	sext.w	s3,s3
    800056c6:	4785                	li	a5,1
    800056c8:	02f98a63          	beq	s3,a5,800056fc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800056cc:	40d0                	lw	a2,4(s1)
    800056ce:	fb040593          	addi	a1,s0,-80
    800056d2:	854a                	mv	a0,s2
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	cec080e7          	jalr	-788(ra) # 800043c0 <dirlink>
    800056dc:	06054b63          	bltz	a0,80005752 <create+0x154>
  iunlockput(dp);
    800056e0:	854a                	mv	a0,s2
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	84c080e7          	jalr	-1972(ra) # 80003f2e <iunlockput>
  return ip;
    800056ea:	b759                	j	80005670 <create+0x72>
    panic("create: ialloc");
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	10450513          	addi	a0,a0,260 # 800087f0 <syscalls+0x2b0>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e4a080e7          	jalr	-438(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800056fc:	04a95783          	lhu	a5,74(s2)
    80005700:	2785                	addiw	a5,a5,1
    80005702:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005706:	854a                	mv	a0,s2
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	4fa080e7          	jalr	1274(ra) # 80003c02 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005710:	40d0                	lw	a2,4(s1)
    80005712:	00003597          	auipc	a1,0x3
    80005716:	0ee58593          	addi	a1,a1,238 # 80008800 <syscalls+0x2c0>
    8000571a:	8526                	mv	a0,s1
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	ca4080e7          	jalr	-860(ra) # 800043c0 <dirlink>
    80005724:	00054f63          	bltz	a0,80005742 <create+0x144>
    80005728:	00492603          	lw	a2,4(s2)
    8000572c:	00003597          	auipc	a1,0x3
    80005730:	0dc58593          	addi	a1,a1,220 # 80008808 <syscalls+0x2c8>
    80005734:	8526                	mv	a0,s1
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	c8a080e7          	jalr	-886(ra) # 800043c0 <dirlink>
    8000573e:	f80557e3          	bgez	a0,800056cc <create+0xce>
      panic("create dots");
    80005742:	00003517          	auipc	a0,0x3
    80005746:	0ce50513          	addi	a0,a0,206 # 80008810 <syscalls+0x2d0>
    8000574a:	ffffb097          	auipc	ra,0xffffb
    8000574e:	df4080e7          	jalr	-524(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005752:	00003517          	auipc	a0,0x3
    80005756:	0ce50513          	addi	a0,a0,206 # 80008820 <syscalls+0x2e0>
    8000575a:	ffffb097          	auipc	ra,0xffffb
    8000575e:	de4080e7          	jalr	-540(ra) # 8000053e <panic>
    return 0;
    80005762:	84aa                	mv	s1,a0
    80005764:	b731                	j	80005670 <create+0x72>

0000000080005766 <sys_dup>:
{
    80005766:	7179                	addi	sp,sp,-48
    80005768:	f406                	sd	ra,40(sp)
    8000576a:	f022                	sd	s0,32(sp)
    8000576c:	ec26                	sd	s1,24(sp)
    8000576e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005770:	fd840613          	addi	a2,s0,-40
    80005774:	4581                	li	a1,0
    80005776:	4501                	li	a0,0
    80005778:	00000097          	auipc	ra,0x0
    8000577c:	ddc080e7          	jalr	-548(ra) # 80005554 <argfd>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005782:	02054363          	bltz	a0,800057a8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005786:	fd843503          	ld	a0,-40(s0)
    8000578a:	00000097          	auipc	ra,0x0
    8000578e:	e32080e7          	jalr	-462(ra) # 800055bc <fdalloc>
    80005792:	84aa                	mv	s1,a0
    return -1;
    80005794:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005796:	00054963          	bltz	a0,800057a8 <sys_dup+0x42>
  filedup(f);
    8000579a:	fd843503          	ld	a0,-40(s0)
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	37a080e7          	jalr	890(ra) # 80004b18 <filedup>
  return fd;
    800057a6:	87a6                	mv	a5,s1
}
    800057a8:	853e                	mv	a0,a5
    800057aa:	70a2                	ld	ra,40(sp)
    800057ac:	7402                	ld	s0,32(sp)
    800057ae:	64e2                	ld	s1,24(sp)
    800057b0:	6145                	addi	sp,sp,48
    800057b2:	8082                	ret

00000000800057b4 <sys_read>:
{
    800057b4:	7179                	addi	sp,sp,-48
    800057b6:	f406                	sd	ra,40(sp)
    800057b8:	f022                	sd	s0,32(sp)
    800057ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057bc:	fe840613          	addi	a2,s0,-24
    800057c0:	4581                	li	a1,0
    800057c2:	4501                	li	a0,0
    800057c4:	00000097          	auipc	ra,0x0
    800057c8:	d90080e7          	jalr	-624(ra) # 80005554 <argfd>
    return -1;
    800057cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ce:	04054163          	bltz	a0,80005810 <sys_read+0x5c>
    800057d2:	fe440593          	addi	a1,s0,-28
    800057d6:	4509                	li	a0,2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	938080e7          	jalr	-1736(ra) # 80003110 <argint>
    return -1;
    800057e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057e2:	02054763          	bltz	a0,80005810 <sys_read+0x5c>
    800057e6:	fd840593          	addi	a1,s0,-40
    800057ea:	4505                	li	a0,1
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	946080e7          	jalr	-1722(ra) # 80003132 <argaddr>
    return -1;
    800057f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f6:	00054d63          	bltz	a0,80005810 <sys_read+0x5c>
  return fileread(f, p, n);
    800057fa:	fe442603          	lw	a2,-28(s0)
    800057fe:	fd843583          	ld	a1,-40(s0)
    80005802:	fe843503          	ld	a0,-24(s0)
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	49e080e7          	jalr	1182(ra) # 80004ca4 <fileread>
    8000580e:	87aa                	mv	a5,a0
}
    80005810:	853e                	mv	a0,a5
    80005812:	70a2                	ld	ra,40(sp)
    80005814:	7402                	ld	s0,32(sp)
    80005816:	6145                	addi	sp,sp,48
    80005818:	8082                	ret

000000008000581a <sys_write>:
{
    8000581a:	7179                	addi	sp,sp,-48
    8000581c:	f406                	sd	ra,40(sp)
    8000581e:	f022                	sd	s0,32(sp)
    80005820:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005822:	fe840613          	addi	a2,s0,-24
    80005826:	4581                	li	a1,0
    80005828:	4501                	li	a0,0
    8000582a:	00000097          	auipc	ra,0x0
    8000582e:	d2a080e7          	jalr	-726(ra) # 80005554 <argfd>
    return -1;
    80005832:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005834:	04054163          	bltz	a0,80005876 <sys_write+0x5c>
    80005838:	fe440593          	addi	a1,s0,-28
    8000583c:	4509                	li	a0,2
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	8d2080e7          	jalr	-1838(ra) # 80003110 <argint>
    return -1;
    80005846:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005848:	02054763          	bltz	a0,80005876 <sys_write+0x5c>
    8000584c:	fd840593          	addi	a1,s0,-40
    80005850:	4505                	li	a0,1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	8e0080e7          	jalr	-1824(ra) # 80003132 <argaddr>
    return -1;
    8000585a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000585c:	00054d63          	bltz	a0,80005876 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005860:	fe442603          	lw	a2,-28(s0)
    80005864:	fd843583          	ld	a1,-40(s0)
    80005868:	fe843503          	ld	a0,-24(s0)
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	4fa080e7          	jalr	1274(ra) # 80004d66 <filewrite>
    80005874:	87aa                	mv	a5,a0
}
    80005876:	853e                	mv	a0,a5
    80005878:	70a2                	ld	ra,40(sp)
    8000587a:	7402                	ld	s0,32(sp)
    8000587c:	6145                	addi	sp,sp,48
    8000587e:	8082                	ret

0000000080005880 <sys_close>:
{
    80005880:	1101                	addi	sp,sp,-32
    80005882:	ec06                	sd	ra,24(sp)
    80005884:	e822                	sd	s0,16(sp)
    80005886:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005888:	fe040613          	addi	a2,s0,-32
    8000588c:	fec40593          	addi	a1,s0,-20
    80005890:	4501                	li	a0,0
    80005892:	00000097          	auipc	ra,0x0
    80005896:	cc2080e7          	jalr	-830(ra) # 80005554 <argfd>
    return -1;
    8000589a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000589c:	02054463          	bltz	a0,800058c4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058a0:	ffffc097          	auipc	ra,0xffffc
    800058a4:	068080e7          	jalr	104(ra) # 80001908 <myproc>
    800058a8:	fec42783          	lw	a5,-20(s0)
    800058ac:	07f9                	addi	a5,a5,30
    800058ae:	078e                	slli	a5,a5,0x3
    800058b0:	97aa                	add	a5,a5,a0
    800058b2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058b6:	fe043503          	ld	a0,-32(s0)
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	2b0080e7          	jalr	688(ra) # 80004b6a <fileclose>
  return 0;
    800058c2:	4781                	li	a5,0
}
    800058c4:	853e                	mv	a0,a5
    800058c6:	60e2                	ld	ra,24(sp)
    800058c8:	6442                	ld	s0,16(sp)
    800058ca:	6105                	addi	sp,sp,32
    800058cc:	8082                	ret

00000000800058ce <sys_fstat>:
{
    800058ce:	1101                	addi	sp,sp,-32
    800058d0:	ec06                	sd	ra,24(sp)
    800058d2:	e822                	sd	s0,16(sp)
    800058d4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058d6:	fe840613          	addi	a2,s0,-24
    800058da:	4581                	li	a1,0
    800058dc:	4501                	li	a0,0
    800058de:	00000097          	auipc	ra,0x0
    800058e2:	c76080e7          	jalr	-906(ra) # 80005554 <argfd>
    return -1;
    800058e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058e8:	02054563          	bltz	a0,80005912 <sys_fstat+0x44>
    800058ec:	fe040593          	addi	a1,s0,-32
    800058f0:	4505                	li	a0,1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	840080e7          	jalr	-1984(ra) # 80003132 <argaddr>
    return -1;
    800058fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058fc:	00054b63          	bltz	a0,80005912 <sys_fstat+0x44>
  return filestat(f, st);
    80005900:	fe043583          	ld	a1,-32(s0)
    80005904:	fe843503          	ld	a0,-24(s0)
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	32a080e7          	jalr	810(ra) # 80004c32 <filestat>
    80005910:	87aa                	mv	a5,a0
}
    80005912:	853e                	mv	a0,a5
    80005914:	60e2                	ld	ra,24(sp)
    80005916:	6442                	ld	s0,16(sp)
    80005918:	6105                	addi	sp,sp,32
    8000591a:	8082                	ret

000000008000591c <sys_link>:
{
    8000591c:	7169                	addi	sp,sp,-304
    8000591e:	f606                	sd	ra,296(sp)
    80005920:	f222                	sd	s0,288(sp)
    80005922:	ee26                	sd	s1,280(sp)
    80005924:	ea4a                	sd	s2,272(sp)
    80005926:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005928:	08000613          	li	a2,128
    8000592c:	ed040593          	addi	a1,s0,-304
    80005930:	4501                	li	a0,0
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	822080e7          	jalr	-2014(ra) # 80003154 <argstr>
    return -1;
    8000593a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000593c:	10054e63          	bltz	a0,80005a58 <sys_link+0x13c>
    80005940:	08000613          	li	a2,128
    80005944:	f5040593          	addi	a1,s0,-176
    80005948:	4505                	li	a0,1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	80a080e7          	jalr	-2038(ra) # 80003154 <argstr>
    return -1;
    80005952:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005954:	10054263          	bltz	a0,80005a58 <sys_link+0x13c>
  begin_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	d46080e7          	jalr	-698(ra) # 8000469e <begin_op>
  if((ip = namei(old)) == 0){
    80005960:	ed040513          	addi	a0,s0,-304
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	b1e080e7          	jalr	-1250(ra) # 80004482 <namei>
    8000596c:	84aa                	mv	s1,a0
    8000596e:	c551                	beqz	a0,800059fa <sys_link+0xde>
  ilock(ip);
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	35c080e7          	jalr	860(ra) # 80003ccc <ilock>
  if(ip->type == T_DIR){
    80005978:	04449703          	lh	a4,68(s1)
    8000597c:	4785                	li	a5,1
    8000597e:	08f70463          	beq	a4,a5,80005a06 <sys_link+0xea>
  ip->nlink++;
    80005982:	04a4d783          	lhu	a5,74(s1)
    80005986:	2785                	addiw	a5,a5,1
    80005988:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	274080e7          	jalr	628(ra) # 80003c02 <iupdate>
  iunlock(ip);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	3f6080e7          	jalr	1014(ra) # 80003d8e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059a0:	fd040593          	addi	a1,s0,-48
    800059a4:	f5040513          	addi	a0,s0,-176
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	af8080e7          	jalr	-1288(ra) # 800044a0 <nameiparent>
    800059b0:	892a                	mv	s2,a0
    800059b2:	c935                	beqz	a0,80005a26 <sys_link+0x10a>
  ilock(dp);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	318080e7          	jalr	792(ra) # 80003ccc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059bc:	00092703          	lw	a4,0(s2)
    800059c0:	409c                	lw	a5,0(s1)
    800059c2:	04f71d63          	bne	a4,a5,80005a1c <sys_link+0x100>
    800059c6:	40d0                	lw	a2,4(s1)
    800059c8:	fd040593          	addi	a1,s0,-48
    800059cc:	854a                	mv	a0,s2
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	9f2080e7          	jalr	-1550(ra) # 800043c0 <dirlink>
    800059d6:	04054363          	bltz	a0,80005a1c <sys_link+0x100>
  iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	552080e7          	jalr	1362(ra) # 80003f2e <iunlockput>
  iput(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	4a0080e7          	jalr	1184(ra) # 80003e86 <iput>
  end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	d30080e7          	jalr	-720(ra) # 8000471e <end_op>
  return 0;
    800059f6:	4781                	li	a5,0
    800059f8:	a085                	j	80005a58 <sys_link+0x13c>
    end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	d24080e7          	jalr	-732(ra) # 8000471e <end_op>
    return -1;
    80005a02:	57fd                	li	a5,-1
    80005a04:	a891                	j	80005a58 <sys_link+0x13c>
    iunlockput(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	526080e7          	jalr	1318(ra) # 80003f2e <iunlockput>
    end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	d0e080e7          	jalr	-754(ra) # 8000471e <end_op>
    return -1;
    80005a18:	57fd                	li	a5,-1
    80005a1a:	a83d                	j	80005a58 <sys_link+0x13c>
    iunlockput(dp);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	510080e7          	jalr	1296(ra) # 80003f2e <iunlockput>
  ilock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	2a4080e7          	jalr	676(ra) # 80003ccc <ilock>
  ip->nlink--;
    80005a30:	04a4d783          	lhu	a5,74(s1)
    80005a34:	37fd                	addiw	a5,a5,-1
    80005a36:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	1c6080e7          	jalr	454(ra) # 80003c02 <iupdate>
  iunlockput(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	4e8080e7          	jalr	1256(ra) # 80003f2e <iunlockput>
  end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	cd0080e7          	jalr	-816(ra) # 8000471e <end_op>
  return -1;
    80005a56:	57fd                	li	a5,-1
}
    80005a58:	853e                	mv	a0,a5
    80005a5a:	70b2                	ld	ra,296(sp)
    80005a5c:	7412                	ld	s0,288(sp)
    80005a5e:	64f2                	ld	s1,280(sp)
    80005a60:	6952                	ld	s2,272(sp)
    80005a62:	6155                	addi	sp,sp,304
    80005a64:	8082                	ret

0000000080005a66 <sys_unlink>:
{
    80005a66:	7151                	addi	sp,sp,-240
    80005a68:	f586                	sd	ra,232(sp)
    80005a6a:	f1a2                	sd	s0,224(sp)
    80005a6c:	eda6                	sd	s1,216(sp)
    80005a6e:	e9ca                	sd	s2,208(sp)
    80005a70:	e5ce                	sd	s3,200(sp)
    80005a72:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a74:	08000613          	li	a2,128
    80005a78:	f3040593          	addi	a1,s0,-208
    80005a7c:	4501                	li	a0,0
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	6d6080e7          	jalr	1750(ra) # 80003154 <argstr>
    80005a86:	18054163          	bltz	a0,80005c08 <sys_unlink+0x1a2>
  begin_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	c14080e7          	jalr	-1004(ra) # 8000469e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a92:	fb040593          	addi	a1,s0,-80
    80005a96:	f3040513          	addi	a0,s0,-208
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	a06080e7          	jalr	-1530(ra) # 800044a0 <nameiparent>
    80005aa2:	84aa                	mv	s1,a0
    80005aa4:	c979                	beqz	a0,80005b7a <sys_unlink+0x114>
  ilock(dp);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	226080e7          	jalr	550(ra) # 80003ccc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005aae:	00003597          	auipc	a1,0x3
    80005ab2:	d5258593          	addi	a1,a1,-686 # 80008800 <syscalls+0x2c0>
    80005ab6:	fb040513          	addi	a0,s0,-80
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	6dc080e7          	jalr	1756(ra) # 80004196 <namecmp>
    80005ac2:	14050a63          	beqz	a0,80005c16 <sys_unlink+0x1b0>
    80005ac6:	00003597          	auipc	a1,0x3
    80005aca:	d4258593          	addi	a1,a1,-702 # 80008808 <syscalls+0x2c8>
    80005ace:	fb040513          	addi	a0,s0,-80
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	6c4080e7          	jalr	1732(ra) # 80004196 <namecmp>
    80005ada:	12050e63          	beqz	a0,80005c16 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ade:	f2c40613          	addi	a2,s0,-212
    80005ae2:	fb040593          	addi	a1,s0,-80
    80005ae6:	8526                	mv	a0,s1
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	6c8080e7          	jalr	1736(ra) # 800041b0 <dirlookup>
    80005af0:	892a                	mv	s2,a0
    80005af2:	12050263          	beqz	a0,80005c16 <sys_unlink+0x1b0>
  ilock(ip);
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	1d6080e7          	jalr	470(ra) # 80003ccc <ilock>
  if(ip->nlink < 1)
    80005afe:	04a91783          	lh	a5,74(s2)
    80005b02:	08f05263          	blez	a5,80005b86 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b06:	04491703          	lh	a4,68(s2)
    80005b0a:	4785                	li	a5,1
    80005b0c:	08f70563          	beq	a4,a5,80005b96 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b10:	4641                	li	a2,16
    80005b12:	4581                	li	a1,0
    80005b14:	fc040513          	addi	a0,s0,-64
    80005b18:	ffffb097          	auipc	ra,0xffffb
    80005b1c:	1c8080e7          	jalr	456(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b20:	4741                	li	a4,16
    80005b22:	f2c42683          	lw	a3,-212(s0)
    80005b26:	fc040613          	addi	a2,s0,-64
    80005b2a:	4581                	li	a1,0
    80005b2c:	8526                	mv	a0,s1
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	54a080e7          	jalr	1354(ra) # 80004078 <writei>
    80005b36:	47c1                	li	a5,16
    80005b38:	0af51563          	bne	a0,a5,80005be2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b3c:	04491703          	lh	a4,68(s2)
    80005b40:	4785                	li	a5,1
    80005b42:	0af70863          	beq	a4,a5,80005bf2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	3e6080e7          	jalr	998(ra) # 80003f2e <iunlockput>
  ip->nlink--;
    80005b50:	04a95783          	lhu	a5,74(s2)
    80005b54:	37fd                	addiw	a5,a5,-1
    80005b56:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b5a:	854a                	mv	a0,s2
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	0a6080e7          	jalr	166(ra) # 80003c02 <iupdate>
  iunlockput(ip);
    80005b64:	854a                	mv	a0,s2
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	3c8080e7          	jalr	968(ra) # 80003f2e <iunlockput>
  end_op();
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	bb0080e7          	jalr	-1104(ra) # 8000471e <end_op>
  return 0;
    80005b76:	4501                	li	a0,0
    80005b78:	a84d                	j	80005c2a <sys_unlink+0x1c4>
    end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	ba4080e7          	jalr	-1116(ra) # 8000471e <end_op>
    return -1;
    80005b82:	557d                	li	a0,-1
    80005b84:	a05d                	j	80005c2a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b86:	00003517          	auipc	a0,0x3
    80005b8a:	caa50513          	addi	a0,a0,-854 # 80008830 <syscalls+0x2f0>
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b96:	04c92703          	lw	a4,76(s2)
    80005b9a:	02000793          	li	a5,32
    80005b9e:	f6e7f9e3          	bgeu	a5,a4,80005b10 <sys_unlink+0xaa>
    80005ba2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ba6:	4741                	li	a4,16
    80005ba8:	86ce                	mv	a3,s3
    80005baa:	f1840613          	addi	a2,s0,-232
    80005bae:	4581                	li	a1,0
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	3ce080e7          	jalr	974(ra) # 80003f80 <readi>
    80005bba:	47c1                	li	a5,16
    80005bbc:	00f51b63          	bne	a0,a5,80005bd2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bc0:	f1845783          	lhu	a5,-232(s0)
    80005bc4:	e7a1                	bnez	a5,80005c0c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bc6:	29c1                	addiw	s3,s3,16
    80005bc8:	04c92783          	lw	a5,76(s2)
    80005bcc:	fcf9ede3          	bltu	s3,a5,80005ba6 <sys_unlink+0x140>
    80005bd0:	b781                	j	80005b10 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005bd2:	00003517          	auipc	a0,0x3
    80005bd6:	c7650513          	addi	a0,a0,-906 # 80008848 <syscalls+0x308>
    80005bda:	ffffb097          	auipc	ra,0xffffb
    80005bde:	964080e7          	jalr	-1692(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005be2:	00003517          	auipc	a0,0x3
    80005be6:	c7e50513          	addi	a0,a0,-898 # 80008860 <syscalls+0x320>
    80005bea:	ffffb097          	auipc	ra,0xffffb
    80005bee:	954080e7          	jalr	-1708(ra) # 8000053e <panic>
    dp->nlink--;
    80005bf2:	04a4d783          	lhu	a5,74(s1)
    80005bf6:	37fd                	addiw	a5,a5,-1
    80005bf8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bfc:	8526                	mv	a0,s1
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	004080e7          	jalr	4(ra) # 80003c02 <iupdate>
    80005c06:	b781                	j	80005b46 <sys_unlink+0xe0>
    return -1;
    80005c08:	557d                	li	a0,-1
    80005c0a:	a005                	j	80005c2a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c0c:	854a                	mv	a0,s2
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	320080e7          	jalr	800(ra) # 80003f2e <iunlockput>
  iunlockput(dp);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	316080e7          	jalr	790(ra) # 80003f2e <iunlockput>
  end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	afe080e7          	jalr	-1282(ra) # 8000471e <end_op>
  return -1;
    80005c28:	557d                	li	a0,-1
}
    80005c2a:	70ae                	ld	ra,232(sp)
    80005c2c:	740e                	ld	s0,224(sp)
    80005c2e:	64ee                	ld	s1,216(sp)
    80005c30:	694e                	ld	s2,208(sp)
    80005c32:	69ae                	ld	s3,200(sp)
    80005c34:	616d                	addi	sp,sp,240
    80005c36:	8082                	ret

0000000080005c38 <sys_open>:

uint64
sys_open(void)
{
    80005c38:	7131                	addi	sp,sp,-192
    80005c3a:	fd06                	sd	ra,184(sp)
    80005c3c:	f922                	sd	s0,176(sp)
    80005c3e:	f526                	sd	s1,168(sp)
    80005c40:	f14a                	sd	s2,160(sp)
    80005c42:	ed4e                	sd	s3,152(sp)
    80005c44:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c46:	08000613          	li	a2,128
    80005c4a:	f5040593          	addi	a1,s0,-176
    80005c4e:	4501                	li	a0,0
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	504080e7          	jalr	1284(ra) # 80003154 <argstr>
    return -1;
    80005c58:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c5a:	0c054163          	bltz	a0,80005d1c <sys_open+0xe4>
    80005c5e:	f4c40593          	addi	a1,s0,-180
    80005c62:	4505                	li	a0,1
    80005c64:	ffffd097          	auipc	ra,0xffffd
    80005c68:	4ac080e7          	jalr	1196(ra) # 80003110 <argint>
    80005c6c:	0a054863          	bltz	a0,80005d1c <sys_open+0xe4>

  begin_op();
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	a2e080e7          	jalr	-1490(ra) # 8000469e <begin_op>

  if(omode & O_CREATE){
    80005c78:	f4c42783          	lw	a5,-180(s0)
    80005c7c:	2007f793          	andi	a5,a5,512
    80005c80:	cbdd                	beqz	a5,80005d36 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c82:	4681                	li	a3,0
    80005c84:	4601                	li	a2,0
    80005c86:	4589                	li	a1,2
    80005c88:	f5040513          	addi	a0,s0,-176
    80005c8c:	00000097          	auipc	ra,0x0
    80005c90:	972080e7          	jalr	-1678(ra) # 800055fe <create>
    80005c94:	892a                	mv	s2,a0
    if(ip == 0){
    80005c96:	c959                	beqz	a0,80005d2c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c98:	04491703          	lh	a4,68(s2)
    80005c9c:	478d                	li	a5,3
    80005c9e:	00f71763          	bne	a4,a5,80005cac <sys_open+0x74>
    80005ca2:	04695703          	lhu	a4,70(s2)
    80005ca6:	47a5                	li	a5,9
    80005ca8:	0ce7ec63          	bltu	a5,a4,80005d80 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	e02080e7          	jalr	-510(ra) # 80004aae <filealloc>
    80005cb4:	89aa                	mv	s3,a0
    80005cb6:	10050263          	beqz	a0,80005dba <sys_open+0x182>
    80005cba:	00000097          	auipc	ra,0x0
    80005cbe:	902080e7          	jalr	-1790(ra) # 800055bc <fdalloc>
    80005cc2:	84aa                	mv	s1,a0
    80005cc4:	0e054663          	bltz	a0,80005db0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cc8:	04491703          	lh	a4,68(s2)
    80005ccc:	478d                	li	a5,3
    80005cce:	0cf70463          	beq	a4,a5,80005d96 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005cd2:	4789                	li	a5,2
    80005cd4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005cd8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005cdc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ce0:	f4c42783          	lw	a5,-180(s0)
    80005ce4:	0017c713          	xori	a4,a5,1
    80005ce8:	8b05                	andi	a4,a4,1
    80005cea:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cee:	0037f713          	andi	a4,a5,3
    80005cf2:	00e03733          	snez	a4,a4
    80005cf6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cfa:	4007f793          	andi	a5,a5,1024
    80005cfe:	c791                	beqz	a5,80005d0a <sys_open+0xd2>
    80005d00:	04491703          	lh	a4,68(s2)
    80005d04:	4789                	li	a5,2
    80005d06:	08f70f63          	beq	a4,a5,80005da4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d0a:	854a                	mv	a0,s2
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	082080e7          	jalr	130(ra) # 80003d8e <iunlock>
  end_op();
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	a0a080e7          	jalr	-1526(ra) # 8000471e <end_op>

  return fd;
}
    80005d1c:	8526                	mv	a0,s1
    80005d1e:	70ea                	ld	ra,184(sp)
    80005d20:	744a                	ld	s0,176(sp)
    80005d22:	74aa                	ld	s1,168(sp)
    80005d24:	790a                	ld	s2,160(sp)
    80005d26:	69ea                	ld	s3,152(sp)
    80005d28:	6129                	addi	sp,sp,192
    80005d2a:	8082                	ret
      end_op();
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	9f2080e7          	jalr	-1550(ra) # 8000471e <end_op>
      return -1;
    80005d34:	b7e5                	j	80005d1c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d36:	f5040513          	addi	a0,s0,-176
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	748080e7          	jalr	1864(ra) # 80004482 <namei>
    80005d42:	892a                	mv	s2,a0
    80005d44:	c905                	beqz	a0,80005d74 <sys_open+0x13c>
    ilock(ip);
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	f86080e7          	jalr	-122(ra) # 80003ccc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d4e:	04491703          	lh	a4,68(s2)
    80005d52:	4785                	li	a5,1
    80005d54:	f4f712e3          	bne	a4,a5,80005c98 <sys_open+0x60>
    80005d58:	f4c42783          	lw	a5,-180(s0)
    80005d5c:	dba1                	beqz	a5,80005cac <sys_open+0x74>
      iunlockput(ip);
    80005d5e:	854a                	mv	a0,s2
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	1ce080e7          	jalr	462(ra) # 80003f2e <iunlockput>
      end_op();
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	9b6080e7          	jalr	-1610(ra) # 8000471e <end_op>
      return -1;
    80005d70:	54fd                	li	s1,-1
    80005d72:	b76d                	j	80005d1c <sys_open+0xe4>
      end_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	9aa080e7          	jalr	-1622(ra) # 8000471e <end_op>
      return -1;
    80005d7c:	54fd                	li	s1,-1
    80005d7e:	bf79                	j	80005d1c <sys_open+0xe4>
    iunlockput(ip);
    80005d80:	854a                	mv	a0,s2
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	1ac080e7          	jalr	428(ra) # 80003f2e <iunlockput>
    end_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	994080e7          	jalr	-1644(ra) # 8000471e <end_op>
    return -1;
    80005d92:	54fd                	li	s1,-1
    80005d94:	b761                	j	80005d1c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d96:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d9a:	04691783          	lh	a5,70(s2)
    80005d9e:	02f99223          	sh	a5,36(s3)
    80005da2:	bf2d                	j	80005cdc <sys_open+0xa4>
    itrunc(ip);
    80005da4:	854a                	mv	a0,s2
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	034080e7          	jalr	52(ra) # 80003dda <itrunc>
    80005dae:	bfb1                	j	80005d0a <sys_open+0xd2>
      fileclose(f);
    80005db0:	854e                	mv	a0,s3
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	db8080e7          	jalr	-584(ra) # 80004b6a <fileclose>
    iunlockput(ip);
    80005dba:	854a                	mv	a0,s2
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	172080e7          	jalr	370(ra) # 80003f2e <iunlockput>
    end_op();
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	95a080e7          	jalr	-1702(ra) # 8000471e <end_op>
    return -1;
    80005dcc:	54fd                	li	s1,-1
    80005dce:	b7b9                	j	80005d1c <sys_open+0xe4>

0000000080005dd0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005dd0:	7175                	addi	sp,sp,-144
    80005dd2:	e506                	sd	ra,136(sp)
    80005dd4:	e122                	sd	s0,128(sp)
    80005dd6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	8c6080e7          	jalr	-1850(ra) # 8000469e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005de0:	08000613          	li	a2,128
    80005de4:	f7040593          	addi	a1,s0,-144
    80005de8:	4501                	li	a0,0
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	36a080e7          	jalr	874(ra) # 80003154 <argstr>
    80005df2:	02054963          	bltz	a0,80005e24 <sys_mkdir+0x54>
    80005df6:	4681                	li	a3,0
    80005df8:	4601                	li	a2,0
    80005dfa:	4585                	li	a1,1
    80005dfc:	f7040513          	addi	a0,s0,-144
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	7fe080e7          	jalr	2046(ra) # 800055fe <create>
    80005e08:	cd11                	beqz	a0,80005e24 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	124080e7          	jalr	292(ra) # 80003f2e <iunlockput>
  end_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	90c080e7          	jalr	-1780(ra) # 8000471e <end_op>
  return 0;
    80005e1a:	4501                	li	a0,0
}
    80005e1c:	60aa                	ld	ra,136(sp)
    80005e1e:	640a                	ld	s0,128(sp)
    80005e20:	6149                	addi	sp,sp,144
    80005e22:	8082                	ret
    end_op();
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	8fa080e7          	jalr	-1798(ra) # 8000471e <end_op>
    return -1;
    80005e2c:	557d                	li	a0,-1
    80005e2e:	b7fd                	j	80005e1c <sys_mkdir+0x4c>

0000000080005e30 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e30:	7135                	addi	sp,sp,-160
    80005e32:	ed06                	sd	ra,152(sp)
    80005e34:	e922                	sd	s0,144(sp)
    80005e36:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	866080e7          	jalr	-1946(ra) # 8000469e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e40:	08000613          	li	a2,128
    80005e44:	f7040593          	addi	a1,s0,-144
    80005e48:	4501                	li	a0,0
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	30a080e7          	jalr	778(ra) # 80003154 <argstr>
    80005e52:	04054a63          	bltz	a0,80005ea6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e56:	f6c40593          	addi	a1,s0,-148
    80005e5a:	4505                	li	a0,1
    80005e5c:	ffffd097          	auipc	ra,0xffffd
    80005e60:	2b4080e7          	jalr	692(ra) # 80003110 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e64:	04054163          	bltz	a0,80005ea6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e68:	f6840593          	addi	a1,s0,-152
    80005e6c:	4509                	li	a0,2
    80005e6e:	ffffd097          	auipc	ra,0xffffd
    80005e72:	2a2080e7          	jalr	674(ra) # 80003110 <argint>
     argint(1, &major) < 0 ||
    80005e76:	02054863          	bltz	a0,80005ea6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e7a:	f6841683          	lh	a3,-152(s0)
    80005e7e:	f6c41603          	lh	a2,-148(s0)
    80005e82:	458d                	li	a1,3
    80005e84:	f7040513          	addi	a0,s0,-144
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	776080e7          	jalr	1910(ra) # 800055fe <create>
     argint(2, &minor) < 0 ||
    80005e90:	c919                	beqz	a0,80005ea6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	09c080e7          	jalr	156(ra) # 80003f2e <iunlockput>
  end_op();
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	884080e7          	jalr	-1916(ra) # 8000471e <end_op>
  return 0;
    80005ea2:	4501                	li	a0,0
    80005ea4:	a031                	j	80005eb0 <sys_mknod+0x80>
    end_op();
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	878080e7          	jalr	-1928(ra) # 8000471e <end_op>
    return -1;
    80005eae:	557d                	li	a0,-1
}
    80005eb0:	60ea                	ld	ra,152(sp)
    80005eb2:	644a                	ld	s0,144(sp)
    80005eb4:	610d                	addi	sp,sp,160
    80005eb6:	8082                	ret

0000000080005eb8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005eb8:	7135                	addi	sp,sp,-160
    80005eba:	ed06                	sd	ra,152(sp)
    80005ebc:	e922                	sd	s0,144(sp)
    80005ebe:	e526                	sd	s1,136(sp)
    80005ec0:	e14a                	sd	s2,128(sp)
    80005ec2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ec4:	ffffc097          	auipc	ra,0xffffc
    80005ec8:	a44080e7          	jalr	-1468(ra) # 80001908 <myproc>
    80005ecc:	892a                	mv	s2,a0
  
  begin_op();
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	7d0080e7          	jalr	2000(ra) # 8000469e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ed6:	08000613          	li	a2,128
    80005eda:	f6040593          	addi	a1,s0,-160
    80005ede:	4501                	li	a0,0
    80005ee0:	ffffd097          	auipc	ra,0xffffd
    80005ee4:	274080e7          	jalr	628(ra) # 80003154 <argstr>
    80005ee8:	04054b63          	bltz	a0,80005f3e <sys_chdir+0x86>
    80005eec:	f6040513          	addi	a0,s0,-160
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	592080e7          	jalr	1426(ra) # 80004482 <namei>
    80005ef8:	84aa                	mv	s1,a0
    80005efa:	c131                	beqz	a0,80005f3e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	dd0080e7          	jalr	-560(ra) # 80003ccc <ilock>
  if(ip->type != T_DIR){
    80005f04:	04449703          	lh	a4,68(s1)
    80005f08:	4785                	li	a5,1
    80005f0a:	04f71063          	bne	a4,a5,80005f4a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f0e:	8526                	mv	a0,s1
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	e7e080e7          	jalr	-386(ra) # 80003d8e <iunlock>
  iput(p->cwd);
    80005f18:	17093503          	ld	a0,368(s2)
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	f6a080e7          	jalr	-150(ra) # 80003e86 <iput>
  end_op();
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	7fa080e7          	jalr	2042(ra) # 8000471e <end_op>
  p->cwd = ip;
    80005f2c:	16993823          	sd	s1,368(s2)
  return 0;
    80005f30:	4501                	li	a0,0
}
    80005f32:	60ea                	ld	ra,152(sp)
    80005f34:	644a                	ld	s0,144(sp)
    80005f36:	64aa                	ld	s1,136(sp)
    80005f38:	690a                	ld	s2,128(sp)
    80005f3a:	610d                	addi	sp,sp,160
    80005f3c:	8082                	ret
    end_op();
    80005f3e:	ffffe097          	auipc	ra,0xffffe
    80005f42:	7e0080e7          	jalr	2016(ra) # 8000471e <end_op>
    return -1;
    80005f46:	557d                	li	a0,-1
    80005f48:	b7ed                	j	80005f32 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f4a:	8526                	mv	a0,s1
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	fe2080e7          	jalr	-30(ra) # 80003f2e <iunlockput>
    end_op();
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	7ca080e7          	jalr	1994(ra) # 8000471e <end_op>
    return -1;
    80005f5c:	557d                	li	a0,-1
    80005f5e:	bfd1                	j	80005f32 <sys_chdir+0x7a>

0000000080005f60 <sys_exec>:

uint64
sys_exec(void)
{
    80005f60:	7145                	addi	sp,sp,-464
    80005f62:	e786                	sd	ra,456(sp)
    80005f64:	e3a2                	sd	s0,448(sp)
    80005f66:	ff26                	sd	s1,440(sp)
    80005f68:	fb4a                	sd	s2,432(sp)
    80005f6a:	f74e                	sd	s3,424(sp)
    80005f6c:	f352                	sd	s4,416(sp)
    80005f6e:	ef56                	sd	s5,408(sp)
    80005f70:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f72:	08000613          	li	a2,128
    80005f76:	f4040593          	addi	a1,s0,-192
    80005f7a:	4501                	li	a0,0
    80005f7c:	ffffd097          	auipc	ra,0xffffd
    80005f80:	1d8080e7          	jalr	472(ra) # 80003154 <argstr>
    return -1;
    80005f84:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f86:	0c054a63          	bltz	a0,8000605a <sys_exec+0xfa>
    80005f8a:	e3840593          	addi	a1,s0,-456
    80005f8e:	4505                	li	a0,1
    80005f90:	ffffd097          	auipc	ra,0xffffd
    80005f94:	1a2080e7          	jalr	418(ra) # 80003132 <argaddr>
    80005f98:	0c054163          	bltz	a0,8000605a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f9c:	10000613          	li	a2,256
    80005fa0:	4581                	li	a1,0
    80005fa2:	e4040513          	addi	a0,s0,-448
    80005fa6:	ffffb097          	auipc	ra,0xffffb
    80005faa:	d3a080e7          	jalr	-710(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fae:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005fb2:	89a6                	mv	s3,s1
    80005fb4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005fb6:	02000a13          	li	s4,32
    80005fba:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005fbe:	00391513          	slli	a0,s2,0x3
    80005fc2:	e3040593          	addi	a1,s0,-464
    80005fc6:	e3843783          	ld	a5,-456(s0)
    80005fca:	953e                	add	a0,a0,a5
    80005fcc:	ffffd097          	auipc	ra,0xffffd
    80005fd0:	0aa080e7          	jalr	170(ra) # 80003076 <fetchaddr>
    80005fd4:	02054a63          	bltz	a0,80006008 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005fd8:	e3043783          	ld	a5,-464(s0)
    80005fdc:	c3b9                	beqz	a5,80006022 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	b16080e7          	jalr	-1258(ra) # 80000af4 <kalloc>
    80005fe6:	85aa                	mv	a1,a0
    80005fe8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fec:	cd11                	beqz	a0,80006008 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fee:	6605                	lui	a2,0x1
    80005ff0:	e3043503          	ld	a0,-464(s0)
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	0d4080e7          	jalr	212(ra) # 800030c8 <fetchstr>
    80005ffc:	00054663          	bltz	a0,80006008 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006000:	0905                	addi	s2,s2,1
    80006002:	09a1                	addi	s3,s3,8
    80006004:	fb491be3          	bne	s2,s4,80005fba <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006008:	10048913          	addi	s2,s1,256
    8000600c:	6088                	ld	a0,0(s1)
    8000600e:	c529                	beqz	a0,80006058 <sys_exec+0xf8>
    kfree(argv[i]);
    80006010:	ffffb097          	auipc	ra,0xffffb
    80006014:	9e8080e7          	jalr	-1560(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006018:	04a1                	addi	s1,s1,8
    8000601a:	ff2499e3          	bne	s1,s2,8000600c <sys_exec+0xac>
  return -1;
    8000601e:	597d                	li	s2,-1
    80006020:	a82d                	j	8000605a <sys_exec+0xfa>
      argv[i] = 0;
    80006022:	0a8e                	slli	s5,s5,0x3
    80006024:	fc040793          	addi	a5,s0,-64
    80006028:	9abe                	add	s5,s5,a5
    8000602a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000602e:	e4040593          	addi	a1,s0,-448
    80006032:	f4040513          	addi	a0,s0,-192
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	194080e7          	jalr	404(ra) # 800051ca <exec>
    8000603e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006040:	10048993          	addi	s3,s1,256
    80006044:	6088                	ld	a0,0(s1)
    80006046:	c911                	beqz	a0,8000605a <sys_exec+0xfa>
    kfree(argv[i]);
    80006048:	ffffb097          	auipc	ra,0xffffb
    8000604c:	9b0080e7          	jalr	-1616(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006050:	04a1                	addi	s1,s1,8
    80006052:	ff3499e3          	bne	s1,s3,80006044 <sys_exec+0xe4>
    80006056:	a011                	j	8000605a <sys_exec+0xfa>
  return -1;
    80006058:	597d                	li	s2,-1
}
    8000605a:	854a                	mv	a0,s2
    8000605c:	60be                	ld	ra,456(sp)
    8000605e:	641e                	ld	s0,448(sp)
    80006060:	74fa                	ld	s1,440(sp)
    80006062:	795a                	ld	s2,432(sp)
    80006064:	79ba                	ld	s3,424(sp)
    80006066:	7a1a                	ld	s4,416(sp)
    80006068:	6afa                	ld	s5,408(sp)
    8000606a:	6179                	addi	sp,sp,464
    8000606c:	8082                	ret

000000008000606e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000606e:	7139                	addi	sp,sp,-64
    80006070:	fc06                	sd	ra,56(sp)
    80006072:	f822                	sd	s0,48(sp)
    80006074:	f426                	sd	s1,40(sp)
    80006076:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	890080e7          	jalr	-1904(ra) # 80001908 <myproc>
    80006080:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006082:	fd840593          	addi	a1,s0,-40
    80006086:	4501                	li	a0,0
    80006088:	ffffd097          	auipc	ra,0xffffd
    8000608c:	0aa080e7          	jalr	170(ra) # 80003132 <argaddr>
    return -1;
    80006090:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006092:	0e054063          	bltz	a0,80006172 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006096:	fc840593          	addi	a1,s0,-56
    8000609a:	fd040513          	addi	a0,s0,-48
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	dfc080e7          	jalr	-516(ra) # 80004e9a <pipealloc>
    return -1;
    800060a6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060a8:	0c054563          	bltz	a0,80006172 <sys_pipe+0x104>
  fd0 = -1;
    800060ac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060b0:	fd043503          	ld	a0,-48(s0)
    800060b4:	fffff097          	auipc	ra,0xfffff
    800060b8:	508080e7          	jalr	1288(ra) # 800055bc <fdalloc>
    800060bc:	fca42223          	sw	a0,-60(s0)
    800060c0:	08054c63          	bltz	a0,80006158 <sys_pipe+0xea>
    800060c4:	fc843503          	ld	a0,-56(s0)
    800060c8:	fffff097          	auipc	ra,0xfffff
    800060cc:	4f4080e7          	jalr	1268(ra) # 800055bc <fdalloc>
    800060d0:	fca42023          	sw	a0,-64(s0)
    800060d4:	06054863          	bltz	a0,80006144 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060d8:	4691                	li	a3,4
    800060da:	fc440613          	addi	a2,s0,-60
    800060de:	fd843583          	ld	a1,-40(s0)
    800060e2:	78a8                	ld	a0,112(s1)
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	58e080e7          	jalr	1422(ra) # 80001672 <copyout>
    800060ec:	02054063          	bltz	a0,8000610c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060f0:	4691                	li	a3,4
    800060f2:	fc040613          	addi	a2,s0,-64
    800060f6:	fd843583          	ld	a1,-40(s0)
    800060fa:	0591                	addi	a1,a1,4
    800060fc:	78a8                	ld	a0,112(s1)
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	574080e7          	jalr	1396(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006106:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006108:	06055563          	bgez	a0,80006172 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000610c:	fc442783          	lw	a5,-60(s0)
    80006110:	07f9                	addi	a5,a5,30
    80006112:	078e                	slli	a5,a5,0x3
    80006114:	97a6                	add	a5,a5,s1
    80006116:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000611a:	fc042503          	lw	a0,-64(s0)
    8000611e:	0579                	addi	a0,a0,30
    80006120:	050e                	slli	a0,a0,0x3
    80006122:	9526                	add	a0,a0,s1
    80006124:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006128:	fd043503          	ld	a0,-48(s0)
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	a3e080e7          	jalr	-1474(ra) # 80004b6a <fileclose>
    fileclose(wf);
    80006134:	fc843503          	ld	a0,-56(s0)
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	a32080e7          	jalr	-1486(ra) # 80004b6a <fileclose>
    return -1;
    80006140:	57fd                	li	a5,-1
    80006142:	a805                	j	80006172 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006144:	fc442783          	lw	a5,-60(s0)
    80006148:	0007c863          	bltz	a5,80006158 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000614c:	01e78513          	addi	a0,a5,30
    80006150:	050e                	slli	a0,a0,0x3
    80006152:	9526                	add	a0,a0,s1
    80006154:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006158:	fd043503          	ld	a0,-48(s0)
    8000615c:	fffff097          	auipc	ra,0xfffff
    80006160:	a0e080e7          	jalr	-1522(ra) # 80004b6a <fileclose>
    fileclose(wf);
    80006164:	fc843503          	ld	a0,-56(s0)
    80006168:	fffff097          	auipc	ra,0xfffff
    8000616c:	a02080e7          	jalr	-1534(ra) # 80004b6a <fileclose>
    return -1;
    80006170:	57fd                	li	a5,-1
}
    80006172:	853e                	mv	a0,a5
    80006174:	70e2                	ld	ra,56(sp)
    80006176:	7442                	ld	s0,48(sp)
    80006178:	74a2                	ld	s1,40(sp)
    8000617a:	6121                	addi	sp,sp,64
    8000617c:	8082                	ret
	...

0000000080006180 <kernelvec>:
    80006180:	7111                	addi	sp,sp,-256
    80006182:	e006                	sd	ra,0(sp)
    80006184:	e40a                	sd	sp,8(sp)
    80006186:	e80e                	sd	gp,16(sp)
    80006188:	ec12                	sd	tp,24(sp)
    8000618a:	f016                	sd	t0,32(sp)
    8000618c:	f41a                	sd	t1,40(sp)
    8000618e:	f81e                	sd	t2,48(sp)
    80006190:	fc22                	sd	s0,56(sp)
    80006192:	e0a6                	sd	s1,64(sp)
    80006194:	e4aa                	sd	a0,72(sp)
    80006196:	e8ae                	sd	a1,80(sp)
    80006198:	ecb2                	sd	a2,88(sp)
    8000619a:	f0b6                	sd	a3,96(sp)
    8000619c:	f4ba                	sd	a4,104(sp)
    8000619e:	f8be                	sd	a5,112(sp)
    800061a0:	fcc2                	sd	a6,120(sp)
    800061a2:	e146                	sd	a7,128(sp)
    800061a4:	e54a                	sd	s2,136(sp)
    800061a6:	e94e                	sd	s3,144(sp)
    800061a8:	ed52                	sd	s4,152(sp)
    800061aa:	f156                	sd	s5,160(sp)
    800061ac:	f55a                	sd	s6,168(sp)
    800061ae:	f95e                	sd	s7,176(sp)
    800061b0:	fd62                	sd	s8,184(sp)
    800061b2:	e1e6                	sd	s9,192(sp)
    800061b4:	e5ea                	sd	s10,200(sp)
    800061b6:	e9ee                	sd	s11,208(sp)
    800061b8:	edf2                	sd	t3,216(sp)
    800061ba:	f1f6                	sd	t4,224(sp)
    800061bc:	f5fa                	sd	t5,232(sp)
    800061be:	f9fe                	sd	t6,240(sp)
    800061c0:	d83fc0ef          	jal	ra,80002f42 <kerneltrap>
    800061c4:	6082                	ld	ra,0(sp)
    800061c6:	6122                	ld	sp,8(sp)
    800061c8:	61c2                	ld	gp,16(sp)
    800061ca:	7282                	ld	t0,32(sp)
    800061cc:	7322                	ld	t1,40(sp)
    800061ce:	73c2                	ld	t2,48(sp)
    800061d0:	7462                	ld	s0,56(sp)
    800061d2:	6486                	ld	s1,64(sp)
    800061d4:	6526                	ld	a0,72(sp)
    800061d6:	65c6                	ld	a1,80(sp)
    800061d8:	6666                	ld	a2,88(sp)
    800061da:	7686                	ld	a3,96(sp)
    800061dc:	7726                	ld	a4,104(sp)
    800061de:	77c6                	ld	a5,112(sp)
    800061e0:	7866                	ld	a6,120(sp)
    800061e2:	688a                	ld	a7,128(sp)
    800061e4:	692a                	ld	s2,136(sp)
    800061e6:	69ca                	ld	s3,144(sp)
    800061e8:	6a6a                	ld	s4,152(sp)
    800061ea:	7a8a                	ld	s5,160(sp)
    800061ec:	7b2a                	ld	s6,168(sp)
    800061ee:	7bca                	ld	s7,176(sp)
    800061f0:	7c6a                	ld	s8,184(sp)
    800061f2:	6c8e                	ld	s9,192(sp)
    800061f4:	6d2e                	ld	s10,200(sp)
    800061f6:	6dce                	ld	s11,208(sp)
    800061f8:	6e6e                	ld	t3,216(sp)
    800061fa:	7e8e                	ld	t4,224(sp)
    800061fc:	7f2e                	ld	t5,232(sp)
    800061fe:	7fce                	ld	t6,240(sp)
    80006200:	6111                	addi	sp,sp,256
    80006202:	10200073          	sret
    80006206:	00000013          	nop
    8000620a:	00000013          	nop
    8000620e:	0001                	nop

0000000080006210 <timervec>:
    80006210:	34051573          	csrrw	a0,mscratch,a0
    80006214:	e10c                	sd	a1,0(a0)
    80006216:	e510                	sd	a2,8(a0)
    80006218:	e914                	sd	a3,16(a0)
    8000621a:	6d0c                	ld	a1,24(a0)
    8000621c:	7110                	ld	a2,32(a0)
    8000621e:	6194                	ld	a3,0(a1)
    80006220:	96b2                	add	a3,a3,a2
    80006222:	e194                	sd	a3,0(a1)
    80006224:	4589                	li	a1,2
    80006226:	14459073          	csrw	sip,a1
    8000622a:	6914                	ld	a3,16(a0)
    8000622c:	6510                	ld	a2,8(a0)
    8000622e:	610c                	ld	a1,0(a0)
    80006230:	34051573          	csrrw	a0,mscratch,a0
    80006234:	30200073          	mret
	...

000000008000623a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000623a:	1141                	addi	sp,sp,-16
    8000623c:	e422                	sd	s0,8(sp)
    8000623e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006240:	0c0007b7          	lui	a5,0xc000
    80006244:	4705                	li	a4,1
    80006246:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006248:	c3d8                	sw	a4,4(a5)
}
    8000624a:	6422                	ld	s0,8(sp)
    8000624c:	0141                	addi	sp,sp,16
    8000624e:	8082                	ret

0000000080006250 <plicinithart>:

void
plicinithart(void)
{
    80006250:	1141                	addi	sp,sp,-16
    80006252:	e406                	sd	ra,8(sp)
    80006254:	e022                	sd	s0,0(sp)
    80006256:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	67c080e7          	jalr	1660(ra) # 800018d4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006260:	0085171b          	slliw	a4,a0,0x8
    80006264:	0c0027b7          	lui	a5,0xc002
    80006268:	97ba                	add	a5,a5,a4
    8000626a:	40200713          	li	a4,1026
    8000626e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006272:	00d5151b          	slliw	a0,a0,0xd
    80006276:	0c2017b7          	lui	a5,0xc201
    8000627a:	953e                	add	a0,a0,a5
    8000627c:	00052023          	sw	zero,0(a0)
}
    80006280:	60a2                	ld	ra,8(sp)
    80006282:	6402                	ld	s0,0(sp)
    80006284:	0141                	addi	sp,sp,16
    80006286:	8082                	ret

0000000080006288 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006288:	1141                	addi	sp,sp,-16
    8000628a:	e406                	sd	ra,8(sp)
    8000628c:	e022                	sd	s0,0(sp)
    8000628e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	644080e7          	jalr	1604(ra) # 800018d4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006298:	00d5179b          	slliw	a5,a0,0xd
    8000629c:	0c201537          	lui	a0,0xc201
    800062a0:	953e                	add	a0,a0,a5
  return irq;
}
    800062a2:	4148                	lw	a0,4(a0)
    800062a4:	60a2                	ld	ra,8(sp)
    800062a6:	6402                	ld	s0,0(sp)
    800062a8:	0141                	addi	sp,sp,16
    800062aa:	8082                	ret

00000000800062ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ac:	1101                	addi	sp,sp,-32
    800062ae:	ec06                	sd	ra,24(sp)
    800062b0:	e822                	sd	s0,16(sp)
    800062b2:	e426                	sd	s1,8(sp)
    800062b4:	1000                	addi	s0,sp,32
    800062b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062b8:	ffffb097          	auipc	ra,0xffffb
    800062bc:	61c080e7          	jalr	1564(ra) # 800018d4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062c0:	00d5151b          	slliw	a0,a0,0xd
    800062c4:	0c2017b7          	lui	a5,0xc201
    800062c8:	97aa                	add	a5,a5,a0
    800062ca:	c3c4                	sw	s1,4(a5)
}
    800062cc:	60e2                	ld	ra,24(sp)
    800062ce:	6442                	ld	s0,16(sp)
    800062d0:	64a2                	ld	s1,8(sp)
    800062d2:	6105                	addi	sp,sp,32
    800062d4:	8082                	ret

00000000800062d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062d6:	1141                	addi	sp,sp,-16
    800062d8:	e406                	sd	ra,8(sp)
    800062da:	e022                	sd	s0,0(sp)
    800062dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062de:	479d                	li	a5,7
    800062e0:	06a7c963          	blt	a5,a0,80006352 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062e4:	0001d797          	auipc	a5,0x1d
    800062e8:	d1c78793          	addi	a5,a5,-740 # 80023000 <disk>
    800062ec:	00a78733          	add	a4,a5,a0
    800062f0:	6789                	lui	a5,0x2
    800062f2:	97ba                	add	a5,a5,a4
    800062f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062f8:	e7ad                	bnez	a5,80006362 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062fa:	00451793          	slli	a5,a0,0x4
    800062fe:	0001f717          	auipc	a4,0x1f
    80006302:	d0270713          	addi	a4,a4,-766 # 80025000 <disk+0x2000>
    80006306:	6314                	ld	a3,0(a4)
    80006308:	96be                	add	a3,a3,a5
    8000630a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000630e:	6314                	ld	a3,0(a4)
    80006310:	96be                	add	a3,a3,a5
    80006312:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006316:	6314                	ld	a3,0(a4)
    80006318:	96be                	add	a3,a3,a5
    8000631a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000631e:	6318                	ld	a4,0(a4)
    80006320:	97ba                	add	a5,a5,a4
    80006322:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006326:	0001d797          	auipc	a5,0x1d
    8000632a:	cda78793          	addi	a5,a5,-806 # 80023000 <disk>
    8000632e:	97aa                	add	a5,a5,a0
    80006330:	6509                	lui	a0,0x2
    80006332:	953e                	add	a0,a0,a5
    80006334:	4785                	li	a5,1
    80006336:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000633a:	0001f517          	auipc	a0,0x1f
    8000633e:	cde50513          	addi	a0,a0,-802 # 80025018 <disk+0x2018>
    80006342:	ffffc097          	auipc	ra,0xffffc
    80006346:	54a080e7          	jalr	1354(ra) # 8000288c <wakeup>
}
    8000634a:	60a2                	ld	ra,8(sp)
    8000634c:	6402                	ld	s0,0(sp)
    8000634e:	0141                	addi	sp,sp,16
    80006350:	8082                	ret
    panic("free_desc 1");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	51e50513          	addi	a0,a0,1310 # 80008870 <syscalls+0x330>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e4080e7          	jalr	484(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	51e50513          	addi	a0,a0,1310 # 80008880 <syscalls+0x340>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>

0000000080006372 <virtio_disk_init>:
{
    80006372:	1101                	addi	sp,sp,-32
    80006374:	ec06                	sd	ra,24(sp)
    80006376:	e822                	sd	s0,16(sp)
    80006378:	e426                	sd	s1,8(sp)
    8000637a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000637c:	00002597          	auipc	a1,0x2
    80006380:	51458593          	addi	a1,a1,1300 # 80008890 <syscalls+0x350>
    80006384:	0001f517          	auipc	a0,0x1f
    80006388:	da450513          	addi	a0,a0,-604 # 80025128 <disk+0x2128>
    8000638c:	ffffa097          	auipc	ra,0xffffa
    80006390:	7c8080e7          	jalr	1992(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006394:	100017b7          	lui	a5,0x10001
    80006398:	4398                	lw	a4,0(a5)
    8000639a:	2701                	sext.w	a4,a4
    8000639c:	747277b7          	lui	a5,0x74727
    800063a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063a4:	0ef71163          	bne	a4,a5,80006486 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063a8:	100017b7          	lui	a5,0x10001
    800063ac:	43dc                	lw	a5,4(a5)
    800063ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063b0:	4705                	li	a4,1
    800063b2:	0ce79a63          	bne	a5,a4,80006486 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063b6:	100017b7          	lui	a5,0x10001
    800063ba:	479c                	lw	a5,8(a5)
    800063bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063be:	4709                	li	a4,2
    800063c0:	0ce79363          	bne	a5,a4,80006486 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063c4:	100017b7          	lui	a5,0x10001
    800063c8:	47d8                	lw	a4,12(a5)
    800063ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063cc:	554d47b7          	lui	a5,0x554d4
    800063d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063d4:	0af71963          	bne	a4,a5,80006486 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063d8:	100017b7          	lui	a5,0x10001
    800063dc:	4705                	li	a4,1
    800063de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063e0:	470d                	li	a4,3
    800063e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063e6:	c7ffe737          	lui	a4,0xc7ffe
    800063ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800063ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063f0:	2701                	sext.w	a4,a4
    800063f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063f4:	472d                	li	a4,11
    800063f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063f8:	473d                	li	a4,15
    800063fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063fc:	6705                	lui	a4,0x1
    800063fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006400:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006404:	5bdc                	lw	a5,52(a5)
    80006406:	2781                	sext.w	a5,a5
  if(max == 0)
    80006408:	c7d9                	beqz	a5,80006496 <virtio_disk_init+0x124>
  if(max < NUM)
    8000640a:	471d                	li	a4,7
    8000640c:	08f77d63          	bgeu	a4,a5,800064a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006410:	100014b7          	lui	s1,0x10001
    80006414:	47a1                	li	a5,8
    80006416:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006418:	6609                	lui	a2,0x2
    8000641a:	4581                	li	a1,0
    8000641c:	0001d517          	auipc	a0,0x1d
    80006420:	be450513          	addi	a0,a0,-1052 # 80023000 <disk>
    80006424:	ffffb097          	auipc	ra,0xffffb
    80006428:	8bc080e7          	jalr	-1860(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000642c:	0001d717          	auipc	a4,0x1d
    80006430:	bd470713          	addi	a4,a4,-1068 # 80023000 <disk>
    80006434:	00c75793          	srli	a5,a4,0xc
    80006438:	2781                	sext.w	a5,a5
    8000643a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000643c:	0001f797          	auipc	a5,0x1f
    80006440:	bc478793          	addi	a5,a5,-1084 # 80025000 <disk+0x2000>
    80006444:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006446:	0001d717          	auipc	a4,0x1d
    8000644a:	c3a70713          	addi	a4,a4,-966 # 80023080 <disk+0x80>
    8000644e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006450:	0001e717          	auipc	a4,0x1e
    80006454:	bb070713          	addi	a4,a4,-1104 # 80024000 <disk+0x1000>
    80006458:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000645a:	4705                	li	a4,1
    8000645c:	00e78c23          	sb	a4,24(a5)
    80006460:	00e78ca3          	sb	a4,25(a5)
    80006464:	00e78d23          	sb	a4,26(a5)
    80006468:	00e78da3          	sb	a4,27(a5)
    8000646c:	00e78e23          	sb	a4,28(a5)
    80006470:	00e78ea3          	sb	a4,29(a5)
    80006474:	00e78f23          	sb	a4,30(a5)
    80006478:	00e78fa3          	sb	a4,31(a5)
}
    8000647c:	60e2                	ld	ra,24(sp)
    8000647e:	6442                	ld	s0,16(sp)
    80006480:	64a2                	ld	s1,8(sp)
    80006482:	6105                	addi	sp,sp,32
    80006484:	8082                	ret
    panic("could not find virtio disk");
    80006486:	00002517          	auipc	a0,0x2
    8000648a:	41a50513          	addi	a0,a0,1050 # 800088a0 <syscalls+0x360>
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006496:	00002517          	auipc	a0,0x2
    8000649a:	42a50513          	addi	a0,a0,1066 # 800088c0 <syscalls+0x380>
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	0a0080e7          	jalr	160(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800064a6:	00002517          	auipc	a0,0x2
    800064aa:	43a50513          	addi	a0,a0,1082 # 800088e0 <syscalls+0x3a0>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	090080e7          	jalr	144(ra) # 8000053e <panic>

00000000800064b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064b6:	7159                	addi	sp,sp,-112
    800064b8:	f486                	sd	ra,104(sp)
    800064ba:	f0a2                	sd	s0,96(sp)
    800064bc:	eca6                	sd	s1,88(sp)
    800064be:	e8ca                	sd	s2,80(sp)
    800064c0:	e4ce                	sd	s3,72(sp)
    800064c2:	e0d2                	sd	s4,64(sp)
    800064c4:	fc56                	sd	s5,56(sp)
    800064c6:	f85a                	sd	s6,48(sp)
    800064c8:	f45e                	sd	s7,40(sp)
    800064ca:	f062                	sd	s8,32(sp)
    800064cc:	ec66                	sd	s9,24(sp)
    800064ce:	e86a                	sd	s10,16(sp)
    800064d0:	1880                	addi	s0,sp,112
    800064d2:	892a                	mv	s2,a0
    800064d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064d6:	00c52c83          	lw	s9,12(a0)
    800064da:	001c9c9b          	slliw	s9,s9,0x1
    800064de:	1c82                	slli	s9,s9,0x20
    800064e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064e4:	0001f517          	auipc	a0,0x1f
    800064e8:	c4450513          	addi	a0,a0,-956 # 80025128 <disk+0x2128>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	6f8080e7          	jalr	1784(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800064f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064f8:	0001db97          	auipc	s7,0x1d
    800064fc:	b08b8b93          	addi	s7,s7,-1272 # 80023000 <disk>
    80006500:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006502:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006504:	8a4e                	mv	s4,s3
    80006506:	a051                	j	8000658a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006508:	00fb86b3          	add	a3,s7,a5
    8000650c:	96da                	add	a3,a3,s6
    8000650e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006512:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006514:	0207c563          	bltz	a5,8000653e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006518:	2485                	addiw	s1,s1,1
    8000651a:	0711                	addi	a4,a4,4
    8000651c:	25548063          	beq	s1,s5,8000675c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006520:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006522:	0001f697          	auipc	a3,0x1f
    80006526:	af668693          	addi	a3,a3,-1290 # 80025018 <disk+0x2018>
    8000652a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000652c:	0006c583          	lbu	a1,0(a3)
    80006530:	fde1                	bnez	a1,80006508 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006532:	2785                	addiw	a5,a5,1
    80006534:	0685                	addi	a3,a3,1
    80006536:	ff879be3          	bne	a5,s8,8000652c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000653a:	57fd                	li	a5,-1
    8000653c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000653e:	02905a63          	blez	s1,80006572 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006542:	f9042503          	lw	a0,-112(s0)
    80006546:	00000097          	auipc	ra,0x0
    8000654a:	d90080e7          	jalr	-624(ra) # 800062d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000654e:	4785                	li	a5,1
    80006550:	0297d163          	bge	a5,s1,80006572 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006554:	f9442503          	lw	a0,-108(s0)
    80006558:	00000097          	auipc	ra,0x0
    8000655c:	d7e080e7          	jalr	-642(ra) # 800062d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006560:	4789                	li	a5,2
    80006562:	0097d863          	bge	a5,s1,80006572 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006566:	f9842503          	lw	a0,-104(s0)
    8000656a:	00000097          	auipc	ra,0x0
    8000656e:	d6c080e7          	jalr	-660(ra) # 800062d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006572:	0001f597          	auipc	a1,0x1f
    80006576:	bb658593          	addi	a1,a1,-1098 # 80025128 <disk+0x2128>
    8000657a:	0001f517          	auipc	a0,0x1f
    8000657e:	a9e50513          	addi	a0,a0,-1378 # 80025018 <disk+0x2018>
    80006582:	ffffc097          	auipc	ra,0xffffc
    80006586:	b00080e7          	jalr	-1280(ra) # 80002082 <sleep>
  for(int i = 0; i < 3; i++){
    8000658a:	f9040713          	addi	a4,s0,-112
    8000658e:	84ce                	mv	s1,s3
    80006590:	bf41                	j	80006520 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006592:	20058713          	addi	a4,a1,512
    80006596:	00471693          	slli	a3,a4,0x4
    8000659a:	0001d717          	auipc	a4,0x1d
    8000659e:	a6670713          	addi	a4,a4,-1434 # 80023000 <disk>
    800065a2:	9736                	add	a4,a4,a3
    800065a4:	4685                	li	a3,1
    800065a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065aa:	20058713          	addi	a4,a1,512
    800065ae:	00471693          	slli	a3,a4,0x4
    800065b2:	0001d717          	auipc	a4,0x1d
    800065b6:	a4e70713          	addi	a4,a4,-1458 # 80023000 <disk>
    800065ba:	9736                	add	a4,a4,a3
    800065bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065c4:	7679                	lui	a2,0xffffe
    800065c6:	963e                	add	a2,a2,a5
    800065c8:	0001f697          	auipc	a3,0x1f
    800065cc:	a3868693          	addi	a3,a3,-1480 # 80025000 <disk+0x2000>
    800065d0:	6298                	ld	a4,0(a3)
    800065d2:	9732                	add	a4,a4,a2
    800065d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065d6:	6298                	ld	a4,0(a3)
    800065d8:	9732                	add	a4,a4,a2
    800065da:	4541                	li	a0,16
    800065dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065de:	6298                	ld	a4,0(a3)
    800065e0:	9732                	add	a4,a4,a2
    800065e2:	4505                	li	a0,1
    800065e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065e8:	f9442703          	lw	a4,-108(s0)
    800065ec:	6288                	ld	a0,0(a3)
    800065ee:	962a                	add	a2,a2,a0
    800065f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065f4:	0712                	slli	a4,a4,0x4
    800065f6:	6290                	ld	a2,0(a3)
    800065f8:	963a                	add	a2,a2,a4
    800065fa:	05890513          	addi	a0,s2,88
    800065fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006600:	6294                	ld	a3,0(a3)
    80006602:	96ba                	add	a3,a3,a4
    80006604:	40000613          	li	a2,1024
    80006608:	c690                	sw	a2,8(a3)
  if(write)
    8000660a:	140d0063          	beqz	s10,8000674a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000660e:	0001f697          	auipc	a3,0x1f
    80006612:	9f26b683          	ld	a3,-1550(a3) # 80025000 <disk+0x2000>
    80006616:	96ba                	add	a3,a3,a4
    80006618:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000661c:	0001d817          	auipc	a6,0x1d
    80006620:	9e480813          	addi	a6,a6,-1564 # 80023000 <disk>
    80006624:	0001f517          	auipc	a0,0x1f
    80006628:	9dc50513          	addi	a0,a0,-1572 # 80025000 <disk+0x2000>
    8000662c:	6114                	ld	a3,0(a0)
    8000662e:	96ba                	add	a3,a3,a4
    80006630:	00c6d603          	lhu	a2,12(a3)
    80006634:	00166613          	ori	a2,a2,1
    80006638:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000663c:	f9842683          	lw	a3,-104(s0)
    80006640:	6110                	ld	a2,0(a0)
    80006642:	9732                	add	a4,a4,a2
    80006644:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006648:	20058613          	addi	a2,a1,512
    8000664c:	0612                	slli	a2,a2,0x4
    8000664e:	9642                	add	a2,a2,a6
    80006650:	577d                	li	a4,-1
    80006652:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006656:	00469713          	slli	a4,a3,0x4
    8000665a:	6114                	ld	a3,0(a0)
    8000665c:	96ba                	add	a3,a3,a4
    8000665e:	03078793          	addi	a5,a5,48
    80006662:	97c2                	add	a5,a5,a6
    80006664:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006666:	611c                	ld	a5,0(a0)
    80006668:	97ba                	add	a5,a5,a4
    8000666a:	4685                	li	a3,1
    8000666c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000666e:	611c                	ld	a5,0(a0)
    80006670:	97ba                	add	a5,a5,a4
    80006672:	4809                	li	a6,2
    80006674:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006678:	611c                	ld	a5,0(a0)
    8000667a:	973e                	add	a4,a4,a5
    8000667c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006680:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006684:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006688:	6518                	ld	a4,8(a0)
    8000668a:	00275783          	lhu	a5,2(a4)
    8000668e:	8b9d                	andi	a5,a5,7
    80006690:	0786                	slli	a5,a5,0x1
    80006692:	97ba                	add	a5,a5,a4
    80006694:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006698:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000669c:	6518                	ld	a4,8(a0)
    8000669e:	00275783          	lhu	a5,2(a4)
    800066a2:	2785                	addiw	a5,a5,1
    800066a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066ac:	100017b7          	lui	a5,0x10001
    800066b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066b4:	00492703          	lw	a4,4(s2)
    800066b8:	4785                	li	a5,1
    800066ba:	02f71163          	bne	a4,a5,800066dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800066be:	0001f997          	auipc	s3,0x1f
    800066c2:	a6a98993          	addi	s3,s3,-1430 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800066c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066c8:	85ce                	mv	a1,s3
    800066ca:	854a                	mv	a0,s2
    800066cc:	ffffc097          	auipc	ra,0xffffc
    800066d0:	9b6080e7          	jalr	-1610(ra) # 80002082 <sleep>
  while(b->disk == 1) {
    800066d4:	00492783          	lw	a5,4(s2)
    800066d8:	fe9788e3          	beq	a5,s1,800066c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800066dc:	f9042903          	lw	s2,-112(s0)
    800066e0:	20090793          	addi	a5,s2,512
    800066e4:	00479713          	slli	a4,a5,0x4
    800066e8:	0001d797          	auipc	a5,0x1d
    800066ec:	91878793          	addi	a5,a5,-1768 # 80023000 <disk>
    800066f0:	97ba                	add	a5,a5,a4
    800066f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066f6:	0001f997          	auipc	s3,0x1f
    800066fa:	90a98993          	addi	s3,s3,-1782 # 80025000 <disk+0x2000>
    800066fe:	00491713          	slli	a4,s2,0x4
    80006702:	0009b783          	ld	a5,0(s3)
    80006706:	97ba                	add	a5,a5,a4
    80006708:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000670c:	854a                	mv	a0,s2
    8000670e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006712:	00000097          	auipc	ra,0x0
    80006716:	bc4080e7          	jalr	-1084(ra) # 800062d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000671a:	8885                	andi	s1,s1,1
    8000671c:	f0ed                	bnez	s1,800066fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000671e:	0001f517          	auipc	a0,0x1f
    80006722:	a0a50513          	addi	a0,a0,-1526 # 80025128 <disk+0x2128>
    80006726:	ffffa097          	auipc	ra,0xffffa
    8000672a:	572080e7          	jalr	1394(ra) # 80000c98 <release>
}
    8000672e:	70a6                	ld	ra,104(sp)
    80006730:	7406                	ld	s0,96(sp)
    80006732:	64e6                	ld	s1,88(sp)
    80006734:	6946                	ld	s2,80(sp)
    80006736:	69a6                	ld	s3,72(sp)
    80006738:	6a06                	ld	s4,64(sp)
    8000673a:	7ae2                	ld	s5,56(sp)
    8000673c:	7b42                	ld	s6,48(sp)
    8000673e:	7ba2                	ld	s7,40(sp)
    80006740:	7c02                	ld	s8,32(sp)
    80006742:	6ce2                	ld	s9,24(sp)
    80006744:	6d42                	ld	s10,16(sp)
    80006746:	6165                	addi	sp,sp,112
    80006748:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000674a:	0001f697          	auipc	a3,0x1f
    8000674e:	8b66b683          	ld	a3,-1866(a3) # 80025000 <disk+0x2000>
    80006752:	96ba                	add	a3,a3,a4
    80006754:	4609                	li	a2,2
    80006756:	00c69623          	sh	a2,12(a3)
    8000675a:	b5c9                	j	8000661c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000675c:	f9042583          	lw	a1,-112(s0)
    80006760:	20058793          	addi	a5,a1,512
    80006764:	0792                	slli	a5,a5,0x4
    80006766:	0001d517          	auipc	a0,0x1d
    8000676a:	94250513          	addi	a0,a0,-1726 # 800230a8 <disk+0xa8>
    8000676e:	953e                	add	a0,a0,a5
  if(write)
    80006770:	e20d11e3          	bnez	s10,80006592 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006774:	20058713          	addi	a4,a1,512
    80006778:	00471693          	slli	a3,a4,0x4
    8000677c:	0001d717          	auipc	a4,0x1d
    80006780:	88470713          	addi	a4,a4,-1916 # 80023000 <disk>
    80006784:	9736                	add	a4,a4,a3
    80006786:	0a072423          	sw	zero,168(a4)
    8000678a:	b505                	j	800065aa <virtio_disk_rw+0xf4>

000000008000678c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000678c:	1101                	addi	sp,sp,-32
    8000678e:	ec06                	sd	ra,24(sp)
    80006790:	e822                	sd	s0,16(sp)
    80006792:	e426                	sd	s1,8(sp)
    80006794:	e04a                	sd	s2,0(sp)
    80006796:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006798:	0001f517          	auipc	a0,0x1f
    8000679c:	99050513          	addi	a0,a0,-1648 # 80025128 <disk+0x2128>
    800067a0:	ffffa097          	auipc	ra,0xffffa
    800067a4:	444080e7          	jalr	1092(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067a8:	10001737          	lui	a4,0x10001
    800067ac:	533c                	lw	a5,96(a4)
    800067ae:	8b8d                	andi	a5,a5,3
    800067b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067b6:	0001f797          	auipc	a5,0x1f
    800067ba:	84a78793          	addi	a5,a5,-1974 # 80025000 <disk+0x2000>
    800067be:	6b94                	ld	a3,16(a5)
    800067c0:	0207d703          	lhu	a4,32(a5)
    800067c4:	0026d783          	lhu	a5,2(a3)
    800067c8:	06f70163          	beq	a4,a5,8000682a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067cc:	0001d917          	auipc	s2,0x1d
    800067d0:	83490913          	addi	s2,s2,-1996 # 80023000 <disk>
    800067d4:	0001f497          	auipc	s1,0x1f
    800067d8:	82c48493          	addi	s1,s1,-2004 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800067dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067e0:	6898                	ld	a4,16(s1)
    800067e2:	0204d783          	lhu	a5,32(s1)
    800067e6:	8b9d                	andi	a5,a5,7
    800067e8:	078e                	slli	a5,a5,0x3
    800067ea:	97ba                	add	a5,a5,a4
    800067ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067ee:	20078713          	addi	a4,a5,512
    800067f2:	0712                	slli	a4,a4,0x4
    800067f4:	974a                	add	a4,a4,s2
    800067f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067fa:	e731                	bnez	a4,80006846 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067fc:	20078793          	addi	a5,a5,512
    80006800:	0792                	slli	a5,a5,0x4
    80006802:	97ca                	add	a5,a5,s2
    80006804:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006806:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000680a:	ffffc097          	auipc	ra,0xffffc
    8000680e:	082080e7          	jalr	130(ra) # 8000288c <wakeup>

    disk.used_idx += 1;
    80006812:	0204d783          	lhu	a5,32(s1)
    80006816:	2785                	addiw	a5,a5,1
    80006818:	17c2                	slli	a5,a5,0x30
    8000681a:	93c1                	srli	a5,a5,0x30
    8000681c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006820:	6898                	ld	a4,16(s1)
    80006822:	00275703          	lhu	a4,2(a4)
    80006826:	faf71be3          	bne	a4,a5,800067dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000682a:	0001f517          	auipc	a0,0x1f
    8000682e:	8fe50513          	addi	a0,a0,-1794 # 80025128 <disk+0x2128>
    80006832:	ffffa097          	auipc	ra,0xffffa
    80006836:	466080e7          	jalr	1126(ra) # 80000c98 <release>
}
    8000683a:	60e2                	ld	ra,24(sp)
    8000683c:	6442                	ld	s0,16(sp)
    8000683e:	64a2                	ld	s1,8(sp)
    80006840:	6902                	ld	s2,0(sp)
    80006842:	6105                	addi	sp,sp,32
    80006844:	8082                	ret
      panic("virtio_disk_intr status");
    80006846:	00002517          	auipc	a0,0x2
    8000684a:	0ba50513          	addi	a0,a0,186 # 80008900 <syscalls+0x3c0>
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	cf0080e7          	jalr	-784(ra) # 8000053e <panic>

0000000080006856 <cas>:
    80006856:	100522af          	lr.w	t0,(a0)
    8000685a:	00b29563          	bne	t0,a1,80006864 <fail>
    8000685e:	18c5252f          	sc.w	a0,a2,(a0)
    80006862:	8082                	ret

0000000080006864 <fail>:
    80006864:	4505                	li	a0,1
    80006866:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
