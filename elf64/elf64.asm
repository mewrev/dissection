BITS 64

; Base addresses.
BASE        equ 0x400000
PAGE        equ 0x1000
BASE_R_SEG  equ BASE
BASE_RW_SEG equ BASE + 1*PAGE + r_seg.size
BASE_RX_SEG equ BASE + 2*PAGE + r_seg.size + rw_seg.size

; ___ [ Read-only segment ] ____________________________________________________

SECTION .rdata vstart=BASE_R_SEG align=1

r_seg_off equ r_seg - BASE_R_SEG

r_seg:

; === [ ELF file header ] ======================================================

; ELF classes.
ELFCLASS64 equ 2 ; 64-bit object

; Data encodings.
ELFDATA2LSB equ 1 ; 2's complement with little-endian encoding

; Object file types.
ET_EXEC equ 2 ; Executable file

; Architecture.
EM_X86_64 equ 62 ; AMD x86-64 architecture

ehdr:

	db      0x7F, "ELF"               ; ident.magic: ELF magic number
	db      ELFCLASS64                ; ident.class: File class
	db      ELFDATA2LSB               ; ident.data: Data encoding
	db      1                         ; ident.version: ELF header version
	db      0, 0, 0, 0, 0, 0, 0, 0, 0 ; ident.pad: Padding
	dw      ET_EXEC                   ; type: Object file type
	dw      EM_X86_64                 ; machine: Architecture
	dd      1                         ; version: Object file version
	dq      text.start                ; entry: Entry point virtual address
	dq      phdr_off                  ; phoff: Program header table file offset
	dq      0                         ; shoff: Section header table file offset
	dd      0                         ; flags: Processor-specific flags
	dw      ehdr.size                 ; ehsize: ELF header size in bytes
	dw      phdr.entsize              ; phentsize: Program header table entry size
	dw      phdr.count                ; phnum: Program header table entry count
	dw      0                         ; shentsize: Section header table entry size
	dw      0                         ; shnum: Section header table entry count
	dw      0                         ; shstrndx: Section header string table index

.size equ $ - ehdr

; === [/ ELF file header ] =====================================================

; === [ Program headers ] ======================================================

; Segment types.
PT_LOAD    equ 1 ; Loadable program segment
PT_DYNAMIC equ 2 ; Dynamic linking information
PT_INTERP  equ 3 ; Program interpreter

; Segment flags.
PF_R equ 0x4 ; Segment is readable
PF_W equ 0x2 ; Segment is writable
PF_X equ 0x1 ; Segment is executable

phdr_off equ phdr - BASE_R_SEG

phdr:

; --- [ Interpreter program header ] -------------------------------------------

  .interp:
	dd      PT_INTERP                ; type: Segment type
	dd      PF_R                     ; flags: Segment flags
	dq      interp_off               ; offset: Segment file offset
	dq      interp                   ; vaddr: Segment virtual address
	dq      interp                   ; paddr: Segment physical address
	dq      interp.size              ; filesz: Segment size in file
	dq      interp.size              ; memsz: Segment size in memory
	dq      0x1                      ; align: Segment alignment

.entsize equ $ - phdr

; --- [ Dynamic array program header ] -----------------------------------------

  .dynamic:
	dd      PT_DYNAMIC             ; type: Segment type
	dd      PF_R                   ; flags: Segment flags
	dq      dynamic_off            ; offset: Segment file offset
	dq      dynamic                ; vaddr: Segment virtual address
	dq      dynamic                ; paddr: Segment physical address
	dq      dynamic.size           ; filesz: Segment size in file
	dq      dynamic.size           ; memsz: Segment size in memory
	dq      0x8                    ; align: Segment alignment

; --- [ Read-only data segment program header ] --------------------------------

  .r_seg:
	dd      PT_LOAD                  ; type: Segment type
	dd      PF_R                     ; flags: Segment flags
	dq      r_seg_off                ; offset: Segment file offset
	dq      r_seg                    ; vaddr: Segment virtual address
	dq      r_seg                    ; paddr: Segment physical address
	dq      r_seg.size               ; filesz: Segment size in file
	dq      r_seg.size               ; memsz: Segment size in memory
	dq      PAGE                     ; align: Segment alignment

