nasm -fbin main.asm -o elos7.img
qemu-system-x86_64 -drive file=elos7.img,format=raw \
	-serial mon:stdio -m 4M -no-shutdown -no-reboot \
	-monitor unix:/tmp/qemu-mon.sock,server,nowait \
	-display gtk,zoom-to-fit=on -d int -D qemu.log
