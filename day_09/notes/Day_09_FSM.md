# Day 09 — Finite State Machines (FSMs)

## 1. FSM Theory

A **Finite State Machine (FSM)** is a sequential circuit whose output depends on the
current state and (optionally) the current inputs. FSMs are the backbone of digital
control logic — from traffic lights to protocol decoders.

Every FSM has:
- A **finite set of states** (S₀, S₁, …, Sₙ)
- A set of **inputs** and **outputs**
- A **state transition function** (next-state logic)
- An **output function**
- A **reset state** (initial state)

---

### 1.1 Moore vs Mealy Machines

| Feature          | Moore Machine                        | Mealy Machine                          |
|------------------|--------------------------------------|----------------------------------------|
| Output depends on| Current state only                   | Current state AND current inputs       |
| Output changes   | Only on state transitions (clock edge)| Can change mid-cycle with input change |
| Timing           | Outputs are registered, glitch-free  | Outputs may glitch (combinational path)|
| Latency          | 1 clock cycle extra latency          | Responds immediately                   |
| # States         | Typically more states                | Typically fewer states                 |
| Preferred when   | Glitch-free outputs are critical     | Low latency is critical                |

> [!TIP]
> In FPGA designs, **Moore machines** are generally preferred because their outputs
> are inherently registered and glitch-free. Vivado synthesis also handles them more
> predictably.

### 1.2 General FSM Template (Verilog-2001)

```verilog
// 3-block FSM style (recommended)
// Block 1: State register (sequential)
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= INIT_STATE;
    else
        state <= next_state;
end

// Block 2: Next-state logic (combinational)
always @(*) begin
    case (state)
        STATE_A: next_state = (condition) ? STATE_B : STATE_A;
        // ...
    endcase
end

// Block 3: Output logic (combinational for Moore, or registered)
always @(*) begin
    case (state)
        STATE_A: output = value_a;
        // ...
    endcase
end
```

---

## 2. State Encoding Methods

| Encoding   | Description                                    | Pros                         | Cons                        |
|------------|------------------------------------------------|------------------------------|-----------------------------|
| **Binary** | States encoded as binary numbers (00,01,10,11) | Minimum flip-flops           | Complex next-state logic    |
| **One-Hot** | One flip-flop per state, only one is '1'       | Simple logic, fast           | More flip-flops needed      |
| **Gray**   | Adjacent states differ by 1 bit                | Reduces glitches, good for async | Limited applicability    |

### Example: 4 States

| State  | Binary | One-Hot | Gray |
|--------|--------|---------|------|
| S0     | 00     | 0001    | 00   |
| S1     | 01     | 0010    | 01   |
| S2     | 10     | 0100    | 11   |
| S3     | 11     | 1000    | 10   |

> [!NOTE]
> Vivado defaults to **one-hot encoding** for FSMs on most Xilinx FPGAs because
> FPGAs have abundant flip-flops but limited LUT inputs. You can override this with
> synthesis attributes: `(* fsm_encoding = "binary" *)` or `"one_hot"` or `"gray"`.

---

## 3. Assignment 1 — Overlapping 110 Detector (LSB First, Moore FSM)

### 3.1 Problem Statement

Detect the binary pattern **110** received **LSB first** on a serial input `din`.

- **110 in binary**: bit2=1, bit1=1, bit0=0
- **LSB first** means bit0 arrives first: reception order is **0, 1, 1**
- The FSM must detect when the last 3 received bits (in order) are: **0 → 1 → 1**
- **Overlapping**: after detection, reuse applicable bits for the next match
- **Output behavior**: TOGGLE a register on each detection (initial output = 0)
- **Machine type**: Moore (output depends only on current state)

### 3.2 State Diagram (ASCII Art)

