function snc = vol2talairachVolume(vw,skipTalFlag)
% Function to give the mean Talairach and MNI coordinates of an ROI.  If no
% output argument is given, a message box will pop up.  Otherwise, the
% coordinates (a vector of 3 numbers) will be output in snc.
%
%    snc = vol2talairachVolume(vw,[skipTalFlag = 0])
%
% skipTalFlag tells the function to ignore the Talairach space.  This is
% useful for scripting across subjects where a Talairach normalization has
% not been created and you just want the spatialNorm (MNI).
%
% Note, the coordinate that you are given is for the current ROI and is
% based on the mean MNI coordinate (after transforming all coordinates to
% MNI).  If you want the peak activation within an ROI, then find that
% point, make a point ROI there, and then call this function for that ROI.
%

global mrSESSION;

if notDefined('skipTalFlag'), skipTalFlag = 0; end

[talairach, spatialNorm] = loadTalairachXform(mrSESSION.subject,[],skipTalFlag);

roiNum = viewGet(vw, 'curROI');
coords = vw.ROIs(roiNum).coords';
name = vw.ROIs(roiNum).name;

if(~isempty(talairach))
    talairach = volToTalairach(coords,talairach.vol2Tal);
    t = round(mean(talairach,1));
    msg = sprintf('ROI name:\t%s\nTalairach:\t%d, %d, %d',name,t(1),t(2),t(3));
else
    msg = [];
end

if(~isempty(spatialNorm))
    if(isfield(spatialNorm,'invLUT'))
        % We need to flip the coords from vAnat space to nifti space
        anatSz = viewGet(vw, 'anat size');
        c = [coords(:,3) anatSz(2)-coords(:,2) anatSz(3)-coords(:,1)];
        sz = size(squeeze(spatialNorm.invLUT.coordLUT(:,:,:,1)));
        inds = sub2ind(sz, c(:,1), c(:,2), c(:,3));
        ssCoords = [spatialNorm.invLUT.coordLUT(inds) spatialNorm.invLUT.coordLUT(inds+prod(sz)) spatialNorm.invLUT.coordLUT(inds+prod(sz)*2)];
        snc = round(mean(ssCoords,1));  % gets mean of all ROI coordinates
    elseif(isfield(spatialNorm,'voxToTemplateLUT'))
        % Support old-style xform:
        sz = size(squeeze(spatialNorm.voxToTemplateLUT(1,:,:,:)));
        inds = sub2ind(sz, coords(:,1), coords(:,2), coords(:,3));
        snc = round(mean(spatialNorm.voxToTemplateLUT(:,inds)',1));
    end
    [junk,tName] = fileparts(spatialNorm.sn.VG.fname); 
    
    
    msg = [msg sprintf('\nSpatial Norm (%s):\t%d, %d, %d\n', tName, snc)];
    msg = [msg sprintf('MNI2Tal on SN:\t%d, %d, %d', round(mni2tal(snc)))];
    %msg = [msg tName];
end

if nargout<1  % only do message box if no output is called for
    msgbox(msg, 'Talairach');
end
fprintf('\n%s\n',msg);

return;
