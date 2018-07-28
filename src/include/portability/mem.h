/*-------------------------------------------------------------------------
 *
 * mem.h
 *	  portability definitions for various memory operations
 *
 * Copyright (c) 2001-2016, PostgreSQL Global Development Group
 *
 * src/include/portability/mem.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef MEM_H
#define MEM_H

#define IPCProtection	(0600)	/* access/modify by user only */

/* Ensure that PG_SHMAT_FLAGS contains the SHM_RND flag so that all requests are
 * nicely aligned. This makes a big difference for CHERI where we really rely on
 * aligned values so that we can store capabilities
 */
#ifdef SHM_RND
/*
 * CHERI CHANGES START
 * {
 *   "updated": 20180728,
 *   "changes": [
 *     "pointer_alignment",
 *   ],
 *   "change_comment": "Set SHM_RND to ensure the shmat() value is aligned to 4096",
 *   "hybrid_specific": false
 * }
 * CHERI CHANGES END
 */
#define PG_SHM_RND SHM_RND
#else
#define PG_SHM_RND 0
#endif


#ifdef SHM_SHARE_MMU			/* use intimate shared memory on Solaris */
#define PG_SHMAT_FLAGS			(SHM_SHARE_MMU | PG_SHM_RND)
#else
#define PG_SHMAT_FLAGS			(PG_SHM_RND)
#endif

/* Linux prefers MAP_ANONYMOUS, but the flag is called MAP_ANON on other systems. */
#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS			MAP_ANON
#endif

/* BSD-derived systems have MAP_HASSEMAPHORE, but it's not present (or needed) on Linux. */
#ifndef MAP_HASSEMAPHORE
#define MAP_HASSEMAPHORE		0
#endif

/*
 * BSD-derived systems use the MAP_NOSYNC flag to prevent dirty mmap(2)
 * pages from being gratuitously flushed to disk.
 */
#ifndef MAP_NOSYNC
#define MAP_NOSYNC			0
#endif

#define PG_MMAP_FLAGS			(MAP_SHARED|MAP_ANONYMOUS|MAP_HASSEMAPHORE)

/* Some really old systems don't define MAP_FAILED. */
#ifndef MAP_FAILED
#define MAP_FAILED ((void *) -1)
#endif

#endif   /* MEM_H */
