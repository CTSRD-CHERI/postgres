/* intentionally no include guards, should only be included by atomics.h */
#ifndef INSIDE_ATOMICS_H
#error "should be included via atomics.h"
#endif

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

// XXXAR: atomic_readandset is not an exchange! instead it does an or with xchg_
// #define PG_HAVE_ATOMIC_EXCHANGE_U32
// static inline uint32
// pg_atomic_exchange_u32_impl(volatile pg_atomic_uint32 *ptr, uint32 xchg_)
// {
// 	return atomic_readandset_32(&ptr->value, xchg_);
// }
//
// #define PG_HAVE_ATOMIC_EXCHANGE_U64
// static inline uint64
// pg_atomic_exchange_u64_impl(volatile pg_atomic_uint64 *ptr, uint64 xchg_)
// {
// 	return atomic_readandset_64(&ptr->value, xchg_);
// }

#define PG_HAVE_ATOMIC_FLAG_SUPPORT
typedef struct pg_atomic_flag
{
	volatile unsigned int value;
} pg_atomic_flag;

#define PG_HAVE_ATOMIC_TEST_SET_FLAG
static inline bool
pg_atomic_test_set_flag_impl(volatile pg_atomic_flag *ptr)
{
	return atomic_cmpset_acq_32(&ptr->value, 0, 1) != 0;
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

/*
 * XXXAR: we can't use the implementation from machine/atomic.h because
 * that only sets the old value on failure, but postgres expects it to always
 * be set! I have no idea why that is different because on success it should
 * be the same so there is no point storing it....
 */
static inline uint32_t
pg_atomic_fcmpset_32(__volatile uint32_t *p, uint32_t *cmpval, uint32_t newval)
{
	uint32_t ret;
#ifndef __CHERI_PURE_CAPABILITY__
	__asm __volatile (
		"1:\n\t"
		"ll	%0, %1\n\t"		/* load old value */
		"bne	%0, %4, 2f\n\t"		/* compare */
		"move	%0, %3\n\t"		/* value to store */
		"sc	%0, %1\n\t"		/* attempt to store */
		"beqz	%0, 1b\n\t"		/* if it failed, spin */
		"j	3f\n\t"
		"2:\n\t"
		"li	%0, 0\n\t"
		"3:\n\t"
		"sw	%0, %2\n"		/* save old value */
		: "=&r" (ret), "+m" (*p), "=m" (*cmpval)
		: "r" (newval), "r" (*cmpval)
		: "memory");
#else
	uint32_t tmp;
	uint32_t expected = *cmpval;
	__asm __volatile (
		"1:\n\t"
		"cllw	%[old], %[ptr]\n\t"		/* load old value */
		"bne	%[old], %[expected], 2f\n\t"	/* compare */
		"nop\n\t"				/* branch delay slot */
		"cscw	%[ret], %[newval], %[ptr]\n\t"	/* attempt to store */
		"beqz	%[ret], 1b\n\t"			/* if it failed, spin */
		"j	3f\n\t"
		"2:\n\t"
		"li	%[ret], 0\n\t"
		"3:\n\t"
		"csw	%[old], $0, 0(%[cmpval])\n"	/* store loaded value */
		: [ret] "=&r" (ret), [old] "=&r" (tmp), [ptr]"+C" (p),
		    [cmpval]"+C" (cmpval)
		: [newval] "r" (newval), [expected] "r" (expected)
		: "memory");
#endif
	return ret;
}

static inline uint64_t
pg_atomic_fcmpset_64(__volatile uint64_t *p, uint64_t *cmpval, uint64_t newval)
{
	uint64_t ret;

#ifndef __CHERI_PURE_CAPABILITY__
	__asm __volatile (
		"1:\n\t"
		"lld	%0, %1\n\t"		/* load old value */
		"bne	%0, %4, 2f\n\t"		/* compare */
		"move	%0, %3\n\t"		/* value to store */
		"scd	%0, %1\n\t"		/* attempt to store */
		"beqz	%0, 1b\n\t"		/* if it failed, spin */
		"j	3f\n\t"
		"2:\n\t"
		"li	%0, 0\n\t"
		"3:\n\t"
		"sd	%0, %2\n"		/* save old value */
		: "=&r" (ret), "+m" (*p), "=m" (*cmpval)
		: "r" (newval), "r" (*cmpval)
		: "memory");
#else
	uint64_t tmp;
	uint64_t expected = *cmpval;

	__asm __volatile (
		"1:\n\t"
		"cld	%[old], $0, 0(%[cmpval])\n\t"	/* get expected value */
		"clld	%[old], %[ptr]\n\t"		/* load old value */
		"bne	%[old], %[expected], 2f\n\t"	/* compare */
		"nop\n\t"				/* branch delay slot */
		"cscd	%[ret], %[newval], %[ptr]\n\t"	/* attempt to store */
		"beqz	%[ret], 1b\n\t"			/* if it failed, spin */
		"j	3f\n\t"
		"2:\n\t"
		"li	%[ret], 0\n\t"
		"3:\n\t"
		"csd	%[old], $0, 0(%[cmpval])\n"	/* store loaded value */
		: [ret] "=&r" (ret), [old] "=&r" (tmp), [ptr]"+C" (p),
		    [cmpval]"+C" (cmpval)
		: [newval] "r" (newval), [expected] "r" (expected)
		: "memory");
#endif
	return ret;
}

/* Use the slow fallback code for now (atomic_fcmpset() is not implemented for CHERI) */
#define PG_HAVE_ATOMIC_COMPARE_EXCHANGE_U32
static inline bool pg_atomic_compare_exchange_u32_impl(volatile pg_atomic_uint32 *ptr, uint32 *expected, uint32 newval) {
	return pg_atomic_fcmpset_32(&ptr->value, expected, newval) != 0;
}

#define PG_HAVE_ATOMIC_COMPARE_EXCHANGE_U64
static inline bool pg_atomic_compare_exchange_u64_impl(volatile pg_atomic_uint64 *ptr, uint64 *expected, uint64 newval) {
	return pg_atomic_fcmpset_64(&ptr->value, expected, newval) != 0;
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
	atomic_store_rel_64(&ptr->value, val);
}

#define PG_HAVE_ATOMIC_READ_U64
static inline uint64
pg_atomic_read_u64_impl(volatile pg_atomic_uint64 *ptr)
{
	return atomic_load_acq_64(&ptr->value);
}

#define PG_HAVE_ATOMIC_FETCH_OR_U32
static inline uint32
pg_atomic_fetch_or_u32_impl(volatile pg_atomic_uint32 *ptr, uint32 or_) {
	return atomic_readandset_32(&ptr->value, or_);
}

#define PG_HAVE_ATOMIC_FETCH_OR_U64
static inline uint64
pg_atomic_fetch_or_u64_impl(volatile pg_atomic_uint64 *ptr, uint64 or_) {
	return atomic_readandset_64(&ptr->value, or_);
}
