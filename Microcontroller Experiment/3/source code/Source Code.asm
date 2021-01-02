;File name: Timer.asm
;Description: 完成了任务三当中的功能
;Designed by:  Ma Xiaotian
;Date:2020-5-30
;--------------------------------------------------------------
$include (C8051F310.inc)
;D9 BEEP KINT
LED		BIT P0.0	;D9黄灯, 低电平有效
BEEP	BIT P3.1	;蜂鸣器, 高电平有效
KINT	BIT P0.1	;独立按键, 按下为低电平
;LED指示灯阵列
DAT_IN	BIT P3.3
CLK		BIT P3.4

		ORG 0000H
		LJMP HERE

		ORG 000BH
		LJMP TIMER0		;TIMER0	1s的授时

		ORG 0013H
		LJMP DETECT		;/INT1 检测KINT键			

		ORG 001BH
		LJMP TIMER1		;TIMER1	检测按键的下按  单次循环约10ms 设置高优先级						

		ORG 0100H
;--------------------------------------------------------------		
		;初始化C8051F310，SYSCLK=24.5/4=6.125MHz（内部晶振） 
		;关WDT
		;推挽、开漏设定
		
		;T1,16bits Timer, TCLK=SYSCLK/4, TH1=88H,TL1=05FH
		;T1一个周期近似为20ms，为按键消抖以及长短按授时
		;T0,16bits Timer, TCLK=SYSCLK/4, TH0=10H, TL0=0DDH
		;T0为数码管提供1s的授时，精度约是每小时快8s（以手机内置定时器为金标
		;设备型号OnePlus 6，固件氢OS 10.0.4）
;--------------------------------------------------------------
//初始化																			    
HERE:   LCALL Init_Device
		;关闭D1-D8，关闭蜂鸣器
		CLR BEEP
		SETB DAT_IN
		MOV R1, #8
INIT:	CLR CLK
		SETB CLK
		DJNZ R1, INIT

		;资源使用说明
		;使用了片内晶振，并4分频作为系统时钟。1个外部中断，2个定时器
		;其余存储空间的使用情况如下 
		MOV SP, #50H
		MOV R7, #0		;R7 临时变量 SETTING部分使用
		MOV R6, #0		;R6	临时变量 DETECT部分使用
		MOV R5, #150	;R5 用于记录KINT是否长按
		MOV R4, #0		;R4	临时变量 显示部分共同使用
		MOV R3, #00H	;R3 分钟
		MOV R2, #00H	;R2 秒钟
		MOV R1, #0		;R1 临时变量
		MOV R0, #30H	;R0 指向30H-33H，显示缓冲区

		MOV 30H, #0			   
		MOV 31H, #0		;31H&30H分别为秒钟的十位、个位
		MOV 32H, #0		
		MOV 33H, #0		;33H&32H分别为分钟的十位、个位
		MOV 34H, #200	;用于控制用户设定时的位选闪烁
		MOV 35H, #25	;用于1s的定时
		MOV 36H, #0		;用于10ms的按键延时
		MOV 37H, #0		;用于存放用户设定的按键值		
		MOV 38H, #3		;用来指示设定位的位选，默认最先设定最高位
		MOV 39H, #0		;用来指示数字键按下状态
		MOV 3AH, #0
		MOV 3BH, #0		;用来存放时间的半值，3BH用来存分，3AH用来存秒
		MOV 3CH, #0		;临时变量
		MOV 3DH, #0		;普通闪烁临时变量		
		MOV 3EH, #1		;超时闪烁变量
		MOV 3FH, #31	;渐快闪烁变量
		MOV 40H, #31	;渐快闪烁变量
		CLR F0			;用户标志位F0，用于提示是(1)否(0)按下按键
		CLR F1			;用户标志位F1，用于提示长按(1)或短按(0)键
		CLR 20H.0		;暂存用户标志位F0，用于提示是否按下按键
		CLR 20H.1		;暂存用户标志位F1，用于提示长按或短按键
		CLR 20H.2		;提示是(1)否(0)进入超时模式
		CLR 20H.3		;提示是(1)否(0)进入渐快模式
		CLR 20H.4		;渐快模式的加速标志,2秒一周期
		CLR 20H.5		;渐快模式亮灭的控制位

		;F0为0时，没有按下；F0为1时且F1为0时，短按；F0为1时且F1为1时，长按
