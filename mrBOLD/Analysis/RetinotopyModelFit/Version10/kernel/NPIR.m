%==============================================================================
% Copyright (C) 2006, Jan Modersitzki and Nils Papenberg, see copyright.m;
% this file is part of the FLIRT Package, all rights reserved,
% http://www.math.uni-luebeck.de/SAFIR/FLIRT-MATLAB.html
%==============================================================================
% function [yc,his,hisstr] = NPIRnD(TD,RD,Omega,m,yKern,yc,varargin);
% JM: 2006/02/07, 2006/02/25, 2006/10/13
% NPIR: Non-Parametric Image Registration
%
%  minimizes J(yc) = D(yc) + \alpha * S(yc-yKern)
%
% using a Gauss-Newton approach with Armijo line search; here
%  Rc = interpolation(RD,Omega,X), a sample of the interpolant of RD a grid X
%  Tc = interpolation(TD,Omega,yc),  a sample of the interpolant of TD a grid y(X)
%  D(yc) = h2/2 * norm(Tc-Rc)^2,
%  S(yc) = h2/2 * norm(B*(yc-yKern))^2,
%
%input:
%  RD,TD:           interpolation data
%  Omega            domain (typically, Omega = ]0,1[ x ]0,1[)
%  m                resolution of the interpolant
%  yKern            is used to simplify the regularization,
%                   note:  S = || B*(yc-yKern) ||^2
%  yc               this guy is what we are looking for,
%                   we may supply a starting guess
%output:
%  yc               our numerical solution to the problem
%  his              the history of the iteration:
%                   his = [iter,J,D,S,|dJ|,|dY|,LS],
%                   LS stands for linsearch steps
%  hisstr           the names of the history
%==============================================================================


%==============================================================================
function [yc,his,hisstr] = NPIRnD(RD1,RD2,TD1,TD2,WD1,WD2,Omega,m,...
  yKern,yc,varargin);
%==============================================================================

alpha       = 1;                  % regularization parameter
beta        = 1;                  % volume preserving parameter
mu          = 1;                  % Lame cosntants mu, lambda
lambda      = 0;
maxIter     = 10;                 % maximum number of iterations
tolJ        = 1e-2;               % for stopping
tolY        = 5e-3;               %   - " -
tolG        = 1e-0;               %   - " -
LSiterMax   = 10;                 % maximum number of linesearch iterations
LSreduction = 1e-4;               % minimal reduction in linesearch
fig         = 1;
regularizer = 'elastic';

for k=1:1:length(varargin)/2,     % overwrite default parameter
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

fprintf('%s\n',char(ones(1,80)*'-'));

% generate the sampling grid for the interpolants
[xStg,h,n] = getGrid(Omega,m,'staggered');
hd = prod(h);                     % shortcut for convenience
if isempty(yKern),                % we don't need to supply yKern,
  yKern = xStg;                   % note: yKern = xStg results in a penalization
end;                              % of the displacement u = yc - xStg
if isempty(yc),                   % we don't need to supply a starting guess
  yc = xStg;                      % note: yc = xStg is the identity
end;


% Regularizer without MG
switch regularizer
  case 'diffusive'
    [B,Bstr] = getDiffusiveMatrixStg(Omega,m);
  case 'elastic'
    [B,Bstr] = getElasticMatrixStg(Omega,m,mu,lambda);
  otherwise
    error('wrong regularizer');
end

PY = stg2center(xStg,m,'Py');
R1c = interpolation(RD1,Omega,PY);
R2c = interpolation(RD2,Omega,PY);
W1c = interpolation(WD1,Omega,PY);
W2c = interpolation(WD2,Omega,PY);

% evaluate reference objective function for
% stopping
[D1c,T1Ref] = distance(R1c,TD1,Omega,m,PY,W1c);
[D2c,T2Ref] = distance(R2c,TD2,Omega,m,PY,W2c);

Dc = D1c + D2c;
Sc = hd/2 * norm(B*(xStg-yKern))^2;
Cc = fctnVol(xStg-yKern,Omega,m);

Jc = Dc + alpha*Sc + beta* Cc;
JRef = abs(Jc) + (Jc == 0);
% evaluate initial objective function for
% plots
PY = stg2center(yc,m,'Py');
[D1c,T1c] = distance(R1c,TD1,Omega,m,PY,W1c);
[D2c,T2c] = distance(R2c,TD2,Omega,m,PY,W2c);
Dc = D1c + D2c;

