; Alien Snipers
; By Matt Johnson (https://github.com/mjohnson108)
; Adapted from "Computer Spacegames" by Daniel Isaaman and Jenny Tyler, Usborne Publishing
; https://usborne.com/gb/books/computer-and-coding-books
; nasm -g -f elf64 alien_snipers.asm
; ld -o alien_snipers alien_snipers.o

section .data

        text1		    db		'ALIEN SNIPERS', 0x0a, 0x0a
        text1Len	    equ		$-text1
        text2		    db		'DIFFICULTY (1-10)', 0x0a
        text2Len	    equ		$-text2
        text3		    db		0x0a, 'YOU HIT '
        text3Len	    equ		$-text3
        text3_s		    times 10 db 0
        text4		    db		'/10', 0x0a
        text4Len	    equ		$-text4
        text5		    db		' ', 0x09
        text5Len	    equ		1	
        text5_s		    times 10 db 0

        cls_code        db      	0x1b, '[2J', 0x1b, '[H'
        cls_len         equ     	$-cls_code

        ; ANSI code to switch on and off the cursor
        cursor_off 	db 		0x1b, '[?25l'
        cursor_off_len	equ		$-cursor_off
        cursor_on 	db 		0x1b, '[?25h'
        cursor_on_len	equ		$-cursor_on

        lf		db		0x0a

        ; input buffer for player input
        inbuf		    times 10 db 0
        inbuf_len    	equ $-inbuf
        null_char    	db 		0

        ; for poll
        ; struct pollfd ("man 2 poll")
        fd			    dd	0	; STDIN
        events			dw	1	; POLLIN, as per poll.h
        revents			dw	0

        ; a scratch buffer for number to string conversion
        scratch		    times 10 db 0
        scratchLen		equ $-scratch
        scratchend		db 0

        ; take random numbers from /dev/urandom
        errMsgRand         	db      'Could not open /dev/urandom', 0x0a
        errMsgRandLen      	equ     $-errMsgRand

        randSrc 	       	db      '/dev/urandom', 0x0
        randNum	        	db      0

section .bss

        S_var		     resq		1
        G_var		     resq		1
        D_var		     resq		1
        N_var		     resq		1
        L_str_var	     resq		1
        I_var		     resb		1

        termios		     resb 		36	; for terminal settings

section .text

        global _start

_start:
_10:	; CLS
        mov rsi, cls_code
        mov rdx, cls_len
        call write_out        
_20:	; PRINT "ALIEN SNIPERS"
_30:	; PRINT
        mov rsi, text1
        mov rdx, text1Len
        call write_out
_40:	; PRINT "DIFFICULTY (1-10)"
        mov rsi, text2
        mov rdx, text2Len
        call write_out
_50:	; INPUT D
        call read_string
        mov rsi, inbuf 
        call string_to_num
        mov [D_var], cl
_60:	; IF D<1 OR D>10 THEN GOTO 50
        cmp qword [D_var], 1
        jl _40		; seems to make more sense to go back to line 40?
        cmp qword [D_var], 10
        jg _40
_70:	; LET S=0
        mov qword [S_var], 0
        ; at this point, change the terminal for INKEY$
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
        mov rax, 16			     ; ioctl
        mov rdi, 0			    ; STDIN
        mov rsi, 0x5402			; TCSETS in ioctls.h
        mov rdx, termios		; write updated terminal settings
        syscall
_80:	; FOR G=1 TO 10
        mov qword [G_var], 1
_90: 	; LET L$=CHR$(INT(RND*(26-D)+38))
        mov rax, 26
        sub rax, qword [D_var]
        mov rcx, 0x41	; not 38: "man ascii" gives the char codes
        call rand_func
        mov qword [L_str_var], rdx
_100:	; LET N=INT(RND*D+1)
        mov rax, qword [D_var]	
        mov rcx, 1
        call rand_func
        mov qword [N_var], rdx
_110:	; CLS
        mov rsi, cls_code
        mov rdx, cls_len
        call write_out        
_120:	; PRINT
        mov rsi, lf
        mov rdx, 1
        call write_out
_130:	; PRINT L$,N
        mov rax, qword [L_str_var]
        mov byte [text5], al
        mov rax, qword [N_var]
        mov r9, text5
        mov r10, 2
        mov r11, text5_s
        mov r12, ' ' 		; this is necessary to overwrite any lingering 0 in the buffer should the player
                            ; choose a difficulty of 10. Really the entire buffer should be cleared each time.
        call display_line	
_140:	; FOR I=1 TO 20+D*5
_150: 	; LET I$=INKEY$
        mov rax, 7		; poll
        mov rdi, fd		; pointer to pollfd struct
        mov rsi, 1		; number of fds to monitor (1 in this case)
        imul rdx, qword [D_var], 1000 ; attempt to come up with a timeout based on difficulty
        add rdx, 2000		; timeout milliseconds 
        syscall
_160:	; IF I$<>"" THEN GOTO 190
_170:	; NEXT I
        cmp rax, 0
        jg _190
_180:	; GOTO 200
        jmp _200
_190:	; IF I$=CHR$(CODE(L$)+N) THEN LET S=S+1
        mov rax, 0		; Read in the entered char
        mov rdi, 0
        mov rdx, 1
        mov rsi, I_var
        syscall
        mov rax, qword [L_str_var]
        add rax, qword [N_var]
        and byte [I_var], 11011111b	; force uppercase for comparison
        cmp al, byte [I_var]
        jne _200
        inc qword [S_var]
_200:	; NEXT G
        cmp byte [G_var], 10
        je _210
        inc qword [G_var]
        jmp _90
_210:	; PRINT "YOU HIT ";S;"/10"
        mov rax, qword [S_var]              
        mov r9, text3
        mov r10, text3Len
        mov r11, text3_s
        xor r12, r12
        call display_line
        mov rsi, text4
        mov rdx, text4Len
        call write_out
_220:	; STOP
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
        cmp r12b, 0
        je show_num
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
        mov rcx, 0		    ; count number of chars entered
get_char:
        ; read a char into the buffer
        mov rax, 0		    ; read
        mov rdi, 0		    ; from stdin
        mov rdx, 1		    ; 1 char
        mov rsi, inbuf		; calculate the current offset into input buffer
        add rsi, rcx		; fill it up one char at a time until newline entered
        push rsi		    ; preserve the pointer
        push rcx		    ; and the counter
        syscall
        pop rcx			    ; restore
        pop rsi
        cmp rax, 0		    ; check for nothing read
        je done_read		; for now just quit
        inc rcx			    ; increment counter
        movzx rax, byte [rsi]	; check for newline entered
        cmp rax, 0x0a
        je done_read		; break out of loop when user hits return 
        cmp rcx, inbuf_len
        jge done_read		; let's not read beyond the end of the buffer
        jmp get_char		; continue
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
        je done_string		            ; if it's null we're done converting
        imul rcx, 10                	; multiply rcx by ten
        inc rsi                     	; increment pointer to get next char when we loop
        jmp atoi_loop
done_string:
        ; rcx is the number
        pop rbp
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


; write a string to stdout
write_out:
        mov rax, 1          
        mov rdi, 1         
        syscall
        ret
				
