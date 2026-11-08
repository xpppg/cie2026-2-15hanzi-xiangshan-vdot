package xiangshan.backend.fu.vector

import chisel3._
import chisel3.util._
import chiseltest._
import chiseltest.simulator.VerilatorCFlags
import org.chipsalliance.cde.config.Parameters
import xiangshan._
import xiangshan.backend.fu.FuConfig.VimacCfg
import xiangshan.backend.fu.wrapper.VIMacU
import xiangshan.backend.decode._
import xiangshan.backend.fu.FuType
import xiangshan.backend.Bundles.DecodedInst
import xiangshan.backend.fu.vector.Bundles.VConfig
import yunsuan.VimacType

// Model the shared execution-unit pipeline around the real VIMAC.
class VDotCsrHarness(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val valid = Input(Bool())
    val a, b, old = Input(Vec(4, UInt(32.W)))
    val vl, start = Input(UInt(8.W))
    val idx = Input(UInt(6.W))
    val lmul = Input(UInt(3.W))
    val sew = Input(UInt(2.W))
    val vm, vill, ta, ma = Input(Bool())
    val op = Input(UInt(9.W))
    val outValid, illegal, sat = Output(Bool())
    val result = Output(Vec(4, UInt(32.W)))
  })
  val dut = Module(new VIMacU(VimacCfg))
  dut.io.in.bits := 0.U.asTypeOf(dut.io.in.bits)
  dut.io.in.valid := io.valid
  dut.io.out.ready := true.B
  dut.io.flush := 0.U.asTypeOf(dut.io.flush)
  dut.io.vxrm.get := 0.U
  dut.io.in.bits.ctrl.fuOpType := io.op
  val vc = dut.io.in.bits.ctrl.vpu.get
  vc.vm := io.vm; vc.vill := io.vill; vc.vta := io.ta; vc.vma := io.ma
  vc.vsew := io.sew; vc.vlmul := io.lmul; vc.vstart := io.start; vc.vuopIdx := io.idx
  dut.io.in.bits.data.src(0) := io.a.asUInt
  dut.io.in.bits.data.src(1) := io.b.asUInt
  dut.io.in.bits.data.src(2) := io.old.asUInt
  val config = WireInit(0.U.asTypeOf(new VConfig))
  config.vl := io.vl
  dut.io.in.bits.data.src(VimacCfg.vconfigIdx) := config.asUInt
  for (i <- 0 to 2) {
    dut.io.in.bits.ctrlPipe.get(i) := ShiftRegister(dut.io.in.bits.ctrl, i)
    dut.io.in.bits.dataPipe.get(i) := ShiftRegister(dut.io.in.bits.data, i)
    dut.io.in.bits.validPipe.get(i) := ShiftRegister(io.valid, i, false.B, true.B)
  }
  io.outValid := dut.io.out.valid
  io.result := dut.io.out.bits.res.data.asTypeOf(io.result)
  io.illegal := dut.io.out.bits.ctrl.exceptionVec.get(ExceptionNO.illegalInstr)
  io.sat := dut.io.out.bits.res.vxsat.get
}

class VDotDecodeHarness(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val valid = Input(Bool())
    val lmul = Input(UInt(3.W))
    val sew = Input(UInt(2.W))
    val start = Input(UInt(8.W))
    val vm, vill = Input(Bool())
    val a, b, dest = Input(UInt(5.W))
    val count = Output(UInt(7.W))
    val illegal = Output(Bool())
    val outs = Output(Vec(p(XSCoreParamsKey).RenameWidth, new Bundle {
      val uopIdx = UInt(7.W)
      val lsrc = Vec(3, UInt(6.W))
      val ldest = UInt(6.W)
      val illegal = Bool()
    }))
    val validOut = Output(Vec(p(XSCoreParamsKey).RenameWidth, Bool()))
  })
  val info = Module(new UopInfoGen)
  info.io.in.preInfo := 0.U.asTypeOf(info.io.in.preInfo)
  info.io.in.preInfo.isVecArith := true.B
  info.io.in.preInfo.typeOfSplit := UopSplitType.VEC_DOT
  info.io.in.preInfo.vlmul := io.lmul
  info.io.in.preInfo.vsew := io.sew
  val decoded = WireInit(0.U.asTypeOf(new DecodedInst))
  decoded.instr := Cat(0.U(6.W), io.vm, io.b, io.a, 0.U(3.W), io.dest, "b0001011".U(7.W))
  decoded.fuType := FuType.vimac.U
  decoded.fuOpType := VimacType.vdot
  decoded.uopSplitType := UopSplitType.VEC_DOT
  decoded.srcType.foreach(_ := SrcType.vp)
  decoded.vecWen := true.B
  decoded.vpu.vsew := io.sew; decoded.vpu.vlmul := io.lmul
  decoded.vpu.vill := io.vill; decoded.vpu.vstart := io.start; decoded.vpu.vm := io.vm
  val exc = Module(new VecExceptionGen)
  exc.io.inst := decoded.instr; exc.io.decodedInst := decoded
  exc.io.vtype := decoded.vpu.vtype; exc.io.vstart := io.start
  io.illegal := exc.io.illegalInst
  io.count := info.io.out.uopInfo.numOfUop
  val comp = Module(new DecodeUnitComp)
  comp.io.in.valid := io.valid
  comp.io.in.bits.simpleDecodedInst := decoded
  comp.io.in.bits.uopInfo := info.io.out.uopInfo
  comp.io.redirect := false.B
  comp.io.csrCtrl := 0.U.asTypeOf(comp.io.csrCtrl)
  comp.io.vtypeBypass := 0.U.asTypeOf(comp.io.vtypeBypass)
  comp.io.out.complexDecodedInsts.zipWithIndex.foreach { case (out, i) =>
    out.ready := true.B
    io.outs(i).uopIdx := out.bits.uopIdx
    io.outs(i).lsrc := VecInit(out.bits.lsrc.take(3))
    io.outs(i).ldest := out.bits.ldest
    io.outs(i).illegal := out.bits.exceptionVec(ExceptionNO.illegalInstr)
    io.validOut(i) := out.valid && comp.io.complexNum =/= 0.U
  }
}

