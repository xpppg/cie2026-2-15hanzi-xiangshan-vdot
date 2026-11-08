#include <klib.h>
#include <stdint.h>

#define ELEMENTS (16 * BENCH_LMUL)
#define SAMPLES 3
extern void fill_vectors(int8_t *, int8_t *, intptr_t, intptr_t);
extern uintptr_t dot_workload(const int8_t *, const int8_t *, uint32_t *,
                              uintptr_t, uintptr_t, uintptr_t);
static int8_t a[BLOCKS][ELEMENTS] __attribute__((aligned(64)));
static int8_t b[BLOCKS][ELEMENTS] __attribute__((aligned(64)));
static uint32_t out[BLOCKS][4] __attribute__((aligned(64)));
static int32_t expected[BLOCKS];
static uintptr_t times[2][SAMPLES];
static unsigned checks;

static void prepare(void) {
  uint32_t rng = 1;
  for (unsigned n = 0; n < BLOCKS; ++n) {
    rng = rng * 1664525u + 1013904223u;
    int base = (int8_t)(rng >> 24);
    rng = rng * 1664525u + 1013904223u;
    int value = (int8_t)(rng >> 24);
    fill_vectors(a[n], b[n], base, value);
    // a[i] = signed INT8(base+i), b[i] = value.
    int wrapped = base + ELEMENTS - 128;
    if (wrapped < 0) wrapped = 0;
    int sum = ELEMENTS * base + ELEMENTS * (ELEMENTS - 1) / 2 - 256 * wrapped;
    expected[n] = sum * value;
  }
}

static int run(unsigned mode, unsigned repeats, uintptr_t *cycles) {
  for (unsigned n = 0; n < BLOCKS; ++n)
    for (unsigned i = 0; i < 4; ++i) out[n][i] = 0xdeadbeef;
  *cycles = dot_workload(a[0], b[0], out[0], BLOCKS, repeats, mode);
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
  printf("SCALE lmul=%u blocks=%u repeats=%u samples=3 elements=%u seed=1\n",
         BENCH_LMUL, BLOCKS, REPEATS, ELEMENTS);
  uintptr_t warm;
  for (unsigned mode = 0; mode < 2; ++mode)
    if (run(mode, 1, &warm)) return 1;
  for (unsigned sample = 0; sample < SAMPLES; ++sample)
    for (unsigned order = 0; order < 2; ++order) {
      unsigned mode = (sample + order) % 2;
      if (run(mode, REPEATS, &times[mode][sample])) return 1;
    }
  for (unsigned sample = 0; sample < SAMPLES; ++sample)
    for (unsigned mode = 0; mode < 2; ++mode)
      printf("WORKLOAD_RESULT mode=%u sample=%u dots=%u cycles=%lu\n",
             mode, sample, BLOCKS * REPEATS, (unsigned long)times[mode][sample]);
  printf("PASS: vdot-scale %u full-vector checks\n", checks);
  return 0;
}