```
                    din=1
               +----------+
               |          |
               v          |
         +----------+     |
  reset  |          |-----+
  ------>|  S_IDLE  |
         |  (out=0) |<-----------+
         +----------+            |
               |                 |
               | din=0           | din=1
               v                 |
         +----------+     +----------+
         |          |     |          |
    +--->|   S_0    |     |  S_011   |---+
    |    | (out=0)  |     | (DETECT!)|   |
    |    +----------+     | (toggle) |   |
    |         |           +----------+   |
    |         | din=1          ^         |
    | din=0   v                |         |
    |    +----------+          |         |
    |    |          |----------+         |
    +----|   S_01   |  din=1             |
         | (out=0)  |                    |
         +----------+                    |
               |                         |
               | din=0                   |
               +--------> S_0  (overlap) |
                                         |
         S_011: din=0 -----> S_0  (overlap, 0 starts new pattern)
         S_011: din=1 -----> S_IDLE      +
```

### 3.3 State Transition Table

| Current State | din | Next State | Detection? | Notes                              |
|---------------|-----|------------|------------|------------------------------------|
| S_IDLE        |  0  | S_0        | No         | '0' matches first bit of pattern   |
| S_IDLE        |  1  | S_IDLE     | No         | '1' doesn't start pattern          |
| S_0           |  0  | S_0        | No         | Stay; this '0' could be new start  |
| S_0           |  1  | S_01       | No         | '0→1' matches first two bits       |
| S_01          |  0  | S_0        | No         | Overlap: '0' restarts pattern      |
| S_01          |  1  | S_011      | No         | '0→1→1' complete! Enter detect     |
| S_011         |  0  | S_0        | **Yes**    | Toggle! Overlap: '0' starts new    |
| S_011         |  1  | S_IDLE     | **Yes**    | Toggle! '1' alone can't start      |

> [!IMPORTANT]
> In the Moore implementation, the **toggle happens upon entering S_011** (at the
> clock edge where state transitions to S_011). The output is a separately maintained
> toggle register that flips each time the FSM enters the detection state.

### 3.4 Overlapping Detection Explained

**Overlapping** means the FSM does NOT reset to the idle state after a successful
detection. Instead, it checks whether the tail-end bits of the detected pattern can
serve as the beginning of a new match.

**Example trace** — input sequence: `0, 1, 1, 0, 1, 1, 0, 1, 1`

```
Cycle:  1   2   3   4   5   6   7   8   9
din:    0   1   1   0   1   1   0   1   1
State:  S0  S01 S011 S0  S01 S011 S0  S01 S011
                 ^              ^              ^
              Detect1        Detect2        Detect3
Output: 0   0   1   1   1   0   0   0   1
```

Three detections occur → output toggles: 0 → 1 → 0 → 1.

After each detection in S_011:
- If next din=0: go to S_0 (the '0' begins a new pattern) ← this is the overlap
- If next din=1: go to S_IDLE (no overlap possible)

---

## 4. Assignment 2 — Maximum Digit Tracker FSM

### 4.1 Problem Statement

Build an FSM over the alphabet **{0, 1, 2, 3}** (2-bit input). The FSM outputs the
**largest digit seen so far** since the last reset.

- **4 states**: MAX_0, MAX_1, MAX_2, MAX_3
- Once the maximum increases, the FSM transitions to a higher state
- The FSM **never goes backwards** (max only increases or stays)
- MAX_3 is an **absorbing state** — once reached, it stays forever

### 4.2 State Diagram (ASCII Art)

```
                 din<1        din<2        din<3        (any din)
                +----+       +----+       +----+       +----+
                |    |       |    |       |    |       |    |
                v    |       v    |       v    |       v    |
  reset   +---------+  +---------+  +---------+  +---------+
  ------->|  MAX_0  |  |  MAX_1  |  |  MAX_2  |  |  MAX_3  |
          | out = 0 |  | out = 1 |  | out = 2 |  | out = 3 |
          +---------+  +---------+  +---------+  +---------+
               |  |         |  |         |             ^
               |  | din=1   |  | din=2   | din=3       |
               |  +-------->+  +-------->+------------>+
               |                                       |
               |              din=2                    |
               +----------------->MAX_2                |
               |              din=3                    |
               +-------------------------------------->+
               |  (din=1 only goes to MAX_1, etc.)
```

### 4.3 State Transition Table

