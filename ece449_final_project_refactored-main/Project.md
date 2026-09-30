## Program Counter
- A special register used to hold the memory address of the next instruction to be fetched and executed
- Automatically advances after each instruction fetch
- Keeps track of where the CPU is in the program
- The amount the PC is incremented is determined by the instruction width
- In this project, the program counter is incremented by 2 as the instruction width is 16 bits

### Flow
- CPU reads the memory at the address stored in the program counter
- CPU loads the instruction then updates the PC to point at the next one
- Program counter is also modified by branch, jump and call instructions

### Needed Functions and Requirements
The program counter needs to be able to function differently under different conditions. The condition or "mode" of the program counter is 
specified by a 2 bit logic vector:
| Operation | Behavior of Program Counter|Code |
|----------|----------|----------|
| Regular     | PC increments by 2 | 00 |
| Branch/Jump/Return    | PC needs to load a specific memory address| 01 |
| NOP    | PC needs to hold the current value | 10 |
| Reset    | PC needs to reset to the start of memory | 11 |

- A program counter must be clocked since it should only update its register value on the rising edge of a clock so a clock input signal is required
- To support branching, jumps and interrupts in addition to the mode selection for the PC, an input signal for the new value is also needed
  - Any calculations on the value (for example adding offset) is performed externally before inputing this address to the PC
- An output signal for reading the value in the program counter is also needed
- Since we need to increment the program counters current value by 2, we need an intermediate signal since VHDL will not allow us to read an output signal
- The addressing/incementing of the program counter and how this translates to the ROM addressing must be accounted for
-   To do this, the LSB is dropped for the internal signal, without dropping this LSB we didn't fetch all the instructions in order

<img width="1450" height="623" alt="image" src="https://github.com/user-attachments/assets/cab58f2f-27e4-4128-9dd5-8c8e08d4c3a5" />
