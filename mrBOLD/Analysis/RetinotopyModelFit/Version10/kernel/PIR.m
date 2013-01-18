%==============================================================================
% JM: 2006/06/16
% function [wc,his,hisstr] = PIR(TD,RD,Omega,m,y0,model,wRef,wc,varargin)
% PIR: Parametric Image Registration
% minimizes J(wc) = D(T(y0+y(wc)+y0)-R) 
% using a Gauss-Newton scheme with Armijo line search.
%
% R and T a defined by interpolation of discrete given data on Omega:
%   Rc = interpolation(RD,Omega,X);
%   Tc = interpolation(TD,Omega,X);
% see interpolation.m for options.
% 
%==============================================================================

function [wc,his,hisstr] = PIR(RD1,RD2,TD1,TD2,WD1,WD2,Omega,m,...
  y0,model,wRef,wc,varargin)

%==============================================================================
fprintf('%s\n',char(ones(1,80)*'-'));
fprintf('%s: %s registration of two %s images\n',mfilename,model,dimstr(m));

his      = [];                    % saves iteration history
[xCC,h,n] = getGrid(Omega,m);     % create an equispaced cell centered grid on Omega 
hd       = prod(h);               % voxel or pixel volume

if isempty(wc),                   % get starting point wc, if not provided
  wc  = feval(model);   
end;
wc = reshape(wc,length(wc),1);    % just make sure w is a column vector

if isempty(y0),                   % initialize y0, if not provided
  y0 = 0;              
end;

% regularisation parameter for the Hessian:
%   as common for a Gauss-Newton approach, we only know about positive 
%   semi-definiteness of the Hessian; in order to get a well-posed
%   linear algebra problem, we add a small part of the identity (leading
%   to a kind of a Levenberg-Marquardt based approach, or: adding small part
%   of the gradient in the search direction)
regHessian = 1e-3;


maxIter     = 10;                 % max number of iterations
tolJ        = 1e-3;               % stopping criteria for the objective function
tolG        = 1e0;                % stopping criteria for the gradient
tolW        = 5e-3;               % stopping criteria for wc
LSiterMax   = 10;                 % max number of line search steps
LSreduction = 1e-4;               % garanteed reduction in line search
fig         = 1;

for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

IP = interpolation;
CD = distance;
fprintf('interpolation=[%s], distance=[%s], model=[%s]\n',...
  IP.MODE,CD.MODE,model);
                                  % compute the interpolants on the grid
R1c =  interpolation(RD1,Omega,xCC);
R2c =  interpolation(RD2,Omega,xCC);
W1c =  interpolation(WD1,Omega,xCC);
W2c =  interpolation(WD2,Omega,xCC);

                                  % for stopping, we compute T(y0+y(wRef)) and JRef
yc = feval(model,wRef,xCC);       % y = y(w) = model(w,xCC)
                                  % compute reference values 
[J1Ref,T1Ref] = distance(R1c,TD1,Omega,m,y0+yc,W1c);
[J2Ref,T2Ref] = distance(R2c,TD2,Omega,m,y0+yc,W2c);

JRef = J1Ref + J2Ref + (J1Ref == 0); 
Jold = JRef;                      
wold = Inf;

iter = 0;                         % counter for iterations
                                  % compute T(y0+y(wc))
[yc,dy] = feval(model,wc,xCC);
[J1c,T1c,res1,dJ1c,dT1,dres1,d2M1] = distance(R1c,TD1,Omega,m,y0+yc,W1c);
[J2c,T2c,res2,dJ2c,dT2,dres2,d2M2] = distance(R2c,TD2,Omega,m,y0+yc,W2c);

T01 = T1c;                      % for later usage in plots
T02 = T2c;                      % for later usage in plots
                                % the initial value of the objective function 
Jc  = J1c + J2c + (J1c == 0);
J0  = Jc;
dJc = dJ1c + dJ2c;

% and set up a history to memorize some intermediate results
his       = zeros(maxIter,5);
hisstr    = {'iter','J(w)=D(T(y(w)),R)','|\nabla J|','|dw|','#LS'};
his(1,:)  = [0,JRef,0,0,0];

% % prepare some plots
% 
% Rstr = sprintf('R, %s',dimstr(m));
% Tstr = @(j)    sprintf('T(%d)',j);
% Dstr = @(j,Jc) sprintf('|T(%d)-R|=%s%%',j,num2str(100*Jc/JRef));
% Gstr  = sprintf('TD+grid, model= %s',model);
% 
% viewOptn = {'fig',fig,'scale','on','invert','on'};
% gridColor = 'b';
% 
% fig = figure(fig); clf
% str = sprintf('%s: parametric registration, %s, %dD-data, %s',...
%   mfilename,model,length(m),dimstr(m));
% set(fig,'numbertitle','off','name',sprintf('[F3:%d] %s',fig,str));
% 
% viewImage(Rc,Omega,m,'fig',fig,'sub',[2,3,1],'name',Rstr);
% viewImage(Tc,Omega,m,'fig',fig,'sub',[2,3,2],'name',Tstr(iter));
% viewImage(abs(Tc-Rc),Omega,m,'sub',[2,3,3],'name',Dstr(iter,Jc),viewOptn{:});
% viewImage(TRef,Omega,m,'fig',fig,'sub',[2,3,4],'name',Gstr);
% plotGrid(y0+yc,Omega,m,'color',gridColor);
% 