;--------------------------------------------------------------
//主程序块
MAIN:	LCALL SHOW  
		JNB F0, MAIN
		JBC F1, JUMP2	
		SJMP JUMP1


JUMP2:	MOV 38H, #3
		LCALL SETTING
		MOV 3FH, #31
		MOV 40H, #31
	//求取设定时间的一半，存入3BH,3AH中
		MOV A, 31H
		MOV B, #10
		MUL AB
		ADD A, 30H		;秒钟的10进制数
		MOV B, #2
		DIV AB			;商在A中，是十进制数
		MOV B, #10
		DIV AB			;十位在A中，个位在B中
		MOV 3AH, B
		MOV B, #16
		MUL AB			;结果在A中
		ADD A, 3AH
		MOV 3AH, A		;暂时算出的秒钟的结果以BCD形式存入了3AH中
		MOV A, 33H
		MOV B, #10
		MUL AB
		ADD A, 32H		;分钟的10进制数
		MOV B, #2
		DIV AB			;商在A中，余数在B中(十进制数)
		MOV 3CH, A
		MOV R1, B
		CJNE R1, #1, NEXT6	;整除
		MOV A, 3AH		;余1，则秒钟加30H
		ADD A, #30H
		MOV 3AH, A		;更新了3AH中的BCD码
NEXT6:	MOV B, #10
		MOV A, 3CH
		DIV AB			;十位在A中，个位在B中
		MOV 3BH, B
		MOV B, #16
		MUL AB			;结果在A中
		ADD A, 3BH
		MOV 3BH, A		;秒钟的结果以BCD码形式存入了3BH中
	//
		CLR 20H.2		;将超时计数标志位清零
		JBC F1, MAIN
		 
		  
JUMP1:	LCALL COUNT
		JNB 20H.2, HERE21	  ;最后的结束
		CJNE R3, #99H, HERE21
		CJNE R2, #59H, HERE21
		SJMP JUMP3
HERE21:	JNB F0, JUMP1
		JBC F1, JUMP1
		SJMP MAIN


JUMP3:	CLR TR0
		LCALL BYE
		JNB F0, JUMP3
		JBC F1, JUMP2
		SJMP JUMP3
;--------------------------------------------------------------	
//子程序块
SHOW:	;固定值显示模式
		MOV P1, #0
		CLR F0
		MOV A, R0
		ANL A, #0FH
		SWAP A
		RL A
		RL A
		MOV R1, A
		MOV A, P0
		ANL A, #3FH
		ORL A, R1		 
		MOV P0, A		;位选传送，显示
		MOV A, @R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;选择相应的数字
		MOV P1, A		;段选传送
		LCALL D05MS

		INC R0
		MOV A, R0
		CJNE A, #34H, SHOW
		MOV P1, #0
		MOV R0, #30H
		MOV R4, #6		;再延时3ms，凑够一个周期5ms
LOOP1:	LCALL D05MS	
		DJNZ R4, LOOP1
		JNB F0, EOC3	;禁止从0000开始
		CJNE R3, #0, EOC3
		CJNE R2, #0, EOC3
		JB F1, EOC3
		CLR F0
EOC3:
	RET




SETTING:;显示+闪烁位选设定
		;显示
		CLR F0
STA1:	MOV P1, #0
		MOV A, R0
		ANL A, #0FH
		SWAP A
		RL A
		RL A
		MOV R1, A
		MOV A, P0
		ANL A, #3FH
		ORL A, R1		 
		MOV P0, A		;位选传送，显示
		MOV A, R0
		ANL A, #0FH
		CJNE A, 38H, HERE15	  ;无需闪烁的位则跳过下面的语句块
		DEC 34H
		MOV A, 34H
		CLR C
		SUBB A, #100
		JC HERE15 
		MOV P1, #0			  ;闪烁
  		CJNE A, #9CH, HERE16
		MOV 34H, #200
		AJMP HERE16

HERE15:	MOV A, @R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;选择相应的数字
		MOV P1, A		;段选传送

HERE16:	
		LCALL D05MS
		INC R0
		MOV A, R0
		CJNE A, #34H, STA1
		MOV P1, #0
 		MOV R0, #30H
		MOV R4, #6		;再延时3ms，凑够一个周期5ms
