function fig = displayVAnat3Axis(vAnat, sliceNum, gamma, clipRange, fig)
%  
%   displayVAnat3Axis(vAnat, sliceNum, [gamma], [clipRange], [fig])
%
% PURPOSE: Displays the specified slices in 3 separate figures.
%   vAnat must be in standard vAnatomy format- a 3-d array of image intensities.
%   sliceNum specifies the [x, y, z] slices. 
%   fig is optional- 3 new figures will be created (and returned).
%   They will be in order of: [coronal, axial, sagittal] (assuming that
%   the vAnatomy data are properly oriented as a 3-d array (X,Y,Z) where
%   X = coronal slice num, Y = axial slice num, and Z = sagittal slice num)
%
% HISTORY:
%   2001.09.10 RFD (bob@white.stanford.edu): created it
%

if(~exist('gamma','var') | isempty(gamma))
    gamma = 1;
end 
if(~exist('clipRange','var') | isempty(clipRange))
   clipRange = [min(vAnat(:)), max(vAnat(:))];
end

if(~exist('fig','var') | isempty(fig) | length(fig)<3)
    fig(1) = figure;
    fig(2) = figure;
    fig(3) = figure;
end

% any sliceNums that are zero will get skipped
for(ii=find(sliceNum))
    % We permute the first two images. The assumption here is that
    % these are the coronal and axial slices, which appear sideways if
    % we don't do this.
    switch ii
        case 1, slice = permute(squeeze(vAnat(:,:,sliceNum(ii))),[2,1]);
        case 2, slice = permute(squeeze(vAnat(:,sliceNum(ii),:)), [2,1]);
        case 3, slice = squeeze(vAnat(sliceNum(ii),:,:));
    end
    if(gamma~=1)
        slice = round(slice.^gamma);
    end
    slice(slice<clipRange(1)) = clipRange(1);
    slice(slice>clipRange(2)) = clipRange(2);
    slice = (slice-clipRange(1))./abs(diff(clipRange))*255;
    figure(fig(ii));
    image(slice);
    colormap(gray(256)); axis image; axis off;
end

return;