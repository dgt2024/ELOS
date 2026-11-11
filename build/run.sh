nasm -felf32 boot.s -o tmp/boot.o
nasm -felf32 kernel/memory.s -o tmp/memory.o
i686-elf-ld -T build/linker.ld tmp/*.o -o tmp/elos7
i686-elf-objcopy -O binary tmp/elos7 out/elos7.img
qemu-system-i386 -display cocoa,zoom-to-fit=on -full-screen \
	-drive file=out/elos7.img,format=raw -d int -D tmp/qemu.log \
	-no-shutdown -no-reboot -monitor stdio
tail -n 42 < tmp/qemu.log
rm tmp/*
