.MODEL small
.STACK 100h

.DATA
    inputNum db 2 dup(0) ; Allocate space for 2 characters
    height DW ?     ; Triangle height
    width  DW ?     ; Triangle width
    horizontal_move dw 90h ; triangle horizontal loction
    vertical_move dw 65h   ; triangle vertical loction
    screen_height dw 200d  ; screen height
    screen_width dw 320d   ;screen width
    rowLength dw ?         ; the current legth of the row drawn
    space dw ?             ; the amount of space required to be in current row
    logo1 db   '    _____     _                   _       ' , 13,10,
          db   '   |_   __ __(_) __ _ _ __   __ _| | ___  ' , 13,10,
          db   '     | || '__| |/ _` | '_ \ / _` | |/ _ \ ' , 13,10,
          db   '     | || |  | | (_| | | | | (_| | |  __/ ' , 13,10,
          db   '     |_||_|  |_|\__,_|_| |_|\__, |_|\___| ' , 13,10,
          db   '                            |___/         ' , 13,10, '$'
    logo2 db   '     __ _  __ _ _ __ ___   ___   ' , 13,10,         
          db   '    / _` |/ _` | |_ ` _ \ / _ \  ' , 13,10, 
          db   '   | (_| | (_| | | | | | |  __/  ' , 13,10,
          db   '    \__, |\__,_|_| |_| |_|\___|  ' , 13,10,
          db   '    |___/                        ' , 13,10,10, '$'     
    msg1  db   '   Welcome, this program draws an isosceles triangle. ', 13,10,
          db   '   after the triangle is drawn you can move it with the arrow keys. ', 13,10,
          db   '   start by typing the height and the width below. ' ,13,10, 
          db   '   the numbers must be between 10-99 ' ,13,10,10, '$' 
    msg2  db   '   Enter height:', 13,10,10,'   ','$' 
    msg3  db   13,10,10, '   Enter width:', 13,10,10,'   ','$'
    error1 db  '   invalid number. type again.',13,10,10, '$'
    errorOutOfBound db '   out of bounds.',13,10,10, '$' 
.CODE
START:
Main proc
    ;this is the main proc that Scheduling the main procs of this program 
    PUSH BP
    MOV BP, SP

    MOV AX, @DATA   ; initialize data segment
    MOV DS, AX                               
    call ClearScreen
    call menu 
    PUSH height ; PUSH height into stack 
    PUSH width  ; PUSH width into stack 
    CALL WindowSettings

    CALL DrawTriangle
    

    input:                
        CALL MoveTriangle
        PUSH height
        PUSH width
        xor si,si
        call DrawTriangle
    jmp input
    
    jmp end start
    POP BP
    RET
endp Main

menu proc
; This proc is the menu to the program, 
;it explains it and calls InputNums and arrToNum 
;that input the chars and make it a numerical value.          
    push bp
    mov bp, sp
    pusha
    
    
    mov ah, 09h
    mov dx, offset logo1
    int 21h
    
    mov ah, 09h
    mov dx, offset logo2
    int 21h    
    
    mov ah, 09h
    mov dx, offset msg1
    int 21h
    
    startInput:
    mov ah, 09h
    mov dx, offset msg2
    int 21h
    
    call InputNums
    call arrToNum
    mov al, inputNum
    mov height, cx
    
    mov ah, 09h
    mov dx, offset msg3
    int 21h
    
    call InputNums
    call arrToNum
    mov al, inputNum
    mov width, cx
    popa
    pop bp
    ret
endp menu
InputNums proc
; This proc is reading the user input of height and width and writes it into inputNum. 
;It checks if the num is valid and lets the user to type
;up to 2 digits.        
    mov bp, sp
    push bp
    push si
    ; Input loop
    lea bx, inputNum ; Load the address of inputNum into dx
    inputLoop:
        ; Read a character from the keyboard
        mov ah, 1
        int 21h
    
        ; Check if the input is a number 
        cmp al, '0'
        jb notNum
        cmp al, '9'
        ja notNum
        
        sub al, '0'
        ; Store the number in the array
        mov [bx+si], al
        
        inc si
        cmp si, 2
        je exit_loop  
        jmp inputLoop
    notNum:
        ; Check if the input is the Enter key (ASCII value 13)
        cmp al, 13
        je exit_loop
        
        ;backspace if not a number
        mov ah, 02h
        mov dx, 8h
        int 21h
        

        jmp inputLoop 
    exit_loop:
    cmp si, 2
    pop si
    pop bp
    jb errorHandler
    ret