% headlines for the output table
fprintf('%-4s %-12s %-12s %-12s %-4s\n','iter','J','|dJ|','|dw|','#LS');
fprintf('%-4d %-12.2e %-12.2e %-12.2e %-4d\n',his(1,:));

% start the iteration
while 1,
  iter = iter + 1;
  % preparing the approximation to the Hessian
  % using a regularized Gauss-Newton approach
  % for positive definiteness add a small portion of the identity    
  dwres1  = dres1 * dy;    
  dwres2  = dres2 * dy;    
  
  H       = dwres1'*d2M1*dwres1 + dwres2'*d2M2*dwres2 + ...
    0*regHessian*eye(length(wc)); 
  g       = (dJc * dy)';
  normdg  = norm(g);

  %% stopping; cf. GILL-MURRAY-WRIGHT
  STOP1 = (Jold-Jc)     <= tolJ*(1+abs(JRef));
  STOP2 = norm(wc-wold) <= tolW*(1+norm(wc));
  STOP3 = hd*norm(g)    <= tolG*(1+abs(Jc));
  STOP4 = hd*norm(g)    <= eps;
  STOP5 = (iter > maxIter);
  
%   disp([STOP1,STOP2,STOP3])
  if STOP1 & STOP2 & STOP3 | STOP4 | STOP5,
    break
  end;
  
  % compute updata by solving the Newton system for dw
  dw      = -H\g;
  dw      = 1*dw;
  normdw  = norm(dw);

  descent = g' * dw;
  %% do line search
  LSgamma = 1;
  for LSiter =1:LSiterMax,
    wt = wc + LSgamma*dw;
    yt = feval(model,wt,xCC);
    J1t = distance(R1c,TD1,Omega,m,y0+yt,W1c);        
    J2t = distance(R2c,TD2,Omega,m,y0+yt,W2c);
    Jt = J1t + J2t;
    if Jt < Jc + LSreduction* LSgamma * descent,
      break; 
    end;
    LSgamma = LSgamma/2;
  end;
    
  % update   
  wold   = wc;
  Jold   = Jc;
  dw     = wt - wc;
  dJ     = Jc - Jt;
  normdw = norm(dw);
  
  % memorize intermediate results, some output
  his(iter+1,:) = [iter,Jt,normdg,normdw,LSiter];
  fprintf('%-4d %-12.2e %-12.2e %-12.2e %-4d\n',his(iter+1,:));
  
  if Jt < Jc+ LSreduction* LSgamma * descent, 
    wc      = wt;
    [yc,dY] = feval(model,wc,xCC);
    [J1c,T1c,res1,dJ1c,dT1,dres1,d2M1] = distance(R1c,TD1,Omega,m,y0+yc,W1c);
    [J2c,T2c,res2,dJ2c,dT2,dres2,d2M2] = distance(R2c,TD2,Omega,m,y0+yc,W2c);
    Jc  = J1c + J2c;
    dJc = dJ1c + dJ2c;
  else
    J1c = distance(R1c,TD1,Omega,m,y0+yc,W1c);
    J2c = distance(R2c,TD2,Omega,m,y0+yc,W2c);
    Jc = J1c + J2c;
    fprintf('Line Search failed - interrupt\n');
    break; 
  end;        
  
  % visualize the intermediate results
%   viewImage(TRef,Omega,m,'fig',fig,'sub',[2,3,4],'name',Gstr);
%   plotGrid(y0+yc,Omega,m,'color',gridColor);
%   viewImage(Tc,Omega,m,'fig',fig,'sub',[2,3,5],'name',Tstr(iter));
%   viewImage(abs(Tc-Rc),Omega,m,'sub',[2,3,6],'name',Dstr(iter,Jc),viewOptn{:});
%   drawnow

end;%while

if STOP1,
  fprintf('(Jold-Jc)=%16.8e <= tolJ*(1+abs(JRef)) = %16.8e\n',...
    (Jold-Jc),tolJ*(1+abs(JRef)))
end;
if STOP2,
  fprintf('norm(wc-wold)=%16.8e <= tolW*(1+norm(wc)) = %16.8e\n',...
    norm(wc-wold),tolW*(1+norm(wc)))
end;
if STOP3,
  fprintf('norm(g)=%16.8e <= tolG*hd*(1+abs(Jc)) = %16.8e\n',...
    norm(g),tolG*hd*(1+abs(Jc)))
end;
if STOP4,
  fprintf('norm(g)=%16.8e <= eps\n',norm(g))
end;
if STOP5,
  fprintf('iter=%d >= maxIter=%d\n',iter,maxIter);  
end;

his = his(1:iter,:);
return;
%==============================================================================


%==============================================================================

function str = dimstr(value)
str = sprintf('%s = [%s',inputname(1),num2str(value(1)));
for j=2:length(value),
  str = [str,sprintf(',%s',num2str(value(j)))];
end;
str = sprintf('%s]',str);

%==============================================================================
