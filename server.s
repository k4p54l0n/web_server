.intel_syntax noprefix
.global _start
_start:

sub rsp, 8192
jmp create_socket

create_socket:
mov rdi, 2
mov rsi, 1
mov rdx, 0
mov rax, 41
syscall
mov r8, rax
jmp initialize_addr

# R8 IS SOCKET FD

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
xor r10, r10 # r10 to null-terminate the request
mov rdi, r8
mov rsi, 0
mov rdx, 0
mov rax, 43
syscall
cmp rax, 0
js exit
mov r9, rax
mov rax, 57
syscall
cmp rax, 0
je read_request
mov rdi, r9
mov rax, 3
syscall
jmp accept 

# R9 = CLIENT FD

read_request:
mov rax, 3
mov rdi, r8
syscall
mov rax, 0
mov rdi, r9
lea rsi, [rsp+24]
mov rdx, 1024
syscall
jmp parse_requests 

parse_requests:
cmp byte ptr [rsi], 'P'   # check if GET request or POST request
je postrequest
cmp byte ptr [rsi], 'G'   # check if GET request or POST request
jne exit
add rsi, 4
jmp parse_getrequest

postrequest:
add rsi, 5
jmp parse_postrequest

parse_postrequest:
cmp byte ptr [rsi+r10], 0x20
je open_postfile
inc r10
jmp parse_postrequest

open_postfile:   # OPEN THE FILE REQUESTED BY POST
mov byte ptr[rsi+r10], 0
mov rdi, rsi
mov rax, 2
mov rsi, 65  # WRITE ONLY | OCREATE
mov rdx, 0777 # FILE PERMISSIONS IN CASE O_CREATE 
syscall
mov r10, rax  # FD OF OPENED POST FILE
lea rsi, [rsp + 180]
jmp find_contentlength

find_contentlength:
inc rsi
cmp byte ptr [rsi], '9'
ja find_contentlength 
cmp byte ptr [rsi], '0'
jb find_contentlength
jmp get_contentlength

get_contentlength:
xor rax, rax
xor rdx, rdx
movzx rax, byte ptr [rsi]
sub rax, 0x30
mov rdx, rax
inc rsi
cmp byte ptr [rsi], '9'
ja done
cmp byte ptr [rsi], '0'
jb done
jmp atoi_loop

atoi_loop:
cmp byte ptr [rsi], '9'
ja done
cmp byte ptr [rsi], '0'
jb done
imul rdx, 10
movzx rax, byte ptr [rsi]
sub rax, 0x30
add rdx, rax
mov rax, rdx
inc rsi
jmp atoi_loop

done:
mov rdx, rax
add rsi, 4  # go past the content length header 
jmp write_postcontent

# write into file then close then write 200 OK
write_postcontent:
mov rax, 1
mov rdi, r10
syscall
mov rax, 3
mov rdi, r10
syscall
mov rdi, r9 # FD RETURNED BY ACCEPT (CLIENT)
lea rsi, [rip+get_answer]
mov rdx, 19
mov rax, 1
syscall
jmp exit

parse_getrequest:
cmp byte ptr [rsi+r10], 0x20
je open_file
inc r10
jmp parse_getrequest

open_file:
mov byte ptr[rsi+r10], 0
mov rdi, rsi
mov rax, 2
mov rsi, 0
mov rdx, 0
syscall
jmp read_file

read_file:
mov rdi, rax # RAX HAS FILE REQUESTED BY GET
mov rax, 0 # READ
lea rsi, [rsp+300]
mov rdx, 1024
syscall
mov r12, rax  # BYTES READ IN RAX
mov rax, 3
syscall
jmp static_getresponse

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
jmp exit

static_getresponse:
mov rdi, r9 # FD RETURNED BY ACCEPT (CLIENT)
lea rsi, [rip+get_answer]
mov rdx, 19
mov rax, 1
syscall
jmp write_file

exit:
add rsp, 8192
mov rdi, 0
mov rax, 60
syscall

get_answer:
.asciz "HTTP/1.0 200 OK\r\n\r\n"
