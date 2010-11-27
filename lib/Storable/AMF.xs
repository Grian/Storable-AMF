#define _CRT_SECURE_NO_DEPRECATE // Win32 compilers close eyes...
#define PERL_NO_GET_CONTEXT
#undef  PERL_IMPLICIT_SYS // Sigsetjmp will not work under this
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#ifndef STATIC_INLINE /* a public perl API from 5.13.4 */
#   if defined(__GNUC__) || defined(__cplusplus__) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#       define STATIC_INLINE static inline
#   else
#       define STATIC_INLINE static
#   endif
#endif /* STATIC_INLINE */

#ifndef inline /* don't like borgs definitions */ /* inline is keyword for STDC compiler  */
#   if defined(__GNUC__) || defined(__cplusplus__) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#   else
#	if defined(WIN32) && defined(_MSV) /* Microsoft Compiler */
#	    define inline _inline
#	else 
#	    define inline 
#	endif
#   endif
#endif /* inline  */

#define MARKER3_UNDEF	  '\x00'
#define MARKER3_NULL	  '\x01'
#define MARKER3_FALSE	  '\x02'
#define MARKER3_TRUE	  '\x03'
#define MARKER3_INTEGER	  '\x04'
#define MARKER3_DOUBLE    '\x05'
#define MARKER3_STRING    '\x06'
#define MARKER3_XML_DOC   '\x07'
#define MARKER3_DATE      '\x08'
#define MARKER3_ARRAY	  '\x09'
#define MARKER3_OBJECT	  '\x0a'
#define MARKER3_XML	  '\x0b'
#define MARKER3_BYTEARRAY '\x0c'
#define MARKER3_AMF_PLUS	  '\x11' // Not supported 

#define MARKER0_NUMBER		  '\x00'
#define MARKER0_BOOLEAN		  '\x01'
#define MARKER0_STRING  	  '\x02'
#define MARKER0_OBJECT		  '\x03'
#define MARKER0_CLIP		  '\x04'
#define MARKER0_UNDEFINED  	  '\x05'
#define MARKER0_NULL		  '\x06'
#define MARKER0_REFERENCE 	  '\x07'
#define MARKER0_ECMA_ARRAY 	  '\x08'
#define MARKER0_OBJECT_END	  '\x09'
#define MARKER0_STRICT_ARRAY	  '\x0a'
#define MARKER0_DATE	  	  '\x0b'
#define MARKER0_LONG_STRING       '\x0c'
#define MARKER0_UNSUPPORTED	  '\x0d'
#define MARKER0_RECORDSET	  '\x0e'
#define MARKER0_XML_DOCUMENT      '\x0f'
#define MARKER0_TYPED_OBJECT	  '\x10'
#define MARKER0_AMF_PLUS	  '\x11' //not supported

#define ERR_EOF 1
#define ERR_REF 2
#define ERR_MARKER 3
#define ERR_BAD_OBJECT 4
#define ERR_OVERFLOW 5
#define ERR_UNIMPLEMENTED 6
#define ERR_BADREF 7
#define ERR_BAD_DATE_REF 8
#define ERR_BAD_OBJECT_REF 9
#define ERR_BAD_ARRAY_REF 10
#define ERR_BAD_STRING_REF 11
#define ERR_BAD_TRAIT_REF 12
#define ERR_BAD_XML_REF 13
#define ERR_BAD_BYTEARRAY_REF 14
#define ERR_EXTRA_BYTE 15
#define ERR_INT_OVERFLOW 16
#define ERR_RECURRENT_OBJECT 17
#define ERR_BAD_REFVAL  18

#define OPT_STRICT        1
#define OPT_DECODE_UTF8   2
#define OPT_ENCODE_UTF8   4
#define OPT_RAISE_ERROR   8
#define OPT_MILLSEC_DATE  16
#define OPT_PREFER_NUMBER 32

#define EXPERIMENT1

#define AMF0 0
#define AMF3 3


#define STR_EMPTY    '\x01'
#define TRACE(ELEM) PerlIO_printf( PerlIO_stderr(), ELEM);
#undef TRACE
#define TRACE(ELEM) ;

#if BYTEORDER == 0x1234
    #define GAX "LIT"
    #define GET_NBYTE(ALL, IPOS, TYPE) (ALL - 1 - IPOS)
#else
#if BYTEORDER == 0x12345678
    #define GAX "LIT"
    #define GET_NBYTE(ALL, IPOS, TYPE) (ALL - 1 - IPOS)
#else
#if BYTEORDER == 0x87654321
    #define GAX "BIG"
    #define GET_NBYTE(ALL, IPOS, TYPE) (sizeof(TYPE) -ALL + IPOS)
#else
#if  BYTEORDER == 0x4321
    #define GAX "BIG"
    #define GET_NBYTE(ALL, IPOS, TYPE) (sizeof(TYPE) -ALL + IPOS)
#else
    #error Unknown byteorder. Please append your byteorder to Storable/AMF.xs
#endif
#endif
#endif
#endif

#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

#define SIGN_BOOL_APPLY( obj, sign, mask ) ( sign > 0 ? obj|=mask : sign <0 ? obj&=~mask : 0 ) 
#define DEFAULT_MASK OPT_PREFER_NUMBER

//#define TRACE0
struct amf3_restore_point{
    int offset_buffer;
    int offset_object;
    int offset_trait;
    int offset_string;
};

struct io_struct{
    unsigned char * ptr;
    unsigned char * pos;
    unsigned char * end;
    char *message;
    void * this_perl;
    SV * sv_buffer;
    AV * refs;
    int RV_COUNT;
    HV * RV_HASH;
    int buffer_step_inc;
    char status;
    char * old_pos;
    Sigjmp_buf target_error;
    AV *arr_string;
    AV *arr_object;
    AV *arr_trait;
    HV *hv_string;
    HV *hv_object;
    HV *hv_trait;
    int rc_string;
    int rc_object;
    int rc_trait;
    int version;
    int options;
};

inline void io_register_error(struct io_struct *io, int);
inline void io_register_error_and_free(pTHX_ struct io_struct *io, int, void *);
inline int
io_position(struct io_struct *io){
    return io->pos-io->ptr;
}

inline void
io_set_position(struct io_struct *io, int pos){
    io->pos = io->ptr + pos;
}

inline void 
io_savepoint(pTHX_ struct io_struct *io, struct amf3_restore_point *p){
    p->offset_buffer = io_position(io);
    p->offset_object = av_len(io->arr_object);
    p->offset_trait  = av_len(io->arr_trait);
    p->offset_string = av_len(io->arr_string);
}
inline void
io_restorepoint(pTHX_ struct io_struct *io, struct amf3_restore_point *p){
    io_set_position(io, p->offset_buffer);	
    while(av_len(io->arr_object) > p->offset_object){
        sv_2mortal(av_pop(io->arr_object));
    }
    while(av_len(io->arr_trait) > p->offset_trait){
        sv_2mortal(av_pop(io->arr_trait));
    }
    while(av_len(io->arr_string) > p->offset_string){
        sv_2mortal(av_pop(io->arr_string));
    }
}


inline void
io_move_backward(struct io_struct *io, int step){
    io->pos-= step;
}

inline void
io_move_forward(struct io_struct *io, int len){
    io->pos+=len;	
}

inline void
io_require(struct io_struct *io, int len){
    if (io->end - io->pos < len){
        io_register_error(io, ERR_EOF);
    }
}

inline void
io_reserve(pTHX_ struct io_struct *io, int len){
    if (io->end - io->pos< len){
        unsigned int ipos = io->pos - io->ptr;
        unsigned int buf_len;

        SvCUR_set(io->sv_buffer, ipos);
        buf_len = SvLEN(io->sv_buffer);
        while( buf_len < ipos + len + io->buffer_step_inc){
            buf_len *= 4;
        }
        io->ptr = (unsigned char *) SvGROW(io->sv_buffer, buf_len);
        io->pos = io->ptr + ipos;
        io->end = io->ptr + SvLEN(io->sv_buffer);
    }
}
inline void io_register_error(struct io_struct *io, int errtype){
    Siglongjmp(io->target_error, errtype);
}

inline void io_register_error_and_free(pTHX_ struct io_struct *io, int errtype, void *pointer){
    if (pointer)
        sv_2mortal((SV*) pointer);
    Siglongjmp(io->target_error, errtype);
}
inline void io_in_init(pTHX_ struct io_struct * io, SV *io_self, SV* data, int amf3){
    //    PerlInterpreter *my_perl = io->interpreter;
    STRLEN io_len;
    io->ptr = (unsigned char *) SvPVX(data);
    io_len  = SvLEN(data);
    io->end = io->ptr + SvCUR(data);
    io->pos = io->ptr;
    io->message = "";
    io->refs    = (AV*) SvRV(io_self);
    io->status  = 'r';
    io->version = amf3;
    if (amf3 == AMF3) {
        io->arr_string = newAV();
        io->arr_trait = newAV();
        io->arr_object = newAV();
        sv_2mortal((SV*) io->arr_string);
        sv_2mortal((SV*) io->arr_trait);
        sv_2mortal((SV*) io->arr_object);
    }
}
inline void io_in_destroy(pTHX_ struct io_struct * io, AV *a){
    int i;
    SV **ref_item;
    int alen;
    SV *item;
    if (a) {
        alen = av_len(a);
        for(i = 0; i<= alen; ++i){
            ref_item = av_fetch(a,i,0);
            if (ref_item){
                if (SvROK(*ref_item)){
                    item = SvRV(*ref_item);
                    if (SvTYPE(item) == SVt_PVAV){
                        av_clear((AV*) item);
                    }
                    else if (SvTYPE(item) == SVt_PVHV){
                        HV * h = (HV*) item;
                        hv_clear(h);
                    }
                }
            }
        }
    }
    else {
        if (io->version == AMF0){
            io_in_destroy(aTHX_  io, io->refs);
        }
        else if (io->version == AMF3) {
            //            fprintf( stderr, "%p %p %p %p\n", io->refs, io->arr_object, io->arr_trait, io->arr_string);
            io_in_destroy(aTHX_  io, io->refs);
            io_in_destroy(aTHX_  io, io->arr_object);
            io_in_destroy(aTHX_  io, io->arr_trait); // May be not needed
            io_in_destroy(aTHX_  io, io->arr_string);
        }
        else {
            croak("bad version at destroy");
        }
    }
}
inline void io_out_init(pTHX_ struct io_struct *io, SV* io_self, int amf3){
    SV *sbuffer;
    unsigned int ibuf_size ;
    unsigned int ibuf_step ;
    sbuffer = newSVpvn("",0);
    io->version = amf3;
    ibuf_size = 10240;
    ibuf_step = 20480;
    SvGROW(sbuffer, ibuf_size);
    io->sv_buffer = sbuffer;
    if (amf3) {

        io->hv_string = newHV();
        io->hv_trait = newHV();
        io->hv_object = newHV();

        io->rc_string = 0;
        io->rc_trait  = 0;
        io->rc_object = 0;

        sv_2mortal((SV *)io->hv_string);
        sv_2mortal((SV *)io->hv_object);
        sv_2mortal((SV *)io->hv_trait);


    }
    io->buffer_step_inc = ibuf_step;
    io->ptr = (unsigned char *) SvPV_nolen(io->sv_buffer);
    io->pos = io->ptr;
    io->end = (unsigned char *) SvEND(io->sv_buffer);
    io->message = "";
    io->status  = 'w';
    io->RV_COUNT = 0;
    io->RV_HASH   = newHV();
    sv_2mortal((SV*)io->RV_HASH);
}

