#include <klib.h>
#include <stdint.h>

extern uintptr_t vadd_once(const uint8_t *a, const uint8_t *b, uint8_t *result);
extern const char vadd_target[];

int main(void) {
  static const uint8_t a[4] __attribute__((aligned(4))) = {0x2c, 0x2d, 0xba, 0xba};
  static const uint8_t b[4] __attribute__((aligned(4))) = {0x23, 0x25, 0xfe, 0xca};
  static uint8_t result[4] __attribute__((aligned(4))) = {0xff, 0xff, 0xff, 0xff};

  printf("vadd.vv test: SEW=8, LMUL=1, requested VL=2\n");
  printf("vadd_target PC: %p\n", (void *)vadd_target);
  uintptr_t vl = vadd_once(a, b, result);

  /* Check active elements and that the store leaves the other bytes intact. */
  if (vl != 2 || result[0] != 0x4f || result[1] != 0x52 ||
      result[2] != 0xff || result[3] != 0xff) {
    printf("FAIL: VL=%d, result=%x %x %x %x\n", (int)vl,
           result[0], result[1], result[2], result[3]);
    return 1;
  }
  printf("PASS: VL=2, result=4f 52 ff ff\n");
  return 0;
}
