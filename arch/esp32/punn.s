	.file	"punn.c"
	.text
	.align	4
	.global	forth_start
	.type	forth_start, @function
forth_start:
	entry	sp, 48
	mov.n	a7, sp
	movi.n	a2, 0
	s32i.n	a2, a7, 0
	l32i.n	a2, a7, 0
	addi.n	a2, a2, 1
	s32i.n	a2, a7, 0
	nop.n
	retw.n
	.size	forth_start, .-forth_start
	.ident	"GCC: (crosstool-NG esp-2020r3) 8.4.0"
