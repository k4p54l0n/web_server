.intel_syntax noprefix
.global _start
_start:

sub rsp, 8192
xor r10, r10 # r10 to null-terminate the request
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
cmp rax, 0
js exit
mov r9, rax
jmp read_request

#r9 is client fd

read_request:
mov rax, 0
mov rdi, r9
lea rsi, [rsp+24]
mov rdx, 1024
syscall
jmp parse_get 

parse_get:
add rsi, 4
jmp parse_request

parse_request:
cmp byte ptr [rsi+r10], 0x20
je open_file
inc r10
jmp parse_request

open_file:
mov byte ptr[rsi+r10], 0
mov rdi, rsi
mov rax, 2
mov rsi, 0
mov rdx, 0
syscall
jmp read_file

read_file:
mov rdi, rax # rax contains the fd of the requested file
mov rax, 0 # read syscall
lea rsi, [rsp+300]
mov rdx, 1024
syscall
mov r12, rax  #bytes read
mov rax, 3
syscall
jmp static_response

write_file:
lea rsi, [rsp+300]
mov rdi, r9
mov rdx, r12
mov rax, 1
syscall
jmp close_file

close_file:
mov rdi, r9
mov rax, 3
syscall
jmp accept # look for next connection

static_response:
mov rdi, r9 #fd returned by accept
lea rsi, [rip+path]
mov rdx, 19
mov rax, 1
syscall
jmp write_file

exit:
add rsp, 8192
mov rdi, 0
mov rax, 60
syscall

path:
.asciz "HTTP/1.0 200 OK\r\n\r\n"
