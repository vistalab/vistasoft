function fiberPath = dtiFiberTEND(seedPoint, dt6, faImg, voxSize, faThresh, stepSizeMm)
% fiberPath = dtiFiberTEND(seedPoint, dt6, faImg, voxSize, faThresh, stepSizeMm)
% fiberPath = dtiFiberTEND(seedPoint, dt6, faImg, voxSize, faThresh, stepSize, trackDir, options)
%
% Implementation of Lazar's Tensor Deflection (TEND) algorithm. Eg:
% White Matter Tractography Using Diffusion Tensor Deflection.
% Lazar, et. al. Human Brain Mapping 18:306 321(2003).
%
%
% options include:
%
% RETURNS:
% fiberPath, a list of coordinates (in image space, but may be real-valued)
% that define the fiber path.
% 
% HISTORY:
%   2004.01.23 GSM (gmulye@stanford.edu) wrote it.
%   2004.01.26 GSM Added changable step size, changed args passed in
%
% NOTE: we need to end tracking when we enter a region where dt6 data are
% zeros (ie. outside the actual image data).

if(~exist('stepSize','var') | isempty(stepSize))
    stepSize = 1;
end
if(~exist('trackDir','var') | isempty(trackDir))
    trackDir = 1;
end
% Parse options
if(~exist('options','var'))
    options = {};
end
% Parse option flags (when we have some!)
% for example:
% opt1 = ~isempty(strmatch('optFlag1',lower(options))));

%disp(squeeze(dt6(round(seedPoint(1)), round(seedPoint(2)), round(seedPoint(3)), :))');

%==================
% MAIN TRACING LOOP
%==================
iter = 0;
done = 0;
maxIter = 1000;
imSize = size(dt6(:,:,:,1));

% Find major direction (fiberDirection) of seedPoint voxel
seedPointTensor = findTensor(seedPoint,dt6,voxSize);
[eigVec,eigVal] = eig(seedPointTensor);

% Initializing variables - Tracking Forward from seedpoint
% <<<<<<< dtiFiberTEND.m
originalDir = flipud(eigVec(:,1)); %Direction of seedPoint
vDirNew = originalDir; 
absPosNew = seedPoint; %Absolute position in voxels
fiberPath = seedPoint; 
stepSize = stepSizeMm./voxSize; %Step size in voxels
% =======
% originalDir = flipud(eigVec(:,1));
% vDirNew = originalDir * trackDir;
% absPosNew = seedPoint;
% fiberPath = seedPoint;
% >>>>>>> 1.4
while (~done & iter<maxIter)
    vDir = vDirNew;
    absPosOld = absPosNew;
    if(any(absPosOld<1) | any(absPosOld>imSize))
        disp('Tracking terminated: path wandered outside image data.');
        done = 1;
    else
        
        % Get the FA for this voxel
        vCoord = floor(absPosOld);
        fa = faImg(vCoord(1), vCoord(2), vCoord(3));
        
        % check vDir data is valid (we are in range)
        if (isnan(fa) | fa < faThresh | sum(vDir) == 0)
            disp(['Tracking terminated: fa=',num2str(fa)]);
            done = 1;
        else
            % absPos is the absolute postion in the image space
            absPosNew = absPosOld + stepSize*vDir';
            vDirNew = findTensor(absPosNew,dt6,voxSize)*vDir; % Find direction for next iteration
            vDirNew = vDirNew/norm(vDirNew);
            fiberPath = [fiberPath; absPosNew];%disp(fiberPath);
        end
    end
end
% <<<<<<< dtiFiberTEND.m

done = 0;
vDirNew = -originalDir;
absPosNew = seedPoint;
while (~done & iter<maxIter)
    vDir = vDirNew;
    absPosOld = absPosNew;
    if(any(absPosOld<1) | any(absPosOld>imSize))
        disp('Tracking terminated: path wandered outside image data.');
        done = 1;
    else
        
        % Get the FA for this voxel
        vCoord = floor(absPosOld);
        fa = faImg(vCoord(1), vCoord(2), vCoord(3));
        
        % check vDir data is valid (we are in range)
        if (fa < faThresh | sum(vDir) == 0)
            disp(['Tracking terminated: fa=',num2str(fa)]);
            done = 1;
        else
            % absPos is the absolute postion in the image space
            absPosNew = absPosOld + stepSize'.*vDir';
            vDirNew = findTensor(absPosNew,dt6,voxSize)*vDir; % Find direction for next iteration
            vDirNew = vDirNew/norm(vDirNew);
            fiberPath = [absPosNew; fiberPath];%disp(fiberPath);
        end
    end
end
return

function tensor = findTensor(point,dt6,voxSize)
persistent initialized;
% Finds tensor interpolation at any point and returns 3x3 D matrix
curPosMm = point.*voxSize';
if(isempty(initialized))
    interpTensor = dtiTensorInterp(dt6, curPosMm, voxSize', 1);
    initialized = 1;
else
    interpTensor = dtiTensorInterp([], curPosMm, voxSize', 1);
end
tensor = [interpTensor(1) interpTensor(4) interpTensor(5); ...
          interpTensor(4) interpTensor(2) interpTensor(6); ...
          interpTensor(5) interpTensor(6) interpTensor(3)];
return;
