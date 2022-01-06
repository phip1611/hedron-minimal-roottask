# For reference look:
# - https://github.com/rust-lang/reference/blob/cf3a28145e06a3294494b5ac2ac4beef9f2e52e0/src/inline-assembly.md
# - https://phip1611.de/blog/direct-systemcalls-to-linux-from-rust-code-x86_64/

# ensure that we only produce 64-bit x86_64 code.
.code64

# entry point into Rust
.EXTERN rust_entry

# start symbol must be globally available (linker must find it, don't discard it)
.GLOBAL start

# -----------------------------------------------------------------

.section .text

# Entry referenced in final ELF.
start:
      # INTEL SYNTAX on x86_64! Destination is left

      # move HIP pointer to first function argument
      mov     rdi,    rsp

      # UTCB is 1 page above HIP
      lea     rsi,    [rsp - 0x1000]

      # SET UP STACK
      # align stack to 64 byte / 512 bits
      # --> otherwise vector instructions or usage of
      #     vector registers  may throw a General Protection Fault

      # "movABS + OFFSET": OFFSET definetly required; works also with just "mov" instruction
      movabs  rax,      OFFSET _initial_stack_top
      sub     rax,      64
      # increase by 8 again: weird x86_64 stack thingy: rsp - 8 must be 64-byte aligned
      # I don't know the name of this reason or technique.. it's just like that for now.
      add     rax,      8
      mov     rsp,      rax
      mov     rbp,      rax

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
