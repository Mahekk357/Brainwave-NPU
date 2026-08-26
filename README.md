# BrainWave-NPU: A From-Scratch FPGA Neural Processing Unit

A SystemVerilog reimplementation of Microsoft's Project BrainWave NPU
architecture (Fowers et al., ISCA 2018) — a software-programmable FPGA
overlay for real-time, batch-1 deep learning inference, targeting
recurrent workloads (RNN/GRU/LSTM) where per-request latency matters
more than aggregate throughput.

Built independently after extending a university digital hardware course
project (a single-tile matrix-vector engine) into a full 5-stage NPU
pipeline with a custom instruction set, hazard detection, and software
toolchain.

## Architecture

- **MVU (Matrix-Vector Unit)** — multi-tile, multi-lane systolic dot-product
  engine with configurable T tiles × D DPEs × L lanes, inter-tile adder-tree
  reduction, and an asymmetric width-converting FIFO to bridge the MVU's
  wide output bandwidth to the narrower downstream pipeline.
- **eVRF (External Vector Register File)** — bypass path allowing
  instructions to skip the MVU for pure vector operations.
- **MFU0 / MFU1 (Multi-Function Units)** — elementwise activation
  (tanh/sigmoid via symmetry-optimized LUTs, plus ReLU), multiply, and
  add/subtract, chained in series.
- **LD (Load/Store Unit)** — input/output FIFO interface with writeback
  to any VRF in the design.
- **Instruction Decode & Dispatch** — a small VLIW-style ISA with
  per-stage macro-operations, a top-level decoder, and read-after-write
  hazard detection with selective stalling (not naive full-pipeline stalls).

## Toolchain

- **Assembler** (Python) — compiles a simple text ISA into a binary
  instruction stream consumable by the RTL.
- **Functional simulator** (Python/NumPy) — golden numerical reference
  for validating NPU programs against PyTorch/NumPy before running RTL sim.
- **RTL testbenches** — per-module unit tests plus an end-to-end
  integration test that runs a real LSTM cell through the full pipeline
  and diffs results against a floating-point reference.

## Status / Verified

- [x] Multi-tile MVU functional in RTL sim
- [x] LUT-based tanh/sigmoid activations, quantized and validated against NumPy
- [x] End-to-end single-gate LSTM computation matching PyTorch reference
- [ ] Hazard detection / instruction chaining
- [ ] Post-synthesis functional simulation & timing closure
- [ ] Stretch: INT8 DSP packing, block floating point

## Background

Based on the published BrainWave architecture description
(Fowers et al., ISCA 2018) and two related papers on FPGA NPU
implementations (Nurvitadhi et al., FCCM 2019; Boutros et al., FPT 2020).
This project was undertaken independently, beyond the scope of the
university lab assignment that inspired it.

## References
- J. Fowers et al., "A Configurable Cloud-Scale DNN Processor for Real-Time AI," ISCA 2018.
- E. Nurvitadhi et al., "Why Compete When You Can Work Together: FPGA-ASIC Integration for Persistent RNNs," FCCM 2019.
- A. Boutros et al., "Beyond Peak Performance: Comparing the Real Performance of AI-Optimized FPGAs and GPUs," FPT 2020.
