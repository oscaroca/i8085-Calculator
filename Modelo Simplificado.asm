.define            
	allowed_count 15
	allowed_countn 10
n 30h


.data 00h
	allowed: db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h
	allowedSig: db 2Bh,26h,7Ch,3Dh
	resta: db 2Dh


carry: db 00h  
operando1: db 00h
operando1d: db 00h
operando1c: db 00h
operando2: db 00h
operando2d: db 00h
operando2c: db 00h
operando3: db 00h
soperando1: db 00h
soperando2: db 00h
ready: db 00h


.org 100h
pila:
.org 200h
	lxi H,pila
	sphl
	mvi B,E0h
	mvi C, 00h
	mvi H, 00h
	jmp bucle2
bucle:
call check_op

bucle2:
	
	jmp bucle2
.org 0024h
	call string_in
	jmp bucle





.org 300h
string_in:
	in 00h
	cpi 00h
	jz no_tecla


tecla:
	call check_allowed
	cpi 00h
	jz no_tecla
	mov E, A








nextcheck:
	call check_numero
	cpi 00h
	jz es_operador




es_numero:

	lda operando3
	cpi 00h
	jz primero


segundo:
	lda operando2
	cpi 00h
	jnz segundodecenas
	mov A,E
	sta operando2
	mvi D,07h
	jmp tecla_final
segundodecenas:
	lda operando2d
	cpi 00h
	jnz segundocentenas
	mov A,E
	sta operando2d
	jmp tecla_final
segundocentenas:
	lda operando2c
	cpi 00h
	jnz tecla_final
	mov A,E
	sta operando2c
	jmp tecla_final


primero:
	lda operando1
	cpi 00h
	jnz primerodecenas
	mov A,E
	sta operando1
	mvi D,01h
	jmp tecla_final
primerodecenas:
	lda operando1d
	cpi 00h
	jnz primerocentenas
	mov A,E
	sta operando1d
	jmp tecla_final
primerocentenas:
	lda operando1c
	cpi 00h
	jnz tecla_final
	mov A,E
	sta operando1c
	jmp tecla_final




es_operador:
	lda operando1
	cpi 00h
	jz num_negativo1
	lda operando3
	cpi 00h
	jz operando
	lda operando2
	cpi 00h
	jz num_negativo2
	mov A,E
	cpi 3Dh
	jz igual
	jmp tecla_final
igual:
	lda operando1
    	cpi 00h
    	jz no_tecla
   	lda operando2
    	cpi 00h
    	jz no_tecla
    	lda operando3
    	cpi 00h
    	jz no_tecla

	mvi A,01h
	sta ready
	jmp tecla_final

operando:
	lda operando3
	cpi 00h
	jnz no_tecla
	mov A,E
	sta operando3
	mvi D,03h
	jmp tecla_final

num_negativo1:
	mov A,E
	cpi 2Dh
	jnz no_tecla
	
	lda soperando1
	cpi 00h
	jz nna
nnr:
	dcr A
	jmp endnnr
nna:
	inr A
endnnr:
	sta soperando1
	jmp tecla_final

num_negativo2:
	mov A,E
	cpi 2Dh
	jnz no_tecla
	lda soperando2
	cpi 00h
	jz nna2
nnr2:
	dcr A
	jmp endnnr2
nna2:
	inr A
endnnr2:
	sta soperando2
	jmp tecla_final



tecla_final:
	mov A,E
	stax B
	inx B



no_tecla: 
	ret




check_allowed:
	push D
	push H
	mvi E,allowed_count
	lxi H, allowed
allowed_loop:
	mov D,M
	cmp D
	jz is_allowed
	inx H
	dcr E
	jnz allowed_loop
	jmp not_allowed
is_allowed:
	mov A,D
	jmp end_allowed
not_allowed:
	mvi A,00h
end_allowed:
	pop H
	pop D
	ret


