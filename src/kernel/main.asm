org 0x7c00
bits 16

%define CR 0x0d, 0x0a

start:
	jmp main

;
; print a string to the screen
; params:
;	ds:si points to the string
;
puts:
	; save regs
	push si
	push ax

.loop:
	lodsb		; load next ascii char into al and inc si
	or al, al	; check zero char
	jz .done

	mov bh ,0
	mov ah, 0x0e	; bios print char
	int 0x10

	jmp .loop

.done:
	pop ax
	pop si
	ret
	


main:
	; setup data segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7c00	; stack grows downwards

	; print message
	mov si, msg_hello
	call puts


	hlt

.halt:
	jmp .halt


msg_hello: db 'Hello world!', CR, 0


times 510-($-$$) db 0
dw 0AA55h