Sc = hd/2 * norm(B*(yc-yKern))^2;
Cc = fctnVol(yc,Omega,m);

Jc = Dc + alpha*Sc + beta * Cc;


% prepare the iteration history
hisstr = {'iter','J','D','S','C','|\nabla J|','|dY|','LS'};
his = zeros(maxIter,8);
his(1,:) = [0,Jc,Dc,Sc,Cc,0,0,0];
iter = 0;
% some output
fprintf('SAFIR: 2006, <%s> %s, alpha=%s, beta=%s\n',...
  mfilename,'regularizer',num2str(alpha),num2str(beta));
fprintf('%s, %s, %s\n',dimstr(m),dimstr(Omega),dimstr(h));
fprintf('%-4s %-10s %-10s %-10s %-10s %-10s %-10s %-4s\n',...
  'iter','J','D','S','C','|dJ|','|dY|','LS');
fprintf('%-4d %-10.4e %-10.2e %-10.2e %-10.2e %-10.2e %-10.2e %-4d\n',his(1,:));

% % do some plots --------------------------------------------------------------
% fig = figure(fig); clf;
% set(fig,'numbertitle','off',...
%   'name',sprintf('[JM-%d]: %s, %s, %s',fig,mfilename,dimstr(m),'mfElasticStg'));
% 
% Rstr = sprintf('R, %s, \\alpha=%s',dimstr(m),num2str(alpha));
% 
% Tstr = @(j)    sprintf('T(%d)',j);
% Dstr = @(j,Jc) sprintf('|T(%d)-R|=%s%%',j,num2str(100*Jc/JRef));
% Gstr = @(dY)   sprintf('TD+grid, |dY| = %s',num2str(dY));
% 
% viewOptn = {'fig',fig,'scale','on','invert','on'};
% gridColor = 'b';
% 
% TRef = interpolation(TD,Omega,stg2center(yKern,m,'Py'));
% 
% viewImage(Rc,Omega,m,'fig',fig,'sub',[2,3,1],'name',Rstr);
% viewImage(Tc,Omega,m,'fig',fig,'sub',[2,3,2],'name',Tstr(iter));
% viewImage(255-abs(Tc-Rc),Omega,m,'sub',[2,3,3],'name',Dstr(iter,Jc),viewOptn{:});
% viewImage(TRef,Omega,m,'fig',fig,'sub',[2,3,4],'name',Gstr(0));
% plotGrid(PY,Omega,m,'color',gridColor);
% %------------------------------------------------------------------------------

yold = 0*yc;
Jold = Jc;

