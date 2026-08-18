.intel_syntax noprefix
.global _start
_start:

#socket

mov rdi, 2
mov rsi, 1
mov rdx, 0
mov rax, 41
syscall

#bind

sub rsp, 16
mov byte ptr [rsp], 2
mov WORD ptr [rsp+2], 0x5000
mov DWORD PTR [rsp+4], 0

mov rdi, rax #fd socket
mov rsi, rsp
mov rdx, 16
mov rax, 49
syscall

#exit

add rsp, 16
mov rdi, 0
mov rax, 60
syscall
