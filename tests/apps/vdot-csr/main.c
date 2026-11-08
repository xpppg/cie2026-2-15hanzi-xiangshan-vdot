#include <klib.h>
#include <stdint.h>

struct result {
  uint32_t word[4];
  uintptr_t start, vl, vtype, sat, rm;
};
extern void vdot_csr_case(const int8_t *, const int8_t *, const void *, struct result *,
                          uintptr_t, uintptr_t, uintptr_t, uintptr_t);
extern uintptr_t vdot_csr_illegal(const void *, struct result *, uintptr_t);
extern void vdot_csr_chain(const int8_t *, const int8_t *, uint32_t *);
extern void vdot_csr_group_chain(const int8_t *, const int8_t *, uint32_t *, const void *);
static int8_t a[128] __attribute__((aligned(16)));
static int8_t b[128] __attribute__((aligned(16)));
static const uint32_t old[4] __attribute__((aligned(16))) = {
  0x89abcdef, 0x01234567, 0x76543210, 0xfedcba98
};
static const uint8_t zero[128] __attribute__((aligned(16))) = {0};
static struct result out __attribute__((aligned(16)));
static uint32_t chain[12] __attribute__((aligned(16)));
static const unsigned enc[] = {5, 6, 7, 0, 1, 2, 3};
static const unsigned cap[] = {2, 4, 8, 16, 32, 64, 128};
static unsigned checks;
static uint32_t rng = 1;
static unsigned random_u32(void) { rng = rng * 1664525u + 1013904223u; return rng; }

static int run(unsigned lm, unsigned vl, unsigned variant, unsigned policy, unsigned flags) {
  int32_t sum = 0;
  int same = variant == 7 || variant == 8 || variant == 10;
  for (unsigned i = 0; i < vl; ++i)
    sum += (int32_t)a[i] * (same ? a[i] : b[i]);
  uint32_t expected[4] = {(uint32_t)sum, 0, 0, 0};
  if (!vl) {
    const void *initial = old;
    if (variant == 1 || variant == 8 || variant == 10) initial = a;
    if (variant == 2) initial = a + 112;
    if (variant == 3) initial = b;
    if (variant == 4) initial = b + 112;
    memcpy(expected, initial, 16);
  }
  memset(&out, 0x55, sizeof(out));
  unsigned vt = enc[lm] | (policy << 6);
  vdot_csr_case(a, b, old, &out, vl, vt, variant, flags);
  ++checks;
  if (memcmp(out.word, expected, 16) || out.start || out.vl != vl || out.vtype != vt ||
      out.sat != (flags & 1) || out.rm != ((flags >> 1) & 3)) {
    printf("FAIL #%u lmul=%u vl=%u variant=%u policy=%u\n", checks, enc[lm], vl, variant, policy);
    printf("expected=%x %x %x %x actual=%x %x %x %x\n",
           expected[0], expected[1], expected[2], expected[3],
           out.word[0], out.word[1], out.word[2], out.word[3]);
    printf("start=%u vl=%u vtype=%x sat=%u rm=%u\n", (unsigned)out.start,
           (unsigned)out.vl, (unsigned)out.vtype, (unsigned)out.sat, (unsigned)out.rm);
    return 1;
  }
  return 0;
}

