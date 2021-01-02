;File name: Timer.asm
;Description: ��������������еĹ���
;Designed by:  Ma Xiaotian
;Date:2020-5-30
;--------------------------------------------------------------
$include (C8051F310.inc)
;D9 BEEP KINT
LED		BIT P0.0	;D9�Ƶ�, �͵�ƽ��Ч
BEEP	BIT P3.1	;������, �ߵ�ƽ��Ч
KINT	BIT P0.1	;��������, ����Ϊ�͵�ƽ
;LEDָʾ������
DAT_IN	BIT P3.3
CLK		BIT P3.4

		ORG 0000H
		LJMP HERE

		ORG 000BH
		LJMP TIMER0		;TIMER0	1s����ʱ

		ORG 0013H
		LJMP DETECT		;/INT1 ���KINT��			

		ORG 001BH
		LJMP TIMER1		;TIMER1	��ⰴ�����°�  ����ѭ��Լ10ms ���ø����ȼ�						

		ORG 0100H
;--------------------------------------------------------------		
		;��ʼ��C8051F310��SYSCLK=24.5/4=6.125MHz���ڲ����� 
		;��WDT
		;���졢��©�趨
		
		;T1,16bits Timer, TCLK=SYSCLK/4, TH1=88H,TL1=05FH
		;T1һ�����ڽ���Ϊ20ms��Ϊ���������Լ����̰���ʱ
		;T0,16bits Timer, TCLK=SYSCLK/4, TH0=10H, TL0=0DDH
		;T0Ϊ������ṩ1s����ʱ������Լ��ÿСʱ��8s�����ֻ����ö�ʱ��Ϊ���
		;�豸�ͺ�OnePlus 6���̼���OS 10.0.4��
;--------------------------------------------------------------
//��ʼ��																			    
HERE:   LCALL Init_Device
		;�ر�D1-D8���رշ�����
		CLR BEEP
		SETB DAT_IN
		MOV R1, #8
INIT:	CLR CLK
		SETB CLK
		DJNZ R1, INIT

		;��Դʹ��˵��
		;ʹ����Ƭ�ھ��񣬲�4��Ƶ��Ϊϵͳʱ�ӡ�1���ⲿ�жϣ�2����ʱ��
		;����洢�ռ��ʹ��������� 
		MOV SP, #50H
		MOV R7, #0		;R7 ��ʱ���� SETTING����ʹ��
		MOV R6, #0		;R6	��ʱ���� DETECT����ʹ��
		MOV R5, #150	;R5 ���ڼ�¼KINT�Ƿ񳤰�
		MOV R4, #0		;R4	��ʱ���� ��ʾ���ֹ�ͬʹ��
		MOV R3, #00H	;R3 ����
		MOV R2, #00H	;R2 ����
		MOV R1, #0		;R1 ��ʱ����
		MOV R0, #30H	;R0 ָ��30H-33H����ʾ������

		MOV 30H, #0			   
		MOV 31H, #0		;31H&30H�ֱ�Ϊ���ӵ�ʮλ����λ
		MOV 32H, #0		
		MOV 33H, #0		;33H&32H�ֱ�Ϊ���ӵ�ʮλ����λ
		MOV 34H, #200	;���ڿ����û��趨ʱ��λѡ��˸
		MOV 35H, #25	;����1s�Ķ�ʱ
		MOV 36H, #0		;����10ms�İ�����ʱ
		MOV 37H, #0		;���ڴ���û��趨�İ���ֵ		
		MOV 38H, #3		;����ָʾ�趨λ��λѡ��Ĭ�������趨���λ
		MOV 39H, #0		;����ָʾ���ּ�����״̬
		MOV 3AH, #0
		MOV 3BH, #0		;�������ʱ��İ�ֵ��3BH������֣�3AH��������
		MOV 3CH, #0		;��ʱ����
		MOV 3DH, #0		;��ͨ��˸��ʱ����		
		MOV 3EH, #1		;��ʱ��˸����
		MOV 3FH, #31	;������˸����
		MOV 40H, #31	;������˸����
		CLR F0			;�û���־λF0��������ʾ��(1)��(0)���°���
		CLR F1			;�û���־λF1��������ʾ����(1)��̰�(0)��
		CLR 20H.0		;�ݴ��û���־λF0��������ʾ�Ƿ��°���
		CLR 20H.1		;�ݴ��û���־λF1��������ʾ������̰���
		CLR 20H.2		;��ʾ��(1)��(0)���볬ʱģʽ
		CLR 20H.3		;��ʾ��(1)��(0)���뽥��ģʽ
		CLR 20H.4		;����ģʽ�ļ��ٱ�־,2��һ����
		CLR 20H.5		;����ģʽ����Ŀ���λ

		;F0Ϊ0ʱ��û�а��£�F0Ϊ1ʱ��F1Ϊ0ʱ���̰���F0Ϊ1ʱ��F1Ϊ1ʱ������
