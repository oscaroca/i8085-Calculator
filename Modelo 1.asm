.define            
	allowed_count 15
	allowed_countn 10
n 30h


.data 00h

	allowed: db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h
	allowedSig: db 2Bh,26h,7Ch,3Dh
	resta: db 2Dh

ro11:db 00h
ro12:db 00h
ro21:db 00h
ro22:db 00h
operando1v1: db 99h
operando1v2: db 99h
operando1v3: db 99h
operando2v1: db 99h
operando2v2: db 99h
operando2v3: db 99h
operacion: db 00h
soperando1: db 00h
soperando2: db 00h
r1:db 00h
r2:db 00h


.org 100h
pila:
.org 200h
	lxi H,pila;Cargamos la pila en la posicion de memoria 100h
	sphl
	mvi B,E0h
	mvi C, 00h

	
bucle: ;iniciamos un bucle infinito
	jmp bucle

.org 0024h	;Interrupcion trap, saltamos a la subrutina string_in
	call string_in
	jmp bucle


.org 300h
string_in:;subrutina de introduccion por teclado
	in 00h
	cpi 00h
	jz no_tecla; Si no se introduce nada, no hace nada
tecla:; Se introduce una tecla
	call check_allowed; confirma que este entre las permitidas
	cpi 00h
	jz no_tecla
	mov E, A

	call check_numero; confierma que es un numero, sino, salta a la parte de operadores
	cpi 00h
	jz es_operador
	
	lda operacion;Si ya hay un operando, asignará el numero al segundo
	cpi 00h
	jz primerValor

segundoValor:;Introduccion del segundo operando
;El funcionamiento de esto es "sencillo", comprueba si hay unidades, si las hay, comprueba si hay decenas, si las hay comrpueba centenas; caso contrario, lo coloca en la correspondiente

	lda operando2v1
	cpi 99h
	jnz sv2
	mov A,E
	sbi 30h
	sta operando2v1
	jmp tecla_final
sv2:
	lda operando2v2
	cpi 99h
	jnz sv3
	mov A,E
	sbi 30h
	sta operando2v2
	jmp tecla_final
sv3:
	lda operando2v3
	cpi 99h
	jnz no_tecla;Significa que ya hay 3 numeros introducidos 
	mov A,E
	sbi 30h
	sta operando2v3
	jmp tecla_final

primerValor:; Repetir lo anterior
	lda operando1v1
	cpi 99h
	jnz pv2
	mov A,E
	sbi 30h
	sta operando1v1
	jmp tecla_final
pv2:
	lda operando1v2
	cpi 99h
	jnz pv3
	mov A,E
	sbi 30h
	sta operando1v2
	jmp tecla_final
pv3:
	lda operando1v3
	cpi 99h
	jnz no_tecla
	mov A,E
	sbi 30h
	sta operando1v3
	jmp tecla_final


es_operador:; LLega hasta aqui si el resultado es un operador(signo)
	lda operando1v1;primero comprueba si esta el primer operando
	cpi 99h
	jz num_negativo1; Si no hay, pensaremos que es un signo menos para el operando, saltará a numnegativo1
	lda operacion;comprobamos si hay una operacion, si la hay, la pondremos
	cpi 00h
	jz operando
	lda operando2v1; en caso de que no haya, miraremos si hay segundo operando, podria ser el signo menos
	cpi 99h
	jz num_negativo2
	mov A,E; si resulta que no es ninguna de las anteriores, solo queda que sea el igual, asi que se imprime y comienza la operacion
	cpi 3Dh
	jz igual
	jmp no_tecla


num_negativo1:; Asignamos el bit de signo del primer operando. Comieza positivo, y va pasando de 0(positivo) a 1(negativo). Esta a prueba de que alguien añada dos -
	mov A,E
	cpi 2Dh
	jnz no_tecla
	
	lda soperando1; si estaba en 1, pasa a 0. Si estaba en 0, pasa a 1
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

num_negativo2:; Sigue el mismo patron que el num_negativo1
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


