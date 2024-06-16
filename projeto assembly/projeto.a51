;Nota: Timer 0 - modo 1(16bits)
;		1 contagem = 1 microseg, 10000 contagens = 10000 microseg = 10 ms
;		65536 - 10000 = 55536(D8F0H)

;R0-> contador para centesimas de segundo(0.01s)
;R1-> contador para decimas de segundo(0.1s)
;R2-> segundos(1s)
;R3->0(Modo escolhe pergunta)/1(modo mostra pergunta)
;R4->Resposta
;R5->0(Mostra segundos restantes)/1(mostra resposta)
;R6->Contar 1 segundo para o modo mostra pergunta

;Defini��o de constantes 
TempoH0			EQU 0xD8	;65536 - 10000 = 55536(D8F0H)
TempoL0			EQU 0xF0
contaMsegundos	EQU 0x0A	;Numero de contagens de 10 ms para contar 0,1s (10 contagens)
maximoSegundos	EQU 0X05	;N�mero m�ximo de segundos a serem contados (5 segundos)

displayD1		EQU	P1
displayD2		EQU P2

BA 				EQU P3.4
BB 				EQU P3.5
BC 				EQU P3.6
BD 				EQU P3.7
	
tracoponto			EQU 0x3F ; -.
	

CSEG AT 0300H
segmentosD1:			DB	0x12, 0x19, 0x30, 0x24, 0x79, 0x40  						; 5., 4., 3., 2., 1., 0.

CSEG AT 0310H
segmentosD2Segundos:  	DB 	0xC0, 0x90, 0x80, 0xF8, 0x82, 0x92, 0x99, 0xB0, 0xA4, 0xF9   ; 0, 9, 8, 7, 6, 5, 4, 3, 2, 1

CSEG AT 0320H
segmentosD2Opcao:  		DB 0x88, 0x83, 0xC6, 0xA1, 0xBF									; A, b, C, d, -

	
CSEG AT 0000H
	JMP Inicio
	
;interrupcao externa 0(P3.2 -> B1)
CSEG AT 0003H
	JMP InterrupcaoExt0
	
;interrupcao timer 0 (de 0,01s a 0,01s)
CSEG AT 000BH
	JMP InterrupcaoTemp0
	
;interrupcao externa 0(P3.3 -> BA & BB & BC & BD)	
CSEG AT 0013H
	JMP InterrupcaoExt1

CSEG AT 0050H
Inicio: 
	CALL inicializacoes					;chama a rotina de inicializacoes
	CALL atualizadisplay1				;mostra inicialmente no display1 o valor 5.
	CALL atualizadisplay2				;mostra inicialmente no display2 o valor 0
	CALL ativaInterrupcoes				;rotina para configurar as interrupcoes Ext0 e Timer0
	CALL configuraTemporizador			;rotina para ativar o temporarizador

;Programa principal
cicloTemporarizador: 
	CJNE R3, #0, cicloMostraResposta	;caso R3 seja diferente de 0 ir� para o modo de mostrar resposta
	CALL atualizadisplay1				;atualiza o display1 consoante o tempo decorrido
	CALL atualizadisplay2				;atualiza o display2 consoante o tempo decorrido
	JMP cicloTemporarizador

cicloMostraResposta:
	CJNE R3, #1, Inicio					;caso R3 seja diferente de 1 quer dizer que B1 foi pressionada e � para voltar ao in�cio
	CJNE R5, #0, mostraRespostaDisplay	;caso R5 seja diferente de 0 salta para o mostraRespostaDisplay
	CALL atualizadisplay1				;mostra no display1 os segundos que faltavam at� chegar a 0
	CALL atualizadisplay2				;mostra no display2 os mil�simos de segundo que faltavam at� chegar a 0
	JMP	cicloMostraResposta	
mostraRespostaDisplay:
	CALL respostadisplay1				;mostra no display1 um -.
	CALL respostadisplay2				;mostra no display2 a op��o que o utilizador escolheu
	JMP cicloMostraResposta

;rotina inicializacoes
inicializacoes:
	MOV R0, #0							;contador das centesimas de segundo = 0
	MOV R1, #0							;contador das decimas de segundo = 0
	MOV R2, #0							;contador dos segundos = 0
	MOV R3, #0							;modo => 0(escolhe pergunta)
	MOV R4, #0							;op��o => 0
	MOV R5, #0							;mostra resposta/ pergunta =>0
	MOV R6, #0							;contador dos segundos para o modo de ver a resposta = 0
	RET
	
;rotina ativaInterrupcoes
ativaInterrupcoes:
	MOV IE, #10000011b					;EA=1, ET1=0, EX1=0, ET0=1 e EX0=1 -> IE=10000011
	RET


configuraTemporizador:
	MOV TMOD, #0x01
	MOV TL0, #TempoL0	 				;valor do byte menos significativo
	MOV TH0, #TempoH0					;valor do byte mais significativo	
	CLR TR0      						;garante que o Timer 0 esteja desligado inicialmente
	SETB IT0     						;gonfigura a interrup��o externa 0 para ser ativada na descida (falling edge)
	RET          						;retorna da sub-rotina

atualizadisplay1:
	MOV DPTR, #segmentosD1				;move para o dptr o endere�o da tabela dos segmentosD1
	MOV A, R2							;move o conte�do R2 para o A. R2 cont�m o �ndice dos segundos do segmento a ser exibido
	MOVC A, @A+DPTR						;usa o conte�do de A como um �ndice para acder � tabela de segmentos. MOVC l� um byte da mem�ria de programa no endere�o (DPTR + A) e move para o acumulador
	MOV displayD1, A					;move o valor do acumulador para displayD1, atualizando o display 1
	RET

