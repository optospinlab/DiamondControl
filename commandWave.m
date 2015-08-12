%COMMANDWAVE send serial commands to wavemeter
% 
%     Send a command to the wavemeter. This function translates simple
%     character string into a series of commands and sends them to the
%     wavemeter. For example, commandWave('S819E') presses the buttons
%     SETPOINT, 8, 1, 9, ENTER. 
% 
% Example
% 
%     First initialize the communication using initWaveDAQ:
%       >> wa1500 = initWaveDAQ()
% 
%     Then send a command to the wavemeter, for example pressing the
%     setpoint button.
%       >> commandWave(wa1500,'S')
% 
%     Send a series of commands, such as typing a number and then pressing
%     enter: 
% 
%       >> commandWave(wa1500,'820.039E')
% 
% Commands
% 
%     Use this table to look up the char to give to commandWave to send a
%     given command.
% 
%           COMMAND             CHARACTER (case-sensitive)
%           0                   0
%           1-10                1-10
%           Clear               C      (doesn't work for some reason)
%           .                   .
%           Enter               E
%           Remote              t
%           Save                s
%           Reset               R
%           Manual Deattenuate  m
%           Manual Attenuate    p
%           Auto Attenuate      A
%           Humidity            H
%           Pressure            P
%           Temperature         T
%           # Averaged          N
%           Analog Res          a
%           Display Res         d
%           Setpoint            S
%           Units               U
%           Display             D
%           Medium              M
%           Resolution          r
%           Averaging           V
% 
%           Broadcast           B
%           Deviation On        K
%           Deviation Off       L
%           Query               Q
% 
%
% See Also: wa1500, initWaveDAQ, devResetQ, resetDeviation, getSetPoint

% 
%     Todd Karin
%     08/22/2012

function commandWave(wa1500,button)

for i=1:length(button)

    % Zero must be treated specially.
    if button(i)=='0'
        fwrite(wa1500,64,'char');
        fwrite(wa1500,0,'char');
        fwrite(wa1500,13,'char');
        fwrite(wa1500,10,'char');
    end
    % Number buttons
    for j=1:9
        if button(i)==num2str(j)
            fprintf(wa1500,['@' char(hex2dec(num2str(j)))] );
        end
    end
    % Clear = 'C'
    if button(i)=='C'
        fprintf(wa1500,['@' char(hex2dec('0A'))]);
    % Period
    elseif button(i)=='.'
        fprintf(wa1500,['@' char(hex2dec('0B'))]);
    % Enter
    elseif button(i)=='E'
        fprintf(wa1500,['@' char(hex2dec('0C'))]);        
    % Remote Button = 'r'    
    elseif button(i)=='t'
        fprintf(wa1500,['@' char(hex2dec('0D'))]);
    % Save    
    elseif button(i)=='s'
        fprintf(wa1500,['@' char(hex2dec('0E'))]);  
    % Reset    
    elseif button(i)=='R'
        fprintf(wa1500,['@' char(hex2dec('0F'))]);
    % Manual Deattenuate    
    elseif button(i)=='m'
        fprintf(wa1500,['@' char(hex2dec('10'))]);
    % Manual Attenuate    
    elseif button(i)=='p'
        fprintf(wa1500,['@' char(hex2dec('11'))]);
    % Auto Attenuate    
    elseif button(i)=='A'
        fprintf(wa1500,['@' char(hex2dec('13'))]);
    % Humidity    
    elseif button(i)=='H'
        fprintf(wa1500,['@' char(hex2dec('20'))]);
    % Pressure    
    elseif button(i)=='P'
        fprintf(wa1500,['@' char(hex2dec('21'))]);
    % Temperature    
    elseif button(i)=='T'
        fprintf(wa1500,['@' char(hex2dec('22'))]);
    % # Averaged    
    elseif button(i)=='N'
        fprintf(wa1500,['@' char(hex2dec('23'))]);
    % Analog Res    
    elseif button(i)=='a'
        fprintf(wa1500,['@' char(hex2dec('24'))]);        
    % Display Res    
    elseif button(i)=='d'
        fprintf(wa1500,['@' char(hex2dec('25'))]);  
    % Setpoint = 'S'
    elseif button(i)=='S'
        fprintf(wa1500,'@&');
    % Units    
    elseif button(i)=='U'
        fprintf(wa1500,['@' char(hex2dec('27'))]);        
    % Display    
    elseif button(i)=='D'
        fprintf(wa1500,['@' char(hex2dec('28'))]);   
    % Medium    
    elseif button(i)=='M'
        fprintf(wa1500,['@' char(hex2dec('29'))]);   
    % Resolution    
    elseif button(i)=='r'
        fprintf(wa1500,['@' char(hex2dec('2A'))]);   
    % Averaging    
    elseif button(i)=='V'
        fprintf(wa1500,['@' char(hex2dec('2B'))]);   
        
    % Broadcast    
    elseif button(i)=='B'
        fprintf(wa1500,['@' char(hex2dec('42'))]);   
    % Deviation On    
    elseif button(i)=='K'
        fprintf(wa1500,['@' char(hex2dec('44'))]);   
    % Deviation Off    
    elseif button(i)=='L'
        fprintf(wa1500,['@' char(hex2dec('55'))]);   
    % Query    
    elseif button(i)=='Q'
        fprintf(wa1500,['@' char(hex2dec('51'))]);   
        
    end     

        
    % Pause to give a little time from last button push.
    pause(.05)
end







% note @ = char(64)

% char(hex2dec('26'))