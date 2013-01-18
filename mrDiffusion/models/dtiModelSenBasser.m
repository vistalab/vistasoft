function [D,fvf] = dtiModelSenBasser(rs, L, rc, Ds)
%
% [D,fvf] = dtiModelSenBasser(rs, L, [rc=0.6*rs], [Ds=0.03])
%
% Implementation of Sen & Basser (2005). A Model for Diffusion in White
% Matter in the Brain. Biophys Journal, 89:2927:2938.
%
% rs = sheath radius (outer radius of the axons)
% L  = on-center distance for the hexpack array of axons
% rc = core radius (inner radius of the axons)
% Ds = sheath diffusivity, in micrometers^2/msec
%
% Returns the simulated diffusion tensor D and the fiber volume fraction
% fvf.
%
% Note that the myelin sheath thickness is thought to scale linearly with
% the axon radius (e.g., see Rushton 1951 JPhysiol(Lond) 115:101–122.) The
% optimal value of the inner radius / outter radius ratio is 0.6, and the
% empirically observed ratios seem to be centered on this optimum. Sen and
% Basser cite the Rushton paper, but chose to use a ratio of 0.7 for their
% defaults.
%
% For all scalar inputs, D is returned as a 3x3 tensor. If any parameter is
% an array, then D will be returned as a nx6 array of [Dxx Dyy Dzz Dxy
% Dxz Dyz] terms. The covariance terms are always zeros for this model, but
% they are inlcuded to make it wasy to call mrDiffusion tensor processing
% functions. E.g., you can pass the output directly into dtiComputeFA.
%
% Note that for hex-packing, the circles occupy pi/(2*sqrt(3)) = 0.9069 of
% the total area when totally packed (e.g., when L = rs*2). When the
% packing is less dense, we can write the fiber volume fraction as
% (2*pi*rs^2)/(L^2*sqrt(3)). This is derived by drawing an equilateral
% triangle between the vertices of 3 adjoining circles. The area of that
% triangle is simply s^2*sqrt(3)/4, where s (side length) = L. Within that
% triangle, we get 3 * 1/6 = 1/2 of a circle, so its area is pi*r^2/2.
% Combining these, we get (pi*rs^2/2) / (L^2*sqrt(3)/4, which simplifies to
% (2*pi*rs^2)/(L^2*sqrt(3)).
%
% To reproduce Sen & basser's Figures 4 & 5:
% rs = [6:0.1:9.1];
% [D,fvf] = dtiModelSenBasser(rs, 18.25, 6.0);
% figure(4); plot(rs,mean(D(:,1:3),2),'k');
% xlabel('r_s (\mum)'); ylabel('ADC (\mum^2/msec)');
% figure(5); plot(rs,D(:,1)./D(:,2),'k');
% xlabel('r_s (\mum)'); ylabel('Anisotropy');
%
% figure(6); plot(fvf,D(:,1)./D(:,2),'k');
% xlabel('Fiber volume fraction'); ylabel('Anisotropy');
%
% rs = [0.5:0.1:5]; sL = [2:.1:6]; clear fvf fa
% for(ii=1:numel(rs)) [D,fvf(:,ii)]=dtiModelSenBasser(rs(ii),sL.*rs(ii)); fa(:,ii)=dtiComputeFA(D); end
% figure; plot(fvf(:),fa(:),'ko');
% p = polyfit(fa(:),fvf(:),2);
% hold on; plot(polyval(p,fvf),fvf,'k-');
%
% HISTORY:
% 2009.04.21 RFD wrote it.
% 

% Subscripts:
%  'c' denotes core (intraaxonal)
%  's' denotes sheath (within the myelin)
%  'b' denotes bath (extraaxonal)
%
% D denotes diffusivity, C denotes equilibrium concentration
%

if(~exist('rc','var')||isempty(rc))
    % Assume that the myelin is 20% or the radius
    rc = 0.6.*rs;
end

% Concentrations are with respect to unit molarity of bulk water
mol = 1.0;

% Set some plausible values for human brain at body temperature
if(~exist('Db','var')||isempty(Db))
    Db = 2.0;
end
if(~exist('Dc','var')||isempty(Dc))
    Dc = 0.75;
end
if(~exist('Ds','var')||isempty(Ds))
    Ds = 0.03;
end

% Concentrations are with respect to unit molarity of bulk water
if(~exist('Cb0','var')||isempty(Cb0))
    Cb0 = 0.95;
end
if(~exist('Cc0','var')||isempty(Dc0))
    Cc0 = 0.88;
end
if(~exist('Cs0','var')||isempty(Cs0))
    Cs0 = 0.5;
end
Cb0 = Cb0.*mol;
Cc0 = Cc0.*mol;
Cs0 = Cs0.*mol;

% L is the on-center distance between cylinders
% rc and rs are the core and sheath radii

% For hexpack:
f = (2.*pi.*rs.^2)./(sqrt(3).*L.^2);

rcs = rc.^2./rs.^2;

% From eq. 7:
Ceff = (1-f).*Cb0 + f.*rcs.*Cc0 + f.*(1-rcs).*Cs0;

% From equation 9:
dlCl = (1-f).*Db.*Cb0 + f.*rcs.*Dc.*Cc0 + f.*(1-rcs).*Ds.*Cs0;

% Compute the odd "lambda 2l-1" terms 
l1 = lambda(1, Cs0, Ds, Cb0, Db, Cc0, Dc, rc, rs);
l5 = lambda(5, Cs0, Ds, Cb0, Db, Cc0, Dc, rc, rs);
l7 = lambda(7, Cs0, Ds, Cb0, Db, Cc0, Dc, rc, rs);


dtCt = Db .* Cb0 .* (1 - 2.*f ./ (l1 + f - (0.07542 .* f.^6 .* l7) ./ (l5 .* l7 - 1.06028.*f.^12)));

n = numel(dlCl);
if(n>1)
    D = zeros(n,6);
    D(:,1:3) = [dlCl./Ceff; dtCt./Ceff; dtCt./Ceff]';
else
    D = diag([dlCl dtCt dtCt] ./ Ceff);
end

if(nargout>1)
    fvf = (2*pi.*rs.^2)./(L.^2.*sqrt(3));
end

return;


function l = lambda(tlm1, Cs0, Ds, Cb0, Db, Cc0, Dc, rc, rs)
% tlm1 = 2*l - 1
es = Cs0 .* Ds;
eb = Cb0 .* Db;
ec = Cc0 .* Dc;
l = ((eb-es).*(es-ec).*rc.^(2.*tlm1) + (eb+es).*(ec+es).*rs.^(2.*tlm1)) ...
 ./ ((eb+es).*(es-ec).*rc.^(2.*tlm1) + (eb-es).*(ec+es).*rs.^(2.*tlm1));
return;


