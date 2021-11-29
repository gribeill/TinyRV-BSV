#include "sequencer.h"
#include "QGL_output.h"

#define PULSE(NAME, QUBIT)  wfm_play(NAME ## _ ## QUBIT ## _ADDR , NAME ## _ ## QUBIT ## _ADDR, ret)

#define X(QUBIT)   PULSE(X, QUBIT)
#define X90(QUBIT) PULSE(X90, QUBIT)
#define Y(QUBIT)   PULSE(Y, QUBIT)
#define Y90(QUBIT) PULSE(Y90, QUBIT)
#define Z(QUBIT)   PULSE(Z, QUBIT)

int main() {
	
	int ret; // For return values

	int ID   = 0x000;
	int X90  = 0x100;
	int MEAS = 0x200;
	int count = 0x10;

	PULSE(X90, Q1);
	X(Q1);

	for (int i=0; i<200; i+=10) {
		sync();
		wait();
		wfm_play(X90, count, ret);
		wfm_ta_play(ID, i, ret); 
		wfm_play(X90, count, ret);
		wfm_play(MEAS, count, ret);
	}	

	asm volatile("ecall");
	return 0;
}

// [i.c() for i in seq_data[0][0]]