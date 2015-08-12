function out=status(serial_obj,device_addr)
fprintf(serial_obj,[device_addr 'TS']); %Get device state
out = fscanf(serial_obj);
end