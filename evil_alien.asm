; Evil Alien
; By Matt Johnson (https://github.com/mjohnson108)
; Adapted from "Computer Spacegames" by Daniel Isaaman and Jenny Tyler, Usborne Publishing
; https://usborne.com/gb/books/computer-and-coding-books
; nasm -g -f elf64 evil_alien.asm
; ld -o evil_alien evil_alien.o

section .data

	    text1		        db	    'EVIL ALIEN', 0x0a
	    text1Len	        equ	$-text1
	    text2		        db	    'X POSITION (0 TO 9)?', 0x0a
	    text2Len	        equ	$-text2
	    text3		        db	    'Y POSITION (0 TO 9)?', 0x0a
	    text3Len	        equ	$-text3
	    text4		        db	    'DISTANCE (0 TO 9)?', 0x0a
	    text4Len	        equ	$-text4
	    text5		        db	    'SHOT WAS '
	    text5Len	        equ	$-text5
	    text6		        db	    'NORTH'
	    text6Len	        equ	$-text6
	    text7		        db	    'SOUTH'
	    text7Len	        equ	$-text7
	    text8		        db	    'EAST'
	    text8Len	        equ	$-text8
	    text9		        db	    'WEST'
	    text9Len	        equ	$-text9
	    text10		        db	    0x0a
	    text10Len	        equ	$-text10
	    text11		        db	    'TOO FAR', 0x0a
	    text11Len	        equ	$-text11
	    text12		        db	    'NOT FAR ENOUGH', 0x0a
	    text12Len	        equ	$-text12
	    text13		        db	    'YOUR TIME HAS RUN OUT!!', 0x0a
	    text13Len	        equ	$-text13
	    text14		        db	    '*BOOM* YOU GOT HIM!', 0x0a
	    text14Len	        equ	$-text14

        ; code to clear the screen
        cls_code            db      0x1b, '[2J', 0x1b, '[H'
        clsLen              equ     $-cls_code

    	; take random numbers from /dev/urandom
	    errMsgRand         	db      'Could not open /dev/urandom', 0x0a
	    errMsgRandLen      	equ     $-errMsgRand

	    randSrc         	db      '/dev/urandom', 0x0
	    randNum         	db      0

	    ; input buffer for player input
	    inbuf    			times 10 db 0
	    inbufLen	    	equ $-inbuf
	    null_char	    	db 0

section .bss

	    S_var		        resb	1
	    G_var		        resb	1
	    X_var		        resb	1
	    Y_var		        resb	1
	    D_var		        resb	1
	    I_var		        resb	1
	    X1_var		        resb	1
	    Y1_var		        resb	1
	    D1_var		        resb	1

section .text

    	global _start

_start:
_5:	    ; CLS
        mov rsi, cls_code
        mov rdx, clsLen
        call write_out
_10:	; PRINT "EVIL ALIEN"
	    mov rsi, text1
	    mov rdx, text1Len
	    call write_out
_20:	; LET S=10
	    mov byte [S_var], 10
_30:	; LET G=4
    	mov byte [G_var], 4
_40:	; LET X=INT(RND*S)
	    movzx rax, byte [S_var]
	    xor ecx, ecx
	    call rand_func
	    mov byte [X_var], dl
_50:	; LET Y=INT(RND*S)
	    movzx rax, byte [S_var]
	    xor ecx, ecx
	    call rand_func
	    mov byte [Y_var], dl
_60: 	; LET D=INT(RND*S)
	    movzx rax, byte [S_var]
	    xor ecx, ecx
	    call rand_func
	    mov byte [D_var], dl
_70:	; FOR I=1 TO G
    	mov byte [I_var], 1
_80:	; PRINT "X POSITION (0 TO 9)?" 
	    mov rsi, text2
	    mov rdx, text2Len
	    call write_out
_85:	; INPUT X1
	    call read_string
	    mov rsi, inbuf 
	    call string_to_num
	    mov [X1_var], cl
_90:	; PRINT "Y POSITION (0 TO 9)?"
	    mov rsi, text3
	    mov rdx, text3Len
	    call write_out
_100:	; INPUT Y1
	    call read_string
	    mov rsi, inbuf 
	    call string_to_num
	    mov [Y1_var], cl
_110:	; PRINT "DISTANCE (0 TO 9)?"
	    mov rsi, text4
	    mov rdx, text4Len
	    call write_out
_120:	; INPUT D1
	    call read_string
	    mov rsi, inbuf 
	    call string_to_num
	    mov [D1_var], cl
_130:	; IF X=X1 AND Y=Y1 AND D=D1 THEN GOTO 300
	    mov al, byte [X_var]
	    cmp al, [X1_var]
	    jne _140
	    mov al, byte [Y_var]
	    cmp al, [Y1_var]
	    jne _140
	    mov al, byte [D_var]
	    cmp al, [D1_var]
	    jne _140
	    jmp _300
_140:	; PRINT "SHOT WAS ";
	    mov rsi, text5
	    mov rdx, text5Len
	    call write_out
_150:	; IF Y1>Y THEN PRINT "NORTH";
	    mov al, [Y1_var]
	    cmp al, [Y_var]
	    jle _160
	    mov rsi, text6
	    mov rdx, text6Len
	    call write_out
_160:	; IF Y1<Y THEN PRINT "SOUTH";
	    mov al, [Y1_var]
	    cmp al, [Y_var]
	    jge _170
	    mov rsi, text7
	    mov rdx, text7Len
	    call write_out
_170:	; IF X1>X THEN PRINT "EAST";
	    mov al, [X1_var]
	    cmp al, [X_var]
	    jle _180
	    mov rsi, text8
	    mov rdx, text8Len
	    call write_out
_180:	; IF X1<X THEN PRINT "WEST";
	    mov al, [X1_var]
	    cmp al, [X_var]
	    jge _190
	    mov rsi, text9
	    mov rdx, text9Len
	    call write_out
_190:	; PRINT
	    mov rsi, text10
	    mov rdx, text10Len
	    call write_out
_200:	; IF D1>D THEN PRINT "TOO FAR"
	    mov al, [D1_var]
	    cmp al, [D_var]
	    jle _210
	    mov rsi, text11
	    mov rdx, text11Len
	    call write_out
_210:	; IF D1<D THEN PRINT "NOT FAR ENOUGH"
	    mov al, [D1_var]
	    cmp al, [D_var]
	    jge _220
	    mov rsi, text12
	    mov rdx, text12Len
	    call write_out
_220:	; NEXT I
	    mov al, byte [G_var]
	    cmp byte [I_var], al
	    je _230
	    add byte [I_var], 1
	    jmp _80
_230:	; PRINT "YOUR TIME HAS RUN OUT!!"
	    mov rsi, text13
	    mov rdx, text13Len
	    call write_out
_240:	; STOP
    	jmp exit
_300:	; PRINT "*BOOM* YOU GOT HIM!"
	    mov rsi, text14
	    mov rdx, text14Len
	    call write_out
_310:	; STOP
exit:
	    mov rax, 0x3c       
	    mov rdi, 0
	    syscall



	    ; write a string to stdout
write_out:
        mov rax, 1          
        mov rdi, 1         
	    syscall
	    ret


 
	    ; random number function. Pulls a byte from /dev/urandom which is used as a random number
	    ; >= 0 and < 1. Pass in a multiplier to this in rax, and an offset to add in rcx.
rand_func:
	    push rbp
	    mov rbp, rsp

	    ; on entry, rax is the multiplier, rcx is the offset.
	    ; in practice it's ax and cx, as it will only work for small numbers
	    push rcx
	    push rax

	    ; open the source of randomness
	    mov rax, 2              ; 'open'
	    mov rdi, randSrc        ; pointer to filename
	    mov rsi, 0              ; flags: 0 is O_RDONLY on my system
	    mov rdx, 0              
	    syscall
        
	    cmp rax, -2             ; file not found           
	    je open_error
	    cmp rax, -13            ; permission denied
	    je open_error

	    mov rbx, rax            ; save the file descriptor

	    ; read a byte
	    mov rax, 0              ; 'read'
	    mov rdi, rbx            ; file descriptor
	    mov rsi, randNum        ; memory location to read to
	    mov rdx, 1              ; read 1 byte
	    push rbx               
	    syscall
	    pop rbx

	    ; close it
	    mov rax, 3              ; 'close'
	    mov rdi, rbx            ; file descriptor
	    syscall

	    ; some fixed-point math. 
	    ; say we have 8 bits of fractional part, and that is the
	    ; random number obtained above, so 0<=rand<1
	    movzx rbx, byte [randNum]   
	    pop rax
	    ; multiply the number in rax by 256 to maintain the fixed-point math.
	    shl rax, 8
	    imul bx
	    ; because the result is in dx:ax, dx already contains the integer portion of the random number.
	    ; so don't have to divide by 256*256.
	    ; add the offset in rcx
	    pop rcx
	    add rdx, rcx

	    pop rbp
	    ret

open_error:
	    ; display a simple message and exit if could not open /dev/urandom
	    mov rsi, errMsgRand
	    mov rdx, errMsgRandLen
	    call write_out
	    jmp exit


read_string:
	    push rbp
	    mov rbp, rsp

; player is going to enter something in the terminal
    	mov rcx, 0		; count number of chars entered
get_char:
	    ; read a char into the buffer
	    mov rax, 0		; read
	    mov rdi, 0		; from stdin
	    mov rdx, 1		; 1 char
	    mov rsi, inbuf		; calculate the current offset into input buffer
	    add rsi, rcx		; fill it up one char at a time until newline entered
	    push rsi		; preserve the pointer
	    push rcx		; and the counter
	    syscall
	    pop rcx			; restore
	    pop rsi
	    cmp rax, 0		; check for nothing read
	    je done_read		; for now just quit
	    inc rcx			; increment counter
	    movzx rax, byte [rsi]	; check for newline entered
	    cmp rax, 0x0a
	    je done_read		; break out of loop when user hits return 
	    cmp rcx, inbufLen
	    jge done_read		; let's not read beyond the end of the buffer
	    jmp get_char		; continue
done_read:
	    mov byte [rsi], 0

	    pop rbp
	    ret


string_to_num:
	    push rbp
	    mov rbp, rsp

	    mov rcx, 0			; rcx will be the final number
atoi_loop:
	    movzx rbx, byte [rsi]       	; get the char pointed to by rsi
	    cmp rbx, 0x30               	; Check if char is below '0' 
	    jl exit
	    cmp rbx, 0x39               	; Check if char is above '9'
	    jg exit
	    sub rbx, 0x30               	; adjust to actual number by subtracting ASCII offset to 0
	    add rcx, rbx                	; accumulate number in rcx
	    movzx rbx, byte [rsi+1]     	; check the next char to see if the string continues
	    cmp rbx, 0                  	; string should be null-terminated
	    je done_string			; if it's null we're done converting
	    imul rcx, 10                	; multiply rcx by ten
	    inc rsi                     	; increment pointer to get next char when we loop
	    jmp atoi_loop
done_string:
	    ; rcx is the number
	    pop rbp
	    ret

