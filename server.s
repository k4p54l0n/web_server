.intel_syntax noprefix
.global _start
_start:

#socket

mov rdi, 2
mov rsi, 1
mov rdx, 0
mov rax, 41
syscall

# bind to socket


sub rsp, 16 #allocate 16 bytes

#initialize 
mov QWORD ptr[rsp], 0
mov QWORD ptr[rsp+8], 0


mov WORD ptr [rsp], 2 # AF_INET
mov WORD ptr [rsp+2], 0x5000 # port(80)
mov DWORD PTR [rsp+4], 0 # padding 

mov rdi, rax #fd socket returned by socket syscall (rax) moved to rdi 
mov rsi, rsp
mov rdx, 16
mov rax, 49
syscall

#exit

add rsp, 16
mov rdi, 0
mov rax, 60
syscall
