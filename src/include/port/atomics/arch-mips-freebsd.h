#include <machine/atomic.h>

#define PG_HAVE_ATOMIC_U32_SUPPORT
typedef struct pg_atomic_uint32
{
	volatile uint32 value;
} pg_atomic_uint32;

#define PG_HAVE_ATOMIC_U64_SUPPORT
typedef struct pg_atomic_uint64
{
	volatile uint64 value pg_attribute_aligned(8);
} pg_atomic_uint64;

#define PG_HAVE_ATOMIC_EXCHANGE_U32
static inline uint32
pg_atomic_exchange_u32_impl(volatile pg_atomic_uint32 *ptr, uint32 xchg_)
{
	return atomic_readandset_32(&ptr->value, xchg_);
}

#define PG_HAVE_ATOMIC_EXCHANGE_U64
static inline uint64
pg_atomic_exchange_u64_impl(volatile pg_atomic_uint64 *ptr, uint64 xchg_)
{
	return atomic_readandset_64(&ptr->value, xchg_);
}

#define PG_HAVE_ATOMIC_FLAG_SUPPORT
typedef struct pg_atomic_flag
{
	volatile unsigned int value;
} pg_atomic_flag;

#define PG_HAVE_ATOMIC_TEST_SET_FLAG
static inline bool
pg_atomic_test_set_flag_impl(volatile pg_atomic_flag *ptr)
{
	return (bool)atomic_cmpset_32(&ptr->value, 0, 1);
}

#define PG_HAVE_ATOMIC_UNLOCKED_TEST_FLAG
static inline bool
pg_atomic_unlocked_test_flag_impl(volatile pg_atomic_flag *ptr)
{
	return ptr->value == 0;
}

#define PG_HAVE_ATOMIC_CLEAR_FLAG
static inline void
pg_atomic_clear_flag_impl(volatile pg_atomic_flag *ptr)
{
	atomic_store_rel_32(&ptr->value, 0);
}

#define PG_HAVE_ATOMIC_INIT_FLAG
static inline void
pg_atomic_init_flag_impl(volatile pg_atomic_flag *ptr)
{
	pg_atomic_clear_flag_impl(ptr);
}

#ifdef __CHERI_PURE_CAPABILITY__s
/* machine/atomic.h does not have a purecap implementation yet! */
static inline uint32_t
atomic_fcmpset_32_copy(__volatile uint32_t *p, uint32_t *cmpval, uint32_t newval)
{
	uint32_t ret;
	uint32_t tmp;
	uint32_t expected = *cmpval;

	__asm __volatile (
		"1:\n\t"
		"cllw	%[ret], %[ptr]\n\t"		/* load old value */
		"bne	%[ret], %[expected], 2f\n\t"	/* compare */
		"move	%[tmp], %[ret]\n\t"		/* save loaded value */
		"cscw	%[ret], %[newval], %[ptr]\n\t"	/* attempt to store */
		"beqz	%[ret], 1b\n\t"			/* if it failed, spin */
		"j	3f\n\t"
		"2:\n\t"
		"csw	%[tmp], $0, 0(%[cmpval])\n\t"	/* store loaded value */
		"li	%[ret], 0\n\t"
		"3:\n"
		: [ret] "=&r" (ret), [tmp] "=&r" (tmp), [ptr]"=C" (p),
		    [cmpval]"=C" (cmpval)
		: [newval] "r" (newval), [expected] "r" (expected)
		: "memory");
	return ret;
}

static inline uint64_t
atomic_fcmpset_64_copy(__volatile uint64_t *p, uint64_t *cmpval, uint64_t newval)
{
	uint64_t ret;
	uint64_t tmp;
	uint64_t expected = *cmpval;

	__asm __volatile (
		"1:\n\t"
		"clld	%[ret], %[ptr]\n\t"		/* load old value */
		"bne	%[ret], %[expected], 2f\n\t"	/* compare */
		"move	%[tmp], %[ret]\n\t"		/* save loaded value */
		"cscd	%[ret], %[newval], %[ptr]\n\t"	/* attempt to store */
		"beqz	%[ret], 1b\n\t"			/* if it failed, spin */
		"j	3f\n\t"
		"2:\n\t"
		"csd	%[tmp], $0, 0(%[cmpval])\n\t"	/* store loaded value */
		"li	%[ret], 0\n\t"
		"3:\n"
		: [ret] "=&r" (ret), [tmp] "=&r" (tmp), [ptr]"=C" (p),
		    [cmpval]"=C" (cmpval)
		: [newval] "r" (newval), [expected] "r" (expected)
		: "memory");
	return ret;
}
#endif

/* Use the slow fallback code for now (atomic_fcmpset() is not implemented for CHERI) */
#define PG_HAVE_ATOMIC_COMPARE_EXCHANGE_U32
static inline bool pg_atomic_compare_exchange_u32_impl(volatile pg_atomic_uint32 *ptr, uint32 *expected, uint32 newval) {
	return (bool)atomic_fcmpset_32_copy(&ptr->value, expected, newval);
}

#define PG_HAVE_ATOMIC_COMPARE_EXCHANGE_U64
static inline bool pg_atomic_compare_exchange_u64_impl(volatile pg_atomic_uint64 *ptr, uint64 *expected, uint64 newval) {
	return (bool)atomic_fcmpset_64_copy(&ptr->value, expected, newval);
}

#define PG_HAVE_ATOMIC_FETCH_ADD_U32
static inline uint32
pg_atomic_fetch_add_u32_impl(volatile pg_atomic_uint32 *ptr, int32 add_)
{
	return atomic_fetchadd_32(&ptr->value, add_);
}

#define PG_HAVE_ATOMIC_FETCH_ADD_U64
static inline uint64
pg_atomic_fetch_add_u64_impl(volatile pg_atomic_uint64 *ptr, int64 add_)
{
	return atomic_fetchadd_64(&ptr->value, add_);
}

/* XXXAR: should these also include a memory barrier? */

#define PG_HAVE_ATOMIC_WRITE_U64
static inline void
pg_atomic_write_u64_impl(volatile pg_atomic_uint64 *ptr, uint64 val)
{
	atomic_set_64(&ptr->value, val);
}

#define PG_HAVE_ATOMIC_READ_U64
static inline uint64
pg_atomic_read_u64_impl(volatile pg_atomic_uint64 *ptr)
{
	uint64_t ret;
	atomic_load_64(&ptr->value, &ret);
	return ret;
}

