; Intergalactic Games
; By Matt Johnson (https://github.com/mjohnson108)
; Adapted from "Computer Spacegames" by Daniel Isaaman and Jenny Tyler, Usborne Publishing
; https://usborne.com/gb/books/computer-and-coding-books
; nasm -g -f elf64 intergalactic_games.asm
; ld -o intergalactic_games intergalactic_games.o

section .data

	    text1		    db	    'INTERGALACTIC GAMES', 0x0a
	    text1Len	    equ	$-text1
	    text2		    db	    'YOU MUST LAUNCH A SATELLITE', 0x0a
	    text2Len	    equ	$-text2
	    text3		    db	    'TO A HEIGHT OF '
	    text3Len	    equ	$-text3
	    text3_s	        times 10 db 0
	    text4		    db	    'ENTER ANGLE (0-90)', 0x0a
	    text4Len	    equ	$-text4
	    text5		    db	    'ENTER SPEED (0-40000)', 0x0a
	    text5Len	    equ	$-text5
	    text6		    db	    'TOO SHALLOW', 0x0a
	    text6Len	    equ	$-text6
	    text7		    db	    'TOO STEEP', 0x0a
	    text7Len	    equ	$-text7
	    text8		    db	    'TOO SLOW', 0x0a
	    text8Len	    equ	$-text8
	    text9		    db	    'TOO FAST', 0x0a
	    text9Len	    equ	$-text9
	    text10		    db	    "YOU'VE FAILED", 0x0a, "YOU'RE FIRED", 0x0a
	    text10Len	    equ	$-text10
	    text11		    db	    "YOU'VE DONE IT", 0x0a, 'NCTV WINS-THANKS TO YOU', 0x0a
	    text11Len	    equ	$-text11
	
	    ; a scratch buffer for number to string conversion
    	scratch		    times 10 db 0
	    scratchLen		equ $-scratch
	    scratchend		db 0

	    ; input buffer for player input
	    inbuf 			times 10 db 0
	    inbufLen	    equ $-inbuf
	    null_char	    db 0

        ; precomputed table of 256 (very) approximate atan values for byte indexing, e.g. in perl:
        ; use Math::Trig;
        ; print join(", ", (map { sprintf("%d", rad2deg(atan2($_*100/256,3))) } (0..255))), "\n";
        atan_table		db	0, 7, 14, 21, 27, 33, 37, 42, 46, 49, 52, 55, 57, 59, 61, 62, 64, 65, 66, 67, 68, 69, 70, 71, 72, 72, 73, 74, 74, 75, 75, 76, 76, 76, 77, 77, 77, 78, 78, 78, 79, 79, 79, 79, 80, 80, 80, 80, 80, 81, 81, 81, 81, 81, 81, 82, 82, 82, 82, 82, 82, 82, 82, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 85, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 86, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 87, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88

	    ; take random numbers from /dev/urandom
	    errMsgRand         	db      'Could not open /dev/urandom', 0x0a
	    errMsgRandLen      	equ     $-errMsgRand

	    randSrc         	db      '/dev/urandom', 0x0
	    randNum         	db      0

	    SSE     			db	'CPU with SSE2 support is required.', 0x0a
	    SSELen  			equ	$-SSE

    	V_multiplier        dq      3000.0
	    align 16	        ; must align this to 16 bytes for movapd later on
    	abs_mask            dq      0x7FFFFFFFFFFFFFFF

section .bss

	    H_var		        resw	1
	    G_var		        resb	1
	    A_var		        resq	1
	    A_abs		        resq	1
	    V_var		        resq	1
	    V_abs		        resq	1

section .text
    	global _start

_start:
        ; before proceeding, check for SSE2
        ; not sure what the chances are of finding an x86 64 cpu without
        ; SSE2 support, but it seems like a good idea to check anyway
        mov rax, 1
        cpuid
        test edx, 1<<26
        jnz _10
        mov rsi, SSE
        mov rdx, SSELen
        call write_out
        jmp exit
        ; no CLS in this one
_10:	; PRINT "INTERGALACTIC GAMES"
        mov rsi, text1
        mov rdx, text1Len
        call write_out
_20:	; LET H=INT(RND*100+1)
        mov rax, 100
        mov rcx, 1
        call rand_func
        mov word [H_var], dx
_30:	; PRINT "YOU MUST LAUNCH A SATELLITE"
        mov rsi, text2
        mov rdx, text2Len
        call write_out
_40:	; PRINT "TO A HEIGHT OF ";H	; listing doesn't mention any units
        movzx rax, word [H_var]              
        mov r9, text3
        mov r10, text3Len
        mov r11, text3_s
        call display_line
_50:	; FOR G=1 TO 8
        mov byte [G_var], 1
_60:	; PRINT "ENTER ANGLE (0-90)"
        mov rsi, text4
        mov rdx, text4Len
        call write_out
_70:	; INPUT A
        call read_string
        mov rsi, inbuf 
        call string_to_num
        mov [A_var], rcx
_80:	; PRINT "ENTER SPEED (0-40000) ; looks like a typo on this line, should have '"'
        mov rsi, text5
        mov rdx, text5Len
        call write_out
_90:	; INPUT V
        call read_string
        mov rsi, inbuf 
        call string_to_num
        mov [V_var], rcx
_100:	; LET A=A-ATN(H/3)*180/3.14159
        ; Here we do (H/3) * scaling factor of 7.5 for lookup table
        ; Which is (H*15)/6
        ; Since H is constant in the loop we don't really have to do all this every time, can put it before the loop. But here we are
        mov ax, word [H_var]
        mov bx, 15
        mul bx				
        mov bx, 6
        div bx
        ; al contains offset into the lookup table
        ; perform lookup to get (very) approximate atan value
        mov rbx, atan_table
        xlatb
        ; atan table already converted to degrees
        sub [A_var], rax ; A=A-ATN(H/3)*rad2deg
_110:	; LET V=V-3000*SQR(H+1/H)
        movzx rax, word [H_var]	
        ; use SSE2 instructions for this one
        cvtsi2sd xmm1, rax	        ; xmm1 = H
        inc rax                     ; rax = H+1
        cvtsi2sd xmm0, rax          ; xmm0 = H+1
        divsd xmm0, xmm1            ; xmm0 = H+1/H
        sqrtsd xmm1, xmm0           ; xmm1 = SQR(H+1/H)
        movsd xmm0, [V_multiplier]  ; xmm0 = 3000
        mulsd xmm0, xmm1            ; xmm0 = 3000*SQR(H+1/H)
        mov rax, [V_var]            ; rax = V
        cvtsi2sd xmm1, rax          ; xmm1 = V
        subsd xmm1, xmm0            ; xmm1 = V-3000*SQR(H+1/H)
        cvtsd2si rax, xmm1      
        mov [V_var], rax	    ; V=V-3000*SQR(H+1/H) 
_120:	; IF ABS(A)<2 AND ABS(V)<100 THEN GOTO 200 ; typo, should be GOTO 210
        ; do ABS(V)
        movapd xmm0, [abs_mask]     ; this is apparently the way to do abs in SSE2
        andpd xmm1, xmm0            ; clear sign bit. xmm1 = ABS(V-3000*SQRT(H+1/H))
        cvtsd2si rax, xmm1      
        mov [V_abs], rax
        ; do ABS(A)
        mov rax, [A_var]
        ; this bit manipulation is apparently the way to do abs on a general register
        cqo
        xor rax, rdx
        sub rax, rdx
        mov [A_abs], rax
        ; do "ABS(A)<2 AND ABS(v)<100"
        cmp qword [A_abs], 2
        jge _130
        cmp qword [V_abs], 100
        jge _130
        ; do "GOTO 200" (actually 210)
        jmp _210
_130:	; IF A<-2 THEN PRINT "TOO SHALLOW"	; assume that <=, >= etc. is meant in lines 130-160 
        cmp qword [A_var], -2
        jg _140
        mov rsi, text6
        mov rdx, text6Len
        call write_out
_140:	; IF A>2 THEN PRINT "TOO STEEP"	
        cmp qword [A_var], 2
        jl _150
        mov rsi, text7
        mov rdx, text7Len
        call write_out
_150:	; IF V<-100 THEN PRINT "TOO SLOW"
        cmp qword [V_var], -100
        jg _160
        mov rsi, text8
        mov rdx, text8Len
        call write_out
_160:	; IF V>100 THEN PRINT "TOO FAST"
        cmp qword [V_var], 100
        jl _170
        mov rsi, text9
        mov rdx, text9Len
        call write_out
_170:	; NEXT G
        cmp byte [G_var], 8
        je _180
        add byte [G_var], 1
        jmp _60
_180:	; PRINT "YOU'VE FAILED"
_190:	; PRINT "YOU'RE FIRED"
        mov rsi, text10
        mov rdx, text10Len
        call write_out
_200:	; STOP
        jmp exit
_210:	; PRINT "YOU'VE DONE IT"
_220:	; PRINT "NCTV WINS-THANKS TO YOU"
        mov rsi, text11
        mov rdx, text11Len
        call write_out
_230:	; STOP
        exit:
        mov rax, 0x3c       
        mov rdi, 0
        syscall


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


        ; display an output string with a number on the end
display_line:
        push rbp
        mov rbp, rsp

        ; 1. Convert number to string in scratch buffer
        mov r8, 10		    	    ; we divide repeatedly by 10 to convert number to string
        mov rdi, scratchend		    ; start from the end of the scratch buffer and work back
        mov rcx, 0		    	    ; this will contain the final number of chars
itoa_inner:
        dec rdi			    	    ; going backwards in memory
        mov rdx, 0		    	    ; set up the division: rax already set coming into procedure
        div r8			    	    ; divide by ten
        add rdx, 0x30	    		; offset the remainder of the division to get the required ascii char
        mov [rdi], dl			    ; write the ascii char to the scratch buffer
        inc rcx			    	    ; keep track of the number of chars produced
        cmp rcx, scratchLen		    ; try not to overfeed the buffer
        je itoa_done			    ; break out if we reach the end of the buffer 
        cmp rax, 0		    	    ; otherwise keep dividing until nothing left 
        jne itoa_inner
itoa_done:
        ; 2. Copy contents of scratch buffer into correct place in output string
        ; rdi now points to beginning of char string and rcx is the number of chars
        ; copy number into display buffer
        mov rsi, rdi
        mov rdi, r11            	; r11 is set coming into procedure, points to where in memory the number string should go
        ; rcx already set from above
        mov r8, rcx;		    	; preserve number of chars in number string 
        rep movsb		            ; copy the number string to the output buffer
        mov byte [rdi], 0x0a		; and put a newline on the end of it
show_num:
        ; 3. Write the complete final string to stdout
        mov rsi, r9		    	    ; pointer to final char buffer, r9 is set coming into procedure
        ; calculate number of chars to display
        mov rdx, r10 			    ; length of the preamble, r10 set coming into procedure
        add rdx, r8		    	    ; plus length of the number string we just made
        inc rdx			    	    ; plus one for newline char
        mov rax, 1		    	    ; write
        mov rdi, 1		    	    ; to stdout
        syscall             		; execute

        pop rbp
        ret                 		; done


read_string:
	    push rbp
	    mov rbp, rsp

; player is going to enter something in the terminal
    	mov rcx, 0		            ; count number of chars entered
get_char:
	    ; read a char into the buffer
	    mov rax, 0		            ; read
	    mov rdi, 0		            ; from stdin
	    mov rdx, 1		            ; 1 char
	    mov rsi, inbuf		        ; calculate the current offset into input buffer
	    add rsi, rcx		        ; fill it up one char at a time until newline entered
	    push rsi		            ; preserve the pointer
	    push rcx		            ; and the counter
	    syscall
	    pop rcx			            ; restore
	    pop rsi
	    cmp rax, 0		            ; check for nothing read
	    je done_read		        ; for now just quit
	    inc rcx			            ; increment counter
	    movzx rax, byte [rsi]	    ; check for newline entered
	    cmp rax, 0x0a
	    je done_read		        ; break out of loop when user hits return 
	    cmp rcx, inbufLen
	    jge done_read		        ; let's not read beyond the end of the buffer
	    jmp get_char		        ; continue
done_read:
	    mov byte [rsi], 0

	    pop rbp
	    ret


string_to_num:
	    push rbp
	    mov rbp, rsp

	    mov rcx, 0			            ; rcx will be the final number
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
	    je done_string			        ; if it's null we're done converting
	    imul rcx, 10                	; multiply rcx by ten
	    inc rsi                     	; increment pointer to get next char when we loop
	    jmp atoi_loop
done_string:
	    ; rcx is the number
	    pop rbp
	    ret

	    ; write a string to stdout
write_out:
        mov rax, 1          
        mov rdi, 1         
	    syscall
	    ret
				