LOOP2:	
		LCALL D05MS
		DJNZ R4, LOOP2

		;按键检测部分
		MOV A, 39H
		JNZ RELAY1		;如果39H=1（按下），就不再进行数字键值检测，防串键
		ANL P2, #0F0H	;行线同时输出低电平
		MOV A, P2
		CJNE A, #0F0H, TEST1;如果KI出现了低电平，则说明可能有按键按下
		JB F1, RELAY3
		SJMP STA1	;否则都为高电平，则说明没有按键按下，返回开头
TEST1:	//LCALL D10MS
		LCALL SHOW
		LCALL SHOW
		MOV A, P2
		CJNE A, #0F0H, NEXT1	;KI仍出现低电平，则说明确实有按键按下
		SJMP STA1	;否则都为高电平，则说明误触，再次返回开头 
NEXT1:	
		JNB P2.4, COLUMN0
		JNB P2.5, COLUMN1
		JNB P2.6, COLUMN2
		JNB P2.7, COLUMN3
COLUMN0:
		ORL P2, #0FH
		CLR P2.0
		JNB P2.4, K0
		SETB P2.0
		CLR P2.1
		JNB P2.4, K1
		SETB P2.1
		CLR P2.2
		JNB P2.4, K2
		SETB P2.2
		CLR P2.3
		JNB P2.4, K3
RELAY1:	AJMP HERE9		;接续跳转		
COLUMN1:
		ORL P2, #0FH
		CLR P2.0
		JNB P2.5, K4
		SETB P2.0
		CLR P2.1
		JNB P2.5, K5
		SETB P2.1
		CLR P2.2
		JNB P2.5, K6
		SETB P2.2
		CLR P2.3
		JNB P2.5, K7
RELAY3:	AJMP HERE11
COLUMN2:
		ORL P2, #0FH
		CLR P2.0
		JNB P2.6, K8
		SETB P2.0
		CLR P2.1
		JNB P2.6, K9
		SETB P2.1
		CLR P2.2
		JNB P2.6, KA
		SETB P2.2
		CLR P2.3
		JNB P2.6, KB
COLUMN3:
		ORL P2, #0FH
		CLR P2.0
		JNB P2.7, KC
		SETB P2.0
		CLR P2.1
		JNB P2.7, KD
		SETB P2.1
		CLR P2.2
		JNB P2.7, KE
		SETB P2.2
		CLR P2.3
		JNB P2.7, KF
K0:		MOV 37H, #0
		LJMP HERE8
K1:		MOV 37H, #1
		LJMP HERE8 
K2:		MOV 37H, #2
		LJMP HERE8
K3:		MOV 37H, #3
		LJMP HERE8
K4:		MOV 37H, #4
		LJMP HERE8
K5:		MOV 37H, #5
		LJMP HERE8
K6:		MOV 37H, #6
		LJMP HERE8
K7:		MOV 37H, #7
		LJMP HERE8
K8:		MOV 37H, #8
		LJMP HERE8
K9:		MOV 37H, #9
		LJMP HERE8
KA:		MOV 37H, #0EH
		LJMP HERE9
KB:		MOV 37H, #0EH
		LJMP HERE9
KC:		MOV 37H, #0EH
		LJMP HERE9
KD:		MOV 37H, #0EH
		LJMP HERE9
KE:		MOV 37H, #0EH
		LJMP HERE9
KF:		MOV 37H, #0EH	;这里KA-KF没有合并写，为了未来添加功能时找入口方便
		LJMP HERE9		;统一设为0EH的输出，方便下面的判断
RELAY2:	AJMP STA1


HERE8:	MOV A, 38H
		CJNE A, #1, HERE12 	;控制当38H=1时，只有0-5有效，其余的均无效
		MOV A, 37H
		CJNE A, #5, HERE13
		SJMP HERE12			;5合法
HERE13:	JC HERE12			;0-4合法
		SJMP HERE9			;其余的不合法
HERE12:	MOV 39H, #1		;已按下有效的键，此时37H和39H都填入了相应的值
HERE9:	ANL P2, #0F0H	;行线同时输出低电平
		MOV A, P2
		CJNE A, #0F0H, RELAY2 ;当有按键按下时，为了保证显示，仍返回SETTING
		
		MOV 39H, #0		;恢复为未按下的状态
		MOV A, 37H		;ABCDEF的筛选
		CJNE A, #0EH, HERE14
		SJMP RELAY2 	;ABCDEF则回到开头，视作无效
HERE14:	MOV A, 38H		;当松开后，根据键入值修改相应位（3210）
		JZ ZERO
		CJNE A, #3, NEXT2