atualizadisplay2:
	MOV DPTR, #segmentosD2Segundos		;guarda no dptr o endere�o da tabela dos segmentosD2 para os segundos
	MOV A, R1							;move o conte�do R1 para o A. R1 cont�m o �ndice dos mil�simos de segundo do segmento a ser exibido
	MOVC A, @A+DPTR						;usa o conte�do de A como um �ndice para acder � tabela de segmentos. MOVC l� um byte da mem�ria de programa no endere�o (DPTR + A) e move para o acumulador.
	MOV displayD2, A					;move o valor do acumulador para displayD2, atualizando o display 2	
	RET	
			
respostadisplay1:
	MOV A, #tracoponto					;move o valor constante 'tracoponto' para o acumulador (A)
	MOV displayD1, A					;move o valor do acumulador para displayD1, atualizando o display 1
	RET

respostadisplay2:
	MOV DPTR, #segmentosD2Opcao			;guarda no dptr o endere�o da tabela dos segmentosD2 para as op��es
	MOV A, R4							;move o conte�do R4 para o A. R4 cont�m o �ndice da op��o do segmento a ser exibido
	MOVC A, @A+DPTR						;usa o conte�do de A como um �ndice para acder � tabela de segmentos. MOVC l� um byte da mem�ria de programa no endere�o (DPTR + A) e move para o acumulador
	MOV displayD2, A					;move o valor do acumulador para displayD2, atualizando o display 2
	RET
	
InterrupcaoExt0:
	SETB TR0							;timer 0 come�a a contar o tempo
	CLR EX0								;desativa interrupcao externa 0
	SETB EX1							;ativa interrupcao externa 1
	MOV R0, #0							;reseta o contador dos microsegundos 
	MOV R3, #0							;reseta o valor do modo pra zero(modo de escolha da pergunta onde decrece os 5 segundos)
	RETI
	
InterrupcaoExt1:
	MOV R0, #0							;reset do contador dos 0,01s
	MOV R3, #1							;Mete o registo 3 a 1(modo onde mostra a ressposta do utilizador)
	SETB EX0							;ativa interrupcao externa 0
	CLR EX1								;desativa a interrup��o externa 1
	JB BA, verificaB					;verifica se o Bot�o BA n�o est� pressionado, se n�o estiver salta para verificaB
	MOV R4, #0 							;caso a op��o escolhida seja A guarda o valor 0 em R4 para incrementar depois no indice da tabela de segmento
	JMP fimExt1							;sai da interrup��o
verificaB:
	JB BB, verificaC					;verifica se o Bot�o BB n�o est� pressionado, se n�o estiver salta para verificaC
	MOV R4, #1 							;caso a op��o escolhida seja B guarda o valor 1 em R4 para incrementar depois no indice da tabela de segmento
	JMP fimExt1							;sai da interrup��o
verificaC:
	JB BC, verificaD					;verifica se o Bot�o BC n�o est� pressionado, se n�o estiver salta para verificaD
	MOV R4, #2 							;caso a op��o escolhida seja C guarda o valor 2 em R4 para incrementar depois no indice da tabela de segmento
	JMP fimExt1							;sai da interrup��o
verificaD:
	MOV R4, #3 							;caso a op��o escolhida seja D guarda o valor 3 em R4 para incrementar depois no indice da tabela de segmento
fimExt1:
	RETI

InterrupcaoTemp0:
	CLR IE0								;limpa flag se P3.2 foi pressionado (ruido botao)
	MOV TL0, #TempoL0					;TL0=0xF0
	MOV TH0, #TempoH0					;TH0=0xD8
	INC R0 								;incrementa o contador das centesimas de segundo
	CJNE R0, #contaMsegundos, fimI		;caso o valor das centesimas de segundo seja igual a 10 temos que incrementar o contador das decimas de segundo se n�o acaba e salta da interrup��o
	CJNE R3, #0, tempoResposta			;caso o valor do modo seja diferente de 0 queremos que o contador conte de 1 em segundo
verificaMsegundo:
	INC R1								;incrementa o valor das decimas de segundo
	MOV R0, #0							;reseta o valor das centesimas de segundo
	CJNE R1, #1, verificaResetSeg		;caso aumente uma decima de segundo e � igual 1 (5.0 -> 4.9) o contador dos segundos tem de incrementar, 
	INC R2								;incrementa o valor das decimas de segundo
verificaResetSeg:
	CJNE R1, #contaMsegundos, fimI		;verica se o contador das decimas de segundo chegou a 10 para voltar ao in�cio se n�o s�i da exce��o
	MOV R1, #0							;reseta o valor das decimas de segundo
	CJNE R2, #maximoSegundos, fimI		;caso ja tenho chegado aos 0 segundos
	MOV R3, #1							;r3 fica com o valor 1 para mostrar a resposta
	MOV R4, #4							;r4 fica com o valor 4 para mostrar em vez de op��o um tra�o -
	SETB EX0							;ativa interrupcao externa 0
	CLR EX1								;desativa interrupcao externa 1
	JMP fimI
	
tempoResposta:
	INC R6								;incrementa o valor do contador das decimas de segundo
	MOV R0, #0							;reseta o valor do contador de centesimas
	CJNE R6, #contaMsegundos, fimI		;caso o valor do contador das decimas de segundo seja igual a 10 incrementa um segundo se n�o acaba a interrup��o
	MOV R6, #0							;reseta o valor do contador das decimas de segundo
	CJNE R5, #1, mudaPara1				;caso o valor de r5 n�o seja igual a 1 salta
	MOV R5, #0							;muda o valor de r5 para 0(mostrar segundos restantes)
	JMP fimI
mudaPara1:
	MOV R5, #1							;muda o valor de r5 para 1(mostrar op��o)
	
fimI:
	RETI
	
END