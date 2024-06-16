#include <reg51.h>

// Constantes
#define maxContams 10
#define maxSegundos 5

#define A 0
#define B 1
#define C 2
#define D 3	

// 65536 - 10000 = 55536 -> D8F0
//interrup��o de 0.01 em 0.01 ssegundos
#define TempH 0xD8
#define TempL 0xF0

// Pinos dos bot�es
sbit BA = P3^4;
sbit BB = P3^5;
sbit BC = P3^6;
sbit BD = P3^7;

// Pinos dos displays de 7 segmentos
sbit segA1 = P1^0;
sbit segB1 = P1^1;
sbit segC1 = P1^2;
sbit segD1 = P1^3;
sbit segE1 = P1^4;
sbit segF1 = P1^5;
sbit segG1 = P1^6;
sbit segDP1 = P1^7;

sbit segA2 = P2^0;
sbit segB2 = P2^1;
sbit segC2 = P2^2;
sbit segD2 = P2^3;
sbit segE2 = P2^4;
sbit segF2 = P2^5;
sbit segG2 = P2^6;
sbit segDP2 = P2^7;

// Estados do sistema
bit estado = 0;
bit estadoOp = 0;

// Vari�veis globais
unsigned char contaCS = 0;		//conta centesimas de segundo
unsigned char contaDS = 0;		//conta decimas de segundo
unsigned char contaDSop = 0;	//conta decimas de segundo no modo para mostrar resposta
unsigned char contaS = 0;			//conta segundoS
unsigned char resposta = 4;  	// Inicialmente � o tra�o '-'

// Segmentos dos displays


void Init(void) {
	
	estado = 0;
	estadoOp = 0;
	
	contaDS = 0;
	contaCS = 0;
	contaDSop = 0;
	contaS = 0;
	resposta = 4;

	// Configura��o do Registo IE
	EA = 1; // ativa interrup��es globais
	ET0 = 1; // ativa interrup��o Timer 0
	EX0 = 1; // ativa interrup��o externa 0
	EX1 = 0; // desativa interrup��o externa 1

	// Configura��o Registo TMOD
	TMOD = 0x01; // Timer 0 no modo 1 (16 bits)

	// Configura��o Timer 0
	TH0 = TempH;
	TL0 = TempL;

	// Configura��o Registo TCON
	TR0 = 0; // Timer 0 come�a desligado
	IT0 = 1; // Interrup��o externa 0 ativa no falling edge
}

void Externall0_ISR(void) interrupt 0 {
	TR0 = 1;			// Inicia o Timer 0
	EX0 = 0;			// Desativa interrup��o externa 0
	EX1 = 1;			// Ativa interrup��o externa 
	estado = 0;
	contaCS = 0;
}

void Timer0_ISR(void) interrupt 1 {

	IE0 = 0; // Limpa flag se P3.2 foi pressionado (ruido botao)

	TH0 = TempH;
	TL0 = TempL;

	contaCS++;												//incrementa o contar de centesimas de segundo
	if (contaCS == maxContams) {			//contador centesimas de segundo = 10
		contaCS = 0;										//centesimas de segundo = 0									
		if (estado == 0) {							//caso o estado = 0(Modo escolhe pergunta)
			contaDS++;										//incrementa o contador de decimas de segundo
			if (contaDS == 1){						//caso aumente uma decima de segundo e � igual 1 (5.0 -> 4.9) o contador dos segundos tem de incrementar
				contaS++;										//incrementa o contador de segundos
			}
			if(contaDS == maxContams){		//caso o contador das decimas de segundo cheguem ao m�ximo -> 10
				contaDS = 0;								//o contador de decimas de segundo vai resetar
				if(contaS == maxSegundos){	//caso chegue aos 5 segundos e decimas de segundo a 10 ou seja 0.0
					estado = ~estado;					//o estado ir� passar de 0 para 1
					EX0 = 1;									//a interrup��o externa 0 ir� ser ativada porque chegou ao final
					EX1 = 0;									//desabilita a interrup��o externa 1 porque n�o pode escolher nenhuma op��o
				}
			}
		}
		else{														//caso o estado = 1(modo mostra pergunta)
			contaDSop++;									//incrementa o contador de decimas de segundo para o modo de mostrar a op��o
			if(contaDSop == maxContams){	//caso chegue a 10, ou seja, passe 1 segundo
				contaDSop = 0;							//contador de decimas de segundo = 0
				estadoOp = ~estadoOp;				//o estado de op muda para o inverso
			}
		}
	}
}

