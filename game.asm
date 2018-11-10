;;=============================================================================;;
;;                                                                             ;;
;;              Balloon Shooting Game                                          ;;
;;                                                                             ;;
;;                                                                             ;;
;;                                                                             ;;
;;              Mayank Vaidya, Manish Kumar                                    ;;
;;              1601CS22, 1601CS21                                             ;;
;;                                                                             ;;
;;=============================================================================;;

.model large
.data

exit db 0
player_pos dw 1760d                         ;position of player

arrow_pos dw 0d                             ;position of arrow
arrow_status db 0d                          ;0 = arrow ready to go else not 
arrow_limit dw  22d     ;150d

loon_pos dw 3860d       ;3990d
loon_status db 0d
         
                                            ;direction of player 
                                            ;up=8, down=2
direction db 0d

state_buf db '00:0:0:0:0:0:00:00$'          ;score veriable
hit_num db 0d
hits dw 0d
miss dw 0d  

game_over_str dw '  ',0ah,0dh
dw '                             |               |',0ah,0dh
dw '                             |---------------|',0ah,0dh
dw '                             | ^   Score   ^ |',0ah,0dh
dw '                             |_______________|',0ah,0dh
dw ' ',0ah,0dh 
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw '                                Game Over',0ah,0dh
dw '                        Press Enter to start again$',0ah,0dh 


game_start_str dw '  ',0ah,0dh

dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw '                ====================================================',0ah,0dh
dw '               ||                                                  ||',0ah,0dh                                        
dw '               ||       *    Balloon Shooting Game      *          ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||--------------------------------------------------||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh          
dw '               ||     Use up and down key to move player           ||',0ah,0dh
dw '               ||          and space button to shoot               ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||            Press Enter to start                  ||',0ah,0dh 
dw '               ||                                                  ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '                ====================================================',0ah,0dh
dw '$',0ah,0dh




.code
main proc
mov ax,@data
mov ds,ax

mov ax, 0B800h                             ;Address of VGA card for text mode
mov es,ax 



jmp game_menu                              ;display main menu

                                                                   
main_loop:                                 ;update logic and display everything
                                           ;check any key is pressed
    mov ah,1h                              ;check keyboard buffer
    int 16h                                ;go if pressed
    jnz key_pressed
    jmp inside_loop                        ;or just continue
    
    inside_loop:                           ;checking every thing
        
        cmp miss, 9                        ;if total misses is 9, go to game over state
        jge game_over
                                   
        mov dx, arrow_pos                  ;checking collitions
        cmp dx, loon_pos
        je hit
        
        cmp direction,8d                   ;update player position
        je player_up
        cmp direction,2d                   ;up or down based on direction veriable
        je player_down
        
        mov dx,arrow_limit                 ;hide arrow if it has travelled more distance than its limit
        cmp arrow_pos, dx
        jge hide_arrow
        
        cmp loon_pos, 0d                   ;check if the loon has been missed
        jle miss_loon
        jne render_loon 
    
        hit:                               ;play sound if hit
            mov ah,2
            mov dx,7d
            int 21h 
            
            inc hits                       ;update score
            
            lea bx,state_buf               ;display score
            call show_score 
            lea dx,state_buf
            mov ah,09h
            int 21h
            
            mov ah, 2                      ;new line
            mov dl, 0dh
            int 21h    
            
            jmp fire_loon                  ;new loon pops up
    
        render_loon:                       ;draw loon
            mov cl, ' '                    ;hide old loon
            mov ch, 1111b
        
            mov bx,loon_pos 
            mov es:[bx], cx
                
            sub loon_pos,160d              ;and draw new one in new position
            
            mov cl, 88d
            mov ch, 1101b
        
            mov bx,loon_pos 
            mov es:[bx], cx
            
            cmp arrow_status,1d            ;check any arrow to render
            je render_arrow
            jne inside_loop2 
        
        render_arrow:                      ;render arrow
        
            mov cl, ' '
            mov ch, 1111b
        
            mov bx,arrow_pos               ;hide old position
            mov es:[bx], cx
                
            add arrow_pos,4d               ;draw new position
            
            mov cl, 26d
            mov ch, 0010b                  ;green
        
            mov bx,arrow_pos 
            mov es:[bx], cx
        
        inside_loop2:
            
            mov cl, 79d                  ;draw player 
            mov ch, 1110b                ;red
            
            mov bx,player_pos 
            mov es:[bx], cx            
             
                       
    cmp exit,0
    je main_loop                          ;end main loop
    jmp exit_game
 
jmp inside_loop2
    
player_up:                                ;hide player old position
    mov cl, ' '
    mov ch, 1111b
        
    mov bx,player_pos 
    mov es:[bx], cx
    
    sub player_pos, 160d                  ;set new postion of player
    mov direction, 0    

    jmp inside_loop2                      ;it will draw in main loop
    
player_down:
    mov cl, ' '                           ;same as player up
    mov ch, 1111b                         ;hide old one and set new postion
                                          
    mov bx,player_pos 
    mov es:[bx], cx
    
    add player_pos,160d                   ;and main loop draw that
    mov direction, 0
    
    jmp inside_loop2

key_pressed:                              ;input hanaling section
    mov ah,0
    int 16h                               ;get the input key pressed

    cmp ah,48h                            ;go upKey if up button is pressed
    je upKey
    
    cmp ah, 50h                           ;go downKey if down button is pressed
    je downKey
    
    cmp ah,39h                            ;go spaceKey if up button is pressed
    je spaceKey
    
    cmp ah,4Bh                            ;go leftKey (this is for debuging)
    je leftKey
     
                                          ;if no key is pressed go to inside of loop
    jmp inside_loop

