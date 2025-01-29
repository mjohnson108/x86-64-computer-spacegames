; Asteroid Belt
; By Matt Johnson (https://github.com/mjohnson108)
; Adapted from "Computer Spacegames" by Daniel Isaaman and Jenny Tyler, Usborne Publishing
; https://usborne.com/gb/books/computer-and-coding-books
; nasm -g -f elf64 asteroid_belt.asm
; ld -o asteroid_belt asteroid_belt.o

section .data

	text1		        db	      'ASTEROID BELT', 0x0a
	text1Len	        equ	      $-text1
	text2		        db	      'CRASHED INTO ASTEROID', 0x0a
	text2Len	        equ	      $-text2
	text3		        db	      'YOU DESTROYED IT', 0x0a
	text3Len	        equ	      $-text3
	text4		        db	      'NOT STRONG ENOUGH', 0x0a
	text4Len	        equ	      $-text4
	text5		        db	      'TOO STRONG', 0x0a
	text5Len	        equ	      $-text5
	text6		        db	      'YOU HIT '
	text6Len	        equ	      $-text6
	text6_s		        times 10 db 0
	text7		        db	      'OUT OF 10', 0x0a
	text7Len	        equ	      $-text7

	lf		            db	      0x0a      ; line feed
	star		        db	      '*'
	tab		            db	      0x09

	; ANSI code to clear the screen
    cls_code            db        0x1b, '[2J', 0x1b, '[H'
    cls_len             equ       $-cls_code

	; ANSI code to switch on and off the cursor
	cursor_off 	        db 	      0x1b, '[?25l'
	cursor_off_len	    equ	      $-cursor_off
	cursor_on 	        db 	      0x1b, '[?25h'
	cursor_on_len	    equ	      $-cursor_on

	; for nanosleep
	; struct timespec
	tv_sec			    dq	      0
	tv_nsec			    dq	      0	

	; for poll
	; struct pollfd ("man 2 poll")
	fd			        dd	      0	; STDIN
	events			    dw	      1	; POLLIN, as per poll.h
	revents			    dw	      0

	; a scratch buffer for number to string conversion
    scratch		    	times 10 db 0
	scratchLen		    equ       $-scratch
	scratchend		    db        0

	; take random numbers from /dev/urandom
	errMsgRand         	db        'Could not open /dev/urandom', 0x0a
	errMsgRandLen      	equ       $-errMsgRand

	randSrc        	    db        '/dev/urandom', 0x0
	randNum        	    db        0

section .bss

	S_var			    resq	  1
	G_var			    resq	  1
	I_var			    resq	  1
	A_var			    resq	  1
	D_var			    resq	  1
	N_var			    resq	  1
	Q_var			    resb	  1

	inbuf			    resb	  1

	termios			    resb 	  36	; for terminal settings

section .text

	global _start

_start:
        ; use ANSI to turn off the cursor
        mov rax, 1
        mov rdi, 1
        mov rsi, cursor_off
        mov rdx, cursor_off_len
        syscall
        ; get the current terminal settings and flip some bits
        ; specifically, for canonical mode and echo
        mov rax, 16			    ; ioctl
        mov rdi, 0			    ; STDIN
        mov rsi, 0x5401			; TCGETS in ioctls.h
        mov rdx, termios		; put terminal settings in this buffer
        syscall
        mov eax, 10			    ; for bitmask, ICANON|ECHO (termbits.h)
        not eax				    ; mask off
        and dword [termios+12], eax	; offset for c_lflag
        ; set the terminal
        mov rax, 16			    ; ioctl
        mov rdi, 0			    ; STDIN
        mov rsi, 0x5402			; TCSETS in ioctls.h
        mov rdx, termios		; write updated terminal settings
        syscall
_10:	; PRINT "ASTEROID BELT"
        mov rsi, text1
        mov rdx, text1Len
        call write_out
        ; insert a pause here to stop the title from being 
        ; instantly wiped by the CLS in line 40
        mov qword [tv_sec], 2	; sleep for 2 seconds
        mov rax, 0x23		    ; nanosleep
        mov rdi, tv_sec
        mov rsi, 0
        syscall
_20:	; LET S=0
        mov qword [S_var], 0
_30:	; FOR G=1 TO 10
        mov qword [G_var], 1
_40:	; CLS
        mov rsi, cls_code
        mov rdx, cls_len
        call write_out        
_50:	; LET A=INT(RND*18+1)
        mov rax, 9	             ; Changed to 9 (from 18) to accommodate terminal limitations
        mov rcx, 1
        call rand_func
        mov qword [A_var], rdx
_60:	; LET D=INT(RND*12+1)
        mov rax, 12
        mov rcx, 1
        call rand_func
        mov qword [D_var], rdx
_70:	; LET N=INT(RND*9+1)
        mov rax, 9
        mov rcx, 1
        call rand_func
        mov qword [N_var], rdx
_80:	; FOR I=1 TO D
        mov qword [I_var], 1
_90:	; PRINT
        mov rsi, lf
        mov rdx, 1
        call write_out
_100:	; NEXT I
        mov al, byte [D_var]
        cmp byte [I_var], al
        je _110
        inc qword [I_var]
        jmp _90
_110:	; FOR I=1 TO N
        mov qword [I_var], 1
_120:	; IF I<>1 AND I<>4 AND I<>7 THEN GOTO 150
        cmp qword [I_var], 1
        je _130
        cmp qword [I_var], 4
        je _130
        cmp qword [I_var], 7
        je _130
        jmp _150
_130:	; PRINT
        mov rsi, lf
        mov rdx, 1
        call write_out
_140:	; PRINT TAB(A)
        mov rcx, qword [A_var]      ; write tab to stdout A times
_140_1:	
        push rcx
        mov rsi, tab
        mov rdx, 1
        call write_out
        pop rcx 
        loop _140_1
_150:	; PRINT "*";
        mov rsi, star
        mov rdx, 1
        call write_out
_160:	; NEXT I
        mov al, byte [N_var]
        cmp byte [I_var], al
        je _170
        inc qword [I_var]
        jmp _120
_170:	; PRINT
        mov rsi, lf
        mov rdx, 1
        call write_out
_180:	; FOR I=1 TO 10
_190:	; LET Q=VAL("0"+INKEY$)
        ; use poll syscall to check stdin with timeout
        mov rax, 7		    ; poll
        mov rdi, fd		    ; pointer to pollfd struct
        mov rsi, 1		    ; number of fds to monitor (1 in this case)
        mov rdx, 1500		; timeout in milliseconds 
        syscall
_200:	; IF Q<>0 THEN GOTO 240
        cmp rax, 0
        jg _240
_210:	; NEXT I
_220:	; PRINT "CRASHED INTO ASTEROID"
        mov rsi, text2
        mov rdx, text2Len
        call write_out
_230:	; GOTO 290
        jmp _290
_240:	; IF Q<>N THEN GOTO 270
        ; read in the entered char
        mov rax, 0
        mov rdi, 0
        mov rdx, 1
        mov rsi, Q_var
        syscall
        mov rax, qword [N_var]
        add rax, 0x30
        cmp byte [Q_var], al
        jne _270
_250:	; PRINT "YOU DESTROYED IT"
        mov rsi, text3
        mov rdx, text3Len
        call write_out
_260:	; LET S=S+1
        inc qword [S_var]
        jmp _290
_270:	; IF Q<N THEN PRINT "NOT STRONG ENOUGH"
        jg _280	
        mov rsi, text4
        mov rdx, text4Len
        call write_out
        jmp _290
_280:	; IF Q>N THEN PRINT "TOO STRONG"
        mov rsi, text5
        mov rdx, text5Len
        call write_out
_290:	; FOR I=1 TO 50
_300:	; NEXT I
        ; Lines 290 and 300 are intended to create a delay, but will execute in negligable time in assembly
        ; use nanosleep with some small time instead
        mov qword [tv_sec], 0	
        mov qword [tv_nsec], 800000000
        mov rax, 0x23		; nanosleep
        mov rdi, tv_sec
        mov rsi, 0
        syscall
        ; clear out the terminal input buffer here in case player accidentally pressed a key during the delay
        mov rax, 7		; poll
        mov rdi, fd		
        mov rsi, 1		
        mov rdx, 0		; just check and return immediately 
        syscall
        cmp rax, 0		; if nothing entered, move on
        je _310
        mov rax, 0		; otherwise read the key from stdin
        mov rdi, 0		; thereby clearing the buffer
        mov rdx, 1
        mov rsi, inbuf
        syscall
_310:	; NEXT G
        cmp byte [G_var], 10
        je _320
        inc qword [G_var]
        jmp _40
_320:	; PRINT "YOU HIT ";S;" OUT OF 10"
        mov rax, qword [S_var]              
        mov r9, text6
        mov r10, text6Len
        mov r11, text6_s
        mov r12, 0x20
        call display_line
        mov rsi, text7
        mov rdx, text7Len
        call write_out
_330:	; STOP
exit:
        ; restore the terminal
        or dword [termios+12], 10
        mov rax, 16
        mov rdi, 0
        mov rsi, 0x5402
        mov rdx, termios
        syscall
        ; turn the cursor back on
        mov rax, 1
        mov rdi, 1
        mov rsi, cursor_on
        mov rdx, cursor_on_len
        syscall

        ; exit
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

        ; 0. Figure out if the number in rax is negative and respond appropriately
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


	; write a string to stdout
write_out:
        mov rax, 1          
        mov rdi, 1         
        syscall
        ret

