; Trip into the Future
; By Matt Johnson (https://github.com/mjohnson108)
; Adapted from "Computer Spacegames" by Daniel Isaaman and Jenny Tyler, Usborne Publishing
; https://usborne.com/gb/books/computer-and-coding-books
; nasm -g -f elf64 trip_into_the_future.asm
; ld -o trip_into_the_future trip_into_the_future.o

section .data

        text1			        db		    'TRIP INTO THE FUTURE', 0x0a
        text1Len		        equ		    $-text1
        text2			        db		    'YOU WISH TO RETURN ',
        text2Len		        equ		    $-text2
        text2_s			        times 10 db 0
        text3			        db		    'YEARS INTO THE FUTURE.', 0x0a, 0x0a
        text3Len		        equ		    $-text3
        text4			        db		    'SPEED OF SHIP (0-1)', 0x0a
        text4Len		        equ		    $-text4
        text5			        db		    'DISTANCE OF TRIP', 0x0a
        text5Len		        equ		    $-text5
        text6			        db		    'YOU TOOK ',
        text6Len		        equ		    $-text6
        text6_s			        times 20 db 0
        text6_2			        db		    'YEARS', 0x0a,
        text6_2Len		        equ		    $-text6_2
        text7			        db		    'AND ARRIVED ',
        text7Len		        equ		    $-text7
        text7_s			        times 20 db 0
        text8			        db		    'IN THE FUTURE.', 0x0a
        text8Len		        equ		    $-text8
        text9			        db		    'YOU ARRIVED ON TIME', 0x0a
        text9Len		        equ		    $-text9
        text10			        db		    'NOT EVEN CLOSE', 0x0a
        text10Len		        equ		    $-text10
        text11			        db		    'YOU DIED ON THE WAY', 0x0a
        text11Len		        equ		    $-text11

        ; code to clear the screen
        cls_code                db      	0x1b, '[2J', 0x1b, '[H'
        cls_len                 equ     	$-cls_code

        ; a scratch buffer for number to string conversion
        scratch	    	        times 20 db 0
        scratchLen		        equ $-scratch
        scratchend		        db 0

        ; input buffer for player input
        inbuf 			        times 10 db 0
        inbuf_len	    	    equ $-inbuf
        null_char	    	    db 0

        ; take random numbers from /dev/urandom
        errMsgRand            	db          'Could not open /dev/urandom', 0x0a
        errMsgRandLen          	equ         $-errMsgRand

        randSrc            	    db          '/dev/urandom', 0x0
        randNum         	    db          0

        SSE    			        db	'CPU with SSE2 support is required.', 0x0a
        SSELen 			        equ	$-SSE

        F_mul			        dq	        1000.0		; fixed point multiplier for output

        align 16		        ; align for movapd
        abs_mask            	dq          0x7FFFFFFFFFFFFFFF

section .bss

	    T_var			        resq		1
	    V_var			        resq		1
	    D_var			        resq		1

	    V_int			        resq		1
	    V_fix			        resq		1
	    V_mul			        resq		1

	    D_int			        resq		1
	    D_fix			        resq		1
	    D_mul			        resq		1

	    T1_var			        resq		1
	    T1_int			        resq		1
	    T1_frac			        resq		1

	    T2_var			        resq		1
	    T2_int			        resq		1
	    T2_frac			        resq		1

section .text

	    global _start

_start:	; test for SSE2
        mov rax, 1
        cpuid
        test edx, 1<<26
        jnz _10
        mov rsi, SSE
        mov rdx, SSELen
        call write_out
        jmp exit
_10:	; CLS
	    mov rsi, cls_code
        mov rdx, cls_len
        call write_out        
_20:	; PRINT "TRIP INTO THE FUTURE"
	    mov rsi, text1
	    mov rdx, text1Len
	    call write_out
_30:	; LET T=INT(RND*100+25)
	    mov rax, 100
	    mov rcx, 25
	    call rand_func
	    mov qword [T_var], rdx
_40:	; PRINT "YOU WISH TO RETURN ";T
	    mov rax, qword [T_var]
	    mov r9, text2
	    mov r10, text2Len
	    mov r11, text2_s
	    call display_line_int
_50:	; PRINT "YEARS INTO THE FUTURE."
_60:	; PRINT
	    mov rsi, text3
	    mov rdx, text3Len
	    call write_out
_70:	; PRINT "SPEED OF SHIP (0-1)"
	    mov rsi, text4
	    mov rdx, text4Len
	    call write_out
_80:	; INPUT V
	    call read_string
	    mov rsi, inbuf 
	    call string_to_fixed
	    mov qword [V_int], rax
	    mov qword [V_fix], rcx
	    mov qword [V_mul], rdx
_90:	; IF V>=1 OR V<=0 THEN GOTO 70
	    cmp rax, 1
	    jge _70
	    cmp rcx, 0
	    jle _70
_100:	; PRINT "DISTANCE OF TRIP"
	    mov rsi, text5
	    mov rdx, text5Len
	    call write_out
_110:	; INPUT D
	    call read_string
	    mov rsi, inbuf 
	    call string_to_fixed
	    mov qword [D_int], rax
	    mov qword [D_fix], rcx
	    mov qword [D_mul], rdx
_120: 	; LET T1=D/V
	    cvtsi2sd xmm1, [V_fix]	; convert fixed point of V to double
	    cmp qword [V_mul], 0	; avoid divide-by-zero 
	    je ._120_1
	    cvtsi2sd xmm2, [V_mul]
	    divsd xmm1, xmm2		; xmm1 = V=V_fix/V_mul
._120_1:
	    cvtsi2sd xmm0, [D_fix]	; convert fixed point of D to double
	    cmp qword [D_mul], 0
	    je ._120_2
	    cvtsi2sd xmm2, [D_mul]
	    divsd xmm0, xmm2		; xmm0 = D=D_fix/D_mul
._120_2:
	    divsd xmm0, xmm1		; xmm0 = T1 = D/V
	    movsd [T1_var], xmm0	; save T1 for later
	    ; load back into registers here, fixed point
	    cvttsd2si rax, xmm0		; extract integer portion of T1 to rax, 'truncate'
	    cvtsi2sd xmm4, rax		; restore integer portion
	    subsd xmm0, xmm4		; xmm0 now contains fractional portion of T1
	    mulsd xmm0, [F_mul]		; convert it to fixed point
	    cvtsd2si rbx, xmm0		; extract fixed point rep. of fraction of T1 to rbx, 'round'
	    mov qword [T1_int], rax
	    mov qword [T1_frac], rbx
_130:	; LET T2=T1/SQR(1-V*V)
	    mulsd xmm1, xmm1		; xmm1 = V*V
	    mov rax, 1
	    cvtsi2sd xmm2, rax
	    subsd xmm2, xmm1		; xmm2 = 1-V*V
	    sqrtsd xmm1, xmm2		; xmm1 = SQR(1-V*V)
	    movsd xmm3, [T1_var]	; xmm3 = T1
	    divsd xmm3, xmm1		; xmm3 = T2 = T1/SQR(1-V*V)
	    movsd [T2_var], xmm3	; save T2
	    cvttsd2si rax, xmm3		; convert to fixed point as above
	    cvtsi2sd xmm1, rax
	    subsd xmm3, xmm1
	    mulsd xmm3, [F_mul]
	    cvtsd2si rbx, xmm3
	    mov qword [T2_int], rax
	    mov qword [T2_frac], rbx
_140:	; PRINT "YOU TOOK ";T1;"YEARS"
	    mov r14, qword [T1_int]
	    mov r15, qword [T1_frac]
	    mov r9, text6
	    mov r10, text6Len
	    mov r11, text6_s
	    mov r12b, ' '
	    call display_line_dec
	    mov rsi, text6_2
	    mov rdx, text6_2Len
	    call write_out
_150:	; PRINT "AND ARRIVED ";T2;"YEARS"
	    mov r14, qword [T2_int]
	    mov r15, qword [T2_frac]
	    mov r9, text7
	    mov r10, text7Len
	    mov r11, text7_s
	    mov r12b, ' '
	    call display_line_dec
	    mov rsi, text6_2
	    mov rdx, text6_2Len
	    call write_out
_160:	; PRINT "IN THE FUTURE."
	    mov rsi, text8
        mov rdx, text8Len
        call write_out
_170:	; IF T1>50 THEN GOTO 210
	    cmp qword [T1_int], 50
	    jg _210				; being lazy here; should also look at T1_frac
_180:	; IF ABS(T-T2)<=5 THEN PRINT "YOU ARRIVED ON TIME"
    	; do ABS(T-T2)
	    mov rax, qword [T_var]
	    cvtsi2sd xmm0, rax		    ; xmm0 = T
	    movsd xmm1, [T2_var]		; xmm1 = T2
	    subsd xmm0, xmm1		    ; xmm0 = T-T2
	    movapd xmm1, [abs_mask]      
        andpd xmm0, xmm1            ; xmm0 = ABS(T-T2)
	    ; do the comparison. 
	    ; More laziness. Will figure out how cmpsd works on another day
	    cvtsd2si rax, xmm0
	    cmp rax, 5	; ABS(T-T2)<=5
	    jg _190
	    ; print 'YOU ARRIVED ON TIME'
	    mov rsi, text9
        mov rdx, text9Len
        call write_out
	    jmp _200		            ; jmp exit
_190:	; IF ABS(T-T2)>5 THEN PRINT "NOT EVEN CLOSE"
	    mov rsi, text10
        mov rdx, text10Len
        call write_out
_200:	; STOP
	    jmp exit
_210:	; PRINT "YOU DIED ON THE WAY"
	    mov rsi, text11
        mov rdx, text11Len
        call write_out
_220: 	; STOP
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

	; display a text string followed by an integer number
display_line_int:
	    push rbp
	    mov rbp, rsp

	    ; 1. Convert number to string in scratch buffer
	    mov r8, 10		    	; we divide repeatedly by 10 to convert number to string
	    mov rdi, scratchend		; start from the end of the scratch buffer and work back
	    mov rcx, 0		    	; this will contain the final number of chars
itoa_inner:
	    dec rdi			    	; going backwards in memory
	    mov rdx, 0		    	; set up the division: rax already set coming into procedure
	    div r8			    	; divide by ten
	    add rdx, 0x30	    	; offset the remainder of the division to get the required ascii char
	    mov [rdi], dl			; write the ascii char to the scratch buffer
	    inc rcx			    	; keep track of the number of chars produced
	    cmp rcx, scratchLen		; try not to overfeed the buffer
	    je itoa_done			; break out if we reach the end of the buffer 
	    cmp rax, 0		    	; otherwise keep dividing until nothing left 
	    jne itoa_inner
itoa_done:
	    ; 2. Copy contents of scratch buffer into correct place in output string
	    ; rdi now points to beginning of char string and rcx is the number of chars
	    ; copy number into display buffer
	    mov rsi, rdi
	    mov rdi, r11            ; r11 is set coming into procedure, points to where in memory the number string should go
	    ; rcx already set from above
	    mov r8, rcx;		    ; preserve number of chars in number string 
	    rep movsb		        ; copy the number string to the output buffer
	    mov byte [rdi], 0x0a	; and put a newline on the end of it
show_num:
	    ; 3. Write the complete final string to stdout
	    mov rsi, r9		    	; pointer to final char buffer, r9 is set coming into procedure
	    ; calculate number of chars to display
	    mov rdx, r10 			; length of the preamble, r10 set coming into procedure
	    add rdx, r8		    	; plus length of the number string we just made
	    inc rdx			    	; plus one for newline char
	    mov rax, 1		    	; write
	    mov rdi, 1		    	; to stdout
	    syscall             	; execute

	    pop rbp
	    ret                 	; done


	    ; read in a string from the terminal up until newline
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
	    mov rsi, inbuf	; calculate the current offset into input buffer
	    add rsi, rcx	; fill it up one char at a time until newline entered
	    push rsi		; preserve the pointer
	    push rcx		; and the counter
	    syscall
	    pop rcx			; restore
	    pop rsi
	    cmp rax, 0		; check for nothing read
	    je exit;		; for now just quit
	    inc rcx			; increment counter
	    movzx rax, byte [rsi]	; check for newline entered
	    cmp rax, 0x0a
	    je done_read		; break out of loop when user hits return 
	    cmp rcx, inbuf_len
	    jge exit;		    ; let's not read beyond the end of the buffer
	    jmp get_char		; continue
done_read:
	    mov byte [rsi], 0

	    pop rbp
	    ret

	; convert a string in decimal point notation to a number in fixed point
string_to_fixed:
	    push rbp
	    mov rbp, rsp

	    xor rax, rax		; integer part of number
	    xor rbx, rbx		; fixed-point divisor (power of 10)
	    xor rcx, rcx		; fixed point representation of number
	    xor rdx, rdx		; increment for decimal point location
.loop_top:
	    movzx r8, byte [rsi]	; get next char in rsi
	    cmp r8, 0		    ; is it null? then end
	    je .done_string
	    cmp r8, '.'		    ; have we reached the decimal point?
	    jne .check_num
	    mov rax, rcx		; save off integer part of number
	    mov rdx, 1		    ; now we have fractional part, shift decimal point by 1 each number
	    jmp .next_char
.check_num:
	    cmp r8, 0x30		; check if char is below '0'
	    jl .next_char		; skip
	    cmp r8, 0x39		; check if char is above '9'
	    jg .next_char		; skip 
	    sub r8, 0x30		; adjust to number representation
	    imul rcx, 10		; make space for next number to be added in
	    add rcx, r8		    ; accumulate number in rcx
	    add rbx, rdx		; inc the number of decimal places if in fractional part
.next_char:
	    inc rsi			    ; move onto the next digit in the string
	    jmp .loop_top
.done_string:
	    cmp rbx, 0		    ; calculate the fixed-point divisor
	    jne .loop_div
	    mov rax, rcx
	    jmp .done_all
.loop_div:	
	    imul rdx, 10
	    dec rbx
	    jnz .loop_div
.done_all:
	    ; rax should be the integer part of the entered number
	    ; rcx the full fixed point number
	    ; rdx the divisor for rcx to convert it back to a real

	    pop rbp
	    ret

	; displays a text string followed by a number with a decimal point
display_line_dec:
	    push rbp
	    mov rbp, rsp

	    ; convert number to string.
	    ; r14 is integer part, r15 is fractional part
.setup:
	    mov r8, 10		    ; divide by ten 
	    mov rdi, scratchend	; start from the end of the buffer and work back
	    xor rcx, rcx		; rcx will be number of chars in the buffer
	    mov rax, r15		; start with fractional part
.inner1:
	    dec rdi			    ; going backwards in the buffer
	    xor rdx, rdx		; this will be the string char of the number
	    div r8			    ; divide the number by 10
	    add rdx, 0x30		; offset to ascii char of the number
	    mov byte [rdi], dl	; write it to the buffer
	    inc rcx			    ; increase the number of chars in the buffer
	    cmp rcx, scratchLen	; don't go beyond end of buffer
	    je .done
	    cmp rax, 0		    ; if nothing left, move on
	    jne .inner1		    ; otherwise continue
	    ; with the fractional part in, put in the decimal point
	    dec rdi
	    mov byte [rdi], '.'
	    inc rcx
	    ; now do the integer part
	    mov rax, r14
.inner2:			        ; same process as above
	    dec rdi
	    xor rdx, rdx
	    div r8
	    add rdx, 0x30
	    mov byte [rdi], dl
	    inc rcx
	    cmp rcx, scratchLen
	    je .done
	    cmp rax, 0
	    jne .inner2
.done:
	    ; copy contents of scratch buffer to output string
        mov rsi, rdi
        mov rdi, r11            ; r11 is set coming into procedure, points to where in memory the number string should go
        ; rcx already set from above
        mov r8, rcx;		    ; preserve number of chars in number string 
        rep movsb		        ; copy the number string to the output buffer
        mov byte [rdi], r12b	; and put whatever's in r12b on the end of it
.show_num:
        ; 3. Write the complete final string to stdout
        mov rsi, r9		    	; pointer to final char buffer, r9 is set coming into procedure
        ; calculate number of chars to display
        mov rdx, r10 			; length of the preamble, r10 set coming into procedure
        add rdx, r8		    	; plus length of the number string we just made
        inc rdx			    	; plus one for end char
        mov rax, 1		    	; write
        mov rdi, 1		    	; to stdout
        syscall             	; execute

	    pop rbp
	    ret

	    ; write a string to stdout
write_out:
        mov rax, 1          
        mov rdi, 1         
	    syscall
	    ret
 

