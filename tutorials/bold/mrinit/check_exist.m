% Function to check if files (in a structure) exist
% If files do not exist, process is aborted 
% Unfound file is printed to screen
%
% INPUTS
% 1. fpaths is a structure of strings specifying paths
%
% OUTPUTS
%1. If any file inside structure does not exist, throws an error and aborts
%
% rl, summer 2014

    
function check_exist(fpaths) 
    fpaths = cellstr(fpaths); 

    for ii = 1:length(fpaths)
       tem.sum = 0; 
       
       f = fpaths{ii}; 
       
       if ~exist(f,'file')
           sprintf(['This file or variable does not exist: \n' fpaths{ii}])
           tem.sum = tem.sum + 1;  
       end

       if tem.sum ~= 0 
           error('Functional files do not exist/defined incorrectly, or variables do not exist.') 
       end
    
    end

end