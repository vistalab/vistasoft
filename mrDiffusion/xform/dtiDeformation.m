function [newImg, MSE, absDeform, deformField] = dtiDeformation(srcImg,trgtImg,maxIter,interpType,deformationFN,smoothLevel) 
% [newImg, MSE, absDeform, deformField] = dtiDeformation(srcImg,trgtImg,maxIter,interpType,deformationFN,smoothLevel) 
% 
% Implementation of Park's demon-based multi-channel image registration
% algorithm. Eg: Spatial normalization of diffusion tensor MRI using multiple channels
% Park, et. al. NeuroImage 20 1995-2009(2003).
%
%
% INPUTS:
% SRCIMG: 3-dimensional source image, in DT6 format
% TRGTIMG: 3-dimensional target image, in DT6 format
% MAXITER: maximum number of iterations desired (default is 50)
% INTERPTYPE: Type of interpolation desired, 'trilinear' (default) or 'pajevic'
% DEFORMATIONFN: Desired filename (default:
%   'SRCsourceCode_to_TRGTtemplate_deformField.mat')
% SMOOTHLEVEL: specify smoothing levels via vector (default is [11 7 5 3])
%
% RETURNS:
% NEWIMG: Deformed source image
% ABSDEFORM: Magnitude of deformation field at each voxel
% MSE: Error curve as function of iteration 
%
% 
% HISTORY:
%   2004.4.11 GSM (gmulye@stanford.edu) wrote it.
%   2004.5.24 GSM Last revision
%   2004.11.10 GSM Preservation of Principle Direction correction added

if(~exist('maxIter','var') | isempty(maxIter))
    maxIter = 50; 
end

if(~exist('interpType','var') | isempty(maxIter))
    interpType = 0; 
else
    interpType = lower(interpType);
    interpType = interpType(1);
    if interpType == 't'
        interpType = 0;
    elseif interpType == 'p'
        interpType = 1;
    else
        'Choose Pajevic or Trilinear to interpolate'
    end
end

if(~exist('smoothLevel','var') | isempty(smoothLevel))
    smoothLevel = [11 9 5 3];
end

%LOAD IN VARIABLES
src = load(srcImg); 
srcDt6 = src.dt6;
srcNotes = src.notes;
trgt = load(trgtImg); 
trgtDt6 = trgt.dt6;

% Make sure target and source image are same dimension
dimSrc = size(srcDt6); dimTrgt = size(trgtDt6);
if (dimSrc ~= dimTrgt)
    disp('Target and source image must be same size!')
    return
end

if(~exist('V','var') | isempty(V))
    V = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3); 
end

%Building a mutual mask - probably an better way to do this
srcMask = zeros(dimSrc(1),dimSrc(2),dimSrc(3));
trgtMask = zeros(dimSrc(1),dimSrc(2),dimSrc(3));
for z = 1:dimSrc(3)
    for c = 1:6
        srcMask(:,:,z) = and(srcMask(:,:,z),roicolor(srcDt6(:,:,z,c),0,1));
        trgtMask(:,:,z) = and(trgtMask(:,:,z),roicolor(trgtDt6(:,:,z,c),0,1));
    end
end
finalMask1 = ~or(srcMask,trgtMask);
finalMask6 = zeros(dimSrc);
for c = 1:6
    finalMask6(:,:,:,c) = finalMask1;
end
%Force edges of both brains to be same
srcDt6 = srcDt6 .* finalMask6;
trgtDt6 = trgtDt6 .* finalMask6;

% Initialize final position matrix (original position at first)
H = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3);
for x = 1:dimSrc(1)
    for y = 1:dimSrc(2)
        for z = 1:dimSrc(3)
            H(x,y,z,:) = [y x z];
        end
    end
end

gauss = newGauss(dimSrc,smoothLevel(1)); %Create 3D Gauss smoothing kernel
newImg = srcDt6;
iter = 1; lastSwitch = 0; 
done = 0;
smoothIndex = 1;
MSE = zeros(maxIter,1);

