function [figHandle,tensorSum] = dtiDrawTensor(d,loc,glyph,col,lightSetting,numPt,gamma)
% Draws a tensor
% 
%    [figHandle,tensorSum] = dtiDrawTensor(d,[loc],[glyph],[numPt],[gamma])
% 
% Inputs:
%    d            - 6x1 vector: [Dxx Dyy Dzz Dxy Dxz Dyz]'
%                   OR 3x1 vector: [lambda1 lambda2 lambda3]'
%    loc          - 3x1 vector: [x y z] coords specifying the center of tensor
%    glyph        - 'ellipsoid' or 'superquadric' (Kindlmann, 2004)
%                   (default = 'ellipsoid')
%    col          - 1x3 vector: [r g b] (default = [0.5 0.5 0.5])
%    lightSetting - 1x3 vector: [ambient diffuse specular]
%                   (default = [0.8 0.8 0.25])
%    numPt        - number of points to be rendered (default = 100)
%    gamma        - determines the "sharpness" of the edges in the
%                   superquadric mode (default = 3)
% 
% Outpus:
%    figHandle - figure handle
%    tensorSum - a structure with the following fields:
%                'md' - mean diffusivity
%                'fa' - fractional anisotropy
%                'pr' - prolate index, i.e., normalized 1st eigenvalue
%                'ob' - oblate index, i.e., normalized 2nd eigenvalue
%                'cl' - Westin's linearity index
%                'cp' - Westin's planarity index
%                'cs' - Westin's sphericity index
% 
% Examples:
%    % create a sample tensor
%    d = [750 250 100 150 50 50];
%    % draw the tensor with default settings
%    dtiDrawTensor(d);
%    % draw again in superquadric mode
%    dtiDrawTensor(d,'superquadric');
% 
%    % draw a tensor with some eigenvalues
%    eigVal = [1600 500 300];
%    % draw the tensor with default settings
%    dtiDrawTensor(eigVal);
%    % draw again in superquadric mode
%    dtiDrawTensor(eigVal,'superquadric');
% 
% References:
%    Kindlmann G., "Superquadric tensor glyphs," in Proc. IEEE TVCG/EG
%    Symposium on Visualization 2004, pp. 147-154, May 2004.
% 
%    Westin C.-F., Peled S., Gubjartsson H., Kikinis R., Jolesz F.,
%    "Geometrical diffusion measures for MRI from tensor basis analysis,"
%    in Proc. 5th Annual ISMRM, 1997.
% 
% History:
%    2006/08/17 shc (shcheung@stanford.edu) wrote it.
%    2007/01/11 shc made lots of changes ... 
% 

if ieNotDefined('loc'),          loc          = [0 0 0]';       end
if ieNotDefined('glyph'),        glyph        = 'ellipsoid';    end
if ieNotDefined('col'),          col          = [0.5 0.5 0.5];  end
if ieNotDefined('lightSetting'), lightSetting = [0.8 0.8 0.25]; end
if ieNotDefined('numPt'),        numPt        = 100;            end

switch length(d)
    case 6 % dt6 format
        D = diag(d(1:3));

        D(1,2) = d(4); D(2,1) = d(4);
        D(1,3) = d(5); D(3,1) = d(5);
        D(2,3) = d(6); D(3,2) = d(6);

        [eigVec,eigVal] = eig(D);
    case 3 % eigenvalues only
        eigVal = diag(d);
        eigVec = [1 0 0; 0 0 1; 0 1 0];
end

lambda = sort(diag(eigVal),'descend');

td = trace(eigVal);
md = td / 3;
ss = sum((lambda - md).^2);
fa = sqrt(3/2) * sqrt(ss/sum(lambda.^2));
pr = lambda(1) / td;
ob = lambda(2) / td;
cl = (lambda(1) - lambda(2)) / td;
cp = 2 * (lambda(2) - lambda(3)) / td;
cs = 3 * lambda(3) / td;

