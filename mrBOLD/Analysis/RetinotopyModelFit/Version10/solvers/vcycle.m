 function [u,res,r] = vcycle(para,u,rhs,tol,level,out)
%function [u,res,r] = vcycle(para,u,rhs,tol,level,out)
%JM: 2004/07/29
% solves 
%
% -----------------------------------------------------------------------------

dim   = 2;
Omega = para.Omega;
m     = para.m;
h     = para.h;

MGcycle        = para.MGcycle;
para.MGcycle   = 1;

if ~isfield(para,'M'), para.M = 0;       end;

if level == para.MGlevel & out==1,
  fprintf('MG: ');
end;
if (level>1) & (min(m)==1)
  fprintf('grid %dx%d --> coarse grid\n',m)
  level = 1;
end;

if out==1,
  fprintf('%d>',level);
end;

[para.B,Bstr] = getElasticMatrixstg(Omega,m);

% -----------------------------------------------------------------------------
if level > 1,
  % ---------------------------------------------------------------------------
  % NOT on COARSE grid
  str = sprintf('  - grid %dx%dx',m);
  
  % initialize
  r = rhs - Au(u,para);
  
 
  % -------------------------------------------------------------
  for i = 1:MGcycle, % loop over the V/W cycles
  % -------------------------------------------------------------
    n = length(r);
    if out>1,
      norm_r_in = norm(r)/n;
      fprintf('%20s |r-in|   = %e\n',str,norm_r_in);
    end;
    
    % pre-smoothing, exp: [u,r] Richardson(x,b,para,MGcycle)
    ur = feval(para.MGsmoother,0*r,r,para,para.MGpresmooth);
    u = u + ur; r = rhs - mfAu(u,para);

    if out>1,
      norm_r_pre = norm(r)/n;
      fprintf('%20s |r-pre|  = %e\n','',norm_r_pre);
    end;
    
    
    % PREPARE FOR COARSER GRID ------------------------------------------------
    B = para.B;
    M = para.M; dm = full(diag(M));
    dm = mfPu(dm,para.dim,para.m(1),para.m(2),1,'PTu')/4;
    para.M = spdiags(dm,0,length(dm),length(dm));
    rc = mfPu(r,para.dim,para.m(1),para.m(2),1,'PTu')/4;
    
    para.m = m/2;
    para.h = para.Omega/para.m;    
    
    % RECUSSIVE CALL -------------------------------------------------
    % Solve the coarse grid system
    uc = vcycle(para,0*rc,rc,1e-16,level-1,out);

    % prolongate, back to fine grid
    ur = mfPu(uc,para.dim,para.m(1),para.m(2),1,'Pu');
    
    
    para.m = m;
    para.h = h;
        
    para.M  = M;
    para.B  = B;
    % ----------------------------------------------------------------
    
    % update
    u = u + ur;  r = rhs - Au(u,para);

    if out>0,
      norm_r_app = norm(r)/n;
    end;
    
    % post-smoothing 
    ur = feval(para.MGsmoother,0*r,r,para,para.MGpostsmooth);
    u = u + ur;  r = rhs - Au(u,para);
    
    if out==1,
      fprintf('<%d',level);
    elseif out>1,
      norm_r_post = norm(r)/n;
      
      fprintf('%20s |r-in|   = %e\n',str,norm_r_in);
      fprintf('%20s |r-pre|  = %e\n','',norm_r_pre);
      fprintf('%20s |r-app|  = %e\n','',norm_r_app);
      fprintf('%20s |r-post| = %e\n','',norm_r_post);
    end;
    
    if para.MGcycle > 2,
      fprintf('iter = %d,  |res| = %e\n',i,norm(r))
    end;
    res(i) = norm(r);
    if res(i) < tol, 
      resi = res(i);
%       fprintf('res(i)=%s',num2str(resi));
      fprintf('(-;');
      return; 
    end;
    
    if level == para.MGlevel & out==1,
      fprintf('>');
    end;
  end;

  % FINE GRID DONE
  % ---------------------------------------------------------------------------
else,
  % ---------------------------------------------------------------------------  
  % COARSE grid
  str = sprintf('  - coarse grid %dx%d',m);
  norm_r_in = norm(rhs);

  if length(rhs)>100, error('rhs too big');  end;
  
  %dum = GetB(para,'out',0);
  A   = para.M + para.alpha*para.B'*para.B;  
  u   = pinv(full(A))*rhs;
  r   = rhs - A*u;
  
  norm_r_out = norm(r);
  res = norm_r_out;
  if out==1,
    fprintf('coarse(%dx%d)',m);
  elseif out>1,
    fprintf('%20s |r-in|   = %e\n',str,norm_r_in);
    fprintf('%20s |r-out|  = %e\n',str,norm_r_out);
  end;
end;
% -----------------------------------------------------------------------------

if level == para.MGlevel & out>0,
  if out==1,
    fprintf('.\n');
  end;
 
  %testMG = norm(rhs - mfAu(u,para));
  %fprintf('MG:|rhs-Au(u)|=%12.4e\n',testMG)
end;

