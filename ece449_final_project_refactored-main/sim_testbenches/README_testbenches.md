# Test benches for `Test FIles/*.mem`

These benches were built from the program intent in the `.lst` / `.asm.txt` files and the current VHDL structure in the repo.

## Important project caveats I found while wiring these up

The current source tree is **not fully simulation-ready yet**, so I split the benches into two categories:

1. **Benches that are directly useful once the core compiles with the current supported ISA path**
   - `FormatA_Test.mem`
   - `FormatBTest1.mem`
   - `FormatBTest2.mem`
   - `FormatBTest3.mem`

2. **Benches that are ready from a stimulus / expected-result standpoint, but depend on ISA pieces that are not fully implemented yet in the current source**
   - `FinalTest1.mem`
   - `FinalTest2.mem`
   - `FactorialTest.mem`
   - `FactorialTestOverflow.mem`
   - `FormatLTest1.mem`

### Current blockers in the source tree

- `rom.vhd` hardcodes `MEMORY_INIT_FILE => "FormatA_Test.mem"`, so each simulation run needs that filename switched to the matching `.mem` file.
- The PC / boot constants and names used in `controller.vhd`, `program_counter.vhd`, and `decode.vhd` do not currently line up cleanly.
- `decode.vhd` / `controller.vhd` do not yet fully cover `LOAD`, `STORE`, `LOADIMM`, and `MOV`.
- `IN` destination handling also looks incomplete in the current decode path.
- `top_level.vhd` currently expects a decode output named `branch_taken`, but `decode.vhd` currently exposes `pc_reset` instead.

Because of that, I did **not** claim these benches were simulator-validated end-to-end inside this container.

## How the benches are intended to be used

1. Put the relevant `.mem` file where Vivado/XSIM can see it.
2. In `rom.vhd`, change:

```vhdl
MEMORY_INIT_FILE => "FormatA_Test.mem"
```

so it points at the test you want to run.

3. Add `sim_testbenches/tb_mem_helpers_pkg.vhd` and the specific bench file to the simulation fileset.
4. Run the matching bench.

## Input driving strategy used

For programs with multiple `IN` instructions, the benches assume the current 4-stage IF/ID → ID/EX → EX/MEM → MEM/WB pipeline intent:

- hold the first input for 4 rising edges after reset is released
- then advance one input value per rising edge for each consecutive `IN`

That lines up with the current architecture intent, but if you later change the pipeline depth or add stalls/flushes, you should adjust the `fill_cycles` argument in the helper procedure.

## Expected results summary

- `FormatA_Test.mem` with inputs `r1=3`, `r2=5` should drive `out_port = 96`.
- `FormatBTest1.mem` with inputs `r0=2`, `r1=3`, `r2=1`, `r3=5` should end with:
  - `r0 = 2`
  - `r1 = 3`
  - `r2 = 2`
  - `r3 = 5`
- `FormatBTest2.mem` with inputs `r0=2`, `r1=3`, `r2=1`, `r3=5`, `r4=528`, `r5=1`, `r6=5`, `r7=0` should end with:
  - `r1 = 158`
  - `r2 = 79`
  - `r6 = 0`
  - `r7 = 0x0222` (return address)
- `FormatBTest3.mem` with inputs `r0=-2`, `r1=3`, `r2=1`, `r3=5` should end with `r6 = -10 = 0xFFF6`.
- `FinalTest1.mem` with input `r1=5` should drive `out_port = 191`.
- `FinalTest2.mem` with input `r1=5` should drive `out_port = 0xFFFA`.
- `FactorialTest.mem` with input `r0=5` should drive `out_port = 120`.
- `FactorialTestOverflow.mem` currently assembles to the same effective loop structure as the non-overflow version in this repo, so with input `5` it should also drive `out_port = 120` unless you regenerate the memory image after adding overflow handling.
- `FormatLTest1.mem` is expected to store `0x050F` into RAM at address `0x0600`, then load it back so `r3 = 0x050F`.

## Suggested wave signals to inspect

Even where the bench includes assertions, these are the first internal signals I would put on the wave window:

- `uut.fetch_pc`
- `uut.fetch_instr`
- `uut.IF_ID_reg.instruction`
- `uut.ID_EX_reg`
- `uut.EX_MEM_reg`
- `uut.MEM_WB_reg`
- `uut.w_data_rf`
- `uut.w_addr_rf`
- `uut.wr_en_rf`
- `uut.out_port`

If you want to turn the register-only benches into fully self-checking benches later, the next step is exposing the register file array through a debug port or using VHDL-2008 external names in XSIM.
