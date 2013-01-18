function [deformField, newImg, absDeform, MSE] = dtiDeformationScalar(srcImg, trgImg, maxIter, smoothLevel) 
% [deformField, newImg, absDeform, MSE] = dtiDeformationScalar(srcImg, trgImg, maxIter, smoothLevel) 
% 
% A demon-based non-linear image registration algorithm. 
%
%
% INPUTS:
% SRCIMG: 3-dimensional source image
% TRGIMG: 3-dimensional target image
% MAXITER: maximum number of iterations desired (default is 50)
% SMOOTHLEVEL: specify smoothing levels via vector (default is [11 7 5 3])
%
% RETURNS:
% deformField: deformation, in target image space
% newImg: Deformed source image
% absDeform: Magnitude of deformation field at each voxel
% MSE: Error curve as function of iteration 
%
% 
% HISTORY:
%   2004.08.11 RFD wrote it, based on code by GSM (gmulye@stanford.edu).

if(~exist('maxIter','var') | isempty(maxIter))
    maxIter = 50; 
end


if(~exist('smoothLevel','var') | isempty(smoothLevel))
    smoothLevel = [11 9 5 3];
end

% Make sure target and source image are same dimension
dimSrc = size(srcImg); 
dimTrg = size(trgImg);
if (dimSrc ~= dimTrg)
    disp('Target and source image must be same size!')
    return
end

V = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3); 

%Building a mutual mask
mask = srcImg<=0 | trgImg<=0;

% Force edges of both brains to be same
srcImg(mask) = 0;
trgImg(mask) = 0;

% Initialize final position matrix (original position at first)
% *** REPLACE THIS WITH MESHGRID
H = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3);
for x = 1:dimSrc(1)
    for y = 1:dimSrc(2)
        for z = 1:dimSrc(3)
            H(x,y,z,:) = [y x z];
        end
    end
end

gauss = newGauss(dimSrc,smoothLevel(1)); % Create 3D Gauss smoothing kernel
newImg = srcImg;
iter = 1; lastSwitch = 0; 
done = 0;
smoothIndex = 1;
MSE = zeros(maxIter,1);

%------------------
% MAIN LOOP 
%------------------
disp(sprintf('Smoothing with %d kernel (level %d of %d)...', smoothLevel(smoothIndex), smoothIndex, length(smoothLevel)));
while (iter <= maxIter & done == 0)
    %CONDITIONALS CONTROL LEVEL OF SMOOTHING
    slope = diff(MSE)';
    if ((iter - lastSwitch > 5) & (smoothIndex < length(smoothLevel))) %Check if smooth level is not highest smoothLevel
        if (slope(iter-2) + slope(iter-1)) >= 0 | (smoothIndex*maxIter/length(smoothLevel) < iter)
            smoothIndex = smoothIndex + 1; 
            gauss = newGauss(dimSrc,smoothLevel(smoothIndex)); %Initialize new gaussian smoothing filter
            disp(sprintf('Smoothing with %d kernel (level %d of %d)...', smoothLevel(smoothIndex), smoothIndex, length(smoothLevel)));
            lastSwitch = iter;
        end    
    elseif ((iter > 5) & smoothIndex == length(smoothLevel)) %Smooth level is highest smooth level
        if (slope(iter-2) + slope(iter-1) >= 0) | (smoothIndex*maxIter/length(smoothLevel) < iter)
            disp(['Finished- MSE curve leveled out at ' num2str(iter) ' iterations.']);
            done = 1;
        end  
    end
    
    % PERFORM SMOOTHING - MULTIPLICATION IN FREQUENCY DOMAIN
    oldV = zeros(size(V));
    for i = 1:3
        ftV = fftshift(fftn(V(:,:,:,i)));
        filteredV = gauss.*ftV;
        oldV(:,:,:,i) = real(ifftn(ifftshift(filteredV)));
    end
    
    newH = H + oldV; % Original position H plus all increments

    %INTERPOLATION- TRILINER 
    coordsList = reshape(newH, prod(dimSrc), 3);
    newImg = reshape(myCinterp3(srcImg, [dimSrc(1),dimSrc(2)],dimSrc(3), coordsList)',dimSrc(1),dimSrc(2),dimSrc(3));
    
    
    V = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3); %Only displacements from current iter
    % Difference between modified source image and target image
    imgDiff = newImg - trgImg; 
    % Gradient of modified source image
    gradNewImg = calcGrad(newImg);
    % Performing point-by-point demons algorithm, using above operations
    mse = 0;
    for x = 1:dimSrc(1)
        for y = 1:dimSrc(2)
            for z = 1:dimSrc(3)
                voxGrad = gradNewImg(x,y,z,:); %1x3 array 
                voxGrad = voxGrad(:);
                voxDiff = imgDiff(x,y,z); %Scalar quantity
                mse2 = voxDiff^2;
                numerator = voxDiff*voxGrad; %1x3
                denominator = (norm(voxGrad)^2 + norm(voxDiff)^2); %Scalar
                if (denominator == 0)
                    denominator = 1;
                end
                V(x,y,z,1) =  V(x,y,z,1) + numerator(2)/(denominator);
                V(x,y,z,2) =  V(x,y,z,2) + numerator(1)/(denominator);
                V(x,y,z,3) =  V(x,y,z,3) + numerator(3)/(denominator);
                mse = mse + sqrt(mse2);
            end
        end
    end
    mse = mse/(dimSrc(1)*dimSrc(2)*dimSrc(3));
    MSE(iter) = mse;
    V = oldV + V; %All stored displacements (current iter and all past iterations)
    disp(mse)
    iter = iter+1;
end
deformField = V;
absDeform = sqrt(deformField(:,:,:,1).^2+deformField(:,:,:,2).^2+deformField(:,:,:,3).^2);
absDeform(mask) = 0; %Zero out crazy values outside mask caused by Interp
return


function outGrad = calcGrad(img)
%Approximates gradient of image - each voxel has an associated 3x1 grad
imgDim = size(img);
outGrad = zeros(imgDim(1),imgDim(2),imgDim(3),3);
[gradX,gradY,gradZ] = gradient(img, 1);  
outGrad(:,:,:,1) = -gradY; 
outGrad(:,:,:,2) = -gradX; 
outGrad(:,:,:,3) = -gradZ;
return

function gauss = newGauss(dimSrc,variance)
% CREATE INITIAL GAUSSIAN SMOOTHING KERNEL
gaussx = gausswin(dimSrc(1),variance);
gaussy = gausswin(dimSrc(2),variance);
gaussz = gausswin(dimSrc(3),variance);
gaussxy = gaussx*gaussy';
gauss = repmat(gaussxy,[1 1 dimSrc(3)]);
for i = 1:dimSrc(1)
    for j = 1:dimSrc(2)
        gauss(i,j,:) = gaussxy(i,j)*gaussz;
    end
end
return