check_numero:
	push D
	push H
	mvi E,allowed_countn
	lxi H, allowed
	jmp allowed_loop

check_minus:
	push D
	push H
	mvi E,1
	lxi H, resta
	jmp allowed_loop













check_op:
	push PSW
	push H
	push D

	
	lda ready
	cpi 01h
	jnz fin

		
	call operacion


	mvi A,00h
	sta operando1
	sta operando2
	sta operando1d
	sta operando2d
	sta operando1c
	sta operando2c
	sta operando3
	sta soperando1
	sta soperando2
	sta ready
	INX B 
	INX B
	INX B
fin:
	pop D
	pop H
	pop PSW
	ret


operacion:
	push H
	push psw


PasarADecimal:

	mvi H,n
	lda operando1
	sub h
	sta operando1
	lda operando2
	sub h
	sta operando2

MirarSiNegativos:

	lda soperando1
	cpi 00h
	jz startop1
	lda operando1
	call inverse
	sta operando1

startop1:	
	lda soperando2
	cpi 00h
	jz startop2
	lda operando2
	call inverse
	sta operando2



startop2:
	lda operando3
	cpi 2Bh
	jz sum

	cpi 2Dh
	jz res

	cpi 26h
	jz and

	cpi 7Ch
	jz or

sum:
	call suma
	jmp finalop

res:
	lda operando2
	call inverse
	sta operando2
	call suma
	jmp finalop

and:
	call andop
	jmp finalop

or:
	call orop
	jmp finalop


finalop:
	pop psw
	pop H
	ret




suma:
	push H
	push PSW

	lda operando1
	lxi H, operando2
	add M
	call imprsum
	
	pop PSW
	pop H
	ret



imprsum:
	push PSW
	push H
	push D

	mvi L,00h
	mov D,A
	cpi 7Fh
	jc positivos

negativos:
	cpi F6h
	jz tenneg
	jnc menorneg
	jmp whileneg


positivos:
	cpi 0Ah
	jz ten
	jc menor
	jmp whilepos


whileneg:
	adi 0Ah
	inr L
	cpi F6h
	jc whileneg
	jmp endwhileNeg


whilepos:
	sbi 0Ah
	inr L
	cpi 0Ah
	jnc whilepos
	jmp endwhilePos

endwhilePos:
	mov E,A
	mov A,L
	mvi H,n
	add H
	STAX B
	INX B
	mov A,E
	add H
	stax B
	INX B



	jmp finimprsum

endwhileNeg:
	mov E,A
	mvi A,2Dh
	STAX B
	INX B
	mov A,L
	
	mvi H,n
	add H
	STAX B
	INX B
	mov A,E
	call inverse
	add H
	stax B
	INX B



	
	jmp finimprsum

ten:
	mvi A,31h
	STAX B
	INX B
	mvi A,30h
	STAX B
	INX B
	jmp finimprsum


tenneg:
	mvi A,2Dh
	STAX B
	INX B
	mvi A,31h
	STAX B
	INX B
	mvi A,30h
	STAX B
	INX B
	jmp finimprsum


menor:
	mvi H,n
	add H
	STAX B
	INX B
	jmp finimprsum


menorneg:
	mov E,A

	mvi A,2Dh
	STAX B
	INX B

	mov A,E
	call inverse
	mvi H,n
	add H
	STAX B
	INX B


finimprsum:
	pop D
	pop H
	pop PSW
	ret


andop:
	push H
	push PSW

	lda operando1
	lxi H, operando2
	ana M

	call imprsum
	
	pop PSW
	pop H
	ret

orop:
	push H
	push PSW

	lda operando1
	lxi H, operando2
	ora M

	call imprsum
	
	pop PSW
	pop H
	ret




inverse:
	push D
	mov D,A
	sub D
	sub D
	pop D
	ret




multiplica10:
push h
mov h,A
mvi l,09h
bucle1:
add h
dcr l
jnz bucle1
pop h
ret
