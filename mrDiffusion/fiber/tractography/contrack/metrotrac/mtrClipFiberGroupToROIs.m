function fgOut=mtrClipFiberGroupToROIs(fgInFile,niT1File,roi1File,roi2File,wmNiftiFile,fgOutFile)
%
% mtrClipFiberGroupToROIs(fgInFile,niT1File,roi1File,roi2File,wmNiftiFile,fgOutFile)
%
% Clips input fiber groups to the two ROIs provided. Reorders fibers so
% that the first point intersects with ROI1 and last point intersects with
% ROI2.  Only the two endpoints will connect to the ROIs.  If there are
% multiple path segments that loop between the ROIs the segment closest to
% the start of the path will be chosen.  
%
% fgInFile - Filename for fiber group to be clipped.
% niT1File - Filename for nifti T1 file.
% roi*File - Filename for ROIs
% wmNiftiFile - Provide a WM mask file to throw away paths that intersect
%   voxels with value 0.
% fgOutFile - Filename for clipped fiber group output.
% 
%
% HISTORY:
% 2007.10.27 Written by Anthony Sherbondy
% 2008.09.14 DY: modified to provide an output argument so that clipped FGs
% can more easily be merged, and fill in fgOut.name field

% Load fiber group
fg = dtiReadFibers(fgInFile);

% Load T1 image
niT1 = niftiRead(niT1File);
% XXX WHY DO I NEED A DIFFERENT ONE FROM ROI
% Matrix for converting fiber group coords into dti image space
%xformFromAcPc = diag([(dt6.mmPerVox(:)') 1])*inv(niT1.qto_xyz);
xformFromAcPc = inv(niT1.qto_xyz);
xformToAcPc = niT1.qto_xyz;

% Get dimensions for mask image
img_mask = zeros(size(niT1.data));

if ieNotDefined('wmNiftiFile')
    img_wm = img_mask+1;
else
    ni = niftiRead(wmNiftiFile);
    img_wm = ni.data;
    clear ni;
end

% Create mask images from ROI files
% ROI1
roi = dtiReadRoi(roi1File);
[center1,length1] = mtrConvertRoiToBox(roi.coords,xformToAcPc);
center1 = center1 + 1;
roi.coords = mrAnatXformCoords(xformFromAcPc, roi.coords);
for ii = 1:size(roi.coords,1)
    img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 1;
end

% ROI2
roi = dtiReadRoi(roi2File);
[center2,length2] = mtrConvertRoiToBox(roi.coords,xformToAcPc);
center2 = center2 + 1;
roi.coords = mrAnatXformCoords(xformFromAcPc, roi.coords);
for ii = 1:size(roi.coords,1)
    img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 2;
end

% Assume ROIs and FG were in the same space, clip FG to ROIs
fgOut = dtiNewFiberGroup;
fOutCount = 1;
for ff = 1:length(fg.fibers)
    fiber = fg.fibers{ff};
    % Convert fiber coordinates into image space
    pos = fg.fibers{ff};
    pos = mrAnatXformCoords(xformFromAcPc, pos')';
    
    % Find values of ROI image along fiber
    index1 = 0;
    index2 = 0;
    pp = 1;
    % This search will stop once we have found an intersection with both
    % ROIs
    while( pp <= size(pos,2) && (index1 == 0 || index2 == 0) )
        iPos = round(pos(:,pp));
        roiImgVal = img_mask(iPos(1),iPos(2),iPos(3));
        if( roiImgVal == 1 && (all(abs((pos(:,pp)-center1(:))) <= length1(:)/2)) )
            index1 = pp;
        elseif( roiImgVal == 2 && (all(abs((pos(:,pp)-center2(:))) <= length2(:)/2)) )
            index2 = pp;        
        end
        pp = pp+1;
    end    
    
    % Store paths that connect both ROIs
    if (index1 > 0 && index2 > 0)
        % Order points to be consistent with ROI ordering
        if (index1 > index2)
            idvec = index1:-1:index2;
        else
            idvec = index1:index2;
        end
        
        bInWM = 1;
        for pp = idvec(2:end-1)
            iPos = round(pos(:,pp));
            if( img_wm(iPos(1),iPos(2),iPos(3)) == 0 )
                bInWM = 0;
                break;
            end
        end

        % Only store valid length paths
        if( bInWM && length(idvec) > 1 )
            fgOut.fibers{fOutCount} = fiber(:,idvec);
            fOutCount = fOutCount+1;
        end
    end
end

% Save output
if isempty(fgOut.fibers)
    disp('No fibers survived the clipping');
else
    [tmp,fgOut.name]=fileparts(fgOutFile);
    dtiWriteFiberGroup(fgOut, fgOutFile);
end