inline SV * io_buffer(struct io_struct *io){
    SvCUR_set(io->sv_buffer, io->pos - io->ptr);
    return io->sv_buffer;
}


// inline char * SVt_string(SV * ref){
    // 	char *type;
    // 	switch(SvTYPE(ref)){
        // 		case SVt_IV:
        // 			type = "Scalar IV";
        // 			break;
        // 		case SVt_NV:
        // 			type = "Scalar NV";
        // 			break;
        // 		case SVt_PV:
        // 			type = "Scalar pointer(PV)";
        // 			break;
        // 		case SVt_RV:
        // 			type = "Scalar reference";
        // 			break;
        // 		case SVt_PVAV:
        // 			type = "Array";
        // 			break;
        // 		case SVt_PVHV:
        // 			type = "Hash";
        // 			break;
        // 		case SVt_PVCV:
        // 			type = "Code";
        // 			break;
        // 		case SVt_PVGV:
        // 			type = "Glob (possible a file handler)";
        // 			break;
        // 		case SVt_PVMG:
        // 			type = "Blessed or Magical Scalar";
        // 			break;
        // 		default:
        // 			type = "Unknown";
        // 			break;
        // 	}
    // 	if (! ref ){
        // 		type = "null pointer";
        // 	}
    // 	return type;
    // }
inline double io_read_double(struct io_struct *io);
inline char io_read_marker(struct io_struct * io);
inline int io_read_u8(struct io_struct * io);
inline int io_read_u16(struct io_struct * io);
inline int io_read_u32(struct io_struct * io);
inline int io_read_u24(struct io_struct * io);


#define MOVERFLOW(VALUE, MAXVALUE, PROC)\
	if (VALUE > MAXVALUE) { \
		PerlIO_printf( PerlIO_stderr(), "Overflow in %s. expected less %d. got %d\n", PROC, MAXVALUE, VALUE); \
		io_register_error(io, ERR_OVERFLOW); \
	}



inline void io_write_double(pTHX_ struct io_struct *io, double value){
    const int step = 8;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io, step );
    v.nv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos[2] = v.c[GET_NBYTE(step, 2, value)];
    io->pos[3] = v.c[GET_NBYTE(step, 3, value)];
    io->pos[4] = v.c[GET_NBYTE(step, 4, value)];
    io->pos[5] = v.c[GET_NBYTE(step, 5, value)];
    io->pos[6] = v.c[GET_NBYTE(step, 6, value)];
    io->pos[7] = v.c[GET_NBYTE(step, 7, value)];
    io->pos+= step ;
    return;
}
inline void io_write_marker(pTHX_ struct io_struct * io, char value)	{
    const int step = 1;
    union vvv{
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } ;
    io_reserve(aTHX_  io, 1);
    io->pos[0]= value;
    io->pos+=step;
    return;
}

inline void io_write_u8(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 1;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    v.uv = value;
    MOVERFLOW(value, 255, "write_u8");
    io_reserve(aTHX_  io, 1);
    io->pos[0]= v.c[0];
    io->pos+=step ;
    return;
}


inline void io_write_s16(pTHX_ struct io_struct * io, signed int value){
    const int step = 2;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    v.iv = value;
    MOVERFLOW(value, 32767, "write_s16");
    io_reserve(aTHX_  io, step);
    io->pos[0]= v.c[GET_NBYTE(step, 0, value)];
    io->pos[1]= v.c[GET_NBYTE(step, 1, value)];
    io->pos+=step;
    return;
}

inline void io_write_u16(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 2;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io,step);
    MOVERFLOW(value, 65535 , "write_u16");
    v.uv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos+=step;
    return;
}

inline void io_write_u32(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 4;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io,step);
    v.uv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos[2] = v.c[GET_NBYTE(step, 2, value)];
    io->pos[3] = v.c[GET_NBYTE(step, 3, value)];
    io->pos+=step;
    return;
}

inline void io_write_u24(pTHX_ struct io_struct * io, unsigned int value){
    const int step = 3;
    union {
        signed   int iv;
        unsigned int uv;
        double nv;
        char   c[8];
    } v;
    io_reserve(aTHX_  io,step);
    MOVERFLOW(value,16777215 , "write_u16");
    v.uv = value;
    io->pos[0] = v.c[GET_NBYTE(step, 0, value)];
    io->pos[1] = v.c[GET_NBYTE(step, 1, value)];
    io->pos[2] = v.c[GET_NBYTE(step, 2, value)];
    io->pos+=step;
    return;
}
inline void io_write_bytes(pTHX_ struct io_struct* io, const char * const buffer, int len){
    io_reserve(aTHX_  io, len);
    Copy(buffer, io->pos, len, char);
    io->pos+=len;
}	
// Date checking
inline bool util_is_date(SV *one);
inline double util_date_time(SV *one);

inline void format_one(pTHX_ struct io_struct *io, SV * one);
inline void format_number(pTHX_ struct io_struct *io, SV * one);
inline void format_string(pTHX_ struct io_struct *io, SV * one);
inline void format_strict_array(pTHX_ struct io_struct *io, AV * one);
inline void format_object(pTHX_ struct io_struct *io, HV * one);
inline void format_null(pTHX_ struct io_struct *io);
inline void format_typed_object(pTHX_ struct io_struct *io, HV * one);

inline bool util_is_date(SV *one){
    if (SvNOKp(one)){
	HV* stash = SvSTASH(one);
	char *class_name = HvNAME(stash);
	if (*class_name == '*' && class_name[1] == 0){
	    return 1;
	}
	else {
	    return 0;
	}
    }
    else {
	return 0;
    }
}
inline double util_date_time(SV *one){
    return (SvNVX(one)*1000);
}
inline void format_reference(pTHX_ struct io_struct * io, SV *ref){
    io_write_marker(aTHX_  io, MARKER0_REFERENCE);
    io_write_u16(aTHX_  io, SvIV(ref));
}
inline void format_scalar_ref(pTHX_ struct io_struct * io, SV *ref){
    const char *const reftype = "REFVAL";
    
    io_write_marker(aTHX_  io, MARKER0_TYPED_OBJECT);
    // special type
    io_write_u16(aTHX_  io, 6);
    io_write_bytes(aTHX_  io, reftype, 6);

    // type
    io_write_u16(aTHX_  io, 6);
    io_write_bytes(aTHX_  io, reftype, 6);
    format_one(aTHX_  io, ref);
    // end marker
    io_write_u16(aTHX_  io, 0);
    io_write_marker(aTHX_  io, MARKER0_OBJECT_END);
}

inline void format_one(pTHX_ struct io_struct *io, SV * one){

    if (SvROK(one)){
        SV * rv = (SV*) SvRV(one);
        // test has stored
        SV **OK = hv_fetch(io->RV_HASH, (char *)(&rv), sizeof (rv), 1);
        if (SvOK(*OK)) {
            format_reference(aTHX_  io, *OK);
        }
        else {
            int type = SvTYPE(rv);
            sv_setiv(*OK, io->RV_COUNT);
            ++io->RV_COUNT;

            if (sv_isobject(one)) {
                if (SvTYPE(rv) == SVt_PVHV){
                    format_typed_object(aTHX_  io, (HV *) rv);
                }
		else if ( util_is_date( rv ) ) {
		    io_write_marker(aTHX_ io, MARKER0_DATE );
		    io_write_double(aTHX_ io, util_date_time( rv ));
		    io_write_s16(aTHX_ io, 0 );
		}
		else {		    
                    // may be i has to format as undef
                    io_register_error(io, ERR_BAD_OBJECT);
                }
            }
            else if (SvTYPE(rv) == SVt_PVAV) 
                format_strict_array(aTHX_  io, (AV*) rv);
            else if (SvTYPE(rv) == SVt_PVHV) {
                io_write_marker(aTHX_  io, MARKER0_OBJECT);
                format_object(aTHX_  io, (HV*) rv);
            }
            else if ( type != SVt_PVCV && type !=  SVt_PVGV ) {
                format_scalar_ref(aTHX_  io, (SV*) rv);
            }
            else {
                io->message = "bad type of object in stream";
                io_register_error(io, ERR_BAD_OBJECT);
            }
        }
    }
    else {
        if (SvOK(one)){
	    #if defined( EXPERIMENT1 )
	    if ( (io->options & OPT_PREFER_NUMBER )){
		if (SvNIOK(one)){
		    format_number(aTHX_  io, one);
		}
		else {
		    format_string(aTHX_  io, one);
		}
	    }
	    else 
	    #endif
		if (SvPOK(one)){
		    format_string(aTHX_  io, one);
		}
		else {
		    format_number(aTHX_  io, one);
		}
        }
        else {
            format_null(aTHX_  io);
        }
    }
}

