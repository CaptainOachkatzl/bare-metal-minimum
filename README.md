This is the minimum you have to do, to get a program to run on a x86_64 architecture with legacy BIOS.  
Navigate to <a href=".vscode/tasks.json">.vscode/tasks.json</a> to see the step by step commands.  
Other examples can be found in the different branches of this project.
  
Documentation:  
"assembler.asm" is the program that the BIOS is going to run. The first line "global \_start" is exposing the address so the linker can find it.  
"linker.ld" is the LD script file and "ENTRY(\_start)" sets the start of the execution to the previously exposed "\_start" address.  
  
Build steps:  
1.) The "assembler.asm" file is build with NASM to get an object file "object.elf".  
2.) The linker creates a bootable binary "program.bin" from the object file  
  
Run it either in Qemu (see tasks) or write it on a USB (see tasks) to run it on hardware.  