%-- start the iteration -------------------------------------------------------
for iter=1:maxIter,


  % compute deformed template Tc and its derivative dT
  PY = stg2center(yc,m,'Py');
  [D1c,T1c,res1,dD1,dT1,dres1,d2phi1] = distance(R1c,TD1,Omega,m,PY,W1c);
  [D2c,T2c,res2,dD2,dT2,dres2,d2phi2] = distance(R2c,TD2,Omega,m,PY,W2c);
  
  Dc = D1c + D2c;
  dD = dD1 + dD2;

  %% compute objective function, gradient and (quasi-) Hessian
  dD = stg2center(dD',m,'PTy');
  By = B*(yc-yKern);
  Sc = hd/2 * norm(By)^2;
  dS = hd   * B'*By;
  [Cc,dC,d2C] = fctnVol(yc,Omega,m);
  Jc = Dc + alpha * Sc + beta * Cc;
 
  dJ = dD + alpha * dS + beta * dC';
  dJcc = stg2center(dJ,m,'Py');

  %% stopping; cf. GILL-MURRAY-WRIGHT
  STOP1 = (Jold-Jc)     <= tolJ*(1+abs(JRef));
  STOP2 = norm(yc-yold) <= tolY*(1+norm(yc));
  STOP3 = hd*norm(dJ)   <= tolG*(1+abs(Jc));
  STOP4 = hd*norm(dJ)   <= eps;
  STOP5 = (iter >= maxIter);

  if STOP1 & STOP2 & STOP3 | STOP4 | STOP5,
    break
  end;

  maxdJ = vecNormCC(dJcc,m);

  %   d2J  = hd*( P'*dT'*dT*P + alpha*B'*B );
  %   para.M = spdiags(diag(P'*dT'*dT*P),0,size(P,2),size(P,2));

  
  m1 = diag(dres1'*d2phi1*dres1);
  m2 = diag(dres2'*d2phi2*dres2);
  
  m1 = stg2center(m1,m,'PTy')/2;
  m2 = stg2center(m2,m,'PTy')/2;
  M1 = spdiags(m1,0,length(m1),length(m1));
  M2 = spdiags(m2,0,length(m2),length(m2));
  M  = M1 + M2;
  
%   dres1cc = stg2center(dres1,m,'PTy')/2;
%   dres2cc = stg2center(dres2,m,'PTy')/2;
% 
%   M = (dres1cc'*d2phi1*dres1cc + dres2cc'*d2phi2*dres2cc);

  M = M + alpha * B'*B + beta * d2C;

 % keyboard;
  dY = solveLinearSystem('matlab',M,-dJ);

  descent =   dJ' * dY;
  if descent > 0,
    warning('no descent direction, switch to -dY!')
    dY      = -dY;
    descent = -descent;
  end;

  %% do line search
  LSgamma = 1;
  for LSiter =1:LSiterMax,
    yt = yc + LSgamma*dY;
    PY = stg2center(yt,m,'Py');
    [D1t,T1t] = distance(R1c,TD1,Omega,m,PY,W1c);
    [D2t,T2t] = distance(R2c,TD2,Omega,m,PY,W2c);
    Dt = D1t + D2t;
    St = hd/2 * norm(B*(yt-yKern))^2;
    Ct = fctnVol(yt,Omega,m);
    Jt = Dt + alpha * St + beta * Ct;
    if Jt<Jc + LSreduction * LSgamma * descent , break; end;
    LSgamma = LSgamma/2;
  end;
  dobreak = (Jt >= Jc + LSreduction * LSgamma * descent );

  % compute changes
  dYcc  = stg2center(yt-yc,m,'Py');
  maxdY = vecNormCC(dYcc,m);

  his(iter+1,:) = [iter,Jt,Dt,St,Ct,maxdJ,maxdY,LSiter];
  fprintf('%-4d %-10.4e %-10.2e %-10.2e %-10.2e %-10.2e %-10.2e %-4d\n',...
    his(iter+1,:));

  %   % do some plots ------------------------------------------------------------
  figure(11)
  PY = stg2center(yt-yKern+xStg,m,'Py');
  %   viewImage(TRef,Omega,m,'fig',fig,'sub',[2,3,4],'name',Gstr(maxdY));
  clf
  plotGrid(PY,Omega,m,'color','r');
  axis image;
%   viewImage(Tt,Omega,m,'fig',fig,'sub',[2,3,5],'name',Tstr(iter));
%   viewImage(255-abs(Tt-Rc),Omega,m,'sub',[2,3,6],'name',Dstr(iter,Jt),viewOptn{:});
%   drawnow
%   %----------------------------------------------------------------------------

  if dobreak, break; end;
  % update
  Jold = Jc;
  yold = yc;
  yc   = yt;
  Jc  = Jt;

end%For; % end of iteration loop
%------------------------------------------------------------------------------

his = his(1:iter,:);

if STOP1,
  fprintf('(Jold-Jc)=%16.8e <= tolJ*(1+abs(JRef)) = %16.8e\n',...
    (Jold-Jc),tolJ*(1+abs(JRef)))
end;
if STOP2,
  fprintf('norm(yc-yold)=%16.8e <= tolY*(1+norm(yc)) = %16.8e\n',...
    norm(yc-yold),tolY*(1+norm(yc)))
end;
if STOP3,
  fprintf('hd*norm(dJ)=%16.8e <= tolG*(1+abs(Jc)) = %16.8e\n',...
    hd*norm(dJ),tolG*(1+abs(Jc)))
end;
if STOP4,
  fprintf('hd*norm(dJ)=%16.8e <= eps\n',hd*norm(dJ))
end;
if STOP5,
  fprintf('iter=%d >= maxIter=%d\n',iter,maxIter);
end;

return;

%==============================================================================

function str = dimstr(value)
str = sprintf('%s = [%s',inputname(1),num2str(value(1)));
for j=2:length(value),
  str = [str,sprintf(',%s',num2str(value(j)))];
end;
str = sprintf('%s]',str);

%==============================================================================

function n = vecNormCC(y,m)

dim = length(m);
m = length(y)/dim;
switch dim
  case 2
    n = max(sqrt(y(1:m).^2+y(m+(1:m)).^2));
  case 3
    n = max(sqrt(y(1:m).^2+y(m+(1:m)).^2+y(2*m+(1:m)).^2));
end;
%==============================================================================
