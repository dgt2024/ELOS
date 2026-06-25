nasm -fbin kernel.asm -o elos5.img
qemu-system-i386 -display none \
  -drive file=elos5.img,format=raw,if=ide,media=disk \
  -d int -D elos5-log.log -no-reboot -no-shutdown -monitor stdio