operando:;El caso del operando,simplemente se guarda el valor en memoria
	lda operacion
	cpi 00h
	jnz no_tecla
	mov A,E
	sta operacion
	jmp tecla_final

igual:; comprueba antes de que ambos operandos esten listos

	lda operando1v1
    	cpi 99h
    	jz no_tecla
   	lda operando2v1
    	cpi 99h
    	jz no_tecla
    	lda operacion; El caso en el que la primera parte de la operacion se acaba
    	cpi 00h
    	jz no_tecla


	push H
	push D
;coloca todos los valores a 0 de os registros que pretendo usar
	mvi A,00h
	mov H,A
	mov L,A
	mov D,A
	mov E,A
FormarValor1:; Esta parte del programa "monta" el numero a partir de las cifras.

;Primero comprueba si hay valor de las centenas, sino salta a dosoperandop(se encargaria de montar s es un numero con decenas) o en su defecto, este(dosoperandop) saltaria a uno encargado de montar las unidades
	
lda operando1v3
	cpi 99h
	jz dosoperandop

	lda operando1v1;Coge el valor de las centenas, las multiplica por 100 y las mete en HL
	call multiplica100
	mov E,A
	DAD D
	lda operando1v2; Coge el valor de decenas, las multiplica por 100 y las suma a HL
	call multiplica10	
	mov E,A
	DAD D
	lda operando1v3; Suma a HL el valor de las unidades
	mov E,A
	DAD D
	mov A,H
	sta ro11
	mov A,L
	sta ro12
	jmp FormarValor2

dosoperandop:; Hace lo mismo que el anterior pero solo con decenas
	lda operando1v2
	cpi 99h
	jz unoperandop


	lda operando1v1
	call multiplica10
	mov E,A
	DAD D
	lda operando1v2
	mov E,A
	DAD D
	mov A,H
	sta ro11
	mov A,L
	sta ro12
	jmp FormarValor2

	
unoperandop:; este es el caso de solo uar unidades

	lda operando1v1
	sta ro12


FormarValor2:; mismo proceso que FormarValor1.

	mvi A,00h
	mov H,A
	mov L,A
	mov D,A
	mov E,A


	lda operando2v3
	cpi 99h
	jz dosoperando2

	lda operando2v1
	call multiplica100
	mov E,A
	DAD D
	lda operando2v2
	call multiplica10	
	mov E,A
	DAD D
	lda operando2v3
	mov E,A
	DAD D
	mov A,H
	sta ro21
	mov A,L
	sta ro22

	jmp endigual

dosoperando2:


	lda operando2v2
	cpi 99h
	jz unoperando2

	lda operando2v1
	call multiplica10
	mov E,A
	DAD D
	lda operando2v2
	mov E,A
	DAD D
	mov A,H
	sta ro21
	mov A,L
	sta ro22

	jmp endigual
unoperando2:
	
	lda operando2v1
	sta ro22

endigual:;El final del igual, realiza la operacion, y restablece los valores de memoria

	pop D
	pop H

	mvi A,3Dh
	stax B
	inx B
	call operar




	mvi A,00h
	sta soperando1
	sta soperando2
	sta operacion
	sta ro11
	sta ro12
	sta ro21
	sta ro22
	sta r1
	sta r2
	mvi	A,99h
	sta operando1v1
	sta operando1v2
	sta operando1v3
	sta operando2v1
	sta operando2v2
	sta operando2v3


	ret


tecla_final:; Imprime la tecla
	mov A,E
	stax B
	inx B


no_tecla: ; No existe tecla y return
	ret




operar:;Subrutina para operar
	push H
	push psw

;Comienza escogiendo la opeacion que se va a hacer, segun el operando

	lda operacion
	cpi 2Bh
	jz sum

	cpi 2Dh
	jz res

	cpi 26h
	jz and

	cpi 7Ch
	jz or

	jmp ERROR; Caso extraordinario...


sum:;realiza la suma llamando  a la subrutina
	
	call suma
	jmp finalop

res:; cambia el bit de signo del segundo operando y despues hace la suma

	lda soperando2
	cpi 00h
	jz nna3
nnr3:
	dcr A
	jmp endnnr3
