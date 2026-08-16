nasm -fbin main.asm -o main.img
qemu-system-i386 -display cocoa,zoom-to-fit=on -full-screen \
  -drive file=main.img,format=raw,if=ide,media=disk \
  -no-reboot -no-shutdown -monitor stdio -d int -D log.log \
  -nic user,model=rtl8139