%%%%%%%%%%%%%%%%%
%%%%MAIN LOOP%%%%
%%%%%%%%%%%%%%%%%
while (iter <= maxIter & done == 0)
    %CONDITIONALS CONTROL LEVEL OF SMOOTHING
    slope = diff(MSE)';
    if ((iter - lastSwitch > 5) & (smoothIndex < length(smoothLevel))) %Check if smooth level is not highest smoothLevel
        if (slope(iter-2) + slope(iter-1)) > 0| (smoothIndex*maxIter/length(smoothLevel) < iter)
            smoothIndex = smoothIndex + 1; 
            gauss = newGauss(dimSrc,smoothLevel(smoothIndex)); %Initialize new gaussian smoothing filter
            disp('Switch smoothing!');
            lastSwitch = iter;
        end    
    elseif ((iter > 5) & smoothIndex == length(smoothLevel)) %Smooth level is highest smooth level
        if (slope(iter-2) + slope(iter-1) > 0) | (smoothIndex*maxIter/length(smoothLevel) < iter)
            disp('MSE Curve Leveled Out, No of Iterations:');
            done = 1;
            disp(iter);
        end  
    end
    
    %PERFORM SMOOTHING - MULTIPLICATION IN FREQUENCY DOMAIN
    oldV = zeros(size(V));
    for i = 1:3
        ftV = fftshift(fftn(V(:,:,:,i)));
        filteredV = gauss.*ftV;
        oldV(:,:,:,i) = real(ifftn(ifftshift(filteredV)));
    end
    
    newH = H + oldV; %Original position H plus all increments

    %INTERPOLATION
    if (interpType == 1) %PAJEVIC INTERPOLATION
        tempCoords = zeros(size(newH));
        tempCoords(:,:,:,1) = newH(:,:,:,2);
        tempCoords(:,:,:,2) = newH(:,:,:,1);
        tempCoords(:,:,:,3) = newH(:,:,:,3);
        coordsList = reshape(tempCoords,dimSrc(1)*dimSrc(2)*dimSrc(3),3);
        listLength = prod(dimSrc(1:3));    
        mmCoordsList = 2*(coordsList - ones(listLength,3));
        if iter == 1
            newImgList = dtiTensorInterp(srcDt6, mmCoordsList, [2 2 2],1); %Outputs listLengthx6 
        else
            newImgList = dtiTensorInterp([], mmCoordsList, [2 2 2]); %Outputs listLengthx6
        end
        newImg = reshape(newImgList,dimSrc);
        
    elseif (interpType == 0) %TRILINER INTERPOLATION
        newImgList = zeros(dimSrc(1)*dimSrc(2)*dimSrc(3),6);
        coordsList = reshape(newH,dimSrc(1)*dimSrc(2)*dimSrc(3),3);
        for i = 1:6
            newImgList(:,i) = myCinterp3(srcDt6(:,:,:,i),[dimSrc(1),dimSrc(2)],dimSrc(3),coordsList)';
        end
        newImg = zeros(dimSrc(1),dimSrc(2),dimSrc(3),6);
        for i = 1:6
            newImg(:,:,:,i) = reshape(newImgList(:,i),dimSrc(1),dimSrc(2),dimSrc(3));
        end
    end
 
    %Reorient to preserve principal direction (PPD)
    R = dtiFindXformPPD(newImg,oldV); %Find voxel by voxel rotation matricies to PPD
    newImg = dtiXformTensorsPPD(newImg,R); %Apply rotation matricies to each voxel (optimized)
  
    V = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3); %Only displacements from current iter
    %Difference between modified source image and target image
    imgDiff = newImg - trgtDt6; 
    %Gradient of modified source image
    gradNewImg = calcGrad(newImg);
    %Performing point-by-point demons algorithm, using above operations
    mse = 0;
    for x = 1:dimSrc(1)
        for y = 1:dimSrc(2)
            for z = 1:dimSrc(3)
                mse2 = 0;
                for c = 1:6
                    voxGrad = gradNewImg(x,y,z,c,:); %1x3 array 
                    voxGrad = voxGrad(:);
                    voxDiff = imgDiff(x,y,z,c); %Scalar quantity
                    mse2 = mse2 + voxDiff^2;
                    numerator = voxDiff*voxGrad; %1x3
                    denominator = (norm(voxGrad)^2 + norm(voxDiff)^2); %Scalar
                    if (denominator == 0)
                        denominator = 1;
                    end
                    V(x,y,z,1) =  V(x,y,z,1) + numerator(2)/(denominator);
                    V(x,y,z,2) =  V(x,y,z,2) + numerator(1)/(denominator);
                    V(x,y,z,3) =  V(x,y,z,3) + numerator(3)/(denominator);
                end
                mse = mse + sqrt(mse2);
            end
        end
    end
    mse = mse/(dimSrc(1)*dimSrc(2)*dimSrc(3));
    MSE(iter) = mse;
    V = V./dimSrc(4); %Average displacements caused by different channels
    V = oldV + V; %All stored displacements (current iter and all past iterations)
    disp(mse)
    iter = iter+1;
