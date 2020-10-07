GPIO load
\ playing sound with a passive buzzer

129 constant: cL
139 constant: cLS
146 constant: dL
156 constant: dLS
163 constant: eL
173 constant: fL
185 constant: fLS
194 constant: gL
207 constant: gLS
219 constant: aL
228 constant: aLS
232 constant: bL
261 constant: c
277 constant: cS
294 constant: d
311 constant: dS
329 constant: e
349 constant: f
370 constant: fS
391 constant: g
415 constant: gS
440 constant: a
455 constant: aS
466 constant: b
523 constant: cH
554 constant: cHS
587 constant: dH
622 constant: dHS
659 constant: eH
698 constant: fH
740 constant: fHS
784 constant: gH
830 constant: gHS
880 constant: aH
910 constant: aHS
933 constant: bH

create: song   a , a , a , f , cH , a , f , cH , a , eH , eH , eH , fH , cH , gS , f , cH , a , aH , a , a , aH , gHS , 
               gH , fHS , fH , fHS , aS , dHS , dH , cHS , cH , b , cH , f , gS , f , a , cH , a , cH , eH , aH , a , a , 
               aH , gHS , gH , fHS , fH , fHS , aS , dHS , dH , cHS , cH , b , cH , f , gS , f , cH , a , f , c , a ,

create: tempo  500 , 500 , 500 , 350 , 150 , 500 , 350 , 150 , 1000 , 500 , 500 , 500 , 350 , 150 , 500 , 350 , 150 , 
               1000 , 500 , 350 , 150 , 500 , 250 , 250 , 125 , 125 , 250 , 250 , 500 , 250 , 250 , 125 , 125 , 250 , 
               125 , 500 , 375 , 125 , 500 , 375 , 125 , 1000 , 500 , 350 , 150 , 500 , 250 , 250 , 125 , 125 , 250 , 
               250 , 500 , 250 , 250 , 125 , 125 , 250 , 250 , 500 , 375 , 125 , 500 , 375 , 125 , 1000 ,                
                
4 constant: PIN \ d2

create: PWM_PINS PIN c,

PIN GPIO_OUT gpio-mode
PWM_PINS 1 pwm-init
1023 pwm-duty

: play ( -- )
    66 0 do
        pwm-start
        song i cells + @ pwm-freq
        tempo i cells + @ ms
        pwm-stop
        20 ms
        i case
            26 of 250 ms endof
            34 of 250 ms endof
            52 of 250 ms endof
            60 of 250 ms endof
            drop
        endcase
    loop ;