endp InputNums



arrToNum proc
; Procedure to convert the array with digits to a number
; it goes through the array, 
; multiplies every digit by its position in the array and returns cx as the result
; example: 1,2 => 1*10 + 2*1 = 12
    mov bp,sp
    push bp
    push si
    xor cx,cx
    mov dx, 10
    xor ax, ax 
    xor si,si
    lea bx, inputNum 
    arr_loop:
        mov al, [bx+si] ; Load the next character to al
        cmp al, 0 ; Check if it's the end of the array.
        je done ; if null done

    
        ; Multiply the current result by 10 and add to the num
        imul dx
        add cx, ax
        inc si
        cmp si, 2
        je done
        mov dx, 1
        jmp arr_loop
    done:
        pop si
        pop bp
        cmp cx, 0
        je errorHandler
        ret
arrToNum endp


DrawTriangle proc
;This proc draws the triangle.
;it gets the horizontal_move and vertical_move of the triangle,
;then calls calcRow to calc current row's length.
;It draws a row and calls calcSpace to calc the space to do next row. 
    PUSH BP
    MOV BP, SP
    
    call ClearScreen
    
    MOV CX, horizontal_move 
    MOV DX, vertical_move

    loop1:
        call calcRow
        mov bx, rowLength
        mov [bp+4], bx
        cmp bx, 0
        je doneDrawing
        
        MOV AL, 0Fh     ; Set pixel color      
        MOV AH, 0CH
        
        loop2:
            INT 10H
            inc cx
            dec bx
            cmp bx, 0
            jne loop2
        

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
;This proc is checking if there is something in the buffer,
;then, if it's an arrow it changes the values of vertical_move and horizontal_move  
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
       ;to do: ;call KeepBounds        
    ret     
endp MoveTriangle

    
WindowSettings proc
;allows using graphical interface. 
    MOV AH, 0
    MOV AL, 13h ;interupt 10h mode 0, 13
    INT 10H
    RET
endp WindowSettings

ClearScreen proc
;clears the screan and applies red and white colors to backround and text.    
    mov ah, 09h
    mov cx, 1000h
    mov al, 20h
    mov bl, 4Fh ; This is red & White.
    INT 10H
    ret
endp ClearScreen

calcRow proc
;calculates the length of the next row using Thales theorem,
;gets the currnt height, total width and total height
;and saves the row length in rowLength.    
    push bp
    mov bp, sp
    
    push dx
    cwd  ; clear dx 
    
    mov ax, [bp+10] ;current height 
    mul width
    mov bx, height
    idiv bx
     
    pop dx
    mov rowLength, ax 
    
    pop bp
    ret
endp calcRow

calcSpace proc   
; calculates the space needed to print in this row
; using (width - current width) / 2     
    push bp
    mov bp, sp
    
    push dx
    mov ax, width
    mov bx, [bp+8] ; current width
    
    sub ax, bx
    mov bx, 2
    cmp ax, 0
    je ifZero
    xor dx, dx
    idiv bx
    jmp next 
    ifZero:
        mov ax, 0
    next:    
    mov space, ax
    pop dx
    pop bp
    ret
endp calcSpace

errorHandler proc
;handels invalid input error
;print a message and returns to startInput
    mov ah, 09h
    mov dx, offset error1
    int 21h  
    ret startInput
errorHandler endp
END START

;to do:

KeepBounds proc
    push bp
    mov bp, sp
    mov ax, height
    add ax, vertical_move 
    cmp ax, screen_height
    jge ErrorHandlerBound
    ; check bottom  
    cmp vertical_move , 0
    jbe ErrorHandlerBound
    ; check left   
    cmp horizontal_move , 0
    jbe ErrorHandlerBound
    ; check right
    mov ax, horizontal_move
    add ax, width 
    cmp ax , screen_width
    jge ErrorHandlerBound
    
    
    
    pop bp
    ret
KeepBounds endp

ErrorHandlerBound proc
    push bp
    mov bp, sp
    
    mov ah, 09h
    mov dx, offset errorOutOfBound
    int 21h

    mov horizontal_move , 90h
    mov vertical_move , 65h    
    
    
    pop bp
    ret
ErrorHandlerBound endp                        