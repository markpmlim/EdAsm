The disassembled source code of the programs of the PRODOS ASSEMBLER TOOLS RELEASE 1.1 are
distributed in the form of an 800K Universal disk image (.2mg). The relevant source files are in the EDASM.SRC folder and are meant for viewing purposes only.

The disassembled source codes are arranged in 5 folders.

If you wish to assemble any of the 5 programs,
1) you should have a copy of the PRODOS Assembler Tools,
2) you know how to run EDASM.SYSTEM, and
3) you should be have some knowledge using the command line of the EDASM editor.

To assemble a particular program  it’s advisable to change the working directory.

There is a README.TXT at the root directory of the disk image containing information on how to assemble the source code(s) in a particular folder.

To understand the source codes, the following are required:

1) a good knowledge of the instructions of the 6502/65C02 CPU.
2) an idea on how to call the Apple ][ Monitor subroutines.
3) a working knowledge of the ProDOS 8 filing protocol including its on-disk data structures.
4) know what EDASM’s assembly directives do.
5) at least some knowledge of the pseudo 16-bit microprocessor SWEET16.

The following are useful references:

1) Beneath Apple ProDOS by Quality Software
2) Programming the 65816 etc by Eyes and Lichty
3) Apple II monitor listings
4) EDASM manual
5) SWEET16 by Steve Wozniak

When you peruse through the source codes you will notice that many data areas are filled with what seems to be garbage. These are actually random data created when the assembler encounters a particular form of the DS directive in original source. I had left them as-is so that a byte-to-byte comparison can be made between the new binaries and the original binaries.

**Some weblinks:**

https://sites.google.com/site/trashgod/edasm

https://groups.google.com/forum/#!msg/comp.sys.apple2.programmer/loRPy3hiUvw/YuqcYU5SHhgJ

https://groups.google.com/forum/#!topic/comp.sys.apple2.programmer/-gv6PdWl77Y

https://groups.google.com/forum/#!topic/comp.sys.apple2.programmer/6Pdl91-w1PQ

