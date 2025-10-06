.intel_syntax noprefix
.global _start




_start:
push rbp
mov rbp, rsp
sub rsp, 0x20
#2 bytes for the main socket
#2 bytes for the accepted socket
#2 bytes for the request length



socket_create:
mov rax, 41
mov rdi, 2
mov rsi, 1 
mov rdx, 0
syscall
mov word ptr[rbp], ax 

socka_addr:
sub rsp, 0x10
mov word ptr[rsp], 0x02
mov word ptr[rsp+0x02], 0x5000
mov dword ptr[rsp+0x04], 0x00
mov qword ptr[rsp+0x08], 0

bind:
mov rdi, rax
mov rax, 49
lea rsi, [rsp]
mov rdx, 0x10
syscall

listen:
mov di, word ptr[rbp]
mov rsi, 0
mov rax, 50
syscall

accept:
mov di, word ptr[rbp] 
xor rsi, rsi
xor rdx, rdx
mov rax, 43
syscall
mov word ptr[rbp-2] , ax

fork:
mov rax, 0x39
syscall

cmp rax, 0x00
jne parent

mov di, word ptr[rbp]
mov rax, 3
syscall

child:

read:
sub rsp, 1024
mov di, word ptr[rbp-2]
lea rsi, [rsp]
mov rdx, 1024
mov rax, 0
syscall

mov word ptr[rbp-4], ax

check_request_type:

mov al, byte ptr[rsp]
cmp al, 'G'
jne 1f
mov al, byte ptr[rsp+1]
cmp al, 'E'
jne BAD_request
mov al, byte ptr[rsp+2]
cmp al, 'T'
je GET_request
jne BAD_request

1:
cmp al, 'P'
jne BAD_request
mov al, byte ptr[rsp+1]
cmp al, 'O'
jne BAD_request
mov al, byte ptr[rsp+2]
cmp al, 'S'
jne BAD_request
mov al, byte ptr[rsp+3]
cmp al, 'T'
je POST_request
jne BAD_request

GET_request:
lea rdi, [rsp+4]
call str_len
mov byte ptr[rdi+rax], 0x00
mov rsi, 0
mov rdx, 0
mov rax, 2
syscall

sub rsp, 256

mov rdi, rax
lea rsi, [rsp]
mov rdx, 256
xor rax, rax
syscall

#close
mov rdx, rax
push rdx
push rsi
mov rax, 3
syscall


mov di, word ptr[rbp-2]
lea rsi, [rip + StaticResponse]
mov rdx, 19
mov rax, 1
syscall

pop rsi
pop rdx
mov rax, 1
syscall

mov di, word ptr[rbp-2]
mov rax, 3
syscall


jmp exit

POST_request:
lea rdi, [rsp+5]
call str_len
mov byte ptr[rdi+rax], 0x00
mov rsi, 0x41 
mov rdx, 0777
mov rax, 2
syscall
push rax

lea rdi, [rsp]
mov si, word ptr[rbp-4]
call find_rnrn

pop rdi
lea rsi, [rsp+rax]

mov dx, word ptr[rbp-4]
sub rdx, rax

mov rax, 1
syscall

#close
mov rax, 3
syscall

mov di, word ptr[rbp-2]
lea rsi, [rip + StaticResponse]
mov rdx, 19
mov rax, 1
syscall

;BAD_request:

exit:
mov rax, 60
mov rdi, 0
syscall



Response:
mov rdi, r12
lea rsi, [rip + StaticResponse]
mov rdx, 19
mov rax, 1
syscall

str_len:
xor rcx, rcx
1:
mov al, [rdi + rcx]
cmp al, ' '
je 2f
inc rcx
cmp rcx, 8192
je 3f
jmp 1b 

2:
mov rax, rcx
ret

3:
mov rax, -1
ret

find_rnrn:
#rsi len of request
#rdi pointer to request
xor rcx, rcx
sub rsi, 3

1:
mov al, [rdi + rcx]
cmp al, '\r'
jne 2f
mov al, [rdi + rcx+1]
cmp al, '\n'
jne 2f
mov al, [rdi + rcx+2]
cmp al, '\r'
jne 2f
mov al, [rdi + rcx+3]
cmp al, '\n'
jne 2f
jmp 4f

2:
inc rcx
cmp rcx, rsi
je 3f
jmp 1b

3:
mov rax, -1
ret

4:
sub rcx, 4
mov rax, rcx
ret

parent:
mov di, word ptr[rbp-2]
mov rax, 3
syscall
jmp accept

.section .data
StaticResponse: .asciz "HTTP/1.0 200 OK\r\n\r\n"
GET: .asciz "GET"
POST: .asciz "POST"
