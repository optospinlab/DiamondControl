function joystickTest()
    joy = vrjoystick(1)
    
    a = axes();
    
    while true
        clc
        [axes2, buttons, povs] = read(joy);
        
        axes2
        buttons
        povs
        scatter(a, [axes2(1)], [axes2(2)]);
        xlim(a, [-1 1]);
        ylim(a, [-1 1]);
        pause(.1);
end