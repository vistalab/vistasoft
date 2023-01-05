%% t_meshMakeShapes
% 
% Make some class files for simple shapes and mesh testing
%
% BW (c) VISTASOFT Team, Stanford

%% Sample coordinates
N = 64;
[X,Y,Z] = meshgrid(1:N,1:N,1:N);
X = X - N/2; Y = Y - N/2; Z = Z - N/2;

%% Sphere
Ds = zeros(N,N,N);
l = sqrt((X(:).^2 + Y(:).^2 + Z(:).^2)) < 24;
Ds(l) = 5;
% showMontage(double(Ds))

%% Write out the sphere class file into vistadata/anatomy

% It is already checked in.  Only do this if you want to change the file.
% 
% curDir = pwd;
% chdir(fullfile(mrvDataRootPath,'anatomy'));
% niClass = niftiCreate;
% niClass.fname = 'sphere';
% niClass.data = Ds;
% niftiWrite(niClass)
% chdir(curDir); 

%% Make an harmonic shape to view curvature

freq = 2;
C = [X(:), Y(:), Z(:)];  
zThresh = round(10*cos(2*freq*pi*X(:)/N) );

Ds = zeros(N,N,N);

% Oscilate in Z dimension
l = (C(:,3) < zThresh );  % All X positions where Z is less than the thresh
Ds(l) = 2;

% Edge on X dimension extremes
l = (C(:,1) < (min(X(:)) + 2)); Ds(l) = 0;
l = (C(:,1) > (max(X(:)) - 2)); Ds(l) = 0;
% showMontage(double(Ds))

% Edge on Y dimension extremes
l = (C(:,2) < (min(Y(:)) + 2)); Ds(l) = 0;
l = (C(:,2) > (max(Y(:)) - 2)); Ds(l) = 0;

% Get bottom edge
l = (C(:,3) < (min(Z(:) + 2))); Ds(l) = 0;

% showMontage(double(Ds))

%% Write the NIFTI file into vistadata/anatomy

% It is already checked in.  Only do this if you want to change the file.

% curDir = pwd;
% chdir(fullfile(mrvDataRootPath,'anatomy'));
% niClass = niftiCreate;
% niClass.fname = 'harmonic';
% niClass.data = Ds;
% niftiWrite(niClass)
% chdir(curDir); 

%% End
