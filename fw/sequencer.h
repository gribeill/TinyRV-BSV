#ifndef SEQUENCER
#define SEQUENCER

// ============================================================================
//  Waveform Commands (not time-amplitude pairs)


#define wfm_play(addr, count, ret) \
{ __asm__  ("wfmplay %0,%1,%2" : "=r" (ret) : "r" (addr), "r" (count)); }
#define wfm_fetch(addr, count, ret) \
{ __asm__  ("wfmftch %0,%1,%2" : "=r" (ret) : "r" (addr), "r" (count)); }
#define wfm_wait(addr, count, ret) \
{ __asm__  ("wfmwait %0,%1,%2" : "=r" (ret) : "r" (addr), "r" (count)); }

// ============================================================================
//  Waveform Commands (time-amplitude pairs)

#define wfm_ta_play(addr, count, ret) \
{ __asm__  ("wfmtaplay %0,%1,%2" : "=r" (ret) : "r" (addr), "r" (count)); }
#define wfm_ta_fetch(addr, count, ret) \
{ __asm__  ("wfmtaftch %0,%1,%2" : "=r" (ret) : "r" (addr), "r" (count)); }
#define wfm_ta_wait(addr, count, ret) \
{ __asm__  ("wfmwait %0,%1,%2" : "=r" (ret) : "r" (addr), "r" (count)); }

// ============================================================================
//  Marker Commands

#define marker_play_high(align, count, ret) \
{ __asm__  ("mrkplayhi %0,%1,%2" : "=r" (ret) : "r" (align), "r" (count)); }
#define marker_fetch_high(align, count, ret) \
{ __asm__  ("mrkftchhi %0,%1,%2" : "=r" (ret) : "r" (align), "r" (count)); }
#define marker_wait_high(align, count, ret) \
{ __asm__  ("mrkwaithi %0,%1,%2" : "=r" (ret) : "r" (align), "r" (count)); }
#define marker_play_low(align, count, ret) \
{ __asm__  ("mrkplaylo %0,%1,%2" : "=r" (ret) : "r" (align), "r" (count)); }
#define marker_fetch_low(align, count, ret) \
{ __asm__  ("mrkftchlo %0,%1,%2" : "=r" (ret) : "r" (align), "r" (count)); }
#define marker_wait_low(align, count, ret) \
{ __asm__  ("mrkwaitlo %0,%1,%2" : "=r" (ret) : "r" (align), "r" (count)); }

// ============================================================================
//  Modulate Commands

#define mod_set_phase(nco, phase, ret) \
{ val = phase; \   __asm__  ("mrkplay %0,%1,%2" : "=r" (ret) : "r" (nco), "r" (val)); \
}
#define mod_set_freq(nco, freq, ret) \
{ incr = freq; \   __asm__  ("mrkftch %0,%1,%2" : "=r" (ret) : "r" (nco), "r" (incr)); \
}
#define mod_update_frame(nco, phase, ret) \
{ val = phase; \   __asm__  ("mrkwait %0,%1,%2" : "=r" (ret) : "r" (nco), "r" (val)); \
}

// ============================================================================
//  Timing and synchronization

#define sync() \
{ __asm__  ("sync x0, x0, x0"); }
#define wait() \
{ __asm__  ("wait x0, x0, x0"); }

#endif