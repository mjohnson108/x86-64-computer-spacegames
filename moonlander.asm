; Moonlander
; By Matt Johnson (https://github.com/mjohnson108)
; Adapted from "Computer Spacegames" by Daniel Isaaman and Jenny Tyler, Usborne Publishing
; https://usborne.com/gb/books/computer-and-coding-books
; nasm -g -f elf64 moonlander.asm
; ld -o moonlander moonlander.o

section .data

        text1			    db		'MOONLANDER', 0x0a
        text1Len		    equ		$-text1
        text2			    db		'TIME '
        text2Len		    equ		$-text2
        text2_s			    times 10 db 0
        text3			    db		'HEIGHT '
        text3Len		    equ		$-text3
        text3_s			    times 10 db 0
        text4			    db		'VEL. '
        text4Len		    equ		$-text4
        text4_s			    times 10 db 0
        text5			    db		'FUEL '
        text5Len		    equ		$-text5
        text5_s			    times 10 db 0
        text6			    db		'BURN? (0-30)', 0x0a
        text6Len		    equ		$-text6
        text7			    db		'YOU CRASHED-ALL DEAD', 0x0a
        text7Len		    equ		$-text7
        text8			    db		'OK-BUT SOME INJURIES', 0x0a
        text8Len		    equ		$-text8
        text9			    db		'GOOD LANDING.', 0x0a
        text9Len		    equ		$-text9

        ; code to clear the screen
        cls_code            db      0x1b, '[2J', 0x1b, '[H'
        cls_len             equ     $-cls_code

        ; input buffer for player input
        inbuf 			    times 10 db 0
        inbufLen	    	equ $-inbuf
        null_char	    	db 0

        ; a scratch buffer for number to string conversion
        scratch		    	times 10 db 0
        scratchLen		    equ $-scratch
        scratchend		    db 0

section .bss

	    T_var			    resq	1
	    H_var			    resq	1
	    V_var			    resq	1
	    F_var			    resq	1
	    B_var			    resq	1	
	    V1_var			    resq	1

section .text

	    global _start

_start:
_10:	; CLS
	    mov rsi, cls_code
        mov rdx, cls_len
        call write_out        
_20:	; PRINT "MOONLANDER"
	    mov rsi, text1
	    mov rdx, text1Len
	    call write_out
_30:	; LET T=0
	    mov qword [T_var], 0
_40:	; LET H=500
	    mov qword [H_var], 500
_50:	; LET V=50
	    mov qword [V_var], 50
_60:	; LET F=120
	    mov qword [F_var], 120
_70:	; PRINT "TIME";T,"HEIGHT";H
        mov rax, qword [T_var]              
        mov r9, text2
        mov r10, text2Len
        mov r11, text2_s
	    mov r12, 0x09                   ; "tab"
        call display_line
	    mov rax, qword [H_var]              
        mov r9, text3
        mov r10, text3Len
        mov r11, text3_s
	    mov r12, 0x0a
        call display_line
_80:	; PRINT "VEL.";V,"FUEL";F
        mov rax, qword [V_var]              
        mov r9, text4
        mov r10, text4Len
        mov r11, text4_s
	    mov r12, 0x09
        call display_line
	    mov rax, qword [F_var]              
        mov r9, text5
        mov r10, text5Len
        mov r11, text5_s
	    mov r12, 0x0a
        call display_line
_90:	; IF F=0 THEN GOTO 140
	    cmp qword [F_var], 0
	    je _140
_100:	; PRINT "BURN? (0-30)"
	    mov rsi, text6
	    mov rdx, text6Len
	    call write_out
_110:	; INPUT B
        call read_string
        mov rsi, inbuf 
        call string_to_num
        mov [B_var], rcx
_120:	; IF B<0 THEN LET B=0
	    cmp qword [B_var], 0
	    jge _130
	    mov qword [B_var], 0
_130:	; IF B>30 THEN LET B=30
	    cmp qword [B_var], 30
	    jle _140
	    mov qword [B_var], 30
_140:	; IF B>F THEN LET B=F
	    mov rax, [F_var]
	    cmp qword [B_var], rax
	    jle _150
	    mov [B_var], rax
_150:	; LET V1=V-B+5
	    mov rax, [V_var]
	    sub rax, [B_var]
	    add rax, 5
	    mov qword [V1_var], rax
_160:	; LET F=F-B
	    mov rax, qword [B_var]
	sub [F_var], rax
_170:	; IF (V1+V)/2>H THEN GOTO 220
	    mov rax, [V1_var]
	    add rax, [V_var]
	    sar rax, 1
	    cmp rax, qword [H_var]
	    jg _220
_180:	; LET H=H-(V1+V)/2
	    mov rax, qword [V1_var]
	    add rax, qword [V_var]
	    sar rax, 1
	    sub qword [H_var], rax
_190:	; LET T=T+1
	    add qword [T_var], 1
_200:	; LET V=V1
	    mov rax, [V1_var]
	    mov [V_var], rax
_210:	; GOTO 70
	    jmp _70
_220:	; LET V1=V+(5-B)*H/V
	    mov rax, 5
	    sub rax, qword [B_var]
	    imul qword [H_var]
	    idiv qword [V_var]
	    add rax, qword [V_var]
	    mov [V1_var], rax
_230:	; IF V1>5 THEN PRINT "YOU CRASHED-ALL DEAD"
	    cmp qword [V1_var], 5
	    jle _240
	    mov rsi, text7
	    mov rdx, text7Len
	    call write_out
	    jmp _260
_240:	; IF V1>1 AND V1<=5 THEN PRINT "OK-BUT SOME INJURIES"
	    cmp qword [V1_var], 1
	    jle _250
	    mov rsi, text8
	    mov rdx, text8Len
	    call write_out
	    jmp _260
_250:	; IF V1<=1 THEN PRINT "GOOD LANDING."
	    mov rsi, text9
	    mov rdx, text9Len
	    call write_out
_260:	; STOP
exit:
	    mov rax, 0x3c       
	    mov rdi, 0
	    syscall


        ; display an output string with a number on the end
        ; this version can display negative numbers, and caller can specify how 
        ; to end the line (in this case, a tab or a newline)
display_line:
        push rbp
        mov rbp, rsp

	    ; 0. Figure out if the number in rax is negative and determine sign appropriately
	    xor r13, r13
	    mov r13b, '+'
	    cmp rax, 0
	    jge itoa_setup
	    ; is negative, setup sign
	    mov r13b, '-'
	    ; do abs
	    cqo
	    xor rax, rdx
	    sub rax, rdx
itoa_setup:
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
	    mov r8, rcx
	    cmp r13b, '+'
	    je past_minus
	    mov byte [rdi], r13b		; sign byte
	    inc rdi
	    inc r8
past_minus:
        ; rcx already set from above
        rep movsb		            ; copy the number string to the output buffer
        mov byte [rdi], r12b		; and put whatever's in r12b at the end of it
show_num:
        ; 3. Write the complete final string to stdout
        mov rsi, r9		    	    ; pointer to final char buffer, r9 is set coming into procedure
        ; calculate number of chars to display
        mov rdx, r10 			    ; length of the preamble, r10 set coming into procedure
        add rdx, r8		    	    ; plus length of the number string we just made
        inc rdx			    	    ; plus one for end char
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
				
				