int main(void) {
  for (unsigned i = 0; i < 128; ++i) { a[i] = (i % 16) + 1; b[i] = (i % 16) + 1; }
  if (run(3, 16, 0, 0, 0)) return 1;
  printf("PASS: positive INT8 dot, VL=16, result=1496 (0x000005d8)\n");
  for (unsigned i = 0; i < 128; ++i) a[i] = -((int)(i % 16) + 1);
  if (run(3, 16, 0, 0, 0)) return 1;
  printf("PASS: negative INT8 dot, VL=16, result=-1496 (0xfffffa28)\n");
  const int limits[][2] = {{127,127}, {-128,-128}, {-128,127}, {0,-128}};
  for (unsigned n = 0; n < 4; ++n) {
    for (unsigned i = 0; i < 128; ++i) { a[i] = limits[n][0]; b[i] = limits[n][1]; }
    if (run(6, 128, 0, 0, n)) return 1;
  }
  printf("PASS: boundary values, LMUL=8, VL=128, 4 checks\n");

#ifdef VDOT_BASIC_ONLY
  printf("PASS: vdot basic %u checks\n", checks);
  return 0;
#endif

  for (unsigned i = 0; i < 128; ++i) { a[i] = (int)i * 9 - 61; b[i] = 93 - (int)i * 7; }
  unsigned begin = checks;
#ifdef VDOT_EXTENDED
  for (unsigned lm = 0; lm < 7; ++lm)
    for (unsigned vl = 0; vl <= cap[lm]; ++vl)
      for (unsigned policy = 0; policy < 4; ++policy)
        if (run(lm, vl, 0, policy, (vl + policy) & 7)) return 1;
#else
  for (unsigned lm = 0; lm < 7; ++lm)
    for (unsigned length = 0; length < 3; ++length)
      for (unsigned policy = 0; policy < 4; ++policy)
        if (run(lm, length == 0 ? 0 : length == 1 ? 1 : cap[lm], 0, policy, (length + policy) & 7)) return 1;
  const unsigned edges[] = {15, 16, 17};
  for (unsigned lm = 4; lm < 7; ++lm) {
    for (unsigned i = 0; i < 3; ++i)
      if (run(lm, edges[i], 0, i & 3, i)) return 1;
    if (run(lm, cap[lm] - 1, 0, 3, 7)) return 1;
  }
  const unsigned single_edges[] = {7, 8, 9, 15};
  for (unsigned i = 0; i < 4; ++i)
    if (run(3, single_edges[i], 0, i, i)) return 1;
#endif
  printf("PASS: LMUL/VL boundaries, four policies and CSR preservation, %u checks\n", checks - begin);

  begin = checks;
#ifdef VDOT_EXTENDED
  for (unsigned lm = 0; lm < 7; ++lm)
    for (unsigned variant = 0; variant < 11; ++variant)
      for (unsigned length = 0; length < 3; ++length)
        for (unsigned policy = 0; policy < 4; ++policy)
          if (run(lm, length == 0 ? 0 : length == 1 ? 1 : cap[lm], variant, policy, variant & 7)) return 1;
#else
  const unsigned alias_lm[] = {3, 6};
  for (unsigned l = 0; l < 2; ++l)
    for (unsigned variant = 0; variant < 11; ++variant)
      for (unsigned full = 0; full < 2; ++full)
        if (run(alias_lm[l], full ? cap[alias_lm[l]] : 0, variant, variant & 3, variant & 7)) return 1;
  for (unsigned variant = 0; variant < 11; ++variant)
    if (run(0, 2, variant, variant & 3, variant & 7)) return 1;
#endif
  printf("PASS: register overlap, identical sources, v0/v31 and zero VL, %u checks\n", checks - begin);

  begin = checks;
#ifdef VDOT_EXTENDED
  const unsigned random_count = 256;
#else
  const unsigned random_count = 32;
#endif
  for (unsigned n = 0; n < random_count; ++n) {
    for (unsigned i = 0; i < 128; ++i) { a[i] = random_u32() >> 24; b[i] = random_u32() >> 24; }
    unsigned lm = random_u32() % 7;
    unsigned vl = random_u32() % (cap[lm] + 1);
    unsigned variant = random_u32() % 11;
    unsigned policy = random_u32() % 4;
    if (run(lm, vl, variant, policy, random_u32() & 7)) return 1;
  }
  printf("PASS: random signed inputs, %u checks\n", checks - begin);

  begin = checks;
  for (unsigned grouped = 0; grouped < 2; ++grouped) {
    int32_t first = 0, dependent = 0;
    unsigned n = grouped ? 128 : 16;
    for (unsigned i = 0; i < n; ++i) first += (int32_t)a[i] * b[i];
    for (unsigned i = 0; i < 4; ++i)
      dependent += (int32_t)(int8_t)((uint32_t)first >> (8 * i)) * (grouped ? b[i] : a[i]);
    if (grouped) vdot_csr_group_chain(a, b, chain, zero);
    else vdot_csr_chain(a, b, chain);
    for (unsigned v = 0; v < 3; ++v) {
      ++checks;
      if (chain[v * 4] != (uint32_t)(v == 2 ? dependent : first) ||
          chain[v * 4 + 1] || chain[v * 4 + 2] || chain[v * 4 + 3]) {
        printf("FAIL: dependent dots LMUL=%u result=%u\n", grouped ? 8 : 1, v);
        return 1;
      }
    }
  }
  printf("PASS: adjacent and dependent dots, LMUL=1/8, %u checks\n", checks - begin);

  begin = checks;
  for (unsigned kind = 0; kind < 13; ++kind) {
    memset(&out, 0x55, sizeof(out));
    uintptr_t cause = vdot_csr_illegal(old, &out, kind);
    uintptr_t start = kind == 4 ? 1 : kind == 5 ? 7 : kind == 6 ? 127 : 0;
    ++checks;
    if (cause != 2 || memcmp(out.word, old, 16) || out.start != start) {
      printf("FAIL: illegal kind=%u cause=%u start=%u\n", kind, (unsigned)cause, (unsigned)out.start);
      return 1;
    }
  }
  printf("PASS: isolated illegal encoding/configuration/state, %u checks\n", checks - begin);
  printf("PASS: vdot CSR %u checks\n", checks);
  return 0;
}
