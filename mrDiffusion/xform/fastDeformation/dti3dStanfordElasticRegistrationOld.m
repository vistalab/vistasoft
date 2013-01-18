function [ux,uy,uz,err,Tnew,fx,fy] = dti3dStanfordElasticRegistration(R,T,maxiter,ux,uy,uz)
% [ux,uy,uz] = dti3dStanfordElasticRegistration(R,T,maxiter) - 3D Elastic registration.
%
% Input:
% R          - Reference image.
% T          - Target image.
% maxiter    - Maximum number of iterations, (optional, default: 10).
% [ux,uy,uz] - Displacement field (optional).
%
% Output:
% [ux,uy,uz] - Displacement field.
% err        - Error vector.
% Tnew       - Displaced target image.
%
% This is just a wrapper routine.
%
%
% Remark:
%
% New coordinates are calculated as follows:
%   xnew(i,j,k) = xold(i,j,k) - ux(i,j,k);
%   ynew(i,j,k) = yold(i,j,k) - uy(i,j,k);
%   znew(i,j,k) = zold(i,j,k) - uz(i,j,k);
%
% (c) 2004 Matthias Bolten

% Size of R
[m,n,o,c] = size(R);

% Default values for input arguments
if (nargin<3),
    maxiter = 10;
end;

if (nargin<6),
    ux = zeros(m,n,o);
    uy = zeros(m,n,o);
    uz = zeros(m,n,o);
end;

% Converting data
RLuebeck = dti3dStanford2dti3d(R);
TLuebeck = dti3dStanford2dti3d(T);

% Calling registration routine
[ux,uy,uz,err,TnewLuebeck,fx,fy,fz] = elasticRegistration3d(RLuebeck,TLuebeck,maxiter,ux,uy,uz);

% Converting data
Tnew = dti3d2dti3dStanford(TnewLuebeck);
