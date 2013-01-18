function [D,Tc,res,dD,dTc,dRes,d2Phi] = distance(varargin)
% NP, JH 2006/11/25
%
% the distance function is phrased as
% D(y) = D(R,T,y) = phi(res(y))
%
% hence
% D   = phi(res(y))
% dD  = dPhi(res(y)) * dRes(y)
% d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
%
% example SSD:
%   phi = hd/2 res'*res,  dPhi = hd * res', d2Phi = hd
%   res = T(y) - R,       dRes = dT

D     = [];
Tc    = [];
res   = [];
dD    = [];
dTc   = [];
dRes  = [];
d2Phi = [];
%
% -----------------------------------------------------------------------------
persistent PARA


if nargout>0 & nargin == 0,            % return PARA
    D  = PARA;
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
    return;
end;
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
% do the work
% -----------------------------------------------------------------------------

Rc     = varargin{1};
TD     = varargin{2};
Omega  = varargin{3};
m      = varargin{4};
Y      = varargin{5};

doDerivative = (nargout > 3);

h   = Omega./m;
hd  = prod(h);
n   = prod(m);
%X   = getGrid(Omega,m);
%Rc  = interpolation(RD,Omega,X);
[Tc,dTc] = interpolation(TD,Omega,Y,doDerivative);

