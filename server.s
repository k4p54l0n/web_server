.intel_syntax noprefix
.global _start
_start:

sub rsp, 4096
jmp create_socket

create_socket:
mov rdi, 2
mov rsi, 1
mov rdx, 0
mov rax, 41
syscall
mov r8, rax
jmp initialize_addr

# r8 is socket fd

initialize_addr:
mov QWORD ptr[rsp], 0
mov QWORD ptr[rsp+8], 0
jmp bind_socket

bind_socket:
mov WORD ptr [rsp], 2 # AF_INET
mov WORD ptr [rsp+2], 0x5000 # port(80)
mov DWORD PTR [rsp+4], 0 # address -> listen to all ipv4 interfaces
mov rdi, r8  
mov rsi, rsp
mov rdx, 16
mov rax, 49
syscall
jmp listen 

listen:
mov rdi, r8
mov rsi, 0
mov rax, 50
syscall
jmp accept

accept:
mov rdi, r8
mov rsi, 0
mov rdx, 0
mov rax, 43
syscall
mov r9, rax
jmp read_request

#r9 is client fd

read_request:
mov rax, 0
mov rdi, r9
lea rsi, [rsp+24]
mov rdx, 1024
syscall
jmp static_response


static_response:
mov rdi, r9 #fd returned by accept
lea rsi, [rip+path]
mov rdx, 19
mov rax, 1
syscall
mov rdi, r9
mov rax, 3
syscall
jmp exit

exit:
add rsp, 4096
mov rdi, 0
mov rax, 60
syscall

path:
.asciz "HTTP/1.0 200 OK\r\n\r\n"
