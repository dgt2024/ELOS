nasm -felf32 boot.s -o tmp/boot.o
nasm -felf32 kernel/memory.s -o tmp/memory.o
ld -T build/linker.ld tmp/*.o -o tmp/elos7
objcopy -O binary tmp/elos7 out/elos7.img
rm tmp/*
