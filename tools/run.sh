nasm -fbin main.asm -o elos7.img -l objects.log
qemu-system-x86_64 -drive file=elos7.img,format=raw \
	-serial mon:stdio -m 8M -no-shutdown -no-reboot \
	-display gtk,zoom-to-fit=on -d int -D qemu.log
#	-monitor unix:/tmp/qemu-mon.sock,server,nowait \
