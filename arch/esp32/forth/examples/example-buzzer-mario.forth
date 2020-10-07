GPIO load

\ playing sound with a passive buzzer
523 constant: C
554 constant: C1
587 constant: D
622 constant: Eb
659 constant: E
698 constant: F
740 constant: F1
784 constant: G
831 constant: Ab
880 constant: A
932 constant: Bb
988 constant: B
1047 constant: c
1109 constant: c1
1175 constant: d
1245 constant: eb
1319 constant: e
1397 constant: f
1479 constant: f1
1567 constant: g
1661 constant: ab
1761 constant: a
1866 constant: bb
1976 constant: b

create: song    e , e , e , c , e , g , G , c , G , E , A , B , Bb , 
                A , G , e , g , a , f , g , e , c , d , B , c ,
                
create: tempo   6 , 12 , 12 , 6 , 12 , 24 , 24 , 18 , 18 , 18 , 12 , 12 , 
                6 , 12 , 8 , 8 , 8 , 12 , 6 , 12 , 12 , 6 , 6 , 6 , 12 ,
                
4 constant: PIN \ d2
create: PWM_PINS PIN c,
PIN GPIO_OUT gpio-mode
PWM_PINS 1 pwm-init
1023 pwm-duty

: play ( -- )  
    25 0 do
        pwm-start
        song i cells + @ pwm-freq
        tempo i cells + @ 20 * ms
        pwm-stop
        1000 us
    loop ;