;--------------------------------------------------------------
//�������
MAIN:	LCALL SHOW  
		JNB F0, MAIN
		JBC F1, JUMP2	
		SJMP JUMP1


JUMP2:	MOV 38H, #3
		LCALL SETTING
		MOV 3FH, #31
		MOV 40H, #31
	//��ȡ�趨ʱ���һ�룬����3BH,3AH��
		MOV A, 31H
		MOV B, #10
		MUL AB
		ADD A, 30H		;���ӵ�10������
		MOV B, #2
		DIV AB			;����A�У���ʮ������
		MOV B, #10
		DIV AB			;ʮλ��A�У���λ��B��
		MOV 3AH, B
		MOV B, #16
		MUL AB			;�����A��
		ADD A, 3AH
		MOV 3AH, A		;��ʱ��������ӵĽ����BCD��ʽ������3AH��
		MOV A, 33H
		MOV B, #10
		MUL AB
		ADD A, 32H		;���ӵ�10������
		MOV B, #2
		DIV AB			;����A�У�������B��(ʮ������)
		MOV 3CH, A
		MOV R1, B
		CJNE R1, #1, NEXT6	;����
		MOV A, 3AH		;��1�������Ӽ�30H
		ADD A, #30H
		MOV 3AH, A		;������3AH�е�BCD��
NEXT6:	MOV B, #10
		MOV A, 3CH
		DIV AB			;ʮλ��A�У���λ��B��
		MOV 3BH, B
		MOV B, #16
		MUL AB			;�����A��
		ADD A, 3BH
		MOV 3BH, A		;���ӵĽ����BCD����ʽ������3BH��
	//
		CLR 20H.2		;����ʱ������־λ����
		JBC F1, MAIN
		 
		  
JUMP1:	LCALL COUNT
		JNB 20H.2, HERE21	  ;���Ľ���
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
//�ӳ����
SHOW:	;�̶�ֵ��ʾģʽ
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
		MOV P0, A		;λѡ���ͣ���ʾ
		MOV A, @R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;ѡ����Ӧ������
		MOV P1, A		;��ѡ����
		LCALL D05MS

		INC R0
		MOV A, R0
		CJNE A, #34H, SHOW
		MOV P1, #0
		MOV R0, #30H
		MOV R4, #6		;����ʱ3ms���չ�һ������5ms
LOOP1:	LCALL D05MS	
		DJNZ R4, LOOP1
		JNB F0, EOC3	;��ֹ��0000��ʼ
		CJNE R3, #0, EOC3
		CJNE R2, #0, EOC3
		JB F1, EOC3
		CLR F0
EOC3:
	RET




SETTING:;��ʾ+��˸λѡ�趨
		;��ʾ
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
		MOV P0, A		;λѡ���ͣ���ʾ
		MOV A, R0
		ANL A, #0FH
		CJNE A, 38H, HERE15	  ;������˸��λ���������������
		DEC 34H
		MOV A, 34H
		CLR C
		SUBB A, #100
		JC HERE15 
		MOV P1, #0			  ;��˸
  		CJNE A, #9CH, HERE16
		MOV 34H, #200
		AJMP HERE16

HERE15:	MOV A, @R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;ѡ����Ӧ������
		MOV P1, A		;��ѡ����

HERE16:	
		LCALL D05MS
		INC R0
		MOV A, R0
		CJNE A, #34H, STA1
		MOV P1, #0
 		MOV R0, #30H
		MOV R4, #6		;����ʱ3ms���չ�һ������5ms
LOOP2:	
		LCALL D05MS
		DJNZ R4, LOOP2

		;������ⲿ��
		MOV A, 39H
		JNZ RELAY1		;���39H=1�����£����Ͳ��ٽ������ּ�ֵ��⣬������
		ANL P2, #0F0H	;����ͬʱ����͵�ƽ
		MOV A, P2
		CJNE A, #0F0H, TEST1;���KI�����˵͵�ƽ����˵�������а�������
		JB F1, RELAY3
		SJMP STA1	;����Ϊ�ߵ�ƽ����˵��û�а������£����ؿ�ͷ
TEST1:	//LCALL D10MS
		LCALL SHOW
		LCALL SHOW
		MOV A, P2
		CJNE A, #0F0H, NEXT1	;KI�Գ��ֵ͵�ƽ����˵��ȷʵ�а�������
		SJMP STA1	;����Ϊ�ߵ�ƽ����˵���󴥣��ٴη��ؿ�ͷ 
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
RELAY1:	AJMP HERE9		;������ת		
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
KF:		MOV 37H, #0EH	;����KA-KFû�кϲ�д��Ϊ��δ����ӹ���ʱ����ڷ���
		LJMP HERE9		;ͳһ��Ϊ0EH�����������������ж�
RELAY2:	AJMP STA1


HERE8:	MOV A, 38H
		CJNE A, #1, HERE12 	;���Ƶ�38H=1ʱ��ֻ��0-5��Ч������ľ���Ч
		MOV A, 37H
		CJNE A, #5, HERE13
		SJMP HERE12			;5�Ϸ�
HERE13:	JC HERE12			;0-4�Ϸ�
		SJMP HERE9			;����Ĳ��Ϸ�
HERE12:	MOV 39H, #1		;�Ѱ�����Ч�ļ�����ʱ37H��39H����������Ӧ��ֵ
HERE9:	ANL P2, #0F0H	;����ͬʱ����͵�ƽ
		MOV A, P2
		CJNE A, #0F0H, RELAY2 ;���а�������ʱ��Ϊ�˱�֤��ʾ���Է���SETTING
		
		MOV 39H, #0		;�ָ�Ϊδ���µ�״̬
		MOV A, 37H		;ABCDEF��ɸѡ
		CJNE A, #0EH, HERE14
		SJMP RELAY2 	;ABCDEF��ص���ͷ��������Ч
HERE14:	MOV A, 38H		;���ɿ��󣬸��ݼ���ֵ�޸���Ӧλ��3210��
		JZ ZERO
		CJNE A, #3, NEXT2
THREE:	MOV 33H, 37H	;37Hд��33H�У����Ӹ�λ��
		MOV A, 37H
		SWAP A
		ANL 03H, #0FH
		ORL 03H, A		;37Hд��R3��4λ��
		SJMP HERE10
ZERO:	MOV 30H, 37H	;37Hд��30H�У����ӵ�λ��
		MOV A, 37H
		ANL 02H, #0F0H
		ORL 02H, A 		;37Hд��R2��4λ��
		SJMP HERE10
NEXT2:	CJNE A, #2, ONE
TWO:	MOV 32H, 37H	;37Hд��32H�У����ӵ�λ��
		MOV A, 37H
		ANL 03H, #0F0H
		ORL 03H, A		;37Hд��R3��4λ��
		SJMP HERE10
ONE:	MOV 31H, 37H
		MOV A, 37H
		SWAP A
		ANL 02H, #0FH	;37Hд��R2��4λ��
		ORL 02H, A
HERE10:	DEC 38H
		MOV A, 38H
		CJNE A, #0FFH ,HERE11
		MOV 38H, #3		;����0ʱҪע��38H�ָ�Ϊ3,����ѭ������
HERE11:	JNB F0, RELAY2	;��ЧKINT������������ѭ�����Ӷ���֤ѡλ������
		JNB F1, RELAY2	;�̰�KINT������������ѭ��		
	RET					;����KINT�����������




COUNT:	;����ʱ+��ʱ����
		SETB TR0
		JB 20H.2, TIMEOUT
		CJNE R3, #1, NEXT7
		CJNE R2, #0, NEXT7
		SETB BEEP			;һ���ӵ�ʱ����һ��
NEXT7:	CJNE R3, #0, FLASH	;������ͨ��˸
		SJMP ACCEL			;����������˸
TIMEOUT:MOV A, 3EH			;��ʱģʽ 
		CJNE A, #2, NEXT8
		MOV 3EH, #0
		CLR LED					
NEXT8:	CJNE R3, #0, DISP	
		CJNE R2, #1, DISP
		SETB BEEP			;��ʱ1s��һ��
		SJMP DISP
HALF:	MOV A, R3
		CJNE A, 3BH, ZER
		MOV A, R2
		CJNE A, 3AH, ZER
		SETB BEEP			;ʱ�������һ��
ZER:	CJNE R3, #0, DISP
		CJNE R2, #0, DISP
		SETB 20H.2			;����00��00��λ��ʱ��־
		SETB BEEP			;��һ��
		CLR LED				;��һ��
		SJMP DISP
FLASH:	MOV A, 3DH			;��ͨģʽ
		CJNE A, #3, NEXT9
		MOV 3DH, #0
		CLR LED		   			
NEXT9:	SJMP HALF
RELAY4:	SJMP COUNT			;���н���
ACCEL:	MOV A, R2
		JZ HERE20
		SETB 20H.3			;����ģʽ
		SJMP NEXT10
HERE20:	CLR 20H.3		
NEXT10:	SJMP HALF

;��ʾ����		
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
		MOV P0, A		;λѡ���ͣ���ʾ
		MOV A, @R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;ѡ����Ӧ������
		MOV P1, A		;��ѡ����

		LCALL D05MS
		SETB TR0

		MOV P1, #0
		INC R0
		MOV A, R0
		CJNE A, #34H, DISP
		MOV P1, #0
		MOV R0, #30H
		MOV R1, #6		;����ʱ3ms���չ�һ������5ms