THREE:	MOV 33H, 37H	;37H写入33H中（分钟高位）
		MOV A, 37H
		SWAP A
		ANL 03H, #0FH
		ORL 03H, A		;37H写入R3高4位中
		SJMP HERE10
ZERO:	MOV 30H, 37H	;37H写入30H中（秒钟低位）
		MOV A, 37H
		ANL 02H, #0F0H
		ORL 02H, A 		;37H写入R2低4位中
		SJMP HERE10
NEXT2:	CJNE A, #2, ONE
TWO:	MOV 32H, 37H	;37H写入32H中（分钟低位）
		MOV A, 37H
		ANL 03H, #0F0H
		ORL 03H, A		;37H写入R3低4位中
		SJMP HERE10
ONE:	MOV 31H, 37H
		MOV A, 37H
		SWAP A
		ANL 02H, #0FH	;37H写入R2高4位中
		ORL 02H, A
HERE10:	DEC 38H
		MOV A, 38H
		CJNE A, #0FFH ,HERE11
		MOV 38H, #3		;等于0时要注意38H恢复为3,进行循环输入
HERE11:	JNB F0, RELAY2	;无效KINT将继续程序内循环，从而保证选位的连续
		JNB F1, RELAY2	;短按KINT将继续程序内循环		
	RET					;长按KINT则会跳出程序




COUNT:	;倒计时+超时计数
		SETB TR0
		JB 20H.2, TIMEOUT
		CJNE R3, #1, NEXT7
		CJNE R2, #0, NEXT7
		SETB BEEP			;一分钟的时侯响一下
NEXT7:	CJNE R3, #0, FLASH	;跳到普通闪烁
		SJMP ACCEL			;跳到渐快闪烁
TIMEOUT:MOV A, 3EH			;超时模式 
		CJNE A, #2, NEXT8
		MOV 3EH, #0
		CLR LED					
NEXT8:	CJNE R3, #0, DISP	
		CJNE R2, #1, DISP
		SETB BEEP			;超时1s响一下
		SJMP DISP
HALF:	MOV A, R3
		CJNE A, 3BH, ZER
		MOV A, R2
		CJNE A, 3AH, ZER
		SETB BEEP			;时间过半响一下
ZER:	CJNE R3, #0, DISP
		CJNE R2, #0, DISP
		SETB 20H.2			;到了00：00置位超时标志
		SETB BEEP			;响一下
		CLR LED				;亮一下
		SJMP DISP
FLASH:	MOV A, 3DH			;普通模式
		CJNE A, #3, NEXT9
		MOV 3DH, #0
		CLR LED		   			
NEXT9:	SJMP HALF
RELAY4:	SJMP COUNT			;上行接力
ACCEL:	MOV A, R2
		JZ HERE20
		SETB 20H.3			;渐快模式
		SJMP NEXT10
HERE20:	CLR 20H.3		
NEXT10:	SJMP HALF

;显示部分		
DISP:	MOV P1, #0
		CLR F0 
		MOV A, R0
		ANL A, #0FH
		SWAP A
		RL A
		RL A
		MOV R1, A
		MOV A, P0
		ANL A, #3FH
		ORL A, R1		 
		MOV P0, A		;位选传送，显示
		MOV A, @R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;选择相应的数字
		MOV P1, A		;段选传送

		LCALL D05MS
		SETB TR0

		MOV P1, #0
		INC R0
		MOV A, R0
		CJNE A, #34H, DISP
		MOV P1, #0
		MOV R0, #30H
		MOV R1, #6		;再延时3ms，凑够一个周期5ms
LOOP3:	LCALL D05MS
		SETB TR0	
		DJNZ R1, LOOP3
	RET




BYE:	;结束语
		MOV P1, #0
		MOV R2, #0
		MOV R3, #0
		MOV 30H, #0
		MOV 31H, #0
		MOV 32H, #0
		MOV 33H, #0
		SETB BEEP
		CLR LED
		CLR F0
		MOV A, R0
		ANL A, #0FH
		SWAP A
		RL A
		RL A
		MOV R1, A
		MOV A, P0
		ANL A, #3FH
		ORL A, R1		 
		MOV P0, A		;位选传送，显示
		MOV A, R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;选择相应的数字
		MOV P1, A		;段选传送
		LCALL D05MS

		INC R0
		MOV A, R0
		CJNE A, #34H, BYE
		MOV P1, #0
		MOV R0, #30H
		MOV R4, #6		;再延时3ms，凑够一个周期5ms
