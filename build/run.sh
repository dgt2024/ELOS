nasm -felf32 boot.s -o tmp/boot.o -g
i686-elf-ld -T build/linker.ld tmp/boot.o -o tmp/elos7
i686-elf-objcopy -O binary tmp/elos7 out/elos7.img
qemu-system-i386 -display cocoa,zoom-to-fit=on -full-screen \
	-drive file=out/elos7.img,format=raw
rm tmp/*
