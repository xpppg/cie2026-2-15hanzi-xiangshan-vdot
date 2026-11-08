#include <klib.h>
#include <stdint.h>

#define BLOCKS 128
#define REPEATS 2
#define SAMPLES 3

extern uintptr_t dot_workload(const int8_t *, const int8_t *, uint32_t *,
                              uintptr_t, uintptr_t, uintptr_t);
static int8_t a[BLOCKS][16] __attribute__((aligned(64)));
static int8_t b[BLOCKS][16] __attribute__((aligned(64)));
static uint32_t out[BLOCKS][4] __attribute__((aligned(64)));
static int32_t expected[BLOCKS];
static uintptr_t times[2][SAMPLES];
static unsigned checks;

static void prepare(void) {
  uint32_t rng = 1;
  const int pairs[][2] = {{127,127}, {-128,-128}, {-128,127}, {0,-128}};
  for (unsigned n = 0; n < BLOCKS; ++n) {
    for (unsigned i = 0; i < 16; ++i) {
      rng = rng * 1664525u + 1013904223u; a[n][i] = rng >> 24;
      rng = rng * 1664525u + 1013904223u; b[n][i] = rng >> 24;
    }
    for (unsigned i = 0; i < 16; ++i) {
      if (n == 0) { a[n][i] = i + 1; b[n][i] = i + 1; }
      else if (n == 1) { a[n][i] = -(int)(i + 1); b[n][i] = i + 1; }
      else if (n < 6) { a[n][i] = pairs[n - 2][0]; b[n][i] = pairs[n - 2][1]; }
    }
    expected[n] = 0;
    for (unsigned i = 0; i < 16; ++i)
      expected[n] += (int32_t)a[n][i] * (int32_t)b[n][i];
  }
}

static int run(unsigned mode, unsigned repeats, uintptr_t *cycles) {
  for (unsigned n = 0; n < BLOCKS; ++n)
    for (unsigned i = 0; i < 4; ++i) out[n][i] = 0xdeadbeef;
  *cycles = dot_workload(&a[0][0], &b[0][0], &out[0][0], BLOCKS, repeats, mode);
  for (unsigned n = 0; n < BLOCKS; ++n) {
    ++checks;
    if (out[n][0] != (uint32_t)expected[n] || out[n][1] || out[n][2] || out[n][3]) {
      printf("FAIL mode=%u block=%u expected=%x actual=%x %x %x %x\n",
             mode, n, (uint32_t)expected[n], out[n][0], out[n][1], out[n][2], out[n][3]);
      return 1;
    }
  }
  return 0;
}

int main(void) {
  prepare();
  printf("WORKLOAD blocks=%u repeats=%u samples=%u elements=16 seed=1\n", BLOCKS, REPEATS, SAMPLES);
  uintptr_t warm;
  for (unsigned mode = 0; mode < 2; ++mode)
    if (run(mode, 1, &warm)) return 1;
  printf("PASS: batch baseline and vdot warmup, %u input cases\n", BLOCKS);

  for (unsigned sample = 0; sample < SAMPLES; ++sample)
    for (unsigned order = 0; order < 2; ++order) {
      unsigned mode = (sample + order) % 2;
      if (run(mode, REPEATS, &times[mode][sample])) return 1;
    }

  for (unsigned sample = 0; sample < SAMPLES; ++sample)
    for (unsigned mode = 0; mode < 2; ++mode)
      printf("WORKLOAD_RESULT mode=%u sample=%u dots=%u cycles=%lu\n",
             mode, sample, BLOCKS * REPEATS, (unsigned long)times[mode][sample]);
  printf("PASS: vdot-bench %u full-vector checks\n", checks);
  return 0;
}