inline void format_number(pTHX_ struct io_struct *io, SV * one){

    io_write_marker(aTHX_  io, MARKER0_NUMBER);
    io_write_double(aTHX_  io, SvNV(one));	
}
inline void format_string(pTHX_ struct io_struct *io, SV * one){

    // TODO: process long string
    if (SvPOK(one)){
        STRLEN str_len;
        char * pv;
        pv = SvPV(one, str_len);
        if (str_len > 65500){
            io_write_marker(aTHX_  io, MARKER0_LONG_STRING);
            io_write_u32(aTHX_  io, str_len);
            io_write_bytes(aTHX_  io, pv, str_len);
        }
        else {

            io_write_marker(aTHX_  io, MARKER0_STRING);
            io_write_u16(aTHX_  io, SvCUR(one));
            io_write_bytes(aTHX_  io, SvPV_nolen(one), SvCUR(one));
        }
    }else{
        format_null(aTHX_  io);
    }
}
inline void format_strict_array(pTHX_ struct io_struct *io, AV * one){
    int i, len;
    AV * one_array;
    one_array =  one;
    len = av_len(one_array);

    io_write_marker(aTHX_  io, '\012');
    io_write_u32(aTHX_  io, len + 1);
    for(i = 0; i <= len; ++i){
        SV ** ref_value = av_fetch(one_array, i, 0);
        if (ref_value) {
            format_one(aTHX_  io, *ref_value);
        }
        else {
            format_null(aTHX_  io);
        }
    }
}
inline void format_object(pTHX_ struct io_struct *io, HV * one){
    STRLEN key_len;
    HV *hv;
    HE *he;
    SV * value;
    char * key_str;
    hv = one;
    if (1) {
        hv_iterinit(hv);
        while( (he =  hv_iternext(hv))){
            key_str = HePV(he, key_len);
            value   = HeVAL(he);
            io_write_u16(aTHX_  io, key_len);
            io_write_bytes(aTHX_  io, key_str, key_len);
            format_one(aTHX_  io, value);
        }
    }
    io_write_u16(aTHX_  io, 0);
    io_write_marker(aTHX_  io, MARKER0_OBJECT_END);
}
inline void format_null(pTHX_ struct io_struct *io){

    io_write_marker(aTHX_  io, MARKER0_UNDEFINED);
}
inline void format_typed_object(pTHX_ struct io_struct *io,  HV * one){
    HV* stash = SvSTASH(one);
    char *class_name = HvNAME(stash);
    io_write_marker(aTHX_  io, MARKER0_TYPED_OBJECT);
    io_write_u16(aTHX_  io, (U16) strlen(class_name));
    io_write_bytes(aTHX_  io, class_name, strlen(class_name));
    format_object(aTHX_  io, one);
}

STATIC_INLINE SV * parse_one(pTHX_ struct io_struct * io);