switch glyph
    case { 'e' , 'ellipsoid' }
        [x,y,z] = ellipsoid(0,0,0,1,1,1,numPt);
        xyz = [x(:),y(:),z(:)]*eigVal*eigVec';
        x(:) = xyz(:,1);
        y(:) = xyz(:,2);
        z(:) = xyz(:,3);
    case { 's' , 'superquadric' }
        [eigVal,ind] = sort(diag(eigVal),'descend');
        eigVec = eigVec(:,ind);
        if ieNotDefined('gamma'), gamma = 3; end
        if cl >= cp
            al = (1 - cp) ^ gamma;
            be = (1 - cl) ^ gamma;
            [x,y,z] = superquadric([numPt,numPt],al,be);
            R = Rm([0 1 0],pi/2);
            eigVal = abs(R * eigVal([3 2 1]));
            xyz = R * [x(:)'; y(:)'; z(:)'];
            [x,y,z] = deal( ...
                reshape(xyz(1,:),size(x)), ...
                reshape(xyz(2,:),size(x)), ...
                reshape(xyz(3,:),size(x)) );
        else % z-axis is the asymmetric axis
            al = (1 - cl) ^ gamma;
            be = (1 - cp) ^ gamma;
            [x,y,z] = superquadric([numPt,numPt],al,be);
        end
        xyz = eigVec * diag(eigVal) * [x(:)'; y(:)'; z(:)'];
        [x,y,z] = deal( ...
            reshape(xyz(1,:),size(x)), ...
            reshape(xyz(2,:),size(x)), ...
            reshape(xyz(3,:),size(x)) );
    otherwise
end

x = x+loc(1);
y = y+loc(2);
z = z+loc(3);

figHandle = surf(x,y,z, ...
    'FaceColor',col,...
    'FaceAlpha',1,...
    'AmbientStrength',lightSetting(1),...
    'DiffuseStrength',lightSetting(2),...
    'SpecularStrength',lightSetting(3),...
    'linestyle','none');
set(gca,'XTick',[],'YTick',[],'ZTick',[]);
axis equal;
title({sprintf('Prolate index = %.2f  Oblate index = %.2f', pr, ob) ; ...
    sprintf('MD = %.2f  FA = %.2f', md, fa); ...
    sprintf('C_l = %.2f  C_p = %.2f  C_s = %.2f', cl, cp, cs)});
xlabel('x - left/right');
ylabel('y - posterior/anterior');
zlabel('z - inferior/superior');
camlight;
view(45,45);

tensorSum = struct('md',md,'fa',fa,'pr',pr,'ob',ob,'cl',cl,'cp',cp,'cs',cs);

return

function [x,y,z] = superquadric(N,alpha,beta)

theta = linspace(-pi,pi,N(1));
phi   = linspace(-pi/2,pi/2,N(2))';

cosTheta = cos(theta);
sinTheta = sin(theta);

cosPhi   = cos(phi);
sinPhi   = sin(phi);

sinTheta(1)    = 0;
sinTheta(N(1)) = 0;

cosPhi(1)    = 0;
cosPhi(N(2)) = 0;

cosBetaPhi    = sign(cosPhi)   .* abs(cosPhi)   .^ beta;
sinBetaPhi    = sign(sinPhi)   .* abs(sinPhi)   .^ beta;
cosAlphaTheta = sign(cosTheta) .* abs(cosTheta) .^ alpha;
sinAlphaTheta = sign(sinTheta) .* abs(sinTheta) .^ alpha;

x = cosBetaPhi * cosAlphaTheta;
y = cosBetaPhi * sinAlphaTheta;
z = sinBetaPhi * ones(size(theta));

return

function R = Rm(ax,alpha)

sz = size(ax);
if sz(1)<sz(2), ax = ax'; end

% make sure it is a unit vector (normalize)
ax = ax./norm(ax,2);   

Wa=[   0    -ax(3)    ax(2);
     ax(3)    0      -ax(1);
    -ax(2)   ax(1)     0     ];

R = cos(alpha) * eye(length(ax)) ...
    + (1-cos(alpha)) * ax * ax' ...
    + sin(alpha) * Wa;

return
