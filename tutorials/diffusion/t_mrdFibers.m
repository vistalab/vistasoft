%% t_mrdFibers
%
% Load, plot and analyze fiber group properties
%
%
% (c) Stanford VISTA Team

%% Read dti data summary and a fiber group
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
dt6 = dtiLoadDt6(dt6Name);

fgName = fullfile(dataDir,'fibers','leftArcuate.pdb');
fg = mtrImportFibers(fgName);

% Fiber coords are stored in ACPC space.  Notice coordinates
mrvNewGraphWin
fibers = fgGet(fg,'fibers');
fList = Randi(length(fibers),[1,50]);
for ii = fList
    plot3(fibers{ii}(1,:),fibers{ii}(2,:),fibers{ii}(3,:));
    hold on
end
axis equal; axis on, grid on
%% Place the fiber coordinates into image indices

% Create a version of the fibers with coordinates represented in 
% acpc space.
%
% dt6.xformToAcpc is image space to acpc.  Fibers are in ACPCP, and we want
% to go back to image space.  Hence the inverse.  Note:  This calculation
% is performed in homogeneous coordinates.
fg = dtiXformFiberCoords(fg,inv(dt6.xformToAcpc));
fibers = fgGet(fg,'fibers');

% Notice that the new locations are all positive, as in image indices
mrvNewGraphWin
for ii = fList
    plot3(fibers{ii}(1,:),fibers{ii}(2,:),fibers{ii}(3,:));
    hold on
end
axis equal; axis on, grid on
%% For each point on each fiber, we make its tensor.

% We do this by setting the d_par and d_perp (axial and radial
% diffusivity).  We use the tangent to the fiber curve at that point and
% these two values to construct a tensor.

% fgGet(fg,'tangent')  - Returns the tangent at each position for each
% fiber

% We checked that the gradients are the same (up to a scale factor of 2).
% thisFiber = fg.fibers{1};
% acpcGradient = gradient(thisFiber);

ff = 10;
thisFiber = fibers{ff};
imgGradient = gradient(thisFiber);

% Draw quivers of x and x + gradient(x).
% This shows the points and the tangent to the curve
% The final 0 is essential for handling Matlab's little arrowheads.
mrvNewGraphWin;
quiver3(thisFiber(1,:),thisFiber(2,:),thisFiber(3,:),...
    imgGradient(1,:),imgGradient(2,:),imgGradient(3,:),0)

%% The largest eigenvalue of the tensor is equal to the axial diffusivity.  

% In units of um^2/ms.
% The average of the next two eigenvalues is the radial diffusivity.
% The average of all of the eigenvalues is the mean diffusivity.

% dtiGetValFromTensors ???
% t = dt6.dt6(50,40,40,:);
% Q = [t(1), t(4), t(5);
%     t(4), t(2), t(6);
%     t(5), t(6), t(3)];
% figure; ellipsoidFromTensor(Q,[0 0 0],16)

% Largest (sorted) eigenvalues
% val = eigs(Q);
% 
% ad = val(1);
% rd = (val(2) + val(3))/2;

% Check this on a linux box.
% dtiGetValFromTensors(dt6, [40,40,40],eye(4),'famdadrd','nearest')

% Reshape the tensor into Quadratic form.
% dt6Tensors = dt6.dt6(40:42,40:41,40:43,:);
coords = [40:42;40:42;40:42]';
Q = dt6toQ(dt6.dt6,coords);
svd(reshape(Q(1,:),3,3))


%% Calculate a simulated tensor for each point and each fiber.

% The tensors all have a common axial and radial diffusivity
d_ad = 1.5; d_rd = 0.2;
dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;

% Calculate a tensor for each point on each fiber.
%
% The tensors differ in their principal diffusion direction, which is
% calculated from the tangent to the fiber's curve.  But they have the same
% ad and rd.
fg.tensors = fgTensors(fg,dParms);  % Should become fgSet


%% Plot a fiber and sampled diffusion ellipsoids
thisFiber     = fg.fibers{ff};
imgGradient   = gradient(thisFiber);
thisTensor    = fg.tensors{ff};

% Try making a picture of the points and the local gradient.
% Draw quivers of x and x + gradient(x).
% This will show the points and the tangent to the curve
%
% The final 0 is essential for handling Matlab's little arrowheads.

mrvNewGraphWin;
nSkip = 10;
newFigure = 0;
for ii=1:nSkip:size(thisFiber,2)
    Q = reshape(thisTensor(ii,:),3,3);
    C = thisFiber(:,ii)';
    ellipsoidFromTensor(Q,C,16,newFigure); 
    hold on;
end
quiver3(thisFiber(1,:),thisFiber(2,:),thisFiber(3,:),...
    imgGradient(1,:),imgGradient(2,:),imgGradient(3,:),0)
hold off

%% This is an example of how to compute the AD, RD and PDD 

% For a particular fiber
thisTensor = fg.tensors{ff};

% And a particular point
thisPoint = 5;
Q = reshape(thisTensor(thisPoint,:),3,3);

% Calculate eigenvalues and eigenvectors
[V,D] = eigs(Q);
val = diag(D);
ad = val(1);
rd = (val(2) + val(3))/2;
pdd = V(:,1);
ad, rd
pdd

%% End