void Externall1_ISR(void) interrupt 2 {
	contaCS = 0;
	estado = 1;
	EX1 = 0; // desativa interrup��o externa 1
	EX0 = 1; // Ativa interrup��o externa 0

	if (BA == 0) resposta = A; // Bot�o A pressionado
	else if (BB == 0) resposta = B; // Bot�o B pressionado
	else if (BC == 0) resposta = C; // Bot�o C pressionado
	else if (BD == 0) resposta = D; // Bot�o D pressionado
	
}

void atualizaDisplay1(unsigned char valor) {
	code unsigned segments[6][8] = {
		{0,1,0,0,1,0,0,0},	//5.
		{1,0,0,1,1,0,0,0},	//4.
		{0,0,0,0,1,1,0,0},	//3.
		{0,0,1,0,0,1,0,0},	//2.
		{1,0,0,1,1,1,1,0},	//1.
		{0,0,0,0,0,0,1,0},	//0.
	};
	segA1 = segments[valor][0];
	segB1 = segments[valor][1];
	segC1 = segments[valor][2];
	segD1 = segments[valor][3];
	segE1 = segments[valor][4];
	segF1 = segments[valor][5];
	segG1 = segments[valor][6];
	segDP1 = segments[valor][7];	
}

void atualizaDisplay2(unsigned char valor) {
    code unsigned segments[10][8] = {
		{0,0,0,0,0,0,1,1},	//0
		{0,0,0,0,1,0,0,1},	//9
		{0,0,0,0,0,0,0,1},	//8
		{0,0,0,1,1,1,1,1},	//7
		{0,1,0,0,0,0,0,1},	//6
		{0,1,0,0,1,0,0,1},	//5
		{1,0,0,1,1,0,0,1},	//4
		{0,0,0,0,1,1,0,1},	//3
		{0,0,1,0,0,1,0,1},	//2
		{1,0,0,1,1,1,1,1},	//1
	};
	
	segA2 = segments[valor][0];
	segB2 = segments[valor][1];
	segC2 = segments[valor][2];
	segD2 = segments[valor][3];
	segE2 = segments[valor][4];
	segF2 = segments[valor][5];
	segG2 = segments[valor][6];
	segDP2 = segments[valor][7];
}

void displayResposta(unsigned char valor) {
	code unsigned segments[6][8] = {
		{0,0,0,1,0,0,0,1},	//A
		{1,1,0,0,0,0,0,1},	//B
		{0,1,1,0,0,0,1,1},	//C
		{1,0,0,0,0,1,0,1},	//D
		{1,1,1,1,1,1,0,1},	//-
		{1,1,1,1,1,1,0,0},	//-.
	};
	segA1 = segments[5][0];
	segB1 = segments[5][1];
	segC1 = segments[5][2];
	segD1 = segments[5][3];
	segE1 = segments[5][4];
	segF1 = segments[5][5];
	segG1 = segments[5][6];
	segDP1 = segments[5][7];	
	
	segA2 = segments[valor][0];
	segB2 = segments[valor][1];
	segC2 = segments[valor][2];
	segD2 = segments[valor][3];
	segE2 = segments[valor][4];
	segF2 = segments[valor][5];
	segG2 = segments[valor][6];
	segDP2 = segments[valor][7];
}

void main(void) {
	
	while (1) {
		Init();
		atualizaDisplay1(contaS);						//inicio comecar a 5.0
		atualizaDisplay2(contaDS);
		while (estado==0){									//estado->0(Modo escolhe pergunta)/1(modo mostra pergunta)
			atualizaDisplay1(contaS);					//atualiza ao longo da execu��o o tempo
			atualizaDisplay2(contaDS);
		}
		while (estado==1){
			if(estadoOp==0){									//estadoOp->0(Mostra segundos restantes)/1(mostra resposta)
				atualizaDisplay1(contaS);				//atualiza os displays com o tempo guardo anteriormente
				atualizaDisplay2(contaDS);
			}
			else{
				displayResposta(resposta);			//mostra a resposta
			}
		}
	}
}
