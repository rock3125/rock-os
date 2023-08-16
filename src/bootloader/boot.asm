org 0x7c00
bits 16

%define CR 0x0d, 0x0a

; view floppy disk using:   mdir -i build/main_floppy.img

;
; FAT12 header
;
jmp short start
nop

bdb_oem:					db 'MSWIN4.1'		; 8 bytes
bdb_bytes_per_sector:		dw 512
bdb_sectors_per_cluster:	db 1
bdb_reserved_sectors:		dw 1
bdb_fat_count:				db 2
bdb_dir_entries_count:		dw 0e0h
bdb_total_sectors:			dw 2880				; 2800 x 512 = 1.44MB
bdb_media_descriptor_type:	db 0f0h				; f0 = 3.5" fdd
bdb_sectors_per_fat:		dw 9
bdb_sectors_per_track:		dw 18
bdb_heads:					dw 2
bdb_hidden_sectors:			dd 0
bdb_large_sector_count:		dd 0

; extended boot record
ebr_drive_number:			db 0 				; 0x00 floppy, 0x80 hdd
							db 0 				; reserved
ebr_signature:				db 29h
ebr_volume_id:				db 19h, 19h, 41h, 41h	; serial number
ebr_volume_label:			db 'Rock volume'		; 11 bytes
ebr_system_id:				db 'FAT12   '			; 8 bytes


;
; code starts here
;


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
	

;
;  MAIN
;
;
;
main:
	; setup data segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7c00	; stack grows downwards

	; read from disk
	; BIOS should set DL to drive number
	mov [ebr_drive_number], dl

	mov ax, 1 		; LBA=1, second sector on disk
	mov cl, 1 		; 1 sector to read
	mov bx, 0x7e00	; data after bootloader
	call disk_read


	; print message
	mov si, msg_hello
	call puts

	cli ; clear interrupts
	hlt

.halt:
	jmp .halt


;
; Error handlers
;

floppy_error:
	mov si, msg_read_fail
	call puts
	jmp wait_key_and_reboot
	hlt

wait_key_and_reboot:
	mov ah, 0
	int 16h				; wait for key
	jmp 0ffffh:0 		; jump to bios start, reboot

.halt:
	cli 				; disable interrupts
	hlt


;
; disk routines
;

;
; convers an LBA address to CHS address
; params:
;	- ax: LBA address
; ret:
;	- cx [bits 0-5] : sector number
;	- cx [bits 6-15]: cylinder
;	- dh: head
;
lba_to_chs:

	push ax
	push dx

	xor dx, dx
	div word [bdb_sectors_per_track]	; ax = LBA / SectorsPerTrack
										; dx = LBA % SectorsPerTrack
	inc dx
	mov cx, dx

	xor dx, dx
	div word [bdb_heads]				; ax = (LBA / SectorsPerTrack) / Heads
										; dx = (LBA / SectorsPerTrack) % Heads
	mov dh, dl
	mov ch, al
	shl ah, 6
	or cl, ah

	pop ax
	mov dl, al
	pop ax

	ret

;
; Reads sectors from a disk
;
; params:
;	- ax: LBA address
;	- cl: number of sectors to read (up to 128)
;	- dl: drive numbers
;	- es:bx: memory address where to store read data
;
disk_read:
	push ax				; save registers
	push bx
	push cx
	push dx
	push di

	push cx
	call lba_to_chs
	pop ax

	mov ah, 02h
	mov di, 3			; recommend to retry three times

.retry:
	pusha				; save all registers
	stc 				; set carry flag - BIOS'es might not
	int 13h				; carry clear = success
	jnc .done			; jump if so

	; read failed
	popa
	call disk_reset

	dec di
	test di, di
	jnz .retry

.fail:
	; all attempts exhausted
	jmp floppy_error

.done:
	popa

	pop di 			; restore registers
	pop dx
	pop cx
	pop bx
	pop ax
	ret

;
; Reset disk controller
; params:
;	- dl: drive number
;
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret



msg_hello: 			db 'Hello world!', CR, 0
msg_read_fail: 		db 'Disk read failed', CR, 0


times 510-($-$$) db 0
dw 0AA55h

