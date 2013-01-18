function dt6new = dtiTensorRotationTest(rotMethod, xform, dt6)

% dt6new = tensorRotationTest(rotMethod, xform, [dt6])
% Displays ellipsoids in 3D in order to test how the rotation
% methods affect the ellipsoids.
%   rotMethod   'SPM', 'FS' or 'PPD'
%   xform       3x3 linear transform
%   dt6         Input XxYxZx6 dt6 array
%   dt6new      Output XxYxZx6 dt6 array
%
% A user prompt allows specifying the desired 3D view point.
% If dt6 is not provided, then an example is generated, in which
% an ellipsoid is shown in eight different initial positions.
% See code for details.
%
% HISTORY:
%   2004.09.17 ASH wrote it

% Debugging
% A = diag([2 0.1 1]);
% dt6 = reshape(A, [1 1 1 3 3]);
% nx = 3; ny = 3;
% dt6 = repmat(dti33to6(dt6), [nx ny 1 1 1]);
% xform = [cos(0.5) -sin(0.5); sin(0.5) cos(0.5)]; xform(3,3) = 1
% rotMethod = 'FS';
% dt6new = dtiTensorRotationTest(rotMethod, xform, dt6)

% Generate dt6 array
if ~exist('dt6'),
    nx = 3; ny = 3;
	dt6 = [2 0.1 0.5 0 0 0]';
	dt6 = reshape(dt6, [1 1 1 6]);
	dt6 = repmat(dt6, [nx ny 1 1]);
    theta = [0.75 0.5 0.25; 1 0 0; -0.75 -0.5 -0.25]*pi;
    for i=1:ny,
        for j=1:nx
            xformtheta = eye(3);
            xformtheta(1:2,1:2) = [cos(theta(i,j)) -sin(theta(i,j)); sin(theta(i,j)) cos(theta(i,j))];
            dt6(i,j,1,:) = dtiXformTensors(dt6(i,j,1,:), xformtheta);
        end
    end
    dt6(2,2,1,:) = 0;
else
    [nx,ny,nz,n6] = size(dt6);
end
dt33 = dti6to33(dt6);

xform
switch rotMethod,
case 'SPM',
    % spm_matrix method
	tmp = xform; tmp(4,4) = 1;
    p = spm_imatrix(tmp);
	p([1:3,10:12]) = 0; p(7:9) = 1;
	rot = spm_matrix(p); rot = rot(1:3,1:3);
 	dt6new = dtiXformTensors(dt6, rot);
case 'FS',
    % Finite strain method
	[rigidXform, deformation] = dtiFiniteStrainDecompose(xform)
 	dt6new = dtiXformTensors(dt6, rigidXform);
case 'PPD',
    % Preservation of principal direction method
    dt6new = dtiXformTensorsPPD(dt6, xform);
end
dt33new = dti6to33(dt6new);

% reference axes
L = [1 0 0; 0 0 0; 0 1 0; 0 0 0; 0 0 1]';
Lnew = xform * L;

figure(gcf), clf
viewpoint = [0 90];
M = max(dt6(:));
for i = 1:ny,
    for j = 1:nx,
        subplot(ny,nx,(i-1)*ny+j), hold on
        drawEllipsoid(squeeze(dt33(i,j,1,:,:)), 'b')
		plot3(L(1,:),L(2,:),L(3,:),'b')
		drawEllipsoid(squeeze(dt33new(i,j,1,:,:)), 'g')
		plot3(Lnew(1,:),Lnew(2,:),Lnew(3,:),'g')
		hold off
        axis([-M M -M M -M M]), view(viewpoint)
    end
end

fprintf('Viewpoint ([Azimut Elevation]): [%d %d]\n', viewpoint(1), viewpoint(2))
while ~isempty(viewpoint),
    for i = 1:ny,
        for j = 1:nx,
			subplot(ny,nx,(i-1)*ny+j), view(viewpoint)
        end
    end
    viewpoint = input('Viewpoint ([Azimut Elevation]): ');
end

return

%----------------------------------------------------------------
function drawEllipse(A, sub, color)

[V,D] = eig(A(sub,sub));
t = 0:0.001:1;
ellip = V * sqrt(D) * [cos(2*pi*t); sin(2*pi*t)];
plot(ellip(1,:),ellip(2,:),color), axis equal

%----------------------------------------------------------------
function drawEllipsoid(A, color)

[V,D] = eig(A);
r = sqrt(diag(D));
N = 20;
[X,Y,Z] = ellipsoid(0,0,0,r(1),r(2),r(3),N);
P = [X(:)'; Y(:)'; Z(:)'];
P = V*P;
X = reshape(P(1,:), [N+1 N+1]);
Y = reshape(P(2,:), [N+1 N+1]);
Z = reshape(P(3,:), [N+1 N+1]);
mesh(X,Y,Z, 'EdgeColor', color)
axis equal, hidden off
xlabel('x'), ylabel('y'), zlabel('z')

return