class VDotCsrTest extends XSTester {
  private val testConfig = config.alterPartial {
    case utility.LogUtilsOptionsKey => utility.LogUtilsOptions(false, false, false)
  }
  // chiseltest 6 uses the old WData name; recent Verilator calls it EData.
  // Expose wide values as 32-bit ports to avoid its removed VlWide pointer cast.
  private val simAnnotations = Seq(VerilatorBackendAnnotation,
    VerilatorCFlags(Seq("-DWData=EData")))
  private def poke128(port: Vec[UInt], value: BigInt): Unit =
    port.zipWithIndex.foreach { case (word, i) => word.poke(((value >> (32 * i)) & mask32).U) }
  private def expect128(port: Vec[UInt], value: BigInt): Unit =
    port.zipWithIndex.foreach { case (word, i) => word.expect(((value >> (32 * i)) & mask32).U) }
  private val mask32 = (BigInt(1) << 32) - 1
  private def packed(xs: Seq[Int]): BigInt = xs.zipWithIndex.map { case (v, i) =>
    BigInt(v & 255) << (8 * i)
  }.foldLeft(BigInt(0))(_ | _)

  it should "honor vl and LMUL, preserve vl=0, and retain ordinary multiplication" in {
    test(new VDotCsrHarness()(testConfig)).withAnnotations(simAnnotations) { d =>
      d.io.valid.poke(false.B); d.io.vm.poke(true.B); d.io.vill.poke(false.B)
      d.io.sew.poke(0.U); d.io.start.poke(0.U); d.io.idx.poke(0.U); d.io.lmul.poke(0.U)
      d.io.ta.poke(false.B); d.io.ma.poke(false.B)
      poke128(d.io.a, 0); poke128(d.io.b, 0); poke128(d.io.old, 0); d.io.vl.poke(0.U)
      d.io.op.poke(VimacType.vdot); d.clock.step(3)
      def issue(a: BigInt, b: BigInt, old: BigInt, vl: Int, idx: Int,
                expected: BigInt, illegal: Boolean = false): Unit = {
        poke128(d.io.a, a); poke128(d.io.b, b); poke128(d.io.old, old)
        d.io.vl.poke(vl.U); d.io.idx.poke(idx.U); d.io.valid.poke(true.B)
        d.clock.step(); d.io.valid.poke(false.B); d.clock.step()
        d.io.outValid.expect(true.B); d.io.illegal.expect(illegal.B)
        if (!illegal) expect128(d.io.result, expected)
        d.io.sat.expect(false.B); d.clock.step()
      }
      val rng = new scala.util.Random(20261108L)
      val old = BigInt("fedcba98765432100123456789abcdef", 16)
      for ((enc, cap, chunks) <- Seq((5, 2, 1), (6, 4, 1), (7, 8, 1),
          (0, 16, 1), (1, 32, 2), (2, 64, 4), (3, 128, 8))) {
        d.io.lmul.poke(enc.U)
        for (vl <- 0 to cap) {
          val a = Vector.fill(chunks * 16)(rng.nextInt(256) - 128)
          val b = Vector.fill(chunks * 16)(rng.nextInt(256) - 128)
          var partial = old
          for (idx <- 0 until chunks) {
            val end = math.min(vl, (idx + 1) * 16)
            val total = a.take(end).zip(b.take(end)).map { case (x, y) => BigInt(x) * y }.sum
            val expected = if (vl == 0) old else total & mask32
            d.io.ta.poke((vl % 2 == 0).B); d.io.ma.poke((vl % 3 == 0).B)
            issue(packed(a.slice(idx * 16, (idx + 1) * 16)),
              packed(b.slice(idx * 16, (idx + 1) * 16)), partial, vl, idx, expected)
            partial = expected
          }
        }
      }
      d.io.lmul.poke(3.U)
      for (value <- Seq(-128, 127, 0); idx <- 0 until 8) {
        issue(packed(Seq.fill(16)(value)), packed(Seq.fill(16)(value)),
          BigInt(idx) * 16 * value * value, 128, idx, BigInt(idx + 1) * 16 * value * value)
      }
      d.io.lmul.poke(0.U)
      d.io.start.poke(1.U); issue(0, 0, old, 0, 0, 0, true)
      d.io.start.poke(0.U); d.io.vm.poke(false.B); issue(0, 0, old, 0, 0, 0, true)
      d.io.vm.poke(true.B); d.io.vill.poke(true.B); issue(0, 0, old, 0, 0, 0, true)
      d.io.vill.poke(false.B)
      for (sew <- 1 to 3) { d.io.sew.poke(sew.U); issue(0, 0, old, 0, 0, 0, true) }
      d.io.sew.poke(0.U); d.io.lmul.poke(4.U); issue(0, 0, old, 0, 0, 0, true)
      d.io.lmul.poke(0.U)
      val a = Seq.tabulate(16)(i => i - 8)
      val b = Seq.tabulate(16)(i => 7 - i)
      for (i <- 0 until 12) {
        val dot = i % 2 == 0
        d.io.op.poke(if (dot) VimacType.vdot else VimacType.vmul)
        val expected = if (dot) a.zip(b).map { case (x, y) => BigInt(x) * y }.sum & mask32
          else packed(a.zip(b).map { case (x, y) => x * y })
        issue(packed(a), packed(b), 0, 16, 0, expected)
      }
      // Accept a new operation every cycle and check the two-cycle output.
      val expectedStream = (0 until 32).map { i =>
        val dot = i % 2 == 0
        if (dot) a.zip(b).map { case (x, y) => BigInt(x) * y }.sum & mask32
        else packed(a.zip(b).map { case (x, y) => x * y })
      }
      for (i <- expectedStream.indices) {
        d.io.valid.poke(true.B)
        d.io.op.poke(if (i % 2 == 0) VimacType.vdot else VimacType.vmul)
        d.clock.step()
        if (i >= 1) {
          d.io.outValid.expect(true.B)
          expect128(d.io.result, expectedStream(i - 1))
          d.io.illegal.expect(false.B)
        }
      }
      d.io.valid.poke(false.B); d.clock.step()
      d.io.outValid.expect(true.B); expect128(d.io.result, expectedStream.last)
    }
  }

