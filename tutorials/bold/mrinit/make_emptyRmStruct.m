% makes rm with empty fields to be loaded into RM so that code doesn't
% crash. hard-coded for now, might try to change this later. 
%
% rl, 08/14
function rmEmpty = make_emptyRmStruct() 
   
    rmEmpty.coords      = []; 
    rmEmpty.indices     = []; 
    rmEmpty.name        = []; 
    rmEmpty.curScan     = []; 
    rmEmpty.vt          = []; 
    rmEmpty.co          = []; 
    rmEmpty.sigma1      = []; 
    rmEmpty.sigma2      = []; 
    rmEmpty.theta       = []; 
    rmEmpty.beta        = []; 
    rmEmpty.x0          = []; 
    rmEmpty.y0          = [];
    rmEmpty.y0real      = []; 
    rmEmpty.ph          = []; 
    rmEmpty.ecc         = []; 
    rmEmpty.session     = ''; 

end