| Current State | din  | Next State | Output | Notes                        |
|---------------|------|------------|--------|------------------------------|
| MAX_0         | 0    | MAX_0      | 0      | No change, max still 0       |
| MAX_0         | 1    | MAX_1      | 0→1    | New max = 1                  |
| MAX_0         | 2    | MAX_2      | 0→2    | New max = 2                  |
| MAX_0         | 3    | MAX_3      | 0→3    | New max = 3                  |
| MAX_1         | 0    | MAX_1      | 1      | 0 < current max, stay        |
| MAX_1         | 1    | MAX_1      | 1      | Equal, stay                  |
| MAX_1         | 2    | MAX_2      | 1→2    | New max = 2                  |
| MAX_1         | 3    | MAX_3      | 1→3    | New max = 3                  |
| MAX_2         | 0    | MAX_2      | 2      | Stay                         |
| MAX_2         | 1    | MAX_2      | 2      | Stay                         |
| MAX_2         | 2    | MAX_2      | 2      | Stay                         |
| MAX_2         | 3    | MAX_3      | 2→3    | New max = 3                  |
| MAX_3         | 0    | MAX_3      | 3      | Absorbing state              |
| MAX_3         | 1    | MAX_3      | 3      | Absorbing state              |
| MAX_3         | 2    | MAX_3      | 3      | Absorbing state              |
| MAX_3         | 3    | MAX_3      | 3      | Absorbing state              |

> [!NOTE]
> This FSM is a pure **Moore machine** — the output is directly determined by the
> current state. The output is simply the state encoding itself.

---

## 5. Vivado Simulation Steps

### Step 1: Create a New Project
1. Launch **Vivado** → Click **Create Project**
2. Project Name: `Day_09_FSM`, Location: choose your working directory
3. Project Type: **RTL Project**, check "Do not specify sources at this time"
4. Select your FPGA part (e.g., `xc7a35tcpg236-1` for Basys3)
5. Click **Finish**

### Step 2: Add Design Sources
1. In **Sources** panel → right-click **Design Sources** → **Add Sources**
2. Select **Add or create design sources**
3. Click **Add Files** → navigate to `Codes/` folder
4. Add `fsm_110_detector.v` and `max_digit_fsm.v`
5. Click **Finish**

### Step 3: Add Simulation Sources
1. Right-click **Simulation Sources** → **Add Sources**
2. Select **Add or create simulation sources**
3. Add `fsm_110_detector_tb.v` and `max_digit_fsm_tb.v`
4. Click **Finish**

### Step 4: Run Behavioral Simulation
1. In the **Flow Navigator** (left panel) → click **Run Behavioral Simulation**
2. Vivado will compile and open the waveform viewer
3. Set the top-level simulation module:
   - For sequence detector: `fsm_110_detector_tb`
   - For max digit FSM: `max_digit_fsm_tb`
4. Click **Run All** (or set simulation time to 500 ns)

### Step 5: Analyze Waveforms
1. Add signals to waveform window: `clk`, `rst`, `din`, `out` (or `max_out`)
2. Also add internal state signal for debugging
3. Zoom to fit → verify state transitions match the transition tables above
4. Check that detection/output matches expected values from testbench

### Step 6: Check Console Output
- Look in the **Tcl Console** for `$display` messages
- Testbenches print **PASS/FAIL** for each test vector
- Verify all tests pass before proceeding

> [!TIP]
> To view FSM states as readable names in the waveform viewer, right-click the
> state signal → **Radix** → **ASCII** (if using `ifdef` names) or create a custom
> radix map in Vivado.

---

## 6. Key Takeaways

1. **3-block FSM coding style** (state register, next-state logic, output logic) is
   the cleanest and most synthesizable approach.
2. **Moore machines** produce glitch-free outputs since outputs depend only on
   registered state.
3. **Overlapping detection** requires careful transition design — the FSM must check
   if tail bits of a match can begin a new match.
4. **Toggle behavior** on detection is implemented with a separate register, not
   through FSM states (this keeps the state count manageable).
5. **Absorbing states** (like MAX_3) are states with no exit — useful for
   "remember the maximum" type problems.