; --- [ Data segment program header ] ------------------------------------------

  .rw_seg:
	dd      PT_LOAD                  ; type: Segment type
	dd      PF_R | PF_W              ; flags: Segment flags
	dq      rw_seg_off               ; offset: Segment file offset
	dq      rw_seg                   ; vaddr: Segment virtual address
	dq      rw_seg                   ; paddr: Segment physical address
	dq      rw_seg.size              ; filesz: Segment size in file
	dq      rw_seg.size              ; memsz: Segment size in memory
	dq      PAGE                     ; align: Segment alignment

; --- [ Code segment program header ] ------------------------------------------

  .rx_seg:
	dd      PT_LOAD                  ; type: Segment type
	dd      PF_R | PF_X              ; flags: Segment flags
	dq      rx_seg_off               ; offset: Segment file offset
	dq      rx_seg                   ; vaddr: Segment virtual address
	dq      rx_seg                   ; paddr: Segment physical address
	dq      rx_seg.size              ; filesz: Segment size in file
	dq      rx_seg.size              ; memsz: Segment size in memory
	dq      PAGE                     ; align: Segment alignment

.size  equ $ - phdr
.count equ .size / .entsize

; === [/ Program headers ] =====================================================

; === [ Sections ] =============================================================

; --- [ .interp section ] ------------------------------------------------------

interp_off equ interp - BASE_R_SEG

interp:

	db      "/lib64/ld-linux-x86-64.so.2", 0

.size equ $ - interp

; --- [/ .interp section ] -----------------------------------------------------

; --- [ .dynamic section ] -----------------------------------------------------

; Dynamic tags.
DT_NULL     equ 0  ; Marks the end of the dynamic array
DT_NEEDED   equ 1  ; String table offset of a required library
DT_PLTGOT   equ 3  ; Address of the PLT and/or GOT
DT_STRTAB   equ 5  ; Address of the string table
DT_SYMTAB   equ 6  ; Address of the symbol table
DT_JMPREL   equ 23 ; Address of the relocation entities of the PLT

dynamic_off equ dynamic - BASE_R_SEG

dynamic:

  .strtab:
	dq      DT_STRTAB              ; tag: Dynamic entry type
	dq      dynstr                 ; val: Integer or address value

.entsize equ $ - dynamic

  .symtab:
	dq      DT_SYMTAB              ; tag: Dynamic entry type
	dq      dynsym                 ; val: Integer or address value

  .jmprel:
	dq      DT_JMPREL              ; tag: Dynamic entry type
	dq      rela_plt               ; val: Integer or address value

  .pltgot:
	dq      DT_PLTGOT              ; tag: Dynamic entry type
	dq      got_plt                ; val: Integer or address value

  .libc:
	dq      DT_NEEDED              ; tag: Dynamic entry type
	dq      dynstr.libc_off        ; val: Integer or address value

  .null:
	dq      DT_NULL                ; tag: Dynamic entry type
	dq      0                      ; val: Integer or address value

.size equ $ - dynamic

; --- [/ .dynamic section ] ----------------------------------------------------

; --- [ .dynstr section ] ------------------------------------------------------

dynstr:

  .libc:
	db      "libc.so.6", 0
  .printf:
	db      "printf", 0
  .exit:
	db      "exit", 0

.libc_off   equ .libc - dynstr
.printf_off equ .printf - dynstr
.exit_off   equ .exit - dynstr

; --- [/ .dynstr section ] -----------------------------------------------------

; --- [ .dynsym section ] ------------------------------------------------------

; Symbol bindings.
STB_GLOBAL equ 1 ; Global symbol

; Symbol types.
STT_FUNC equ 2 ; Code object

; Symbol visibility.
STV_DEFAULT equ 0 ; Default visibility.

