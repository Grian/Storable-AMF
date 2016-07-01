#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>


void my_longjmp(jmp_buf a, int code){
	fprintf(stderr, "doing longjmp=%d\n", code);
	longjmp(a,code);
	fprintf(stderr, "I am still alive\n");
}

int my_setjmp(jmp_buf a){
	int code = setjmp(a);
	fprintf(stderr, "setjmp code=%d\n", code);
	return code;
}


typedef int my_cb(int version, void *, void *, void *, void *);
int do_sigsetjmp(int version, my_cb cb, void *jmp, void *interp, void *io, void *data, void*sv_option){

	fprintf(stderr, "I like perl\n");
    if (! setjmp(jmp)){
		fprintf(stderr, "I like perl callback\n");
        cb(version, interp, io, data, sv_option);
        return 0;
    }
    else {
		fprintf(stderr, "I got error\n");
        return 1;
    }
}
