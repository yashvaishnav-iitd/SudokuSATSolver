# Sudoku Solver using SAT Encoding

## Overview
This project implements a complete Sudoku solver pipeline that encodes Sudoku puzzles as CNF (Conjunctive Normal Form) formulas, uses Z3 SAT solver to find solutions, and decodes Z3's output back into human-readable Sudoku grids.

## Architecture

### Pipeline Flow
```
input.txt → sudoku2cnf → problem.cnf → z3 → sat_output.txt → sol2grid → output.txt
```

### Components

#### 1. sudoku2cnf.ml (Encoder)
Translates Sudoku puzzles into DIMACS CNF format for SAT solvers.

**Variable Encoding:**
Each cell (row r, column c) with value v is represented by a unique variable:
```
variable = (r × size × size) + (c × size) + (v - 1) + 1
```

**Constraint Types:**
- **Cell constraints**: Each cell must contain exactly one value
- **Row constraints**: Each value must appear exactly once in each row
- **Column constraints**: Each value must appear exactly once in each column
- **Box constraints**: Each value must appear exactly once in each √size × √size box

**"Exactly One" Encoding:**
For a set of variables, "exactly one must be true" is encoded as:
- At least one: `[v1, v2, v3, ...]` (one clause)
- At most one: `[-v1, -v2], [-v1, -v3], [-v2, -v3], ...` (pairwise negations)

**Fixed Clues:**
Pre-filled cells are added as unit clauses (single positive literals).

#### 2. sol2grid.ml (Decoder)
Converts Z3's satisfying assignment back into a Sudoku grid.

**Process:**
1. Parse Z3 output to extract positive literals (true variables)
2. Detect if puzzle is unsatisfiable
3. Reverse the variable encoding to get (row, column, value) tuples
4. Reconstruct and print the complete grid

**Size Detection:**
The grid size is computed from total variables: `size = ∛(total_variables)`

## Compilation and Execution
```bash
make run
```
Runs the complete pipeline:
1. Reads `input.txt` from current directory
2. Generates intermediate files (`problem.cnf`, `sat_output.txt`)
3. Creates `output.txt` with the solved grid


### Cleanup
```bash
make clean
```
Removes all compiled binaries and intermediate files.


## Output Format (`output.txt`)
- Complete solved grid
- `1-9` for 9×9 puzzles
- `0-9` and `A-F` for 16×16 puzzles
- Each row on a new line
- No empty cells

## Supported Puzzle Sizes
- **9×9**: 3×3 boxes (standard Sudoku)
- **16×16**: 4×4 boxes

## Edge Cases and Special Handling

### Edge Case 1: Unsolvable Puzzles
**Scenario:** Invalid or contradictory initial clues

**Handling:**
- Z3 returns "UNSATISFIABLE"
- `sol2grid` detects this and outputs: `NO SOLUTION`
- Program exits gracefully without attempting to construct a grid

### Edge Case 2: Multiple Solutions
**Scenario:** Under-constrained puzzle with multiple valid solutions

**Handling:**
- My implementation returns **one valid solution** (the first satisfying assignment Z3 finds)
- All returned solutions are valid according to Sudoku rules

**Detecting Multiple Solutions:**
To check if multiple solutions exist:
1. Take the output solution and convert each cell assignment to its corresponding variable
2. Create a blocking clause by negating all true variables from the solution
   - If solution has variables 5, 17, 23... true, add clause `[-5, -17, -23, ...]`
3. Append this blocking clause to the original CNF formula
4. Run Z3 again on the augmented formula
5. **If Z3 returns SAT** with a different assignment → multiple solutions exist
6. **If Z3 returns UNSAT** → the original solution was unique

**Note:** Uniqueness checking is not automated in my pipeline but can be implemented as described above.

## Implementation Details

### Character Encoding for 16×16
The code handles size-dependent character mapping:
- **9×9 and smaller**: Direct mapping (1→'1', 2→'2', ..., 9→'9')
- **16×16**: Offset mapping (1→'0', 2→'1', ..., 10→'9', 11→'A', ..., 16→'F')

This is handled consistently in both encoder and decoder through conditional logic based on grid size.

### Makefile Targets
- `make` or `make all`: Compiles both executables
- `make sudoku2cnf`: Compiles only the encoder
- `make sol2grid`: Compiles only the decoder (with Str library)
- `make run`: Executes the full pipeline (encode → solve → decode)
- `make clean`: Removes binaries, object files, and intermediate outputs

### Performance
- **Encoding**:  (9×9 generates ~11,000 clauses)

Expected runtime: <10s per puzzle on standard hardware

## Files Included
- `sudoku2cnf.ml` - Encoder source code
- `sol2grid.ml` - Decoder source code
- `Makefile` - Build and execution automation
- `README.md` - This documentation
