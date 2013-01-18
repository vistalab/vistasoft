function [b1fit, b, b1map] = relaxB1map (data, alphaIndex, brainMask)
%
% function relaxB1map (data, alphaIndex)
%
% This function computes a B1 map using the data passed along as 
% a struct, along with a vector of subscripts
% that index the B1 mapping scans and a brainMask

b1FlipAngle = [data(alphaIndex).flipAngle];
largerFlipInd = find(alphaIndex & [data(:).flipAngle] == max(b1FlipAngle));
smallerFlipInd = find(alphaIndex & [data(:).flipAngle] == min(b1FlipAngle));
    
% B1 mapping scans need to be cast to double for acos to work
% I want alpha1 to always be the larger flip angle
alpha1 = cast(data(largerFlipInd).imData, 'double');
alpha2 = cast(data(smallerFlipInd).imData, 'double');
    
% avoid degenrate voxels
minVal1 = mean(alpha1(brainMask))*.2;
minVal2 = mean(alpha2(brainMask))*.2;
nz = alpha2>minVal2 & alpha1>minVal1 & brainMask;
b1map = repmat(NaN,size(alpha1));
b1map(nz) = 180/pi*abs(acos(.5*alpha1(nz)./alpha2(nz)))/min(b1FlipAngle);
[b1fit, b] = relaxFitBiasField(b1map, [2 2 2]);
    
%     % Clip to reasonable values
%     b1map(b1map>1.5) = 1.5;
%     b1map(b1map<0.5) = 0.5;
%     % Apply a median filter
%     b1map = dtiOrdFilter3d(b1map,14);
%     % Now some gaussian smoothing
%     b1map = dtiSmooth3(b1map,[13 13 7]);
%     %b1map = dtiSmoothAnisoPM(b1map, 5, 1/44, 0.5, 1, s(alphaIndex(1)).mmPerVox);
%     showMontage(b1map); % This will display the B1 inhomogeneity as a fraction of 1
    
return