LOOP15:	LCALL D05MS	
		DJNZ R4, LOOP15
		JB F1, EOC4
		CLR F0
EOC4:
	RET




;D10MS 10ms按键间隔
D10MS:	PUSH ACC
		MOV R7, #250
LOOP7:	DJNZ R7, LOOP8
		POP ACC
		RET
		

LOOP8:	MOV 36H, #60
LOOP6:	DJNZ 36H, LOOP6
			
	SJMP LOOP7




;D1MS 1ms间隔
D1MS:	PUSH ACC
		MOV R7, #25
LOOP13:	DJNZ R7, LOOP14
		POP ACC
		RET
		

LOOP14:	MOV 36H, #60
LOOP12:	DJNZ 36H, LOOP12
			
	SJMP LOOP13




;D05MS 0.5ms显示间隔
D05MS:	PUSH ACC
		MOV R7, #167
LOOP10:	DJNZ R7, LOOP11
		POP ACC
		RET
		

LOOP11:	MOV 36H, #3
LOOP9:	DJNZ 36H, LOOP9
			
	SJMP LOOP10



;--------------------------------------------------------------
//ISR 

;TIMER0 1s定时，需循环25次
TIMER0:
		CLR TR0	
		MOV TH0, #0FH
		MOV TL0, #0B5H
		JNB 20H.3, NEXT13 ;渐快模式涉及下面的语句块
		DEC 40H
		MOV A, 40H
		CJNE A, #1, JUDGE
		MOV 40H, 3FH		;重置为零
		CPL 20H.5			;亮灭切换
JUDGE:	JB 20H.5, NEXT11
		SETB LED			;20H.5=0，灯灭 
		SJMP NEXT13
NEXT11:	CLR LED				;20H.5=1，灯亮 
NEXT13:	MOV A, 35H
		DEC A
		MOV 35H, A 
		CJNE A, #0, HERE7	;这里是小循环		
		SETB TR0
		CPL 20H.4
		JNB 20H.2, NEXT12	
		INC 3EH				;超时模式
		CLR 20H.3			;清除20H.3的渐快模式的置位
		SJMP NEXT18
NEXT12:	JNB 20H.3, NEXT17
		JNB 20H.4, NEXT14
		DEC 3FH
		SJMP NEXT14
NEXT17:	INC 3DH				;普通模式
NEXT18:	SETB LED			;关LED
NEXT14:	MOV P1, #0
		CLR BEEP
NEXT16:	MOV 35H, #25
NEXT15:	JB 20H.2, HERE17	;20H.2置位时进入超时计数模式
		CJNE R2, #0, HERE6	;倒计时模式
		MOV R2, #59H
		MOV A, R3
		ADD A, #99H
		DA A
		MOV R3, A
		SJMP HERE5
HERE6:	MOV A, R2
		ADD A, #99H
		DA A
		MOV R2, A
HERE5:	MOV A, R2		;对30H-33H进行更改
		ANL A, #0FH
		MOV 30H, A
		MOV A, R2
		ANL A, #0F0H
		SWAP A
		MOV 31H, A
		MOV A, R3
		ANL A, #0FH
		MOV 32H, A
		MOV A, R3
		ANL A, #0F0H
		SWAP A
		MOV 33H, A
		SJMP HERE7
HERE17:	CJNE R2, #59H, HERE19
		MOV R2, #00H
		MOV A, R3
		ADD A, #01H
		DA A
		MOV R3, A
		SJMP HERE18
HERE19:	MOV A, R2
		ADD A, #01H
		DA A
		MOV R2, A
HERE18:	SJMP HERE5
HERE7:
	RETI
	
  		



;TIMER1 消抖、长按授时
TIMER1:	
		CLR TR1
		JB 20H.0, HERE1	;已经按下，20H.0=1，就跳到HERE1
		CJNE R5, #150, HERE3	;这行指令是为了重装R5的值到150
HERE4:	JB KINT, HERE1 	;假按，第一次时间短于10ms，不置20H.0为1
		SETB 20H.0		;20H.0=1 	
HERE1:	MOV TH1, #0C4H
		MOV TL1, #030H
		JB KINT, EOCO	
		DJNZ R5, EOCD	;按下，暂记为短按，置20H.0为1
		SJMP EOCC
