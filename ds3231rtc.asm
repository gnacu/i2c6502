;----[ ds3231rtc.asm ]------------------

;DS3231 RTC over i2c6502 for C64
;Copyright (c) 2020 Greg Nacu

         *= $0801

         .word end    ;next line ptr
         .word 64     ;basic line #64

         .byte $9e    ;sys
         .null "2061" ;$080d
end      .word $00    ;end of basic

doset    = 0

i2cbase  = $2000

init_    = 0
reset_   = 3
prep_rw_ = 6
readreg_ = 9
writreg_ = 12

ds3231addr = $68
dssecsreg = $00

chrout   = $ffd2

;-----------------------
;--[ main ]-------------
;-----------------------

         jsr i2cbase+init_
         .ifne doset
         beq settime
         .endif
         .ifeq doset
         beq gettime
         .endif

         ldx #<errmsg_init
         ldy #>errmsg_init
         jmp msg_out

         .ifne doset
settime  ldx #<dss_secs
         ldy #>dss_secs
         lda #dss_size
         jsr i2cbase+prep_rw_

         lda #ds3231addr
         ldy #dssecsreg
         jsr i2cbase+writreg_
         beq showsetmsg

         ldx #<errmsg_sett
         ldy #>errmsg_sett
         jmp msg_out

showsetmsg
         ldx #<msg_settime
         ldy #>msg_settime
         jmp msg_out
         .endif

         .ifeq doset
gettime  ldx #<dss_secs
         ldy #>dss_secs
         lda #dss_size
         jsr i2cbase+prep_rw_

         lda #ds3231addr
         ldy #dssecsreg
         clc ;don't skip reg write
         jsr i2cbase+readreg_
         beq showtime

         ldx #<errmsg_time
         ldy #>errmsg_time
         jmp msg_out

showtime
         ldx #<msg_curt
         ldy #>msg_curt
         jsr msg_out

         lda dss_date
         jsr bcd_out
         lda #"/"
         jsr chrout

         lda dss_mon
         jsr bcd_out
         lda #"/"
         jsr chrout

         lda dss_year
         jsr bcd_out
         lda #" "
         jsr chrout

         lda dss_hrs
         jsr bcd_out
         lda #":"
         jsr chrout

         lda dss_mins
         jsr bcd_out
         lda #":"
         jsr chrout

         lda dss_secs
         jsr bcd_out
         lda #" "
         jsr chrout

         ldx #<msg_wd
         ldy #>msg_wd
         jsr msg_out

         lda dss_dow
         jmp bcd_out
         .endif

;-----------------------
;--[ print msgs ]-------
;-----------------------

bcd_out  ;A -> number in bcd
         pha
         lsr a
         lsr a
         lsr a
         lsr a

         clc
         adc #$30;convert to petscii
         jsr chrout

         pla
         and #$0f

         clc
         adc #$30;convert to petscii
         jmp chrout

msg_out
         .block
         ;RegPtr -> message

         stx $fb
         sty $fc

         ldy #0

loop     lda ($fb),y
         beq done

         jsr chrout
         iny
         bne loop

done     rts
         .bend

msg_curt .null "current time: "
msg_wd   .null "wd: "

msg_settime
         .null "rtc time has been set"
errmsg_init
         .null "failed to init i2c bus"
errmsg_time
         .null "failed to get rtc time"
errmsg_sett
         .null "failed to set rtc time"

;----------------------
;--[ data structure ]---
;-----------------------

;ds seconds register struct

         .ifne doset

;Set values must be in BCD

dss_secs .byte $00
dss_mins .byte $01
dss_hrs  .byte $02
dss_dow  .byte $03
dss_date .byte $25
dss_mon  .byte $06
dss_year .byte $81
         .endif

         .ifeq doset
dss_secs .byte 0
dss_mins .byte 0
dss_hrs  .byte 0
dss_dow  .byte 0
dss_date .byte 0
dss_mon  .byte 0
dss_year .byte 0
         .endif

dss_size = 7
