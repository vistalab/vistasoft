%==============================================================================
% Copyright (C) 2006, Jan Modersitzki and Nils Papenberg, see copyright.m;
% this file is part of the FLIRT Package, all rights reserved,
% http://www.math.uni-luebeck.de/SAFIR/FLIRT-MATLAB.html
%==============================================================================
% function [T,dT] = interpolation(varargin)
%
% NP: 2006/05/10, JM: 2006/07/05, 2006/10/06
% NP: 2006/11/25
% 
% An interpolant for the data TD given on implicitely defined points XD is 
% evaluated at points X.
%
% TD:             data
% XD:             discretization of (0,Omega(1))x(0,Omega(2))x(0,Omega(3))
% X:              X=(X^1,X^2,X^3), points at which the interpolation 
%                 has to be evaluated (X is assumed on cell-centered grid)
% doDerivative:   flag for derivative computation
%  
% T:              T  = interp(XD,TD,X), values of interpolation
% dT:             dT = \nabla interp(XD,TD,X), derivative, is required
%                 only computed if nargout > 1 & doDerivative == 1
%
%
% we use persistent PARA to control the interpolation 
%     call interpolation('set','MODE',MODE[,'period',period[,...]]) 
%       to set fields of PARA
%     call PARA = interpolation
%       to get the PARA
%     call [T,dT] = interpolation(RD,Omega,X)
%       to get the interpolatant T(X) and its derivative
%
% the following MODEs are supported:
%   linear, linear-periodic, 

% note: if nargout < 1, derivative is not computed
%==============================================================================

function [T,dT] = interpolation(varargin)


% prepare the output
T  = [];
dT = [];

% -----------------------------------------------------------------------------
% self-testing mode, set PARA, B-spline coeeficients,
% -----------------------------------------------------------------------------
persistent PARA

doTest = (nargout == 0);
if (nargin > 0 & isstr(varargin{1})), doTest = 0;  end;

if doTest,
  testMe(varargin{:})
  return;
end;

if nargout>0 & nargin == 0,            % return PARA
  T  = PARA; 
  return; 
end;

                                       % clear PARA
if isstr(varargin{1}) & strcmp(varargin{1},'clear'),  
  PARA = [];
  return;
end;
                                       % set PARA
if isstr(varargin{1}) & strcmp(varargin{1},'set'),  
  PARA = setPARA(PARA,varargin{2:end});
  T = PARA;
  
  return;
end;


if isempty(PARA), PARA = setPARA(PARA);  end;
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
% start the work
% -----------------------------------------------------------------------------

TD    = varargin{1};
Omega = varargin{2};
X     = varargin{3};
if nargin > 3, doDerivative = varargin{4}; else doDerivative = 1;  end;


% get dimension of interpolation problem and the number n of
% input points

dim = length(Omega);                   % dimension of the problem dim=2,3
n   = length(X)/dim;                   % cut X into pieces X=(X^1,X^2,X^3)

                                       % if matlab-dlinear is choosen, we need to 
if strcmp(PARA.MODE,'matlab-linear'),       
  XD = getDataGrid(Omega,TD);          %  compute the underlying grid explicitely
end;

doDerivative = doDerivative & (nargout>1);
if isempty(PARA.MODE),
  PARA.MODE = 'linear';
  warning('!!! no interpolation MODE given yet, set to linear !!!')
end;
mode = sprintf('%s-%d',PARA.MODE,dim);

[T,dT] = interp2Dlinear(TD,Omega,X,doDerivative);


return;
%==============================================================================
function d = sdiag(d);
d = spdiags(d,0,length(d),length(d));
% =============================================================================



% =============================================================================
% =============================================================================

% ------------------------------------------------------------------------------
% set persistent parameter
% -----------------------------------------------------------------------------
function PARA = setPARA(PARA,varargin)

%disp(mfilename)
%varargin{:}

if ~isfield(PARA,'MODE') | isempty(getfield(PARA,'MODE')),
  PARA = setfield(PARA,'MODE','linear');
end;

for j=1:length(varargin),
  if strcmp(varargin{j},'MODE'),
    PARA.MODE = varargin{j+1};
    varargin([j,j+1]) = [];
    break;
  end;
end;


fprintf('set interpolation PARA: ');

if strcmp(PARA.MODE,'linear-periodic')
  if ~isfield(PARA,'period') | isempty(getfield(PARA,'period')),
    PARA = setfield(PARA,'period',2*pi);
  end;
end;

% overwrite PARA
for k=1:length(varargin)/2,
  str = sprintf('PARA=setfield(PARA,''%s'',varargin{%d});',varargin{2*k-1},2*k);
  %disp(str);
  eval(str);
end;

if ~isempty(PARA),
  fn = fieldnames(PARA);
  for j=1:length(fn),
    if j == 1,
      str = sprintf('%s=%s',fn{j},num2str(getfield(PARA,fn{j})));
    else
      str = sprintf('%s, %s=%s',str, fn{j},num2str(getfield(PARA,fn{j})));
    end;
  end;
  fprintf('%s',str)
end;
fprintf('\n')
return;
% -----------------------------------------------------------------------------


