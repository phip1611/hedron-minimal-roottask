/*
MIT License

Copyright (c) 2022 Philipp Schuster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

# For reference look:
# - https://github.com/rust-lang/reference/blob/rust-1.63.0/src/inline-assembly.md
# - https://phip1611.de/blog/direct-systemcalls-to-linux-from-rust-code-x86_64/

# ensure that we only produce 64-bit x86_64 code.
.code64

# entry point into Rust
.EXTERN rust_entry

# start symbol must be globally available (linker must find it, don't discard it)
.GLOBAL start

# -----------------------------------------------------------------

.section .text.init

# Entry referenced in final ELF.
start:
      # GAS-like assembly syntax with intel noprefix mode
      # -> destination register is left

      # prepare argument 1
      movabs    rdi,    7
      # prepare argument 2
      movabs    rsi,    3

      # SET UP STACK
      movabs  rsp,      OFFSET _initial_stack_top

      # jump into high level code
      jmp     rust_entry
      ud2

# -----------------------------------------------------------------
.section .data

# reserve 128 KiB as stack (no stack overflow protection so far!)
.ALIGN 0x1000
_initial_stack_bottom:
    # implicitly fills zeroes
    # https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_chapter/as_7.html#SEC91
    .FILL 0x20000
_initial_stack_top:

# -----------------------------------------------------------------
# According to Rust doc, it seems like I have to reset the assembler to the original state.
# I think default is ".text"
.section .text
