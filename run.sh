cd Build
clang -target i386-unknown-none-elf -ffreestanding -c program.c -o program.o
i686-elf-ld -T "elos.ld" program.o -o program.elf
./main program.elf program
rm program.elf program.o
cd ..
nasm -fbin main.asm -o main.img
qemu-system-i386 -display cocoa,zoom-to-fit=on \
  -drive file=main.img,format=raw,if=ide,media=disk \
  -no-reboot -no-shutdown -monitor stdio -d int -D log.log
