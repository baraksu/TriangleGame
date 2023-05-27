.MODEL small
.STACK 100h

.DATA
    ; The emulator is slow so you need to put low numbers in it to work acceptably fast.
    height DW 20     ; Triangle height
    width  DW 20     ; Triangle width
.CODE
    MOV AX, @DATA   ; Initialize data segment
    MOV DS, AX                               
    PUSH height
    PUSH width
    MOV AH, 0
    MOV AL, 13h
    INT 10H
    CALL DrawTriangle
    input: ;everything from this part is still not working
        CALL MoveTriangle
        PUSH height
        PUSH width
        call DrawTriangle
    jmp input
        
    MOV AH, 4Ch     ; Exit program
    INT 21h


DrawTriangle proc
    PUSH BP
    MOV BP, SP
    
    mov ah, 09h
    mov cx, 1000h
    mov al, 20h
    mov bl, 17  ; This is Blue & White.
    INT 10H
    
    MOV AH, 0CH
    MOV CX, 50H
    MOV DX, 50H
    MOV AL, 20H     ; Set pixel color
    loop1:
        push bx
        mov bx, [bp+4]
        loop2:
            INT 10H
            inc cx
            dec bx
            cmp bx, 0
            jne loop2
        pop bx
        cmp bx, 0
        je doneDrawing
        add si, 1
        mov cx, 50h
        add cx, si
        dec dx
        dec [bp+4]
        dec [bp+4]
        cmp [bp+4], 0
        je doneDrawing
        jmp loop1
    doneDrawing:          
    POP BP
    RET
endp DrawTriangle

MoveTriangle proc 
    PUSH BP
    MOV BP, SP
    waitForInput:
        mov ah, 0h
        int 16h
        ; Check for extended key code (AL = 0)
        cmp al, 0
        jne waitForInput
    
        ; Check if the input is an arrow key (AH = 48, 50, 52, or 54)
        cmp ah, 48h ; Up arrow
        je valid
        cmp ah, 50h ; Down arrow
        je valid
        cmp ah, 4dh ; Left arrow
        je valid
        cmp ah, 4bh ; Right arrow
        je valid
        jmp waitForInput  
    valid:
        POP BP
        RET
endp MoveTriangle
END

