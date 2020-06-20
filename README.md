Shows how to setup a two (or more) stage boot loader. Also includes the linking of two assembly files into a combined binary with a linker script file.
Navigate to <a href=".vscode/tasks.json">.vscode/tasks.json</a> to see the step by step commands.  

Build steps:  
1.) The files "stage1.asm" and "stage.asm" are build with NASM to get their respective object file in .elf format  
2.) The linker uses the linker script "linker.ld" to create a runnable file "program" from the object files  
  
Run it either in Qemu (see tasks) or write it on a USB (see tasks) to run it on hardware.  