switch PARA.MODE,

    case 'SSD',
        % D   = phi(res(y))
        % dD  = dPhi(res(y)) * dRes(y)
        % d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
        %
        % example SSD:
        %   phi = hd/2 res'*res,  dPhi = hd * res, d2Phi = hd
        %   res = T(y) - R,       dRes = dT

        res   = (Tc-Rc);
        D     = hd/2 * res' * res;

        if ~doDerivative, return; end;

        dRes  = dTc;
        dD    = hd * res' * dRes;
        d2Phi = hd;


    case 'SSD_W',
        % D   = phi(res(y))
        % dD  = dPhi(res(y)) * dRes(y)
        % d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
        %
        % example SSD:
        %   phi = hd/2 res'*res,  dPhi = hd * res, d2Phi = hd
        %   res = T(y) - R,       dRes = dT
        
        mask   = varargin{6};

        res    = (Tc-Rc).*mask;
        D      = hd/2 * res' * res;

        if ~doDerivative, return; end;

        dRes  = sdiag(mask) * dTc;
        dD    = hd * res' * dRes;
        d2Phi = hd;

    case 'SSD_WP',
        % D   = phi(res(y))
        % dD  = dPhi(res(y)) * dRes(y)
        % d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
        %
        % example SSD:
        %   phi = hd/2 res'*res,  dPhi = hd * res, d2Phi = hd
        %   res = T(y) - R,       dRes = dT
        period = PARA.period;
        period2 = period/2;

        mask   = varargin{6};

        res1   = Tc - Rc;

        p      = zeros(size(res1));
        p(res1 > period2)  = -period;
        p(res1 < -period2) =  period;

        res1   = res1 + p;
        res    = res1.*mask;
        D      = hd/2 * res' * res;

        if ~doDerivative, return; end;

        dRes  = sdiag(mask) * dTc;
        dD    = hd * res' * dRes;
        d2Phi = hd;

    case 'NGF',
        % D   = phi(res(y))
        % dD  = dPhi(res(y)) * dRes(y)
        % d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
        %
        % example NGF:
        %   phi = hd/2 res'*res,  dPhi = hd * res, d2Phi = hd
        %   dR_i  = \nabla R_i / |\nabla R_i|_edge
        %   res = (\nabla T(y_i)' * dR_i) / ( |\nabla T(y_i)|_edge )
        %   dRes = complicated, see below

        edge = PARA.edge;
        [G1,G2,G3] = getGrad('c',Omega,m);
        if isempty(G3), G3 = 0; end;

        d1R = G1 * Rc(:);    d2R = G2 * Rc(:);    d3R = G3 * Rc(:);
        d1T = G1 * Tc(:);    d2T = G2 * Tc(:);    d3T = G3 * Tc(:);

        ndR = sqrt(d1R.^2 + d2R.^2 + d3R.^2 + edge^2);
        ndT = sqrt(d1T.^2 + d2T.^2 + d3T.^2 + edge^2);

        nd1R = d1R./ndR;      %nd1T = d1T./ndT;
        nd2R = d2R./ndR;      %nd2T = d2T./ndT;
        nd3R = d3R./ndR;      %nd3T = d3T./ndT;

        res1 = (nd1R.*d1T + nd2R.*d2T + nd3R.*d3T);
        res2 = 1./ndT;
        res  = res1 .* res2;

        D    = -hd/2 * res' * res;

        if ~doDerivative, return; end;

        dRes1 = sdiag(nd1R)*G1 + sdiag(nd2R)*G2 + sdiag(nd3R)*G3;
        dRes2 = -sdiag(1./ndT.^3)*(sdiag(d1T)*G1 + sdiag(d2T)*G2 + sdiag(d3T)*G3);
        dRes  = (sdiag(res2)*dRes1 + sdiag(res1)*dRes2) * dTc;

        dD    = -hd * res' * dRes;
        d2Phi = hd; % note the missing minus sign is not a bug!


    case 'MI'
        % D   = phi(res(y))
        % dD  = dPhi(res(y)) * dRes(y)
        % d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
        %
        % example MI:
        %   phi   = res' * log(res + tol) + ...
        %   dPhi  = log(res + tol) + res./(res + tol) + ...
        %   d2Phi = (res + 2*tol)./(res + tol)^2 + ...
        %   res   = rho(T(y),R)
        %   dRes  = drho, see pdfestimate
        tol         = PARA.entropyTol;
        [rho,drho]  = pdfestimate(Rc,Tc,PARA,doDerivative);
        [n1,n2]     = size(rho);

        rhoR = sum(rho,2);
        rhoT = sum(rho,1)';
        rho  = rho(:);

        res  = rho;
        D    = rhoR'*log(rhoR+tol)+rhoT'*log(rhoT+tol) - rho'*log(rho+tol);

        if ~doDerivative, return; end;

        SR    = sparse(kron(ones(1,n2),speye(n1,n1)));
        ST    = sparse(kron(speye(n2,n2),ones(1,n1)));

        dPhi  = ...
            (log(rhoR+tol)+rhoR./(rhoR+tol))'*SR ...
            +(log(rhoT+tol)+rhoT./(rhoT+tol))'*ST ...
            -(log(rho +tol)+rho ./(rho +tol))';

        dRes  = drho*dTc;
        dD    = dPhi * dRes;

        d2Phi = ...
            SR'*sdiag((rhoR + 2*tol)./(rhoR+tol).^2)*SR ...
            +ST'*sdiag((rhoT + 2*tol)./(rhoT+tol).^2)*ST ...
            -sdiag((rho + 2*tol)./(rho+tol).^2);

        a = 1/sqrt(PARA.ngvR*PARA.ngvT);
        a = 1e0;
        d2Phi = - a * d2Phi;

    otherwise, error(sprintf('MODE = %s not implemented',MODE));
end;

return;

% =============================================================================
function d = sdiag(d);
d = spdiags(d,0,length(d),length(d));
% =============================================================================
function testMe(varargin)

fprintf('test %s\n',mfilename)

if nargin == 0,
    TD = zeros(100,100);
    TD(31:60,31:60) = 100;
    RD = TD + 1e1*randn(size(TD));
    Omega = [1,1];
    m     = [32,32];
    X  = getGrid(Omega,m);
    interpolation('set','MODE','linear-smooth');
    Rc = interpolation(RD,Omega,X);

    X = X+0.1;
end;

fctn = @(X) distance(Rc,TD,Omega,m,X);
testDerivative(fctn,X);

return;

% =============================================================================
function testDerivative(fctn,xc)

fprintf('derivative(%s)\n',mfilename)

[f,Tc,res,df]  = feval(fctn,xc);
v       = randn(size(xc));
dfv     = df*v;
hh      = logspace(0,-10,11);
fprintf('%12s %12s %12s \n','h','|fc-ft|','|fc+vdfc-ft|');
for j=1:length(hh),
    xt = xc + hh(j)*v;
    ft = feval(fctn,xt);
    n1 = norm(f(:)-ft(:));
    n2 = norm(f(:)+hh(j)*dfv-ft(:));
    fprintf('%12.4e %12.4e %12.4e\n',hh(j),n1,n2);
end;
return;
% =============================================================================

% ------------------------------------------------------------------------------
% set persistent parameter
% -----------------------------------------------------------------------------
function PARA = setPARA(PARA,varargin)

%disp(mfilename)
%varargin{:}

if ~isfield(PARA,'MODE') | isempty(getfield(PARA,'MODE')),
    PARA = setfield(PARA,'MODE','SSD');
end;

for j=1:length(varargin),
    if strcmp(varargin{j},'MODE'),
        PARA.MODE = varargin{j+1};
        varargin([j,j+1]) = [];
        break;
    end;
end;

fprintf('set distance MODE to %s, ',PARA.MODE);
switch PARA.MODE,
    case 'SSD',
        fprintf('no additional parameter needed\n');
    case 'SSD_W',
        fprintf('no additional parameter needed\n');
    case 'SSD_WP',
        if ~isfield(PARA,'period'), PARA.period = [];  end;
        if isempty(PARA.period),    PARA.period = 10;  end;
        for k=1:length(varargin)/2,
            str = sprintf('PARA=setfield(PARA,''%s'',varargin{%d});',...
                varargin{2*k-1},2*k);
            %disp(str);
            eval(str);
        end;
        fprintf('period=%s\n',num2str(PARA.period));
    case 'NGF',
        if ~isfield(PARA,'edge'), PARA.edge = [];  end;
        if isempty(PARA.edge),    PARA.edge = 10;  end;
        for k=1:length(varargin)/2,
            str = sprintf('PARA=setfield(PARA,''%s'',varargin{%d});',...
                varargin{2*k-1},2*k);
            %disp(str);
            eval(str);
        end;
        fprintf('edge=%s\n',num2str(PARA.edge));
    case 'MI',
        PARA = setMIpara(PARA,varargin{:});
        fprintf('setMIpara used\n');
    otherwise,
        error(sprintf('MODE = %s',MODE))
end;

return;
% -----------------------------------------------------------------------------
% -----------------------------------------------------------------------------
