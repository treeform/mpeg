## ARM64 guarantees Advanced SIMD. Keep multiply and add separate to match
## the portable synthesis window's rounding and tap order.
{.localPassC: "-fno-fast-math -ffp-contract=off".}
{.emit: """
#include <arm_neon.h>
static void mpeg_synthesis_neon(const float *ring, const float *window,
                                int pos, float *samples) {
  float32x4_t sums[8];
  for (int i = 0; i < 8; ++i) sums[i] = vdupq_n_f32(0);
  int base = 512 - (pos >> 1), phase = (pos & 127) >> 1;
  for (int half = 0; half < 2; ++half) {
    int vb = half == 0 ? phase : 96 - phase;
    for (int tap = 0; tap < 8; ++tap) {
      int w = (base + half * 32 + tap * 64) & 511;
      int v = vb + tap * 128;
      for (int i = 0; i < 8; ++i)
        sums[i] = vaddq_f32(sums[i],
          vmulq_f32(vld1q_f32(window+w+i*4), vld1q_f32(ring+v+i*4)));
    }
  }
  for (int i = 0; i < 8; ++i) vst1q_f32(samples+i*4, sums[i]);
}
""".}
proc synthesisNeon(ring, window: ptr float32, pos: cint, samples: ptr float32)
  {.importc: "mpeg_synthesis_neon", nodecl, raises: [].}
proc synthesisWindowNeon*(ring: array[1024, float32],
    window: array[512, float32], vPos: int, samples: var array[32, float32]) =
  synthesisNeon(unsafeAddr ring[0], unsafeAddr window[0], cint(vPos), addr samples[0])

{.emit: """
void mpeg_rgba_neon(const unsigned char *y, const unsigned char *cb,
 const unsigned char *cr, unsigned char *dst, int width) {
 for(int x=0;x+8<=width;x+=8) {
  uint32_t uc,vc;
  __builtin_memcpy(&uc,cb+x/2,4); __builtin_memcpy(&vc,cr+x/2,4);
  uint8x8_t ub=vreinterpret_u8_u64(vcreate_u64(uc));
  uint8x8_t vb=vreinterpret_u8_u64(vcreate_u64(vc));
  int16x8_t u=vsubq_s16(vreinterpretq_s16_u16(vmovl_u8(vzip_u8(ub,ub).val[0])),vdupq_n_s16(128));
  int16x8_t v=vsubq_s16(vreinterpretq_s16_u16(vmovl_u8(vzip_u8(vb,vb).val[0])),vdupq_n_s16(128));
  int16x8_t yy=vsubq_s16(vreinterpretq_s16_u16(vmovl_u8(vld1_u8(y+x))),vdupq_n_s16(16));
  uint8x8x4_t out;
  int16x4_t rr[2],gg[2],bb[2];
  for(int h=0;h<2;h++) {
   int16x4_t uu=h?vget_high_s16(u):vget_low_s16(u);
   int16x4_t vv=h?vget_high_s16(v):vget_low_s16(v);
   int16x4_t yl=h?vget_high_s16(yy):vget_low_s16(yy);
   int32x4_t lum=vshrq_n_s32(vmulq_n_s32(vmovl_s16(yl),76309),16);
   int32x4_t r=vshrq_n_s32(vmulq_n_s32(vmovl_s16(vv),104597),16);
   int32x4_t b=vshrq_n_s32(vmulq_n_s32(vmovl_s16(uu),132201),16);
   int32x4_t g=vshrq_n_s32(vaddq_s32(vmulq_n_s32(vmovl_s16(uu),25674),vmulq_n_s32(vmovl_s16(vv),53278)),16);
   rr[h]=vmovn_s32(vaddq_s32(lum,r));
   gg[h]=vmovn_s32(vsubq_s32(lum,g));
   bb[h]=vmovn_s32(vaddq_s32(lum,b));
  }
  out.val[0]=vqmovun_s16(vcombine_s16(rr[0],rr[1]));
  out.val[1]=vqmovun_s16(vcombine_s16(gg[0],gg[1]));
  out.val[2]=vqmovun_s16(vcombine_s16(bb[0],bb[1]));
  out.val[3]=vdup_n_u8(255);
  vst4_u8(dst+x*4,out);
 }
}
""".}
proc opaqueRgbaRowNeon*(y, cb, cr, dest: ptr uint8, width: cint)
  {.importc: "mpeg_rgba_neon", raises: [].}
