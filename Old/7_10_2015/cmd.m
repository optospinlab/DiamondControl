function cmd(serial_obj,device_addr,c)
fprintf(serial_obj,[device_addr c]); 
% out = fscanf(serial_obj);
% if ~isempty(out)
%     disp(['ERR' out])
% end
end