LOOP3:	LCALL D05MS
		SETB TR0	
		DJNZ R1, LOOP3
	RET




BYE:	;������
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
		MOV P0, A		;λѡ���ͣ���ʾ
		MOV A, R0
		MOV DPTR, #0700H
		MOVC A, @A+DPTR	;ѡ����Ӧ������
		MOV P1, A		;��ѡ����
		LCALL D05MS

		INC R0
		MOV A, R0
		CJNE A, #34H, BYE
		MOV P1, #0
		MOV R0, #30H
		MOV R4, #6		;����ʱ3ms���չ�һ������5ms
LOOP15:	LCALL D05MS	
		DJNZ R4, LOOP15
		JB F1, EOC4
		CLR F0
EOC4:
	RET




;D10MS 10ms�������
D10MS:	PUSH ACC
		MOV R7, #250
LOOP7:	DJNZ R7, LOOP8
		POP ACC
		RET
		

LOOP8:	MOV 36H, #60
LOOP6:	DJNZ 36H, LOOP6
			
	SJMP LOOP7




;D1MS 1ms���
D1MS:	PUSH ACC
		MOV R7, #25
LOOP13:	DJNZ R7, LOOP14
		POP ACC
		RET
		

LOOP14:	MOV 36H, #60
LOOP12:	DJNZ 36H, LOOP12
			
	SJMP LOOP13




;D05MS 0.5ms��ʾ���
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

;TIMER0 1s��ʱ����ѭ��25��
TIMER0:
		CLR TR0	
		MOV TH0, #0FH
		MOV TL0, #0B5H
		JNB 20H.3, NEXT13 ;����ģʽ�漰���������
		DEC 40H
		MOV A, 40H
		CJNE A, #1, JUDGE
		MOV 40H, 3FH		;����Ϊ��
		CPL 20H.5			;�����л�
JUDGE:	JB 20H.5, NEXT11
		SETB LED			;20H.5=0������ 
		SJMP NEXT13
NEXT11:	CLR LED				;20H.5=1������ 
NEXT13:	MOV A, 35H
		DEC A
		MOV 35H, A 
		CJNE A, #0, HERE7	;������Сѭ��		
		SETB TR0
		CPL 20H.4
		JNB 20H.2, NEXT12	
		INC 3EH				;��ʱģʽ
		CLR 20H.3			;���20H.3�Ľ���ģʽ����λ
		SJMP NEXT18
NEXT12:	JNB 20H.3, NEXT17
		JNB 20H.4, NEXT14
		DEC 3FH
		SJMP NEXT14
NEXT17:	INC 3DH				;��ͨģʽ
NEXT18:	SETB LED			;��LED
NEXT14:	MOV P1, #0
		CLR BEEP
NEXT16:	MOV 35H, #25
NEXT15:	JB 20H.2, HERE17	;20H.2��λʱ���볬ʱ����ģʽ
		CJNE R2, #0, HERE6	;����ʱģʽ
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
HERE5:	MOV A, R2		;��30H-33H���и���
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
	
  		



;TIMER1 ������������ʱ
TIMER1:	
		CLR TR1
		JB 20H.0, HERE1	;�Ѿ����£�20H.0=1��������HERE1
		CJNE R5, #150, HERE3	;����ָ����Ϊ����װR5��ֵ��150
HERE4:	JB KINT, HERE1 	;�ٰ�����һ��ʱ�����10ms������20H.0Ϊ1
		SETB 20H.0		;20H.0=1 	
HERE1:	MOV TH1, #0C4H
		MOV TL1, #030H
		JB KINT, EOCO	
		DJNZ R5, EOCD	;���£��ݼ�Ϊ�̰�����20H.0Ϊ1
		SJMP EOCC
HERE3:	MOV R5, #150
		SJMP HERE4		;��װ������������ִ��
EOCD:	SETB 20H.0
		SJMP EOCR
EOCC:	SETB 20H.1
		SJMP EOCR
EOCO:	MOV C, 20H.0	;ͳһ���
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
		CLR C			;������
		CLR 20H.0
		CLR 20H.1
EOCR:	ANL P0, #0FFH	;ͨ����-��-дˢ��һ��
		SETB EX1
	RETI
	



;DETECT ��ӦKINT��
DETECT:	
		CLR EX1			;�ص��ⲿ�ж�1ʹ�ܣ���ֹ��ν������ʾ�ĸ���
		SETB TR1		;TIMER1��ʼ��ʱ��֧�ְ���ȥ���ͳ��̰�ʶ��ȹ���
		SETB KINT		;��1
	RETI

 

;---------��������---------------------------------------						
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