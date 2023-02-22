function y = solveLinearSystem(mode,A,b,para);

switch mode,
  case {'matlab','MATLAB'},
    y = A\b;
%     file = createFileName('prefix','JL');
%     save(file,'A','b');
    
  case 'MG', 
    para.MGlevel      = log2(para.m(1))+1;
    para.MGcycle      = 1;
    para.MGomega      = 0.5;   %% !!! 0.5 should be better
    para.MGsmoother   = 'mfJacobi';
    para.MGpresmooth  = 3;
    para.MGpostsmooth = 1;
    para.dim = length(para.Omega);
    u = zeros(size(b));
    [y,res,r] = mfvcycle(para,u,b,1e-12,para.MGlevel,(max(para.m)>32));
end;

