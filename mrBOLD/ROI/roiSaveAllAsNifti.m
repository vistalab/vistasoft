function [roiFile, labelFile] = roiSaveAllAsNifti(vw, fname)
% Export all current ROIs in a mrVista view as a nifti segmentation file,
% with each ROI corresponding to a different layer (integer) in the nifti
% file.
%
% [roiFile, labelFile] = roiSaveAllAsNifti(vw, fname, roiColor)
%
% Oct 2008: JW
%
% See roiSaveAsNifti.m

% global variables
mrGlobals;

% get the view struct
if notDefined('vw'), vw = getCurView; end

% check that it's a gray or volume view
viewType = viewGet(vw, 'viewtype');
switch lower(viewType)
    case {'gray', 'volume'}
        nROIs = numel(vw.ROIs);
    otherwise
        error('[%s]: Must be in gray view', mfilename);
end

% check the name of the file to save
if notDefined('fname'),
    fname = [fileparts(vANATOMYPATH) filesep  'ROIs-' datestr(now,1) '.nii.gz'];
end

% make a 3D image with all points set to zero except ROI = roiColor
roiData = zeros(size(vw.anat));

% loop through all ROIs in view struct
for rois = 1:nROIs
    vw = viewSet(vw, 'selected ROI', rois);

    %get ROI coords
    coords = getCurROIcoords(vw);
    nVoxels = size(coords, 2);

    % assign all voxels within the ROI a unique value (the roinum). this
    % will be the label number if the nifti file is imported to itkGray.
    thelabel = rois;

    for voxel = 1:nVoxels
        roiData(coords(1,voxel), coords(2,voxel),coords(3,voxel)) = thelabel;
    end

end


% save the file
roiFile = niftiSaveVistaVolume(vw, roiData, fname);

% create a label file for itkGray
useV1V2V3V4colors = true;
labelFile = saveLabels(vw, useV1V2V3V4colors);

message = sprintf...
    ('ROI file saved as %s.\n\nLabel file save as %s.', roiFile, labelFile);
disp(message);

%------------------------------------------------------------------------

end


%------------------------------------------------------------------------
function fname = saveLabels(vw, useV1V2V3V4colors)
% create and save an itkGray-compatible label file

mrGlobals
if notDefined('useV1V2V3V4colors'), useV1V2V3V4colors = true; end

% create a blank file
fname = [fileparts(vANATOMYPATH) filesep  'ROIs-' datestr(now,1), '.lbl'];
fid = fopen(fname, 'w');

% print some typical headers
h{1} = '################################################';
h{2} = '# ITK-SnAP Label Description File';
h{3} = '# File format:';
h{4} = '# IDX   -R-  -G-  -B-  -A--  VIS MSH  LABEL';
h{5} = '# Fields:';
h{6} = '#    IDX:   Zero-based index ';
h{7} = '#    -R-:   Red color component (0..255)';
h{8} = '#    -G-:   Green color component (0..255)';
h{9} = '#    -B-:   Blue croiSaveAllForItkGrayolor component (0..255)';
h{10} = '#    -A-:   Label transparency (0.00 .. 1.00)';
h{11} = '#    VIS:   Label visibility (0 or 1)';
h{12} = '#    IDX:   Label mesh visibility (0 or 1)';
h{13} = '#  LABEL:   Label description ';
h{14} = '################################################';
for ii = 1:14
    fwrite(fid, sprintf('%s\n',h{ii}));
end


% count the ROIs
nROIs = length(viewGet(vw, 'ROIs'));

% make some colors for the different labels
theColors   = hsv(nROIs);


% type out a line of text into the label file for each ROI
for roi = 1:nROIs

    c = theColors(roi, :);
    rname = vw.ROIs(roi).name;
    % -----------------------------------------------------------
    if useV1V2V3V4colors
        % force a color scheme on the labels for v1/v2/v3/v4
        if strfind(lower(rname), 'v1')
            c = [255 0 0 ];
        elseif strfind(lower(rname), 'v2')
            c = [255 255 0 ];
        elseif strfind(lower(rname), 'v3a')
            c = [255 255 255];
        elseif strfind(lower(rname), 'v3b')
            c = [0 255 255];
        elseif strfind(lower(rname), 'v3')
            c = [0 255 0 ];
        elseif strfind(lower(rname), 'v4')
            c = [0 0 255 ];
        elseif strfind(lower(rname), 'vo1')
            c = [255 255 255 ];
        elseif strfind(lower(rname), 'vo2')
            c = [0 255 255 ];
        elseif strfind(lower(rname), 'lo1')
            c = [255 0 255 ];
        elseif strfind(lower(rname), 'lo2')
            c = [127 127 255 ];
        elseif strfind(lower(rname), 'to1')
            c = [0 255 0];
        elseif strfind(lower(rname), 'to2')
            c = [255 0 0 ];
        end     
    end
    %------------------------------------------------------------

    a = sprintf('%d\t%d\t%d\t%d\t1\t1\t1\t"%s"\n', ...
        roi, c(1), c(2), c(3), rname);
    fwrite(fid, a);
end
%fclose('all');

end