nna3:
	inr A
endnnr3:
	sta soperando2

	call suma
	jmp finalop

and:
	call cargar
	call andop
	jmp finalop

or:
	call cargar
	call orop
	jmp finalop

ERROR:	;Imprime el mensaje error
	mvi A,45h
	STAX B
	INX B
	mvi A,52h
	STAX B
	INX B
	mvi A,52h
	STAX B
	INX B
	mvi A,4fh
	STAX B
	INX B
	mvi A,52h
	STAX B
	INX B
	ret


finalop:;fin de la operacion
	pop psw
	pop H
	ret


suma:;Operacion suma y parcialmente, la resta
	push psw
	push D
	push H
;colocamos los valores en los pares HL y DE para hacer la suma
	lda ro11
	mov H,A
	lda ro12
	mov L,A
	lda ro21
	mov D,A
	lda ro22
	mov E,A

;Comprueba si alguno de los valores deben pasarse a negativo

	lda soperando1
	cpi 00h
	jz comp2
	call inverseoH

comp2:
	lda soperando2
	cpi 00h
	jz jmpcomp2
	call inverseoD

jmpcomp2:; una vez con los valores en el correcto signo, hacemos la suma

	DAD D;Si, todo lo anterior para simplemente hacer DAD D. HL+DE=>HL
	mov A,H; movemos el valor de H al acumulador para saber si ha dado positivo o negativo
	cpi 7Fh; lo comparamos con algo mas de 32000, si es mayor será negativo, sino positivo
	jc finsum; SI es positivo ya lo tenemos, sino, lo invertiremos
	call inverseoH
	mvi A,2Dh;Añadiremos el signo de resta
	STAX B
	INX B
finsum:;movemos los resultados a r1 y r2 en memoria 
	mov A,H
	sta r1
	mov A,L
	sta r2

	call imprime;imprimimos el resultado

	pop H
	pop D
	pop PSW
	ret;fin de la subrutina




andop:;La operacion and carga los valores y hace el and de ambos registros 2 a 2
	push H
	push D
	push PSW

	lda ro11
	mov H,A
	lda ro21
	ana H
	sta r1
	lda ro12
	mov H,A
	lda ro22
	ana H
	sta r2

	mvi A,00h
	sta r1;PARA QUE NO DE ERROR AL IMPRIMIR POR SER MAYOR QUE 255

	call imprime; imprime el resultado
	
	pop PSW
	pop D
	pop H
	ret

orop:;carga los valores y hace el or 2 a 2, igual que el and
	push H
	push D
	push PSW

	lda ro11
	mov H,A
	lda ro21
	ora H
	sta r1
	lda ro12
	mov H,A
	lda ro22
	ora H
	sta r2
	
	mvi A,00h
	sta r1;PARA QUE NO DE ERROR AL IMPRIMIR POR SER MAYOR QUE 255
	call imprime; imprime los valores
	
	pop PSW
	pop D
	pop H
	ret


imprime:;subrutina para imprimir
	push PSW
	push H
	push D
	mvi A,00h
	mov H,A

	lda r1;Si r1 contiene algun valor(entonces mayor que 255), saldra error. Asi queda establecido en el ejercicio, deberia ser capaz de operar hasta los 1000, siendo capaz de sumarlos, pero no imprimirlos
	cpi 00h
	jnz prefin
centenasim:;si hay valor de centenas resta 100 hasta que el valor sea menor a 100, y la cantidad de iteraciones es la cifra
	lda r2
	cpi 64h
	jc decenasimp;sino salta a imprimir decenas

bucleimpcent:;bucle para restar 100
	sbi 64h
	mov D,A
	inr H
	cpi 63h
	jnc bucleimpcent
	mov L,A
	mov A,H
	adi 30h
	STAX B;imprime la cifra
	INX B
	mov A,L
	sta r2
	jmp decenasim
decenasimp:;Aqui llega si no hay centeanas, entonces imrpime un 0 y prosigue
	mvi A,00h
	adi 30h
	STAX B
	INX B
	lda r2