STATIC_INLINE SV* parse_boolean(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_object(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_movieclip(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_null(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_undefined(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_reference(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_object_end(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_strict_array(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_ecma_array(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_date(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_long_string(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_unsupported(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_recordset(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_xml_document(pTHX_ struct io_struct *io);
STATIC_INLINE SV* parse_typed_object(pTHX_ struct io_struct *io);

inline void io_write_double(pTHX_ struct io_struct *io, double value);
inline void io_write_marker(pTHX_ struct io_struct * io, char value);
inline void io_write_u8(pTHX_ struct io_struct * io, unsigned int value);
inline void io_write_s16(pTHX_ struct io_struct * io, signed int value);
inline void io_write_u16(pTHX_ struct io_struct * io, unsigned int value);
inline void io_write_u32(pTHX_ struct io_struct * io, unsigned int value);
inline void io_write_u24(pTHX_ struct io_struct * io, unsigned int value);

inline double io_read_double(struct io_struct *io){
    const int step = sizeof(double);
    double a;
    unsigned char * ptr_in  = io->pos;
    char * ptr_out = (char *) &a; 
    io_require(io, step);
    ptr_out[GET_NBYTE(step, 0, a)] = ptr_in[0] ;
    ptr_out[GET_NBYTE(step, 1, a)] = ptr_in[1] ;
    ptr_out[GET_NBYTE(step, 2, a)] = ptr_in[2] ;
    ptr_out[GET_NBYTE(step, 3, a)] = ptr_in[3] ;
    ptr_out[GET_NBYTE(step, 4, a)] = ptr_in[4] ;
    ptr_out[GET_NBYTE(step, 5, a)] = ptr_in[5] ;
    ptr_out[GET_NBYTE(step, 6, a)] = ptr_in[6] ;
    ptr_out[GET_NBYTE(step, 7, a)] = ptr_in[7] ;
    io->pos += step;
    return a;
}
inline char *io_read_bytes(struct io_struct *io, int len){
    char * pos = ( char * )io->pos;
    io_require(io, len);
    io->pos+=len;
    return pos;
}
inline char *io_read_chars(struct io_struct *io, int len){
    char * pos = ( char * )io->pos;
    io_require(io, len);
    io->pos+=len;
    return pos;
}

inline char io_read_marker(struct io_struct * io){
    const int step = 1;
    unsigned char marker;
    io_require(io, step);
    marker = *(io->pos);
    io->pos++;
    return marker;
}
inline int io_read_u8(struct io_struct * io){
    const int step = 1;
    union{
        unsigned int x;
        unsigned char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    io->pos+= step;
    return (int) str.x;
}
inline int io_read_s16(struct io_struct * io){
    const int step = 2;
    union{
        int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x =  io->pos[step - 1] & '\x80' ? -1 : 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    io->pos+= step;
    return (int) str.x;
}
inline int io_read_u16(struct io_struct * io){
    const int step = 2;
    union{
        unsigned int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    io->pos+= step;
    return (int) str.x;
}
inline int io_read_u24(struct io_struct * io){
    const int step = 3;
    union{
        unsigned int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    str.bytes[GET_NBYTE(step, 2, str.x)] = io->pos[2];
    io->pos+= step;
    return (int) str.x;
}
inline int io_read_u32(struct io_struct * io){
    const int step = 4;
    union{
        unsigned int x;
        char bytes[8];
    } str;
    io_require(io, step);
    str.x = 0;
    str.bytes[GET_NBYTE(step, 0, str.x)] = io->pos[0];
    str.bytes[GET_NBYTE(step, 1, str.x)] = io->pos[1];
    str.bytes[GET_NBYTE(step, 2, str.x)] = io->pos[2];
    str.bytes[GET_NBYTE(step, 3, str.x)] = io->pos[3];
    io->pos+= step;
    return (int) str.x;
}
inline void amf3_write_integer(pTHX_ struct io_struct *io, IV ivalue){
    UV value;
    if (ivalue<0){
        value = 0x3fffffff & (UV) ivalue;	
    }
    else {
        value = ivalue;
    }
    if (value<128){
        io_reserve(aTHX_  io, 1);
        io->pos[0]= (U8) value;
        io->pos+=1;
    }
    else if (value<= 0x3fff ) {
        io_reserve(aTHX_  io, 2);
        io->pos[0] = (U8) (value>>7) | 128;
        io->pos[1] = (U8) (value & 0x7f);
        io->pos+=2;
    }
    else if (value <= 0x1fffff) {
        io_reserve(aTHX_  io, 3);

        io->pos[0] = (U8) (value>>14) | 128;
        io->pos[1] = (U8) (value>>7 & 0x7f) |128;
        io->pos[2] = (U8) (value & 0x7f);
        io->pos+=3;
    }
    else if ((value <= 0x3FFFFFFF)){
        io_reserve(aTHX_  io, 4);

        io->pos[0] = (U8) (value>>22 & 0xff) |128;
        io->pos[1] = (U8) (value>>15 & 0x7f) |128;
        io->pos[2] = (U8) (value>>8  & 0x7f) |128;
        io->pos[3] = (U8) (value     & 0xff);
        io->pos+=4;
    }
    else {
        io_register_error( io, ERR_INT_OVERFLOW);
        return;
    }
    return;
}

inline int amf3_read_integer(struct io_struct *io){
    I32 value;
    io_require(io, 1);
    if ((U8) io->pos[0] > 0x7f) {
        io_require(io, 2);
        if ((U8) io->pos[1] >0x7f) {

            io_require(io, 3);
            if ((U8) io->pos[2] >0x7f) {
                value =  ((io->pos[0] & 0x7f) <<22)| ((io->pos[1] & 0x7f) <<15) | ((io->pos[2] & 0x7f) <<8) | io->pos[3];
                io_require(io, 4);

                if ((U8) io->pos[3] >0x7f) {
                    value = value | ~(0x0fffffff);
                }
                else {
                    // no return value;
                }
                io_move_forward(io, 4);
            }
            else {
                value = ((io->pos[0] & 0x7f) <<14) + ((io->pos[1] & 0x7f) <<7) + io->pos[2];
                io_move_forward(io, 3);
            }
        }
        else {
            value = ((io->pos[0] & 0x7f) << 7) + io->pos[1];
            io_move_forward(io, 2);
        }
    }
    else {
        value = (U8) io->pos[0];
        io_move_forward(io, 1);
    }
    return value;
}
STATIC_INLINE SV * parse_utf8(pTHX_ struct io_struct * io){
    int string_len = io_read_u16(io);
    SV * RETVALUE;
    char *x = io_read_chars(io, string_len);
    RETVALUE = newSVpvn(x, string_len);
    if (io->options & OPT_DECODE_UTF8)
	SvUTF8_on(RETVALUE);

    return RETVALUE;
}

STATIC_INLINE SV * parse_object(pTHX_ struct io_struct * io){
    HV * obj;
    int len_next;
    char * key;
    SV * value;
    int obj_pos;

    obj =  newHV();
    av_push(io->refs, newRV_noinc((SV *) obj));
    obj_pos = av_len(io->refs);
    while(1){
        len_next = io_read_u16(io);
        if (len_next == 0) {
            char object_end;
            object_end= io_read_marker(io);
            if ((object_end == MARKER0_OBJECT_END))
            {
                if (io->options & OPT_STRICT){
                    SV* RETVALUE = *av_fetch(io->refs, obj_pos, 0);
                    if (SvREFCNT(RETVALUE) > 1)
                        io_register_error(io, ERR_RECURRENT_OBJECT);
                    ;
                    SvREFCNT_inc_simple_void_NN(RETVALUE);
                    return RETVALUE;
                }
                else {
                    return (SV*) newRV_inc((SV*)obj);
                }
            }
            else {
                io->pos--;
                key = "";
                value = parse_one(aTHX_  io);
            }
        }
        else {
            key = io_read_chars(io, len_next);
            value = parse_one(aTHX_  io);
        }

        (void) hv_store(obj, key, len_next, value, 0);
    }
}

STATIC_INLINE SV* parse_movieclip(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    io->message = "Movie clip unsupported yet";
    RETVALUE = newSV(0);
    return RETVALUE;
}
STATIC_INLINE SV* parse_null(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}

STATIC_INLINE SV* parse_undefined(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}

STATIC_INLINE SV* parse_reference(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    int object_offset;
    AV * ar_refs;
    object_offset = io_read_u16(io);
    ar_refs = (AV *) io->refs;
    if (object_offset > av_len(ar_refs)){
        io_register_error(io, ERR_REF);
    }
    else {
        RETVALUE = *av_fetch(ar_refs, object_offset, 0);
        SvREFCNT_inc_simple_void_NN(RETVALUE);
    }
    return RETVALUE;
}

STATIC_INLINE SV* parse_object_end(pTHX_ struct io_struct *io){
    io_read_marker(io);
    return 0;
}

STATIC_INLINE SV* parse_strict_array(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    int array_len;
    AV* this_array;
    AV * refs = io->refs;
    int i;

    refs = (AV*) io->refs;
    array_len = io_read_u32(io);
    this_array = newAV();
    av_extend(this_array, array_len);
    av_push(refs, RETVALUE = newRV_noinc((SV*) this_array));

    for(i=0; i<array_len; ++i){
        av_push(this_array, parse_one(aTHX_  io));
    }
    if (SvREFCNT(RETVALUE) > 1 && io->options & OPT_STRICT)
    io_register_error(io, ERR_RECURRENT_OBJECT);
    SvREFCNT_inc_simple_void_NN(RETVALUE);

    return RETVALUE;
}

STATIC_INLINE SV* parse_ecma_array(pTHX_ struct io_struct *io){
    SV* RETVALUE;

    U32 array_len;
    AV * this_array;
    AV * refs = io->refs;
    int  position; //remember offset for array convertion to hash
    int last_len;
    char last_marker;
    int av_refs_len;
    int key_len;
    char *key_ptr;
    array_len = io_read_u32(io);
    position= io_position(io);

    this_array = newAV();
    av_extend(this_array, array_len);

    av_refs_len = av_len(refs);
    av_push(refs, newRV_noinc((SV*) this_array));

    #ifdef TRACEA
    fprintf( stderr, "Start parse array %d\n", array_len);
    fprintf( stderr, "position %d\n", io_position(io));
    #endif
    if (0 <= array_len){
        bool ok;
        UV index;
        key_len = io_read_u16(io);
        key_ptr = io_read_chars(io, key_len);


        ok = ((key_len == 1) && (IS_NUMBER_IN_UV & grok_number(key_ptr, key_len, &index)) &&	 (index < array_len ));
        if (ok){
            av_store(this_array, index, parse_one(aTHX_  io));
        }
        else {
            if (((key_len) == 6  &&  strnEQ(key_ptr, "length", 6))){
                ok = 1;
                array_len++; // safe for flash v.9.0
                sv_2mortal( parse_one(aTHX_  io));
            }
            else {
                ok = 0;
            };
        }
        if (ok){ 
	    U32 i;
            for(i=1; i<array_len; ++i){
                UV index;
                int key_len= io_read_u16(io);
                char *s = io_read_chars(io, key_len);

                #ifdef TRACEA
                fprintf( stderr, "index =%d, position %d\n", i, io_position(io));
                #endif
                if ((IS_NUMBER_IN_UV & grok_number(s, key_len, &index)) &&
                    (index < array_len)){
                    av_store(this_array, index, parse_one(aTHX_  io));
                    #ifdef TRACEA
                    fprintf( stderr, "index =%d, position %d\n", i, io_position(io));
                    #endif
                }
                else {
                    if ((key_len) != 6  || strnEQ(key_ptr, "length", 6)!=0){
                        io_move_backward(io, key_len + 2);
                        break;
                    }
                    else {
                        array_len++;
                        sv_2mortal( parse_one(aTHX_  io));
                    }
                }
            }
        }
        else {
            io_move_backward(io, key_len + 2);
        }
    }


    #ifdef TRACEA
    fprintf( stderr, "almost at end parse array %d\n", array_len);
    fprintf( stderr, "position %d\n", io_position(io));
    #endif
    last_len = io_read_u16(io);
    last_marker = io_read_marker(io);
    #ifdef TRACEA
    fprintf( stderr, "at end parse array %d\n", array_len);
    fprintf( stderr, "position %d\n", io_position(io));
    #endif
    if ((last_len == 0) && (last_marker == MARKER0_OBJECT_END)) {
        RETVALUE = *av_fetch(refs, av_refs_len + 1, 0);
        if (io->options & OPT_STRICT && (SvREFCNT(RETVALUE) > 1))
        io_register_error(io, ERR_RECURRENT_OBJECT);
        ;
        SvREFCNT_inc_simple_void_NN(RETVALUE);
    }
    else{
        // Need rollback referenses 
        int i;
        for( i = av_len(refs) - av_refs_len; i>0 ;--i){
            SV * ref = av_pop(refs);
            sv_2mortal(ref);
        }
        io_set_position(io, position);
        RETVALUE = parse_object(aTHX_  io);
    }
    return RETVALUE;
}

STATIC_INLINE SV* parse_date(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    double time;
    int tz;
    time = io_read_double(io);
    tz = io_read_s16(io);
    if ( io->options & OPT_MILLSEC_DATE )
	RETVALUE = newSVnv(time);
    else 
	RETVALUE = newSVnv(time/1000.0);
    av_push(io->refs, RETVALUE);
    SvREFCNT_inc_simple_void_NN(RETVALUE);
    return RETVALUE;
}

STATIC_INLINE SV* parse_long_string(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    STRLEN len;
    len = io_read_u32(io);

    RETVALUE = newSVpvn(io_read_chars(io, len), len);
    if (io->options & OPT_DECODE_UTF8)
	SvUTF8_on(RETVALUE);
    return RETVALUE;
}

STATIC_INLINE SV* parse_unsupported(pTHX_ struct io_struct *io){
    io_register_error(io, ERR_UNIMPLEMENTED);
    return 0;
}
STATIC_INLINE SV* parse_recordset(pTHX_ struct io_struct *io){
    io_register_error(io, ERR_UNIMPLEMENTED);
    return 0;
}
STATIC_INLINE SV* parse_xml_document(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    RETVALUE = parse_long_string(aTHX_  io);
    SvREFCNT_inc_simple_void_NN(RETVALUE);
    av_push(io->refs, RETVALUE);
    return RETVALUE;
}
inline SV *parse_scalar_ref(pTHX_ struct io_struct *io){
        SV * obj;
        int obj_pos;
        int len_next;
        char *key;
        SV *value;

        io->pos+=6;
        obj =  newSV(0);
        av_push(io->refs,  obj);
        obj_pos = av_len(io->refs);
        value = 0;

        while(1){
            len_next = io_read_u16(io);
            if (len_next == 0) {
                char object_end;
                object_end= io_read_marker(io);
                if ((object_end == MARKER0_OBJECT_END))
                {
                    SV* RETVALUE = *av_fetch(io->refs, obj_pos, 0);
                    if (!value)
                        io_register_error(io, ERR_BAD_REFVAL);
                        sv_setsv(obj, newRV_noinc(value));

                    if (io->options & OPT_STRICT){
                        if (SvREFCNT(RETVALUE) > 1)
                            io_register_error_and_free(aTHX_ io, ERR_RECURRENT_OBJECT, value);
                        ;
                        SvREFCNT_inc_simple_void_NN(RETVALUE);
                        return RETVALUE;
                    }
                    else {
                        SvREFCNT_inc_simple_void_NN(RETVALUE);
                        return RETVALUE;
                    }
                }
                else {
                    io_register_error_and_free(aTHX_ io, ERR_BAD_REFVAL, value);
                }
            }
            else if ( len_next ==  6) {
                key = io_read_chars(io, len_next);
                if (strncmp(key, "REFVAL", 6) || value )
                    io_register_error_and_free(aTHX_ io, ERR_BAD_REFVAL, value);
                
                value = parse_one(aTHX_  io);
            }
            else {
                io_register_error_and_free(aTHX_ io, ERR_BAD_REFVAL, value);
            }
    }
}
STATIC_INLINE SV* parse_typed_object(pTHX_ struct io_struct *io){
    SV* RETVALUE;
    HV *stash;
    int len;

    len = io_read_u16(io);
    if (len == 6 && !strncmp( (char *)io->pos, "REFVAL", 6)){
        // SCALAR
        RETVALUE = parse_scalar_ref(aTHX_ io);
        if (RETVALUE)
            return RETVALUE;
        
    }
    if (io->options & OPT_STRICT){
        stash = gv_stashpvn((char *)io->pos, len, 0);
    }
    else {
        stash = gv_stashpvn((char *)io->pos, len, GV_ADD );
    }
    io->pos+=len;
    RETVALUE = parse_object(aTHX_  io);
    if (stash) 
    sv_bless(RETVALUE, stash);
    return RETVALUE;
}
STATIC_INLINE SV* parse_double(pTHX_ struct io_struct * io){
    return newSVnv(io_read_double(io));
}

STATIC_INLINE SV* parse_boolean(pTHX_ struct io_struct * io){
    char marker;
    marker = io_read_marker(io);
    return newSViv(marker == '\000' ? 0 :1);
}

inline SV * amf3_parse_one(pTHX_ struct io_struct *io);
STATIC_INLINE SV * amf3_parse_undefined(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_null(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSV(0);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_false(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSViv(0);
    return RETVALUE;
}

STATIC_INLINE SV * amf3_parse_true(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSViv(1);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_integer(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSViv(amf3_read_integer(io));
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_double(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = newSVnv(io_read_double(io));
    return RETVALUE;
}
inline char * amf3_read_string(pTHX_ struct io_struct *io, int ref_len, STRLEN *str_len){

    AV * arr_string = io->arr_string;
    if (ref_len & 1) {
        *str_len = ref_len >> 1;
        if (*str_len>0){
            char *pstr;
            pstr = io_read_chars(io, *str_len);
            av_push(io->arr_string, newSVpvn(pstr, *str_len));
            return pstr;
        }
        else {
            return "";
        }
    }
    else {
        int ref = ref_len >> 1;	
        SV ** ref_sv  = av_fetch(arr_string, ref, 0);
        if (ref_sv) {
            char* pstr;
            pstr = SvPV(*ref_sv, *str_len);
            return pstr; 
        }
        else {
            // Exception: May be there throw some
            io_register_error(io, ERR_BADREF);
	    return 0; // Never reach this lime
        }
    }
}
STATIC_INLINE SV * amf3_parse_string(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int ref_len;
    STRLEN plen;
    char* pstr;
    ref_len  = amf3_read_integer(io);
    pstr = amf3_read_string(aTHX_  io, ref_len, &plen);
    RETVALUE = newSVpvn(pstr, plen);
    if (io->options & OPT_DECODE_UTF8) 
	SvUTF8_on(RETVALUE);
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_xml(pTHX_ struct io_struct *io);
STATIC_INLINE SV * amf3_parse_xml_doc(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    RETVALUE = amf3_parse_xml(aTHX_  io);
    return RETVALUE;
}
inline SV * amf3_parse_date(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int i = amf3_read_integer(io);
    if (i&1){

        double x = io_read_double(io);
	if ( io->options & OPT_MILLSEC_DATE ){
	    RETVALUE = newSVnv(x);
	}
	else {
	    RETVALUE = newSVnv(x/1000.0);
	};
	SvREFCNT_inc_simple_void_NN(RETVALUE);
        av_push(io->arr_object, RETVALUE);
    }
    else {
        SV ** item = av_fetch(io->arr_object, i>>1, 0);
        if (item) {
            RETVALUE = *item;
            SvREFCNT_inc_simple_void_NN(RETVALUE);
        }
        else{
            io_register_error(io, ERR_BAD_DATE_REF);
        }
    }
    return RETVALUE;
}


inline void amf3_store_object(pTHX_ struct io_struct *io, SV * item){
    av_push(io->arr_object, newRV_noinc(item));
}
inline void amf3_store_object_rv(pTHX_ struct io_struct *io, SV * item){
    av_push(io->arr_object, item);
}

inline SV * amf3_parse_array(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int ref_len = amf3_read_integer(io);
    if (ref_len & 1){
        // Not referense
        int len = ref_len>>1;
        int str_len;
        SV * item;
        char * pstr;
        bool recover;
        STRLEN plen;		
        struct amf3_restore_point rec_point; 
        int old_vlen;
        SV * item_value;
        UV item_index;
        int obj_pos;


        AV * array;
        str_len = amf3_read_integer(io);
        old_vlen = str_len;

        io_savepoint(aTHX_  io, &rec_point);		

        // Пытаемся востановить как массив 
        // Считаем что это массив если первый индекс от 0 до 9 и все индексы числовые
        //
        array=newAV();
        item = (SV *) array;
        RETVALUE = newRV_noinc(item);

        amf3_store_object_rv(aTHX_  io, RETVALUE);
        obj_pos = av_len(io->arr_object); 


        recover = FALSE;
        if (str_len !=1){
            pstr = amf3_read_string(aTHX_  io, str_len, &plen);
            if (IS_NUMBER_IN_UV & grok_number(pstr, plen, &item_index) && item_index< 10){

                item_value= amf3_parse_one(aTHX_  io);
                av_store(array, item_index, item_value);

                str_len = amf3_read_integer(io);
                while(str_len != 1){
                    pstr = amf3_read_string(aTHX_  io, str_len, &plen);
                    if (IS_NUMBER_IN_UV & grok_number(pstr, plen, &item_index)){

                        item_value= amf3_parse_one(aTHX_  io);
                        av_store(array, item_index, item_value);

                        str_len = amf3_read_integer(io);
                    }
                    else {
                        //recover
                        recover = TRUE;
                        break;
                    }
                };
            }
            else {
                //recover
                recover = TRUE;
            }
        }

        if (!recover) {
            int i;
            for(i=0; i< len; ++i){
                av_store(array, i, amf3_parse_one(aTHX_  io));
            };
        }
        else {
            //востанавливаем как хэш
            HV * hv;
            char *pstr;
            STRLEN plen;
            char buf[2+2*sizeof(int)];
            int i;

            io_restorepoint(aTHX_  io, &rec_point);	

            str_len = old_vlen;
            hv   = newHV();
            item = (SV *) hv;
            RETVALUE = newRV_noinc(item);
            amf3_store_object_rv(aTHX_  io, RETVALUE);
            while(str_len != 1){
                SV *one;
                pstr = amf3_read_string(aTHX_  io, str_len, &plen);
                one = amf3_parse_one(aTHX_  io);
                (void) hv_store(hv, pstr, plen, one, 0);
                str_len = amf3_read_integer(io);

            };
            for(i=0; i<len;++i){
                (void) snprintf(buf, sizeof(buf), "%d", i);
                (void) hv_store(hv, buf, strlen(buf), amf3_parse_one(aTHX_  io), 0);
            }
        };
        if (io->options & OPT_STRICT){
            if (SvREFCNT(RETVALUE)>1){
                io_register_error(io, ERR_RECURRENT_OBJECT);
            }
        }
        SvREFCNT_inc_simple_void_NN(RETVALUE);
    }
    else {
        SV ** value = av_fetch(io->arr_object, ref_len>>1, 0);	
        if (value) {
            SvREFCNT_inc_simple_void_NN(*value);
            RETVALUE = *value;
        }
        else {
            io_register_error(io, ERR_BAD_ARRAY_REF);
        }
    }
    return RETVALUE;
}
struct amf3_trait_struct{
    int sealed;
    bool dynamic;
    bool externalizable;
    SV* class_name;
    HV* stash;
};
inline SV * amf3_parse_object(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int obj_ref = amf3_read_integer(io);
    #ifdef TRACE0
    fprintf(stderr, "obj_ref = %d\n", obj_ref);
    #endif
    if (obj_ref & 1) {// not a ref object
        AV * trait;
        int sealed;
        bool dynamic;
	bool externalizable;
        SV * class_name_sv;
        HV *one;
        int i;

        if (!(obj_ref & 2)){// not trait ref
            SV** trait_item	= av_fetch(io->arr_trait, obj_ref>>2, 0);
            if (! trait_item) {
                io_register_error(io, ERR_BAD_TRAIT_REF);
            };
            trait = (AV *) SvRV(*trait_item);

            sealed  = (int)  SvIV(*av_fetch(trait, 0, 0));
            dynamic = (bool) SvIV(*av_fetch(trait, 1, 0));
	    externalizable = (bool) SvIV(*av_fetch(trait, 2, 0));
            class_name_sv = *av_fetch(trait, 3, 0);
        }
        else {	
            int i;
	    trait = newAV();
	    av_push(io->arr_trait, newRV_noinc((SV *) trait));
	    sealed  = obj_ref >>4;
	    dynamic = obj_ref & 8;
	    externalizable = ( obj_ref  & 0x04) != 0;
	    class_name_sv = amf3_parse_string(aTHX_  io);

	    av_push(trait, newSViv(sealed));
	    av_push(trait, newSViv(dynamic));
	    av_push(trait, newSViv( externalizable )); // external processing
	    av_push(trait, class_name_sv);

	    for(i =0; i<sealed; ++i){
		SV * prop_name;

		prop_name = amf3_parse_string(aTHX_  io);
		av_push(trait, prop_name);
	    }			
        };
        one = newHV();
        RETVALUE = newRV_noinc((SV*) one);
        amf3_store_object_rv(aTHX_  io, RETVALUE);

	if ( externalizable ){
	    (void) hv_store( one, "externalizedData", 16, amf3_parse_one(aTHX_  io), 0);
	};

        for(i=0; i<sealed; ++i){
            (void) hv_store_ent( one, *av_fetch(trait, 4+i, 0), amf3_parse_one(aTHX_  io), 0);	
        };

        if (dynamic) {
            char *pstr;
            STRLEN plen;
            int varlen;
            varlen = amf3_read_integer(io);
            pstr = amf3_read_string(aTHX_  io, varlen, &plen);

            while(plen != 0) { 
                (void) hv_store(one, pstr, plen, amf3_parse_one(aTHX_  io), 0);				
                varlen = -1;
                plen = -1;
                varlen = amf3_read_integer(io);
                pstr = amf3_read_string(aTHX_  io, varlen, &plen);
            }
        }
        if (SvREFCNT(RETVALUE) > 1 && io->options & OPT_STRICT){
            io_register_error(io, ERR_RECURRENT_OBJECT);
        };
        SvREFCNT_inc_simple_void_NN(RETVALUE);
        if (SvCUR(class_name_sv)) {
            HV *stash;
            if (io->options & OPT_STRICT){
                stash = gv_stashsv(class_name_sv, 0 );
            }
            else {
                stash = gv_stashsv(class_name_sv, GV_ADD );
            }
            if (stash) 
            sv_bless(RETVALUE, stash);
        }
        else {
            // No bless
        }
    }
    else {
        SV ** ref = av_fetch(io->arr_object, obj_ref>>1, 0);
        if (ref) {
            RETVALUE = *ref;
            SvREFCNT_inc_simple_void_NN(RETVALUE);
        }
        else {
            io_register_error(io, ERR_BAD_TRAIT_REF);
            RETVALUE = &PL_sv_undef;	
        }
    }
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_xml(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int Bi = amf3_read_integer(io);
    if (Bi & 1) { // value
        int len = Bi>>1;
        char *b = io_read_bytes(io, len);
        RETVALUE = newSVpvn(b, len);
        if (io->options & OPT_DECODE_UTF8)
	    SvUTF8_on(RETVALUE);
        SvREFCNT_inc_simple_void_NN(RETVALUE);
        av_push(io->arr_object, RETVALUE);
    }
    else {
        SV ** sv = av_fetch(io->arr_object, Bi>>1, 0);
        if (sv) {
            RETVALUE = newSVsv(*sv);
        }		
        else {
            io_register_error(io, ERR_BAD_XML_REF);
        }
    }
    return RETVALUE;
}
STATIC_INLINE SV * amf3_parse_bytearray(pTHX_ struct io_struct *io){
    SV * RETVALUE;
    int Bi = amf3_read_integer(io);
    if (Bi & 1) { // value
        int len = Bi>>1;
        char *b = io_read_bytes(io, len);
        RETVALUE = newSVpvn(b, len);
        SvREFCNT_inc_simple_void_NN(RETVALUE);
        av_push(io->arr_object, RETVALUE);
    }
    else {
        SV ** sv = av_fetch(io->arr_object, Bi>>1, 0);
        if (sv) {
            RETVALUE = newSVsv(*sv);
        }		
        else {
            io_register_error(io, ERR_BAD_BYTEARRAY_REF);
        }
    }
    return RETVALUE;
}
inline void amf3_format_date( pTHX_ struct io_struct *io, SV * one){
    io_write_marker( aTHX_ io, MARKER3_DATE );
    amf3_write_integer( aTHX_ io, 1 );
    io_write_double( aTHX_ io, util_date_time( one ));
}
inline void amf3_format_one(pTHX_ struct io_struct *io, SV * one);
inline void amf3_format_integer(pTHX_ struct io_struct *io, SV *one){

    IV i = SvIV(one);
    if (i <= 0x3fffffff && i>= -(0x3fffffff)){
        io_write_marker(aTHX_  io, MARKER3_INTEGER);
        amf3_write_integer(aTHX_  io, SvIV(one));
    }
    else {
        io_write_marker(aTHX_  io, MARKER3_DOUBLE);
        io_write_double(aTHX_  io, (double) i);
    }
}

inline void amf3_format_double(pTHX_ struct io_struct * io, SV *one){

    io_write_marker(aTHX_  io, MARKER3_DOUBLE);
    io_write_double(aTHX_  io, SvNV(one));
}

inline void amf3_format_undef(pTHX_ struct io_struct *io){
    io_write_marker(aTHX_  io, MARKER3_UNDEF);
}
inline void amf3_format_null(pTHX_ struct io_struct *io){
    io_write_marker(aTHX_  io, MARKER3_NULL);
}

inline void amf3_write_string_pvn(pTHX_ struct io_struct *io, char *pstr, STRLEN plen){
    HV* rhv;
    SV ** hv_item;

    rhv = io->hv_string;
    hv_item = hv_fetch(rhv, pstr, plen, 0);

    if (hv_item && SvOK(*hv_item)){
        int sref = SvIV(*hv_item);
        amf3_write_integer(aTHX_  io, sref <<1);
    }
    else {
        if (plen) {
            amf3_write_integer(aTHX_  io, (plen << 1)	| 1);
            io_write_bytes(aTHX_  io, pstr, plen);
            (void) hv_store(rhv, pstr, plen, newSViv(io->rc_string), 0);
            io->rc_string++;
        }
        else {
            io_write_marker(aTHX_  io, STR_EMPTY);
        }
    }
}

inline void amf3_format_string(pTHX_ struct io_struct *io, SV *one){
    char *pstr;
    STRLEN plen;
    pstr = SvPV(one, plen);
    io_write_marker(aTHX_  io, MARKER3_STRING);
    amf3_write_string_pvn(aTHX_  io, pstr, plen);
}

inline void amf3_format_reference(pTHX_ struct io_struct *io, SV *num){
    amf3_write_integer(aTHX_  io, SvIV(num)<<1);
}

inline void amf3_format_array(pTHX_ struct io_struct *io, AV * one){
    int alen;
    int i;
    SV ** aitem;
    io_write_marker(aTHX_  io, MARKER3_ARRAY);
    alen = av_len(one)+1;
    amf3_write_integer(aTHX_  io, 1 | (alen) <<1 );
    io_write_marker(aTHX_  io, STR_EMPTY); // no sparse array;
    for( i = 0; i<alen ; ++i){
        aitem = av_fetch(one, i, 0);
        if (aitem) {
            amf3_format_one(aTHX_  io, *aitem);
        }
        else {
            io_write_marker(aTHX_  io, MARKER3_NULL);
        }
    }
}
inline void amf3_format_object(pTHX_ struct io_struct *io, SV * rone){
    AV * trait;
    SV ** rv_trait;
    char *class_name;
    int class_name_len;
    HV *one;
    one =(HV *) SvRV(rone);

    io_write_marker(aTHX_  io, MARKER3_OBJECT);
    if (sv_isobject((SV*)rone)){
        HV* stash = SvSTASH(one);
        class_name = HvNAME(stash);
        class_name_len = strlen(class_name);
    }
    else {

        class_name = "";
        class_name_len = 0;
    };

    rv_trait = hv_fetch(io->hv_trait, class_name, class_name_len, 0);
    if (rv_trait){
        int ref_trait;
        trait = (AV *) SvRV(*rv_trait);	
        ref_trait = SvIV( *av_fetch(trait, 1, 0));

        amf3_write_integer(aTHX_  io, (ref_trait<< 2) | 1);		
    }
    else {
        SV * class_name_sv;
        int const sealed_count = 0;
        trait = newAV();
        av_extend(trait, 3);
        class_name_sv = newSVpvn(class_name, class_name_len);
        rv_trait = hv_store( io->hv_trait, class_name, class_name_len, newRV_noinc((SV*)trait), 0);
        av_store(trait, 0, class_name_sv);
        av_store(trait, 1, newSViv(io->rc_trait));
        av_store(trait, 2, newSViv(0));

        amf3_write_integer(aTHX_  io, ( sealed_count << 4) | 0x0b );
        amf3_write_string_pvn(aTHX_  io, class_name, class_name_len);
        io->rc_trait++;

    }

    // where must enumeration of sealed attributes

    // where will dynamic properties

    if (1){
        HV *hv;
        SV * value;
        char * key_str;
        I32 key_len;

        hv = one;

        hv_iterinit(hv);
        while( (value  = hv_iternextsv(hv, &key_str, &key_len)) ){
            if (key_len){
                amf3_write_string_pvn(aTHX_  io, key_str, key_len);
                amf3_format_one(aTHX_  io, value);
            };
        }
    }

    io_write_marker(aTHX_  io, STR_EMPTY); 
}
inline void amf3_format_one(pTHX_ struct io_struct *io, SV * one){

    if (SvROK(one)){
        SV * rv = (SV*) SvRV(one);
        // test has stored
        SV **OK = hv_fetch(io->hv_object, (char *)(&rv), sizeof (rv), 1);
        if (SvOK(*OK)) {
            if (SvTYPE(rv) == SVt_PVAV) {
                io_write_marker(aTHX_  io, MARKER3_ARRAY);
                amf3_format_reference(aTHX_  io, *OK);
            }
            else if (SvTYPE(rv) == SVt_PVHV){
                io_write_marker(aTHX_  io, MARKER3_OBJECT);
                amf3_format_reference(aTHX_  io, *OK);
            }
	    else if (sv_isobject(one) && util_is_date(rv)){
		io_write_marker(aTHX_ io, MARKER3_OBJECT ); //#TODO
		amf3_format_reference(aTHX_  io, *OK);
	    }
            else {
                io_register_error(io, ERR_BAD_OBJECT);
            }
        }
        else {
            sv_setiv(*OK, io->rc_object);
            (void) hv_store(io->hv_object, (char *) (&rv), sizeof (rv), newSViv(io->rc_object), 0);
            ++io->rc_object;

            if (SvTYPE(rv) == SVt_PVAV) 
		amf3_format_array(aTHX_  io, (AV*) rv);
            else if (SvTYPE(rv) == SVt_PVHV) {
                amf3_format_object(aTHX_  io, one);
            }
	    else if (sv_isobject( one ) && util_is_date( rv ) ){
		amf3_format_date(aTHX_ io, rv );
	    }
            else {
                io->message = "bad type of object in stream";
                io_register_error(io, ERR_BAD_OBJECT);
            }
        }
    }
    else {
        if (SvOK(one)){
	    #if defined( EXPERIMENT1 )
	    if ( (io->options & OPT_PREFER_NUMBER )){
		if (SvNIOK(one)){
		    if ( SvIOK( one ) ){
			amf3_format_integer(aTHX_ io, one );
		    }
		    else {
			amf3_format_double(aTHX_  io, one);
		    }
		}
		else {
		    amf3_format_string(aTHX_  io, one);
		}
	    }
	    else 
	    #endif
            if (SvPOK(one)) {
                amf3_format_string(aTHX_  io, one);
            } else 
            if (SvIOK(one)){
                amf3_format_integer(aTHX_  io, one);
            }
            else if (SvNOK(one)){
                amf3_format_double(aTHX_  io, one);
            }
	    else {
		io_register_error(io, ERR_BAD_OBJECT );
	    }
        }
        else {
            amf3_format_null(aTHX_  io);
        }
    }
}
typedef SV* (*parse_sub)(pTHX_ struct io_struct *io);


parse_sub parse_subs[] = {
    &parse_double,
    &parse_boolean,
    &parse_utf8,
    &parse_object,
    &parse_movieclip,
    &parse_null,
    &parse_undefined,
    &parse_reference,
    &parse_ecma_array,
    &parse_object_end,
    &parse_strict_array,
    &parse_date,
    &parse_long_string,
    &parse_unsupported,
    &parse_recordset,
    &parse_xml_document,
    &parse_typed_object
};

parse_sub amf3_parse_subs[] = {
    &amf3_parse_undefined,
    &amf3_parse_null,
    &amf3_parse_false,
    &amf3_parse_true,
    &amf3_parse_integer,
    &amf3_parse_double,
    &amf3_parse_string,
    &amf3_parse_xml_doc,
    &amf3_parse_date,
    &amf3_parse_array,
    &amf3_parse_object,
    &amf3_parse_xml,
    &amf3_parse_bytearray,
};

inline SV * amf3_parse_one(pTHX_ struct io_struct * io){
    unsigned char marker;

    marker = (unsigned char) io_read_marker(io);
    if (marker < ARRAY_SIZE( amf3_parse_subs )){
        return (amf3_parse_subs[marker])(aTHX_ io);
    }
    else {
        io_register_error(io, ERR_MARKER);
	return 0; // Never reach this statement
    }
}
STATIC_INLINE SV * parse_one(pTHX_ struct io_struct * io){
    unsigned char marker;
    marker = (unsigned char) io_read_marker(io);
    if ( marker < ARRAY_SIZE( parse_subs )){
        return (parse_subs[marker])(aTHX_ io);
    }
    else {
        return io_register_error(io, ERR_MARKER),(SV *)0;
    }
}
inline SV * deep_clone(pTHX_ SV * value);
inline AV * deep_array(pTHX_ AV* value){
    AV* copy =  (AV*) newAV();
    int c_len;
    int i;
    av_extend(copy, c_len = av_len(value));
    for(i = 0; i <= c_len; ++i){
        av_store(copy, i, deep_clone(aTHX_  *av_fetch(value, i, 0)));
    }
    return copy;
}

inline HV * deep_hash(pTHX_ HV* value){
    HV * copy =  (HV*) newHV();
    SV * key_value;
    char * key_str;
    I32 key_len;
    SV*	copy_val;

    hv_iterinit(value);
    while((key_value  = hv_iternextsv(value, &key_str, &key_len)) ){
        copy_val = deep_clone(aTHX_  key_value);
        (void) hv_store(copy, key_str, key_len, copy_val, 0);
    }
    return copy;
}

inline SV * deep_scalar(pTHX_ SV * value){
    return deep_clone(aTHX_  value);
}

inline SV * deep_clone(pTHX_ SV * value){
    if (SvROK(value)){
        SV * rv = (SV*) SvRV(value);
        SV * copy;
        if (SvTYPE(rv) == SVt_PVHV) {
            copy = newRV_noinc((SV*)deep_hash(aTHX_  (HV*) rv));
        }
        else if (SvTYPE(rv) == SVt_PVAV) {
            copy = newRV_noinc((SV*)deep_array(aTHX_  (AV*) rv));
        }
        else if (SvROK(rv)) {
            copy = newRV_noinc((SV*)deep_clone(aTHX_  (SV*) rv));
        }
        else {
            // TODO: error checking
            //return newSV(0);
            copy = newRV_noinc(deep_clone(aTHX_  rv));
        }
        if (sv_isobject(value)) {
            HV * stash;
            stash = SvSTASH(rv);
            sv_bless(copy, stash);
        }
        return copy;
    }
    else {
        SV * copy;
        copy = newSV(0);
        if (SvOK(value)){
            sv_setsv(copy, value);
        }
        return copy;
    }
}
inline void ref_clear(pTHX_ HV * go_once, SV *sv){

    SV *ref_addr;
    if (! SvROK(sv))
    return;
    ref_addr = SvRV(sv);
    if (hv_exists(go_once, (char *) &ref_addr, sizeof (ref_addr)))
    return;
    (void) hv_store( go_once, (char *) &ref_addr, sizeof(ref_addr), &PL_sv_undef, 0);

    if (SvTYPE(ref_addr) == SVt_PVAV){
        AV * refarray = (AV*) ref_addr;
        int ref_len = av_len(refarray);
        int ref_index;
        for( ref_index = 0; ref_index <= ref_len; ++ref_index){
            SV ** ref_item = av_fetch( refarray, ref_index, 0);
            if (ref_item)
            ref_clear(aTHX_  go_once, *ref_item);
        }
        av_clear(refarray);
    }
    else if (SvTYPE(ref_addr) == SVt_PVHV){
        HV *ref_hash = (HV *) ref_addr;
        char *   key;
        I32  key_len;
        SV*  item;

        hv_iterinit(ref_hash);
        while( (item = hv_iternextsv(ref_hash, &key, &key_len)) ){
            ref_clear(aTHX_  go_once, item);
        };
        hv_clear(ref_hash);
    }
}    


MODULE = Storable::AMF0 PACKAGE = Storable::AMF0		

void 
dclone(SV * data)
    ALIAS:
	Storable::AMF::dclone= 1
	Storable::AMF3::dclone= 2
    PROTOTYPE: $
    INIT:
        SV* retvalue;
    PPCODE:
	PERL_UNUSED_VAR(ix);
        retvalue = deep_clone(aTHX_  data);
        sv_2mortal(retvalue);
        XPUSHs(retvalue);

void
thaw(SV *data, ...)
    ALIAS:
	Storable::AMF::thaw=1
    PROTOTYPE: $;$
    INIT:
        SV* retvalue;
        SV* io_self;
        struct io_struct io_record;
    PPCODE:
	PERL_UNUSED_VAR(ix);
        if (SvMAGICAL(data))
        mg_get(data);
        // sting options mode
        if (1 == items ){
            io_record.options = 0;
        }
        else {
            SV * opt = ST(1);
            if (! SvIOK(opt)){
                warn( "options are not integer" );
                return ;
            };
            io_record.options = SvIV(opt);
        };

        if (SvPOKp(data)){
            int error_code;
            if (SvUTF8(data)) {
                croak("Storable::AMF0::thaw(data, ...): data is in utf8. Can't process utf8");
            }else {
            };
            io_self = newRV_noinc((SV*)newAV());
            io_in_init(aTHX_  &io_record, io_self, data, AMF0);
            sv_2mortal(io_self);
            if ((error_code = Sigsetjmp(io_record.target_error, 0)) ){
                //croak("Failed parse string. unspected EOF");
                //TODO: ERROR CODE HANDLE
                if (io_record.options & OPT_RAISE_ERROR){
                    croak("Error at parse AMF0 (%d)", error_code);
                }
                else {
                    sv_setiv(ERRSV, error_code);
                    sv_setpvf(ERRSV, "Error at parse AMF0 (%d)", error_code);
                    SvIOK_on(ERRSV);
                }
                io_in_destroy(aTHX_  &io_record, 0); // all obects
            }
            else {
                retvalue = (SV*) (parse_one(aTHX_  &io_record));
                retvalue = sv_2mortal(retvalue);
                if (io_record.pos!=io_record.end){
                    if (io_record.options & OPT_RAISE_ERROR){
                        croak("EOF at parse AMF0 (%d)", ERR_EXTRA_BYTE);
                    }
                    else {
                        sv_setiv(ERRSV, ERR_EOF);
                        sv_setpvf(ERRSV, "EOF at parse AMF0 (%d)", ERR_EXTRA_BYTE);
                        SvIOK_on(ERRSV);
                    }                    
                    io_in_destroy(aTHX_  &io_record, 0); // all objects                    

                }
                else {
                    sv_setsv(ERRSV, &PL_sv_undef);
                    XPUSHs(retvalue);
                }
            }
        }
        else {
            croak("USAGE Storable::AMF0::thaw( $amf0). First arg must be string");
        }

void
deparse_amf(SV *data, ...)
    PROTOTYPE: $;$
    ALIAS:
	Storable::AMF::deparse_amf=1
    INIT:
        SV* retvalue;
        SV* io_self;
        struct io_struct io_record;
    PPCODE:
	PERL_UNUSED_VAR(ix);
        if (SvMAGICAL(data))
        mg_get(data);
        // sting options mode
        if (1 >= items ){
            io_record.options = 0;
        }
        else {
            SV * opt = ST(1);
            if (! SvIOK(opt)){
                warn( "options are not integer" );
                return ;
            };
            io_record.options = SvIV(opt);
        };

        if (SvPOKp(data)){
            int error_code;
            if (SvUTF8(data)) {
                croak("Storable::AMF0::deparse_amf(data, ...): data is in utf8. Can't process utf8");
            } else {
            };
            io_self = newRV_noinc((SV*)newAV());
            io_in_init(aTHX_  &io_record, io_self, data, AMF0);
            sv_2mortal(io_self);
            if ( !(error_code = Sigsetjmp(io_record.target_error, 0))){
                
                retvalue = (SV*) (parse_one(aTHX_  &io_record));
                retvalue = sv_2mortal(retvalue);
                sv_setsv(ERRSV, &PL_sv_undef);
                if (GIMME_V == G_ARRAY){
                    XPUSHs(retvalue);
                    XPUSHs( sv_2mortal(newSViv( io_record.pos - io_record.ptr )) );
                }
                else {
                    XPUSHs(retvalue);
                }
            }
            else {
                //croak("Failed parse string. unspected EOF");
                //TODO: ERROR CODE HANDLE
                if (io_record.options & OPT_RAISE_ERROR){
                    croak("Error at parse AMF0 (%d)", error_code);
                }
                else {
                    sv_setiv(ERRSV, error_code);
                    sv_setpvf(ERRSV, "Error at parse AMF0 (%d)", error_code);
                    SvIOK_on(ERRSV);
                }
                io_in_destroy(aTHX_  &io_record, 0); // all obects

            }
        }
        else {
            croak("USAGE Storable::AMF0::deparse( $amf0). First arg must be string");
        }



void freeze(SV *data, ... )
    ALIAS:
	Storable::AMF::freeze=1
    PROTOTYPE: $;$
    INIT:
        SV * retvalue;
        SV * io_self;
        struct io_struct io_record;
        int error_code;
    PPCODE:
	PERL_UNUSED_VAR(ix);        //#io_self= newSVpvn("",0);
        io_self= newSV(0);
        sv_2mortal(io_self);
        io_out_init(aTHX_  &io_record, 0, AMF0);
        if (1 == items){
            io_record.options = DEFAULT_MASK;
        }
        else {
            SV * opt = ST(1);
            if (! SvIOK(opt)){
                warn( "invalid options." );
                return ;
            };
            io_record.options = SvIV(opt);
        };
        if (!(error_code = Sigsetjmp(io_record.target_error, 0))){
            format_one(aTHX_  &io_record, data);
            retvalue = sv_2mortal(io_buffer(&io_record));
            XPUSHs(retvalue);
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        else{
            sv_setiv(ERRSV, error_code);
            sv_setpvf(ERRSV, "failed format to AMF0(code %d)", error_code);
            SvIOK_on(ERRSV);
        }


MODULE = Storable::AMF0		PACKAGE = Storable::AMF3		

void
deparse_amf(data, ...)
    SV * data
    PROTOTYPE: $;$
    INIT:
        SV* retvalue;
        SV* io_self;
        struct io_struct io_record;
    PPCODE:

        if (SvMAGICAL(data))
        mg_get(data);
        // Steting options mode
        if (1 == items){
            io_record.options = 0;
        }
        else {
            SV * opt = ST(1);
            if (! SvIOK(opt)){
                warn( "invalid options: " );
                return ;
            };
            io_record.options = SvIV(opt);
        };

        if (SvPOKp(data)){
            int error_code;
            if (SvUTF8(data)) {
                croak("Storable::AMF0::deparse_amf(data, ...): data is in utf8. Can't process utf8");
            }
            io_self = newRV_noinc((SV*)newAV());
            io_in_init(aTHX_  &io_record, io_self, data, AMF3);
            sv_2mortal(io_self);
            if ( ! (error_code = Sigsetjmp(io_record.target_error, 0))){
                retvalue = (SV*) (amf3_parse_one(aTHX_  &io_record));
                sv_2mortal(retvalue);
                sv_setsv(ERRSV, &PL_sv_undef);

                if (GIMME_V == G_ARRAY){
                    XPUSHs(retvalue);
                    XPUSHs( sv_2mortal(newSViv( io_record.pos - io_record.ptr )) );
                }
                else {
                    XPUSHs(retvalue);
                }
            }
            else {
                if (io_record.options & OPT_RAISE_ERROR){
                    croak("Error at parse AMF0 (%d)", error_code);
                }
                else {
                    sv_setiv(ERRSV, error_code);
                    sv_setpvf(ERRSV, "AMF3 parse failed. (%d)", error_code);
                    SvIOK_on(ERRSV);
                }

                io_in_destroy(aTHX_  &io_record, 0);

            }
        }
        else {
            croak("USAGE Storable::AMF3::deparse_amf( $amf3). First arg must be string");
        }

void
thaw(data, ...)
    SV * data
    PROTOTYPE: $;$
    INIT:
        SV* retvalue;
        SV* io_self;
        struct io_struct io_record;
    PPCODE:

        if (SvMAGICAL(data))
        mg_get(data);
        // Steting options mode
        if (1 == items){
            io_record.options = DEFAULT_MASK;
        }
        else {
            SV * opt = ST(1);
            if (! SvIOK(opt)){
                sv_dump(opt);
                warn( "options are not integer" );
                return ;
            };
            io_record.options = SvIV(opt);
        };

        if (SvPOKp(data)){
            int error_code;
            if (SvUTF8(data)) {
                croak("Storable::AMF3::thaw(data, ...): data is in utf8. Can't process utf8");
            }
            io_self = newRV_noinc((SV*)newAV());
            io_in_init(aTHX_  &io_record, io_self, data, AMF3);
            sv_2mortal(io_self);
            if ( ! (error_code = Sigsetjmp(io_record.target_error, 0))){
                retvalue = (SV*) (amf3_parse_one(aTHX_  &io_record));
                sv_2mortal(retvalue);
                if (io_record.pos!=io_record.end){
                    if (io_record.options & OPT_RAISE_ERROR){
                        croak("AMF3 thaw  failed. EOF at parse (%d)", ERR_EOF);
                    }
                    else {
                        sv_setiv(ERRSV, ERR_EOF);
                        sv_setpvf(ERRSV, "AMF3 thaw  failed. EOF at parse (%d)", ERR_EOF);
                        SvIOK_on(ERRSV);
                    }
                    io_in_destroy(aTHX_  &io_record, 0);                    
                }
                else {
                    sv_setsv(ERRSV, &PL_sv_undef);
                    XPUSHs(retvalue);
                };
            }
            else {
                if (io_record.options & OPT_RAISE_ERROR){
                    croak("Error at parse AMF3 (%d)", error_code);
                }
                else {
                    sv_setiv(ERRSV, error_code);
                    sv_setpvf(ERRSV, "AMF3 parse failed. (%d)", error_code);
                    SvIOK_on(ERRSV);
                }

                io_in_destroy(aTHX_  &io_record, 0);

            }
        }
        else {
            croak("USAGE Storable::AMF3::thaw( $amf3). First arg must be string");
        }

void 
endian()
    PPCODE:
    PerlIO_printf(PerlIO_stderr(), "%s %x\n", GAX, BYTEORDER);

void freeze(SV *data, int opts=DEFAULT_MASK)
    PROTOTYPE: $;$
    PREINIT:
        SV * retvalue;
        SV * io_self;
        struct io_struct io_record;
        int error_code;
    PPCODE:
        io_self= newSV(0);
        io_out_init(aTHX_  &io_record, 0, AMF3);
	io_record.options = opts;
        if (!(error_code = Sigsetjmp(io_record.target_error, 0))){
            amf3_format_one(aTHX_  &io_record, data);
            sv_2mortal(io_self);
            retvalue = sv_2mortal(io_buffer(&io_record));
            XPUSHs(retvalue);
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        else {

            //TODO: ERROR CODE HANDLE
            sv_setiv(ERRSV, error_code);
            sv_setpvf(ERRSV, "AMF3 format  failed. (Code %d)", error_code);
            SvIOK_on(ERRSV);
        }

void
new_amfdate(NV timestamp )
    PREINIT:
    SV *mortal;
    PROTOTYPE: $
    ALIAS:
	Storable::AMF::new_amfdate =1
	Storable::AMF0::new_amfdate=2
	Storable::AMF::new_date =3
	Storable::AMF0::new_date=4
	Storable::AMF3::new_date=5
    PPCODE:
	PERL_UNUSED_VAR( ix );
	mortal=sv_newmortal();
	sv_setref_nv( mortal, "*", timestamp ); //Stupid but it works
	XPUSHs( mortal );

void 
perl_date(SV *date)
    PREINIT:
    SV *mortal;
    PROTOTYPE: $
    ALIAS: 
	Storable::AMF::perl_date=1
	Storable::AMF0::perl_date=2
    PPCODE:
	PERL_UNUSED_VAR( ix );
	if ( SvROK( date ) && util_is_date( (SV*) SvRV(date))){
	    XPUSHs((SV*) SvRV(date));
	}
	else if ( SvNOK( date )){
	    mortal = sv_newmortal();
	    sv_setnv( mortal, SvNV( date ));
	    XPUSHs(mortal);
	}
	else {
	    croak("Expecting perl/amf date as argument" );
	}

void
parse_option(char * s, int options=0)
    PREINIT: 
    I8 s_strict;
    I8 s_utf8_decode;
    I8 s_utf8_encode;
    I8 s_milldate;
    I8 s_raise_error;
    I8 s_prefer_number;
    I8 sign;
    char *word;
    char *current;
    bool error;
    PROTOTYPE: $;$
    ALIAS:
    Storable::AMF::parse_option=1
    Storable::AMF0::parse_option=2
    Storable::AMF::parse_serializator_option=3
    Storable::AMF3::parse_serializator_option=4
    Storable::AMF0::parse_serializator_option=5
    PPCODE:
    PERL_UNUSED_VAR( ix );
    s_strict = 0;
    s_utf8_decode = 0;
    s_utf8_encode = 0;
    s_milldate    = 0;
    s_raise_error = 0;
    s_prefer_number = 0;
    options       = 0;
    current = s;
    for( ;*current && ( !isALPHA( *current ) && *current!='+' && *current!='-' ) ; ++current ); 

    word = current;
    while( *word ){
	++current;
	error = 0;
	sign  = 1;
	if ( *word == '+' ){
	    ++word;
	}
	else if ( *word =='-' ){
	    sign = -1;
	    ++word;
	}
	for( ; *current && ( isALNUM( *current ) || *current == '_' ); ++current );
	switch( current - word ){
	case 6:
	    if (!strncmp("strict", word, 6)){
		s_strict = sign;
	    }
	    else {
		error = 1;
	    };
	    break;
	case 11:
	    if (!strncmp( "utf8_decode", word, 11)){
		s_utf8_decode = sign;
	    }
	    else if (!strncmp( "utf8_encode", word, 11)){
		s_utf8_encode = sign;
	    }
	    else if (!strncmp("raise_error", word, 9)){
		s_raise_error=sign;
	    }
	    else {
		error = 1;
	    }
	    break;
	case 13:
	    if (!strncmp( "prefer_number", word, 13)){
		s_prefer_number = sign;
	    }
	    else {
		error = sign;
	    };
	    break;
	case   16:
	    if (!strncmp("millisecond_date", word, 16)){
		s_milldate = sign;
	    }
	    else 
		error = 1;
	    break;
	default:
	    error = 1;
	};
	if (error)
	    croak("Storable::AMF0::parse_option: unknown option '%.*s'", current - word, word);

	for(; *current && !isALPHA(*current) && *current!='+' && *current!='-'; ++current);
	word = current;
    };	
    SIGN_BOOL_APPLY( options, s_strict,   OPT_STRICT );
    SIGN_BOOL_APPLY( options, s_milldate, OPT_MILLSEC_DATE );
    SIGN_BOOL_APPLY( options, s_utf8_decode, OPT_DECODE_UTF8 );
    SIGN_BOOL_APPLY( options, s_utf8_encode, OPT_ENCODE_UTF8 );
    SIGN_BOOL_APPLY( options, s_raise_error, OPT_RAISE_ERROR );
    SIGN_BOOL_APPLY( options, s_prefer_number, OPT_PREFER_NUMBER );
    mXPUSHi(  options ); 
	
MODULE=Storable::AMF
