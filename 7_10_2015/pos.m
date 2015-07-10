function out=pos(serial_obj,device_addr)
fprintf(serial_obj,[device_addr 'TP']); %Get device state
out = fscanf(serial_obj);
end
