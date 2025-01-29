; Starship Takeoff
; By Matt Johnson (https://github.com/mjohnson108)
; Adapted from "Computer Spacegames" by Daniel Isaaman and Jenny Tyler, Usborne Publishing
; https://usborne.com/gb/books/computer-and-coding-books
; nasm -g -f elf64 starship_takeoff.asm
; ld -o starship_takeoff starship_takeoff.o

section .data

	    ; various text strings used in the game
	    text1		        db	'STARSHIP TAKE-OFF', 0x0a
	    text1Len		    equ	$-text1
	    text2			    db	'GRAVITY= '	
	    text2Len		    equ	$-text2
	    text2_s		        times 10 db 0
	    text3			    db	'TYPE IN FORCE', 0x0a
	    text3Len		    equ	$-text3
	    text4			    db	'TOO HIGH'
	    text4Len		    equ	$-text4
	    text5			    db	'TOO LOW'
	    text5Len		    equ	$-text5
	    text6			    db	', TRY AGAIN', 0x0a
	    text6Len		    equ	$-text6
	    text7			    db	0x0a, 'YOU FAILED -', 0x0a, 'THE ALIENS GOT YOU', 0x0a
	    text7Len		    equ	$-text7
	    text8			    db	'GOOD TAKE OFF', 0x0a
	    text8Len		    equ	$-text8

	    ; a scratch buffer for number to string conversion
	    scratch		        times 10 db 0
	    scratchLen		    equ $-scratch
	    scratchend		    db 0

	    ; input buffer for player input
	    inbuf 			    times 10 db 0
	    inbufLen	        equ $-inbuf
	    null_char	        db 0

	    ; ANSI code to clear the screen
        cls_code            db      0x1b, '[2J', 0x1b, '[H'
        clsLen              equ     $-cls_code

	    ; take random numbers from /dev/urandom
	    errMsgRand         	db      'Could not open /dev/urandom', 0x0a
	    errMsgRandLen      	equ     $-errMsgRand

	    randSrc        	    db      '/dev/urandom', 0x0
	    randNum        	    db      0

section .bss

	    ; in-game variables
	    G_var			    resb	2
	    W_var			    resb	2
	    R_var			    resb	2
	    C_var			    resb	1

section .text

	    global _start

_start:
	    ; try to follow the program listing as closely as possible
_10:	; CLS
        mov rsi, cls_code
        mov rdx, clsLen
        call write_out        
_20:	; PRINT "STARSHIP TAKE-OFF"
        mov rsi, text1  
        mov rdx, text1Len 
	    call write_out
_30:	; LET G=INT(RND*20+1)
	    mov rax, 20
	    mov rcx, 1
	    call rand_func
	    mov word [G_var], dx
_40:	; LET W=INT(RND*40+1)
	    mov rax, 40
	    mov rcx, 1
	    call rand_func
	    mov word [W_var], dx
_50:	; LET R=G*W
	    mov bx, dx
	    movzx rax, word [G_var]
	    imul bx
	    mov word [R_var], ax
_60:	; PRINT "GRAVITY= ";G
	    movzx rax, word [G_var]
	    mov r9, text2
	    mov r10, text2Len
	    mov r11, text2_s
	    call display_line
_70:	; PRINT "TYPE IN FORCE"
	    mov rsi, text3
	    mov rdx, text3Len
	    call write_out
_80:	; FOR C=1 TO 10
	    mov byte [C_var], 1
_90:	; INPUT F
	    call read_string
	    mov rsi, inbuf 
	    call string_to_num
_100:	; IF F>R THEN PRINT "TOO HIGH";
	    movzx rbx, word [R_var]
	    cmp rbx, rcx
	    jg too_high
_110:	; IF F<R THEN PRINT "TOO LOW";
	    jl too_low
_120:	; IF F=R THEN GOTO 190
	    je _190
_130:	; IF C<>10 THEN PRINT ", TRY AGAIN"
	    cmp byte [C_var], 10
	    je _150
	    mov rsi, text6
	    mov rdx, text6Len
	    call write_out
_140:	; NEXT C
	    add byte [C_var], 1
	    jmp _90
_150:	; PRINT
_160:	; PRINT "YOU FAILED -"
_170:	; PRINT "THE ALIENS GOT YOU"
	    mov rsi, text7
	    mov rdx, text7Len
	    call write_out
_180:	; STOP
	    jmp exit
_190:	; print "GOOD TAKE OFF"
	    mov rsi, text8
	    mov rdx, text8Len
	    call write_out
exit:
	    mov rax, 0x3c       
	    mov rdi, 0
	    syscall

;;;;;;;;;;;;;;;;;;;;;;

; display text for too high and too low
too_low:
	    mov rsi, text4
	    mov rdx, text4Len
	    call write_out
	    jmp _130

too_high:
	    mov rsi, text5
	    mov rdx, text5Len
	    call write_out
	    jmp _130

	    ; random number function. Pulls a byte from /dev/urandom which is used as a random number
	    ; >= 0 and < 1. Pass in a multiplier to this in rax, and an offset to add in rcx.
rand_func:
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
	    ret

open_error:
	    ; display a simple message and exit if could not open /dev/urandom
	    mov rsi, errMsgRand
	    mov rdx, errMsgRandLen
	    call write_out
	    jmp exit

	    ; this is to display the random number for the gravity
display_line:
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
	    ret                 	; done


read_string:
	    ; player is going to enter something in the terminal
	    mov rcx, 0		        ; count number of chars entered
get_char:
	    ; read a char into the buffer
	    mov rax, 0		        ; read
	    mov rdi, 0		        ; from stdin
	    mov rdx, 1		        ; 1 char
	    mov rsi, inbuf		    ; calculate the current offset into input buffer
	    add rsi, rcx		    ; fill it up one char at a time until newline entered
	    push rsi		        ; preserve the pointer
	    push rcx		        ; and the counter
	    syscall
	    pop rcx			        ; restore
	    pop rsi
	    cmp rax, 0		        ; check for nothing read
	    je exit;		        ; for now just quit
	    inc rcx			        ; increment counter
	    movzx rax, byte [rsi]	; check for newline entered
	    cmp rax, 0x0a
	    je done_read		    ; break out of loop when user hits return 
	    cmp rcx, inbufLen
	    jge exit;		        ; let's not read beyond the end of the buffer
	    jmp get_char		    ; continue
done_read:
	    mov byte [rsi], 0
	    ret


string_to_num:
	    mov rcx, 0			        ; rcx will be the final number
atoi_loop:
	    movzx rbx, byte [rsi]       ; get the char pointed to by rsi
	    cmp rbx, 0x30               ; Check if char is below '0' 
	    jl exit
	    cmp rbx, 0x39               ; Check if char is above '9'
	    jg exit
	    sub rbx, 0x30               ; adjust to actual number by subtracting ASCII offset to 0
	    add rcx, rbx                ; accumulate number in rcx
	    movzx rbx, byte [rsi+1]     ; check the next char to see if the string continues
	    cmp rbx, 0                  ; string should be null-terminated
	    je done_string			    ; if it's null we're done converting
	    imul rcx, 10                ; multiply rcx by ten
	    inc rsi                     ; increment pointer to get next char when we loop
	    jmp atoi_loop
done_string:
	    ; rcx is the number
	    ret

	    ; write a string to stdout
write_out:
        mov rax, 1          
        mov rdi, 1         
	    syscall
	    ret