decenasim:; hace va restando 10 hasta que el numeoro sea menor que 10, despues imprime ese valor, sino, salta a unidades
	mvi A,00h
	mov H,A
	lda r2
	cpi 0Ah
	jc unidadesimp;salta a unidades
	lda r2
bucleimpde:;bucle para restar 10
	sbi 0Ah
	mov D,A
	inr H
	cpi 09h
	jnc bucleimpde
	mov L,A
	mov A,H
	adi 30h
	STAX B
	INX B
	mov A,L
	sta r2
	jmp unidadesim

unidadesimp:;no hay decenas, entonces imprime un 0 y prosigue
	mvi A,00h
	adi 30h
	STAX B
	INX B
	lda r2

unidadesim:; simplemente imprime el valor de la s unidades
	mvi A,00h
	mov H,A
	lda r2
	adi 30h
	STAX B
	INX B
	jmp finimprime

prefin:;En caso de que haya un error llama a la subrutina error
call ERROR


finimprime:;Despues de imprimir las cifras , hace dos espacion en blanco y vuelve.


	mvi A,00h
	STAX B
	INX B
	mvi A,00h
	STAX B
	INX B

	pop D
	pop H
	pop PSW
	ret




check_allowed:;Esta subrutina se encarga de checkear los numeros, ya estaba implementada en el codigo base proporcionado
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


check_numero:; A diferenceia de check_allowed, esta solo carga los valores numericos, pero realiza las misamas operaciones
	push D
	push H
	mvi E,allowed_countn
	lxi H, allowed
	jmp allowed_loop







MirarSiNegativos:
	push psw
	lda soperando1
	cpi 00h
	jz startop1
	lda operando1v1
	call inverse
	sta operando1v1

startop1:	
	lda soperando2
	cpi 00h
	jz startop2
	lda operando2v1
	call inverse
	sta operando2v1
startop2:
	pop psw
ret



inverse:;invierte un numero de 8 bits. Hay 3 maneras, restando 2 veces el valor; restando el valor a 0; hacer un xor y sumar uno para ca2. Hay mas pero son mas complejas
	push D
	mov D,A
	sub D
	sub D
	pop D
	ret

inverseoH2:;invierte el par HL
push psw
	mvi A,FFh
	xra H
	inx H
pop psw
	ret
inverseoD2:;invierte el par DE
push psw
	mvi A,FFh
	xra D
	inx D
pop psw
	ret
inverseoH:;invierte el par HL
push psw
	mvi A,FFh
	xra H
	mov H,A
	mvi A,FFh
	xra L
	mov L,A
	inx H
pop psw
	ret
inverseoD:;invierte el par DE
push psw
	mvi A,FFh
	xra D
	mov D,A
	mvi A,FFh
	xra E
	mov E,A
	inx D
	
pop psw
	ret


mod10:;dado un numero en acc, devuelve el modulo de 10 y la cantidad de iteraciones en L
	inr L
	sbi 0Ah
	cpi 0Ah
	jnc mod10

	ret

mod100:; lo mismo que mod10, pero con 100
	inr L
	sbi 64h
	cpi 64h
	jnc mod100

	ret



multiplica10:; dado el acc, lo multiplica por 10
	push h
	mov h,A
	mvi l,09h
	bucle10:
	add h
	dcr l
	jnz bucle10
	pop h
	ret

multiplica100:; dado el acc, lo multiplica por 100
	push h
	mov h,A
	mvi l,63h
	bucle100:
	add h
	dcr l
	jnz bucle100
	pop h
	ret

cargar:
;colocamos los valores en los pares HL y DE para hacer la suma
	lda ro11
	mov H,A
	lda ro12
	mov L,A
	lda ro21
	mov D,A
	lda ro22
	mov E,A

;Comprueba si alguno de los valores deben pasarse a negativo

	lda soperando1
	cpi 00h
	jz comp2x
	call inverseoH

comp2x:
	lda soperando2
	cpi 00h
	jz jmpcomp2x
	call inverseoD
jmpcomp2x:
mov A,H
sta ro11
mov A,L
sta ro12
mov A,D
sta ro21
mov A,E
sta ro22
ret