  it should "split LMUL groups safely and reject illegal alignment and state" in {
    test(new VDotDecodeHarness()(testConfig)).withAnnotations(simAnnotations) { d =>
      d.io.valid.poke(false.B); d.io.sew.poke(0.U); d.io.start.poke(0.U)
      d.io.vm.poke(true.B); d.io.vill.poke(false.B)
      d.io.a.poke(8.U); d.io.b.poke(16.U); d.io.dest.poke(3.U)
      d.io.lmul.poke(0.U); d.clock.step(2)
      for ((enc, n) <- Seq((5, 1), (6, 1), (7, 1), (0, 1), (1, 2), (2, 4), (3, 8));
           dest <- Seq(0, 3, 8, 15, 16, 23, 31)) {
        d.io.lmul.poke(enc.U); d.io.dest.poke(dest.U)
        d.io.count.expect(n.U); d.io.illegal.expect(false.B)
        d.io.valid.poke(true.B); d.clock.step(); d.io.valid.poke(false.B)
        var seen = 0
        var cycles = 0
        while (seen < n && cycles < 10) {
          for (i <- d.io.validOut.indices if d.io.validOut(i).peek().litToBoolean) {
            val u = d.io.outs(i)
            u.uopIdx.expect(seen.U)
            u.lsrc(0).expect((8 + seen).U); u.lsrc(1).expect((16 + seen).U)
            u.lsrc(2).expect((if (seen == 0) dest else 32).U)
            u.ldest.expect((if (seen == n - 1) dest else 32).U)
            u.illegal.expect(false.B)
            seen += 1
          }
          d.clock.step(); cycles += 1
        }
        assert(seen == n); d.clock.step()
      }
      d.io.lmul.poke(3.U); d.io.a.poke(9.U); d.io.illegal.expect(true.B)
      d.io.a.poke(8.U); d.io.b.poke(17.U); d.io.illegal.expect(true.B)
      d.io.b.poke(16.U); d.io.start.poke(1.U); d.io.illegal.expect(true.B)
      d.io.start.poke(0.U); d.io.vm.poke(false.B); d.io.illegal.expect(true.B)
      d.io.vm.poke(true.B); d.io.vill.poke(true.B); d.io.illegal.expect(true.B)
      d.io.vill.poke(false.B); d.io.lmul.poke(4.U); d.io.illegal.expect(true.B)
      d.io.lmul.poke(0.U)
      for (sew <- 1 to 3) { d.io.sew.poke(sew.U); d.io.illegal.expect(true.B) }
    }
  }
}
