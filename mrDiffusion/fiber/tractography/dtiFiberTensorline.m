function fiberPath = dtiFiberTensorlinePreinterp(seedPoint, dt6, faImg, voxSize, faThresh, angleThresh, ...
    stepSizeMm, wPuncture, whichAlgorithm)

% fiberPath = dtiFiberTensorlinePreinterp(seedPoint, dt6, faImg, voxSize, faThresh, angleThresh, stepSizeMm, wPuncture, whichAlgorithm)
% 
% Implementation of Lazar's Tensorline algorithm. Eg:
% White Matter Tractography Using Diffusion Tensor Deflection.
% Lazar, et. al. Human Brain Mapping 18:306 321(2003).
%
%
% Can be used to find Tensorline, FACT, or TEND fiber tracing
% Choosing Algorithm using whichAlgorithm: 
%   0 = TensorLine
%   1 = FACT
%   2 = TEND
% 
% Step Size:
% Determines resolution of DTI grid; default is 2x2x2mm voxels
% 1. Step Size < voxel size of inputted DTI matrix.
% Algorithm is forced to reinterpolate tensors at each point (SLOW!).
% 2. Step Size > voxel size of inputted matrix
% Step Size is reinitialized to voxel size of inputted matrix.  
% Algorithm uses "nearest neighbor" concept to find proper tensor
% from the inputted dt6 file
%
% RETURNS:
% fiberPath, a list of coordinates (in voxels, but may be real-valued)
% that define the fiber path.
% 
% HISTORY:
%   2004.02.09 GSM (gmulye@stanford.edu) wrote it.
%   2004.02.09 GSM Minor updates, more userdefined parameters
%   2004.02.13 GSM Modified to use pre-interpolated tensors

%voxSize = [1 1 1]'; %%%FORCE SMALL VOXELS
%oneMmDt6GridSize = [145 196 131 6]; %Size of dt6 array with 1x1x1 voxels
%origDt6GridSize = size(dt6); %Size of dt6 array inputted into function
%origDt6VoxSize = (origDt6GridSize + 1) ./ oneMmDt6GridSize; %vox size of inputted array

stepSize = stepSizeMm*ones(3,1);

if all(voxSize <= stepSize)
    reinterp = 0;
else
    reinterp = 1;
end

%stepSize = stepSizeMm./voxSize; %Step size in voxels - voxSize is 3x1 column vector

% Initialize variables for tracing
% Find major direction (originalDir) of seedPoint voxel
if (reinterp == 0)
    %   voxCoords = nearestNeighbor(seedPoint,voxSize);
    voxCoords = round(seedPoint);
    dt6Tensor = dt6(voxCoords(1),voxCoords(2),voxCoords(3),1:6);
    dt6Tensor = dt6Tensor(:); %Vectorize  
elseif (reinterp == 1)
    dt6Tensor = findTensor(seedPoint,dt6,voxSize);
end
[originalDir junk] = majorEigVec(dt6Tensor);
nextDir = originalDir; % Initialize to seedPoint direction
nextPosition = seedPoint; %Absolute position in voxels
fiberPath = seedPoint; % First point is seed point
fiberPath = tracer(whichAlgorithm,nextPosition,originalDir,voxSize,dt6,reinterp,faImg,faThresh,angleThresh,wPuncture,stepSize,fiberPath,1);
fiberPath = tracer(whichAlgorithm,nextPosition,originalDir,voxSize,dt6,reinterp,faImg,faThresh,angleThresh,wPuncture,stepSize,fiberPath,-1);
return;

