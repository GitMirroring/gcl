#include "include.h"
#include "arth.h"

#define EMPTY()
#define DEFER(id) id EMPTY()

#define EVAL(...)     EVAL64(__VA_ARGS__)
#define EVAL64(...)   EVAL32(EVAL32(__VA_ARGS__))
#define EVAL32(...)   EVAL16(EVAL16(__VA_ARGS__))
#define EVAL16(...)   EVAL8(EVAL8(__VA_ARGS__))
#define EVAL8(...)    EVAL4(EVAL4(__VA_ARGS__))
#define EVAL4(...)    EVAL2(EVAL2(__VA_ARGS__))
#define EVAL2(...)    EVAL1(EVAL1(__VA_ARGS__))
#define EVAL1(...)    __VA_ARGS__

#define minus(a,b) M_ ## a ## _ ## b
#define MINUS(a,b) minus(a,b)
#define DEC(n) MINUS(n,1)

#define SECOND(a, b, ...) b
#define IS_ONE_PROXY(...) SECOND(__VA_ARGS__)
#define IS_ONE_1 ~, 1
#define IS_ONE_CHECK(n) IS_ONE_PROXY(Mjoin(IS_ONE_, n), 0)

#define GCNT_0(P,n,m) , DEFER(GCNT_ID)()(P,n,m)
#define GCNT_1(P,n,m) 
#define GCNT_ID() GCNT

#define GCNT(P,n,m) P(n,m) Mjoin(GCNT_,IS_ONE_CHECK(n))(P,DEC(n),m)
#define PPP1(n,m) object
#define PPP2(n,m) x[MINUS(m,n)]
#define CSTCL(m,n) case n*(MAX_ARGS+1)+m: return ((object (*)(GCNT(PPP1,m,m),...))f)(GCNT(PPP2,n,n));

#define OGCNT_0(P,n,m) DEFER(OGCNT_ID)()(P,n,m)
#define OGCNT_1(P,n,m) 
#define OGCNT_ID() OGCNT

#define OGCNT(P,n,m) P(n,m) Mjoin(OGCNT_,IS_ONE_CHECK(n))(P,DEC(n),m)
#define OWLK(m,n) OGCNT(CSTCL,m,m)

#define PGCNT_0(P,n,m) DEFER(PGCNT_ID)()(P,n,m)
#define PGCNT_1(P,n,m) 
#define PGCNT_ID() PGCNT

#define PGCNT(P,n,m) P(n,m) Mjoin(PGCNT_,IS_ONE_CHECK(n))(P,DEC(n),m)
#define IPGCNT(P,n) PGCNT(P,n,n)


static inline object
vc_apply_n(void *f, int n, object *x) {

  switch (n) {

    EVAL(IPGCNT(OWLK,MAX_ARGS))
    case 0*(MAX_ARGS+1)+1: return ((object (*)(object ,...))f)(OBJNULL);
    default: FEerror("vc bar ~s",1,make_fixnum(n));

  }

}

#define RCSTCL(m,n) case m: return ((object (*)(GCNT(PPP1,m,m)))f)(GCNT(PPP2,m,m));
#define PWLK(m,n) RCSTCL(m,m)

static inline object
rc_apply_n(void *f, int n, object *x) {

  switch (n) {

    EVAL(IPGCNT(PWLK,MAX_ARGS))
    case 0*(MAX_ARGS+1)+0: return ((object (*)())f)();
    default: FEerror("rc bar ~s",1,make_fixnum(n));

  }

}

static inline object
c_apply_n_fun(object fun,int n,object *b) {

  return fun->fun.fun_minarg<fun->fun.fun_maxarg ?
    vc_apply_n(fun->fun.fun_self,n*(MAX_ARGS+1)+(fun->fun.fun_minarg ? fun->fun.fun_minarg : 1),b) :
    rc_apply_n(fun->fun.fun_self,n,b);

}

object
quick_call_function_vec(object fun,ufixnum n,object *b) {

  return c_apply_n_fun(fun,n,b);

}