dynsym:

  .printf:
	dd      dynstr.printf_off        ; name: Symbol name (string table offset)
	db      STB_GLOBAL<<4 | STT_FUNC ; info: Symbol type and binding
	db      STV_DEFAULT              ; other: Symbol visibility
	dw      0                        ; shndx: Section index
	dq      0                        ; value: Symbol value
	dq      0                        ; size: Symbol size

.entsize equ $ - dynsym

  .exit:
	dd      dynstr.exit_off          ; name: Symbol name (string table offset)
	db      STB_GLOBAL<<4 | STT_FUNC ; info: Symbol type and binding
	db      STV_DEFAULT              ; other: Symbol visibility
	dw      0                        ; shndx: Section index
	dq      0                        ; value: Symbol value
	dq      0                        ; size: Symbol size

.printf_idx equ (.printf - dynsym) / .entsize
.exit_idx   equ (.exit - dynsym) / .entsize

; --- [/ .dynsym section ] -----------------------------------------------------

; --- [ .rela.plt section ] ----------------------------------------------------

; Relocation types.
R_386_JMP_SLOT equ 7

rela_plt:

  .printf:
	dq      got_plt.printf                         ; offset: Address
	dq      dynsym.printf_idx<<32 | R_386_JMP_SLOT ; info: Relocation type and symbol index
	dq      0                                      ; addend: Addend

  .exit:
	dq      got_plt.exit                           ; offset: Address
	dq      dynsym.exit_idx<<32 | R_386_JMP_SLOT   ; info: Relocation type and symbol index
	dq      0                                      ; addend: Addend

; --- [/ .rela.plt section ] ---------------------------------------------------

; --- [ .rodata section ] ------------------------------------------------------

rodata:

  .hello:
	db      "hello world", 10, 0

; --- [/ .rodata section ] -----------------------------------------------------

r_seg.size equ $ - r_seg

; ___ [/ Read-only segment ] ___________________________________________________

; ___ [ Read-write segment ] ___________________________________________________

SECTION .data vstart=BASE_RW_SEG follows=.rdata align=1

rw_seg_off equ rw_seg - BASE_RW_SEG + r_seg.size

rw_seg:

; --- [ .got.plt section ] -----------------------------------------------------

got_plt:

  .dynamic:
	dq      dynamic

  .link_map:
	dq      0

  .dl_runtime_resolve:
	dq      0

  .printf:
	dq      plt.resolve_printf

  .exit:
	dq      plt.resolve_exit

; --- [/ .got.plt section ] ----------------------------------------------------

rw_seg.size equ $ - rw_seg

; ___ [/ Read-write segment ] __________________________________________________

; ___ [ Executable segment ] ___________________________________________________

SECTION .text vstart=BASE_RX_SEG follows=.data align=1

rx_seg_off equ rx_seg - BASE_RX_SEG + r_seg.size + rw_seg.size

rx_seg:

; --- [ .plt section ] ---------------------------------------------------------

plt:

  .resolve:
	push    qword [rel got_plt.link_map]
	jmp     [rel got_plt.dl_runtime_resolve]

  .printf:
	jmp     [rel got_plt.printf]

  .resolve_printf:
	push    qword dynsym.printf_idx
	jmp     near .resolve

  .exit:
	jmp     [rel got_plt.exit]

  .resolve_exit:
	push    qword dynsym.exit_idx
	jmp     near .resolve

; --- [/ .plt section ] --------------------------------------------------------

; --- [ .text section ] --------------------------------------------------------

text:

  .start:
	lea     rdi, [rel rodata.hello]   ; arg1, "hello world\n"
	call    plt.printf                ; printf
	mov     rdi, 42                   ; arg1, 42
	call    plt.exit                  ; exit
	ret

; --- [/ .text section ] -------------------------------------------------------

; === [/ Sections ] ============================================================

rx_seg.size equ $ - rx_seg

; ___ [/ Executable segment ] __________________________________________________