function fiberPath = tracer(whichAlgorithm,nextPosition,nextDir,voxSize,dt6,reinterp,faImg,faThresh,angleThresh,wPuncture,stepSize,fiberPath,fwdBkwd)
%==================
% MAIN FUNCTION
%==================
%Traces fiberpath forwards and backwards
iter = 0;
done = 0;
maxIter = 1000;
imSize = size(dt6(:,:,:,1));
nextDir = fwdBkwd*nextDir;
while (~done & iter<maxIter)
    dir = nextDir; %Direction vectors are all 3x1 column vectors
    currentPosition = nextPosition; %Position coordinates are 1x3 row vectors
    if(any(currentPosition<1) | any(currentPosition>imSize))
        disp('Tracking terminated: path wandered outside image data.');
        done = 1;
    else
        % Get the FA for this voxel
        vCoord = floor(currentPosition);
        fa = faImg(vCoord(1), vCoord(2), vCoord(3));
        
        % check dir data is valid (we are in range)
        if (fa <= faThresh | sum(dir) == 0 | isnan(fa))
            disp(['Tracking terminated: fa=',num2str(fa)]);
            done = 1;
        else
            nextPosition = currentPosition + (stepSize'./voxSize') .*dir'; %convert stepSize to voxels
            % Find next diffusion tensor
            if (reinterp == 0)
                %voxCoords = nearestNeighbor(nextPosition,voxSize);
                voxCoords = round(nextPosition);
                if(any(voxCoords==0) | any(voxCoords>imSize) | ~any(isfinite(voxCoords)))
                    disp(['Tracking terminated: path wandered outside image']);
                    done = 1;
                    voxCoords(voxCoords==0) = 1;
                else
                    nextDt6Tensor = dt6(voxCoords(1),voxCoords(2),voxCoords(3),1:6);
                    nextDt6Tensor = nextDt6Tensor(:); %Vectorize
                end
            elseif (reinterp == 1)
                nextDt6Tensor = findTensor(nextPosition,dt6,voxSize);
            end
            % FACT direction, checked to see if angle is less than
            % threshold
            [factDir, nextTensor] = majorEigVec(nextDt6Tensor);
            [smallAngle,direction,angle] = checkAngle(dir,factDir,angleThresh);
            if (smallAngle & (direction == -1)) 
                factDir = -factDir;
            end
            % TEND direction
            tendDir = nextTensor*dir;
            nd = norm(tendDir);
            if(nd<=0)
                tendDir = tendDir/nd;
            else
                tendDir = NaN;
            end
            % Tensorline Algorithm
            if (whichAlgorithm == 0)
                if(tendDir==NaN)
                    disp(['Tracking terminated: tendDir = NaN']);
                    done = 1;
                else
                    if (~smallAngle) % Turning too sharp, ignore FACT vector
                        nextDir = (1-wPuncture)*dir + wPuncture*tendDir;
                    else  % Normal case: Use FACT vector
                        nextDir = fa*factDir + (1-fa)*((1-wPuncture)*dir + wPuncture*tendDir);
                    end
                end
                % FACT only    
            elseif (whichAlgorithm == 1) 
                if (~smallAngle) % Angle too big
                    done = 1; % End tracing due to sharp turn
                    disp(['Tracking terminated: angle (' num2str(round(angle)) ') exceeds threshold.']);
                else
                    nextDir = factDir;
                end
                % TEND only    
            elseif (whichAlgorithm == 2) 
                if(tendDir==NaN)
                    disp(['Tracking terminated: tendDir = NaN']);
                    done = 1;
                else
                    nextDir = tendDir;
                end
            end
            % Append to fiberpath
            if (fwdBkwd == 1)
                fiberPath = [fiberPath; nextPosition];    
            elseif (fwdBkwd == -1)
                fiberPath = [nextPosition;fiberPath];
            end
        end
    end
end
return;


function dt6Tensor = findTensor(point,dt6,voxSize)
persistent initialized;
% Finds tensor interpolation at any point and return dt6 tensor
curPosMm = point.*voxSize';
if(isempty(initialized))
    dt6Tensor = dtiTensorInterp(dt6, curPosMm, voxSize', 1);
    initialized = 1;
else
    dt6Tensor = dtiTensorInterp([], curPosMm, voxSize', 1);
end
return;

function intVox = nearestNeighbor(realCoord,voxSize)
% Rounds mm input into voxel coordinates
decVox = realCoord./voxSize'; %decimal voxels is 1x3
intVox = round(decVox); 
return;

function [majorDir, fullTensor] = majorEigVec(dt6Tensor)
% Finds major direction for given tensor (in 3x3 format)
fullTensor = [dt6Tensor(1) dt6Tensor(4) dt6Tensor(5); ...
        dt6Tensor(4) dt6Tensor(2) dt6Tensor(6); ...
        dt6Tensor(5) dt6Tensor(6) dt6Tensor(3)];
[eigVec,eigVal] = eig(fullTensor);
[maxVal,i] = max(max(eigVal));
majorDir = eigVec(:,i);
%majorDir = [majorDir(2) majorDir(3) majorDir(1)]';
return;

function [angleCheck, direction, angle] = checkAngle(a,b,angleThresh)
% Checks the angle between 2 vectors, returns if angle is less than thresh
% The angle between two vectors is given by acos(aDOTb/{mag(a)*mag(b)})  
anglePos = 180*acos(a'*b)/pi; % In degrees; both vectors are unit vectors
angleNeg = 180*acos(-a'*b)/pi; % Angle with one vector reversed
[angle,i] = min(abs([anglePos angleNeg]));
direction = 0;
if (angle <= angleThresh)
    angleCheck = 1; % Angle is within permissable range
    if (i==2)
        direction = -1; % Use FACT vector in opposite direction
    end
else
    angleCheck = 0; % Does not pass check
end
return