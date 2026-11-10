ENTRY(start)
SECTIONS {
	. = 0x7c00;
	.boot : { *(.boot) }
	. = 0x7dfe;
	.signature : { *(.signature) }
}