end
deformField = V;
absDeform = zeros(dimSrc(1),dimSrc(2),dimSrc(3));
for x = 1:dimSrc(1)
    for y = 1:dimSrc(2)
        for z = 1:dimSrc(3)
            coords = deformField(x,y,z,:);coords = coords(:);
            absDeform(x,y,z) = norm(coords);
        end
    end
end    

absDeform = absDeform .* finalMask1; %Zero out crazy values outside mask caused by Pajevic Interp

[junk eigTrgt] = dtiSplitTensor(trgtDt6);
faTrgt = dtiComputeFA(eigTrgt);
[junk eigReg] = dtiSplitTensor(newImg);
faReg = dtiComputeFA(eigReg);
faDifference = faTrgt-faReg;

% SAVES OUT DEFORMATION FIELD FILE
sourceImage = srcImg;
targetImage = trgtImg;
iterations = maxIter;
if (~exist('deformationFN','var'))
    [a srcImgFN b c] = fileparts(srcImg);
    [a trgtImgFN b c] = fileparts(trgtImg);
    us=findstr('_',srcImgFN);
    srcCode = srcImgFN(1:us(1)-1);
    us=findstr('_',trgtImgFN);
    trgtCode = trgtImgFN(1:us(1)-1);
    deformationFN = [srcCode,'_2_',trgtCode,'_DF'];
end

save(deformationFN,'deformField','absDeform','sourceImage','targetImage','iterations','MSE','faDifference');

% TO SAVE OUT DEFORMED IMAGE
fn = strcat(srcCode,'_reg2_',trgtCode);
b0 = src.b0;
xformToAcPc = src.xformToAcPc;
xformToAnat = src.xformToAnat;
anat = src.anat;
mmPerVox = src.mmPerVox;
dt6 = newImg;
notes = strcat(sourceImage,' registered to ', targetImage, 'with ', iterations, ' iterations');
save(fn,'b0','xformToAcPc','xformToAnat','anat','notes','mmPerVox','dt6');
return

%==========================================================================

function dt6Grad = calcGrad(dt6Img)
%Approximates gradient of dt6 image - each voxel has an associated 3x6 grad
imgDim = size(dt6Img);
dt6Grad = zeros(imgDim(1),imgDim(2),imgDim(3),6,3);
for i = 1:6 %Approximates gradients one tensor value at a time
    [gradX,gradY,gradZ] = gradient(dt6Img(:,:,:,i),1);  
    dt6Grad(:,:,:,i,1) = -gradY; 
    dt6Grad(:,:,:,i,2) = -gradX; 
    dt6Grad(:,:,:,i,3) = -gradZ;
end
return

%==========================================================================

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