.MODEL small
.STACK 100h

.DATA
    ; The emulator is slow so you need to put low numbers in it to work acceptably fast.
    height DW 12     ; Triangle height
    width  DW 12     ; Triangle width
    horizontal_move dw 90h
    vertical_move dw 65h
    rowLength dw ?
    space dw ?
    
.CODE
START:
Main proc 
    PUSH BP
    MOV BP, SP
    
    MOV AX, @DATA   ; Initialize data segment
    MOV DS, AX                               
    PUSH height
    PUSH width
    CALL WindowSettings
    CALL DrawTriangle
    

    input: ;everything from this part is still not working
        CALL MoveTriangle
        PUSH height
        PUSH width
        xor si,si
        call DrawTriangle
    jmp input
    
    POP BP
    RET
endp Main

DrawTriangle proc
    PUSH BP
    MOV BP, SP
    
    call ClearScreen
    call calcRow
    
    MOV CX, horizontal_move 
    MOV DX, vertical_move

    loop1:
    
    MOV AL, 0Fh     ; Set pixel color      
    MOV AH, 0CH
        
        mov bx, [bp+4] ; width
        loop2:
            INT 10H
            inc cx
            dec bx
            cmp bx, 0
            jne loop2
        
        mov bx, [bp+4]
        sub bx, rowLength
        mov [bp+4], bx

        dec dx  
        dec [bp+6]
        
        call calcSpace
        mov cx, horizontal_move
        add cx, space
        
        cmp [bp+6], 0
        je doneDrawing
        jmp loop1
    doneDrawing:
    pop bp          
    RET 4 ; clear stack
endp DrawTriangle

MoveTriangle proc 
    waitForInput:
        mov ah, 0h
        int 16h
        ; Check for extended key code (AL = 0)
        cmp al, 0
        jne waitForInput
    
        ; Check if the input is an arrow key (AH = 48, 50, 52, or 54)
        cmp ah, 48h ; Up arrow
        je up    
        cmp ah, 50h ; Down arrow
        je down
        cmp ah, 4dh ; Left arrow
        je left
        cmp ah, 4bh ; Right arrow
        je right
        jmp waitForInput  
    up:
        sub vertical_move , 30
        add horizontal_move, 0
        jmp move  
    down:
        add vertical_move , 30
        add horizontal_move, 0
        jmp move 
    left:
        add vertical_move , 0
        add horizontal_move, 30
        jmp move 
    right:
        add vertical_move , 0
        sub horizontal_move, 30
        jmp move 
    move:
    ret     
endp MoveTriangle

WindowSettings proc 
    MOV AH, 0
    MOV AL, 13h ;interupt 10h mode 0, 13
    INT 10H
    RET
endp WindowSettings

ClearScreen proc   
    mov ah, 09h
    mov cx, 1000h
    mov al, 20h
    mov bl, 40h ; This is Blue & White.
    INT 10H
    ret
endp ClearScreen

calcRow proc   
    push bp
    mov bp, sp
    
    push dx
    mov ax, width ; width
    mov bx, height ; height
    dec bx
    cwd  ; prevent overflow 
    div bx
    pop dx
    mov rowLength, ax 
    
    pop bp
    ret
endp calcRow

calcSpace proc   
    
    push bp
    mov bp, sp
    
    push dx
    mov ax, width
    mov bx, [bp+10] ; current height
    
    sub ax, bx
    mov bx, 2
    cmp ax, 0
    je ifZero
    cwd ; prevent overflow
    div bx
    jmp next 
    ifZero:
        mov ax, 0
    next:    
    mov space, ax
    pop dx
    pop bp
    ret
endp calcSpace

; we calc the points  for each row - take the height -1 and divide the width with it and this should be the number of pixels to decrease for each row - the first row will be always the width.
; (width - 1) / height 
END START                       