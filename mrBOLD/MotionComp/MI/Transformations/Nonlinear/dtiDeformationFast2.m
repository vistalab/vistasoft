function [ux,uy,uz,err,Tnew,fx,fy,fz] = dtiDeformationFast2(R,T,maxiter,ux,uy,uz)
% [ux,uy,uz] = dti3dStanfordElasticRegistration3d(R,T,maxiter) - 3D Elastic registration.
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

% Set size of pad
pad = 25;

% Default values for input arguments
 
if (nargin<3),
    maxiter = 10;
end;

if (nargin<6),
    ux = zeros(m+2*pad,n+2*pad,o+2*pad);
    uy = zeros(m+2*pad,n+2*pad,o+2*pad);
    uz = zeros(m+2*pad,n+2*pad,o+2*pad);
end;

% Initializing R and T with pad
RLuebeck = zeros(m+2*pad,n+2*pad,o+2*pad,c);
TLuebeck = zeros(m+2*pad,n+2*pad,o+2*pad,c);

% Converting data
if(c==6)
    RLuebeck(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad,:) = dti3dStanford2dti3d(R);
    TLuebeck(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad,:) = dti3dStanford2dti3d(T);
else
    RLuebeck(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad,:) = R;
    TLuebeck(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad,:) = T;
end

% Calling registration routine
[ux,uy,uz,err,TnewLuebeck,fx,fy,fz] = elasticRegistration3dNopad(RLuebeck,TLuebeck,maxiter,ux,uy,uz);

% Converting data
if(c==6)
    Tnew = dti3d2dti3dStanford(TnewLuebeck(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad,:));
else
    Tnew = TnewLuebeck(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad,:);
end

% Removing pad
ux = ux(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad);
uy = uy(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad);
uz = uz(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad);
fx = fx(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad);
fy = fy(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad);
fz = fz(1+pad:m+pad,1+pad:n+pad,1+pad:o+pad);

return

function [ux,uy,uz,err,Tnew,fx,fy,fz] = elasticRegistration3dNopad(R,T,maxiter,ux,uy,uz) 

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
% (c) 2004 Matthias Bolten

% If maxiter is not set, set it to the default.


% if (nargin<5),
if (nargin<3),
    maxiter = 10;
end;

% Setting stepsize.
stepsize = 1;

% Getting size of R.
[m,n,o,c] = size(R);

% Checking size of T.
[mcheck,ncheck,ocheck,ccheck] = size(T);
if (mcheck~=m||ncheck~=n||ocheck~=o||ccheck~=c),
    error('Sizes of R and T do not match!');
end;

% Default values:
istancemeasure = 1;
interpolation = 2;

% If no displacement field is given, create it.
if (nargin<6),
    ux = zeros(m,n,o); uy = ux; uz = uy;
end;

% If a displacement field is given, apply it.
if (nargin>5),
    for j=1:c,
% For my FORTRAN-version:
%        Tnew(:,:,:,j) = displaceT3d(T(:,:,:,j),-ux,-uy,-uz);
        Tnew(:,:,:,j) = trilin(T(:,:,:,j),ux,uy,uz);
    end;
    normux = sqrt(sum(sum(sum(ux.^2))));
    normuy = sqrt(sum(sum(sum(uy.^2))));
    normuz = sqrt(sum(sum(sum(uz.^2))));
else
    Tnew = T;
    normux = 0;
    normuy = 0;
    normuz = 0;
end;

% Initializing solver.

%%%%%%TEST SCRIPT%%%%%%%%
lambda = 0;
mu = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%

loesePDE('what','init','lambda',lambda,'mu',mu,'n1',m,'n2',n,'n3',o);

% Initial output.
err = [sqrt(sum(sum(sum(sum((R-Tnew).^2)))))];

force = [];
disp(sprintf('Iteration %d: ||R(x)-T(x-u(x))|| = %f',0,err(end)));

for i=1:maxiter,
    fx = zeros(m,n,o); fy = fx; fz = fx;
    for j=1:c,
        fx = fx + (Tnew(:,:,:,j)-R(:,:,:,j)).*(Tnew([2:end,end],:,:,j)-Tnew([1,1:end-1],:,:,j));
        fy = fy + (Tnew(:,:,:,j)-R(:,:,:,j)).*(Tnew(:,[2:end,end],:,j)-Tnew(:,[1,1:end-1],:,j));
        fz = fz + (Tnew(:,:,:,j)-R(:,:,:,j)).*(Tnew(:,:,[2:end,end],j)-Tnew(:,:,[1,1:end-1],j));
    end;
    normfx = sqrt(sum(sum(sum(fx.^2))));
    normfy = sqrt(sum(sum(sum(fy.^2))));
    normfz = sqrt(sum(sum(sum(fz.^2))));

    disp(sprintf('Iteration %d: ||f_{x}|| = %f, ||f_{y}|| = %f, ||f_{z}|| = %f.',i-1,normfx,normfy,normfz))
    disp(sprintf('Iteration %d: ||u_{x}|| = %f, ||u_{y}|| = %f, ||u_{z}|| = %f.',i-1,normux,normuy,normuz))

    [vx,vy,vz]=loesePDE('what','solve','f1',-fx,'f2',-fy,'f3',-fz);
    delta=stepsize/max(abs([vx(:);vy(:);vz(:)])+1e-15);

    ux = ux + delta * vx;
    uy = uy + delta * vy;
    uz = uz + delta * vz;
    normux = sqrt(sum(sum(sum(ux.^2))));
    normuy = sqrt(sum(sum(sum(uy.^2))));
    normuz = sqrt(sum(sum(sum(uz.^2))));

    for j=1:c,
% For my FORTRAN-version:
%        Tnew(:,:,:,j) = displaceT3d(T(:,:,:,j),-ux,-uy,-uz);
        Tnew(:,:,:,j) = trilin(T(:,:,:,j),ux,uy,uz);
    end;
    
    % Output.
    err = [err,sqrt(sum(sum(sum(sum((R-Tnew).^2)))))];
    force = [force,sqrt(normfx.^2+normfy.^2+normfz.^2)];
    disp(sprintf('Iteration %d: ||R(x)-T(x-u(x))|| = %f',i,err(end)));
end;