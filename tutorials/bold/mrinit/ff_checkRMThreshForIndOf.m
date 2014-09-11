% very specific function.
% looks for index corresponding to subject's initials
% assumes RM_th has a field called subject

 function ind = ff_checkRMThreshForIndOf(initials,RM_th)

 ind = 0; 
 
for ii = 1:length(RM_th)
    
    if strcmp(RM_th{ii}.subject, initials)
       ind = ii;  
    end
  
end


if ind == 0
   error('Error in finding subject index'); 
end

 end