HERE3:	MOV R5, #150
		SJMP HERE4		;重装完再跳回正常执行
EOCD:	SETB 20H.0
		SJMP EOCR
EOCC:	SETB 20H.1
		SJMP EOCR
EOCO:	MOV C, 20H.0	;统一输出
		JNC NEXT19
		SETB BEEP
		LCALL D05MS
		CLR BEEP
NEXT19:	MOV F0, C
		MOV C, 20H.1
		JNC NEXT20
		CLR LED
		SETB BEEP
		LCALL D1MS
		SETB LED
		CLR BEEP
NEXT20:	MOV F1, C
		CLR C			;清理缓存
		CLR 20H.0
		CLR 20H.1
EOCR:	ANL P0, #0FFH	;通过读-改-写刷新一下
		SETB EX1
	RETI
	



;DETECT 相应KINT键
DETECT:	
		CLR EX1			;关掉外部中断1使能，防止多次进入对显示的干扰
		SETB TR1		;TIMER1开始计时，支持按键去抖和长短按识别等功能
		SETB KINT		;置1
	RETI

 

;---------定义段码表---------------------------------------						
		ORG 0700H
LUT1:	DB 0FCH, 60H, 0DAH, 0F2H	;0-3
		DB 66H, 0B6H, 0BEH, 0E0H	;4-7
		DB 0FEH, 0F6H				;8,9

		ORG 0730H
LUT2:	DB 01H, 7AH, 2AH, 9EH		;End.
		
; Peripheral specific initialization functions,
; Called from the Init_Device label
;------------------------------------
;-  Generated Initialization File  --
;------------------------------------
PCA_Init:
    anl  PCA0MD,    #0BFh
    mov  PCA0MD,    #000h
    ret

Timer_Init:
    mov  TMOD,      #011h
    mov  CKCON,     #001h
    mov  TL0,       #0B4h
    mov  TL1,       #0F7h
    mov  TH0,       #00Fh
    mov  TH1,       #0C2h
    mov  TMR2RLL,   #0F0h
    mov  TMR2L,     #0F0h
    mov  TMR3RLH,   #0DCh
    mov  TMR3H,     #0DCh
    ret

Port_IO_Init:
    ; P0.0  -  Unassigned,  Push-Pull,  Digital
    ; P0.1  -  Unassigned,  Open-Drain, Digital
    ; P0.2  -  Skipped,     Push-Pull,  Analog
    ; P0.3  -  Skipped,     Push-Pull,  Analog
    ; P0.4  -  Unassigned,  Open-Drain, Digital
    ; P0.5  -  Unassigned,  Open-Drain, Digital
    ; P0.6  -  Unassigned,  Push-Pull,  Digital
    ; P0.7  -  Unassigned,  Push-Pull,  Digital

    ; P1.0  -  Unassigned,  Push-Pull,  Digital
    ; P1.1  -  Unassigned,  Push-Pull,  Digital
    ; P1.2  -  Unassigned,  Push-Pull,  Digital
    ; P1.3  -  Unassigned,  Push-Pull,  Digital
    ; P1.4  -  Unassigned,  Push-Pull,  Digital
    ; P1.5  -  Unassigned,  Push-Pull,  Digital
    ; P1.6  -  Unassigned,  Push-Pull,  Digital
    ; P1.7  -  Unassigned,  Push-Pull,  Digital
    ; P2.0  -  Unassigned,  Push-Pull,  Digital
    ; P2.1  -  Unassigned,  Push-Pull,  Digital
    ; P2.2  -  Unassigned,  Push-Pull,  Digital
    ; P2.3  -  Unassigned,  Push-Pull,  Digital

    mov  P0MDIN,    #0F3h
    mov  P0MDOUT,   #0CDh
    mov  P1MDOUT,   #0FFh
    mov  P2MDOUT,   #00Fh
    mov  P3MDOUT,   #002h
    mov  P0SKIP,    #00Ch
    mov  XBR1,      #040h
    ret

Oscillator_Init:
    mov  OSCICN,    #081h
    ret

Interrupts_Init:
    mov  IP,        #02Eh
    mov  IT01CF,    #014h
    mov  IE,        #0AEh
    ret

; Initialization function for device,
; Call Init_Device from your main program
Init_Device:
    lcall PCA_Init
    lcall Timer_Init
    lcall Port_IO_Init
    lcall Oscillator_Init
    lcall Interrupts_Init
    ret

end