#include <klib.h>
#include <stdint.h>

struct testcase {
  const char *name;
  unsigned op, vtype, vl, vxsat;
  uint8_t a[16] __attribute__((aligned(16)));
  uint8_t b[16], old[32], expected[32];
};
#include "build/cases.h"

extern uintptr_t vimac_case(const void *, const void *, const void *, void *,
                            uintptr_t, uintptr_t, uintptr_t, const void *);
extern uintptr_t vimac_dot_mixed(const void *, const void *, const void *, void *);
static uint8_t out[96] __attribute__((aligned(16)));
static const uint8_t mask[16] __attribute__((aligned(16))) = {
  0x55,0x55,0x55,0x55,0x55,0x55,0x55,0x55,
  0x55,0x55,0x55,0x55,0x55,0x55,0x55,0x55
};

int main(void) {
  unsigned count = sizeof(cases) / sizeof(cases[0]);
  for (unsigned n = 0; n < count; ++n) {
    const struct testcase *t = &cases[n];
    uintptr_t sat = vimac_case(t->a, t->b, t->old, out, t->vtype, t->vl, t->op, mask);
    if (sat != t->vxsat || memcmp(out, t->expected, 32)) {
      printf("FAIL: %s vxsat=%u expected=%u\n", t->name, (unsigned)sat, t->vxsat);
      for (unsigned i = 0; i < 32; ++i)
        if (out[i] != t->expected[i])
          printf("byte=%u expected=%x actual=%x\n", i, t->expected[i], out[i]);
      return 1;
    }
  }
  printf("PASS: VIMAC %u multiply/accumulate/widen/mask/saturate cases\n", count);
  uintptr_t sat = vimac_dot_mixed(mixed_a, mixed_b, mixed_old, out);
  if (sat != mixed_vxsat || memcmp(out, mixed_expected, sizeof(out))) {
    printf("FAIL: interleaved VIMAC/vdot vxsat=%u expected=%u\n", (unsigned)sat, mixed_vxsat);
    for (unsigned i = 0; i < sizeof(out); ++i)
      if (out[i] != mixed_expected[i])
        printf("byte=%u expected=%x actual=%x\n", i, mixed_expected[i], out[i]);
    return 1;
  }
  printf("PASS: interleaved vdot/vmul/vmacc/vsmul, 6 full vectors, sticky vxsat preserved\n");
  return 0;
}