leftKey:                                  ;we use it for debuging 
    ;jmp game_over
    inc miss
            
    lea bx,state_buf
    call show_score 
    lea dx,state_buf
    mov ah,09h
    int 21h
    
    mov ah,2                             
    mov dl, 0dh                           ;carriage return -> Set cursor to start of current line
    int 21h
jmp inside_loop
    
upKey:                                    ;set player direction to up
    mov direction, 8d
    jmp inside_loop

downKey:
    mov direction, 2d                     ;set player direction to down
    jmp inside_loop
    
spaceKey:                                 ;shoot a arrow
    cmp arrow_status,0                    ;check if arrow can be fired or not
    je  fire_arrow
    jmp inside_loop

fire_arrow:                               ;set arrow postion equal to player position
    mov dx, player_pos                    ;so arrow is fired from the player's postion
    mov arrow_pos, dx
    
    mov dx,player_pos                     ;when an arrow is fired it should also set the limit
    mov arrow_limit, dx                   ;of arrow, ie, distance where it should be hidden
    add arrow_limit, 22d  ;150
    
    mov arrow_status, 1d                  ;set arrow status.It prevents multiple 
    jmp inside_loop                       ;shooting 

miss_loon:
    add miss,1                            ;update score

    lea bx,state_buf                      ;display score
    call show_score 
    lea dx,state_buf
    mov ah,09h
    int 21h
                                          ;new line
    mov ah,2
    mov dl, 0dh
    int 21h
jmp fire_loon
    
fire_loon:                                ;fire new balloon
    mov loon_status, 1d
    mov loon_pos, 3860d                   ;Initial position
    jmp render_loon
    
hide_arrow:
    mov arrow_status, 0                   ;hide arrow
    
    mov cl, ' '
    mov ch, 1111b
    
    mov bx,arrow_pos 
    mov es:[bx], cx
    
    cmp loon_pos, 0d 
    jle miss_loon
    jne render_loon 
    
    jmp inside_loop2
                                          ;print game over screen
game_over:
    mov ah,09h
    ;mov dh,0
    mov dx, offset game_over_str
    int 21h
    
    
    
    mov cl, ' '                           ;hide last of screen balloon
    mov ch, 1111b 
    mov bx,arrow_pos                      
    mov es:[bx], cx
     
    mov cl, ' '                           ;hide player
    mov ch, 1111b 
    mov bx,player_pos  
    mov es:[bx], cx
     
    mov cl, ' '                           ;hide loon
    mov ch, 1111b
    mov bx,loon_pos
    mov es:[bx], cx
    ;reset value                          ;update variable for start again
    mov miss, 0d
    mov hits,0d
    
    mov player_pos, 1760d

    mov arrow_pos, 0d
    mov arrow_status, 0d 
    mov arrow_limit, 22d      ;150d

    mov loon_pos, 3860d       ;3990d
    mov loon_status, 0d
         
    mov direction, 0d
                                           ;wait for input
    input:
        mov ah,1
        int 21h
        cmp al,13d
        jne input
        call clear_screen
        jmp main_loop
    

game_menu:
                                           ;game menu screen
    mov ah,09h                             ;Print initial instructions  {dos interrput 09, output 'dx' }
    mov dh,0
    mov dx, offset game_start_str
    int 21h
                                           ;wait for input
    input2:
        mov ah,01h                         ;take input {dos interrupt 01}
        int 21h
        cmp al,13d                         ;check if the input is ENTER, if yes then start the game else take input again
        jne input2
        call clear_screen                  ;clear the screen
        
        lea bx,state_buf                   ;display score
        call show_score 
        lea dx,state_buf
        mov ah,09h
        int 21h
    
        mov ah,2
        mov dl, 0dh                        ;carriage return -> Set cursor to start of current line
        int 21h
        
        jmp main_loop

exit_game:                                 ;end of our sweet game :)
mov exit,10d

main endp



;;--------------------------------------------------------------------;;
;;                                                                    ;;
;;  show score in same postion on screen                              ;;
;;  using base pointer to get segment of variable                     ;;
;;                                                                    ;;
;;____________________________________________________________________;;

proc show_score
    lea bx,state_buf
    
    mov dx, hits
    add dx,48d              ;add 48 to convert into character
    
    mov word [bx], 9d       ;TAB character
    mov word [bx+1], 9d
    mov word [bx+2], 9d
    mov word [bx+3], 9d
    mov word [bx+4], 'H'
    mov word [bx+5], 'i'                                        
    mov word [bx+6], 't'
    mov word [bx+7], 's'
    mov word [bx+8], ':'
    mov word [bx+9], dx
    
    mov dx, miss
    add dx,48d
    mov word [bx+10], ' '
    mov word [bx+11], 'M'
    mov word [bx+12], 'i'
    mov word [bx+13], 's'
    mov word [bx+14], 's'
    mov word [bx+15], ':'
    mov word [bx+16], dx
ret    
show_score endp 


;;--------------------------------------------------------------------;;
;;                                                                    ;;
;;  Clear the sceen                                                   ;;
;;  Just set new text mood for avoiding complexicity                  ;;
;;                                                                    ;;
;;____________________________________________________________________;;

clear_screen proc
        mov ah,0                            ;mode function{00 -> set video mode}
        mov al,3                            ;set video mode to text mode 80x25 chars and 16 colours
        int 10h        
        ret
clear_screen endp

end main
