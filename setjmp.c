#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>

int main(){
	fprintf(stderr, "I like perl\n");
	jmp_buf a;
	if (!setjmp(a)){
		fprintf(stderr, "process\n");

		longjmp(a, 1);

		fprintf(stderr, "continue\n");
	}
	else {
		fprintf(stderr, "I catch\n");
	}
}
