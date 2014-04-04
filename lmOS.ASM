	use16

;Boot procedure

start:
	push cs
	pop ds		   ;Code and Data inside same segment

	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h
	mov ds, ax		; Set data segment to where we're loaded
	mov es, ax		; Set extra segment to where we're loaded

	mov ax, 4f02h
	mov bx, 10ch
	int 10h 	       ;change video mode

	mov si, system_welcome	   ; Put string position into SI
	call print_string	; Call our string-printing routine
	call newline
	call newline
	call sysready
	call newline
	call prompt
	call input_loop

;Main data area

	system_welcome	db 'LM/0S v1.0.1', 224, 0
	system_ready	db 'Ready', 0
	system_error	db 'Syntax Error', 0
	unknown_fs	db 'Unknown system command', 0
	unknown_lisp	db 'Lisp statement syntax error' ,0
	buffer_overflow db 'Buffer Overflow', 0
	buff		db 20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	newlinechars	db 0ah,0dh,0
	promptstring	db '> ',0
	inputbuff	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;Main input loop

input_loop:
	mov di, inputbuff
.input:
	mov ah,01h
	int 16h
	jnz .got_key
	jmp .input
.got_key:
	mov ah,00h
	int 16h
	cmp ah, 28
	je .input_complete
	stosb					;stosb increments di for us
	mov ah,0eh
	int 10h
	jmp .input
.input_complete:
	call newline
	call newline
	mov si, inputbuff
	call process_input
	call newline
	call newline
	call sysready
	call newline
	call prompt
	mov di, inputbuff
	jmp .input

;Procedure for printing a line to the screen. Called by message functions

print_string:			; Routine: output string in SI to screen
	mov ah, 0Eh		; int 10h 'print char' function
.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h 		; Otherwise, print it
	jmp .repeat
.done:
	ret

;Procedure for processing input once "enter" has been pressed by the user

process_input:
	lodsb
	cmp al, "*"
	je .fs_input
	cmp al, "("
	je .lisp_input
	call syserr
	call flush_buffer
	ret
.fs_input:
	call unknown_fs_command
	call flush_buffer
	ret
.lisp_input:
	call unknown_lisp_command
	call flush_buffer
	ret

flush_buffer:
	mov di,inputbuff
	mov ah,0
	mov bx,0
.flush_loop:
	stosb
	inc bx
	cmp bx,64
	jne .flush_loop
	ret

;Message functions

newline:
	mov si, newlinechars
	call print_string
	ret

prompt:
	mov si, promptstring
	call print_string
	ret

sysready:
	mov si, system_ready
	call print_string
	ret

syserr:
	mov si, system_error
	call print_string
	ret

unknown_fs_command:
	mov si, unknown_fs
	call print_string
	ret

unknown_lisp_command:
	mov si, unknown_lisp
	call print_string
	ret

;Padding to create correct image file size

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature



