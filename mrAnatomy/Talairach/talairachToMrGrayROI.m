function talairachToMrGrayROI(talCoords, talXform, outFile, roiColor)
%
% talairachToMrGrayROI(talCoords, talXform, outFile, roiColor)
% 
% Write a mrGrayROI file given a set of Talairach coordinates. 
%
% talCoords should be an array of talairach cordiantes in 'n X 3'
% row-vector form (e.g., [0,0,0; 0,0,-102]).
%
% If outFile is empty or omitted, you will be prompted for it.
%
% talXform should be the Talairach transform structure (eg., as 
% created by computeTalairach). If omitted or empty, you will be prompted
% for the file containing the xform.
%
% roiColor should be one of ('r','g','b','y','m','c','k','w') or an RGB
% triplet ([0,0,0] through [255,255,255]). It defaults to 'r' (red).
% 
% HISTORY:
% 2003.01.23 RFD wrote it.
% 

if(nargin<1)
    help(mfilename);
    return;
end
if(~exist('talXform','var') | isempty(talXform))
    [f,p] = uigetfile({'*.mat'}, 'Select the Talairach transform file...');
    if(isnumeric(f))
        disp('No Talairach file selected- aborting...');
        return;
    end
    talXform = load(fullfile(p,f));
end
if(~exist('outFile','var') | isempty(outFile))
    [f,p,filterIndex] = uiputfile({'*.*'}, 'Save the mrGray ROI file as...');
    if(isnumeric(f))
        disp('No output file selected- aborting...');
        return;
    end
    outFile = fullfile(p,f);
end
if(~exist('roiColor','var') | isempty(roiColor))
    roiColor = 'r';
end
if(ischar(roiColor))
    switch roiColor
        case 'r'
            roiColor = [255 0 0];
        case 'g'
            roiColor = [0 255 0];
        case 'b'
            roiColor = [0 0 255];  
        case 'y'
            roiColor = [255 255 0];
        case 'm'
            roiColor = [255 0 255];
        case 'c'
            roiColor = [0 255 255];
        case 'k'
            roiColor = [0 0 0];
        case 'w'
            roiColor = [255 255 255];
        otherwise
            warning('Unknown roiColor code- using white.');
            roiColor = [255 255 255];
    end
end

volCoords = round(talairachToVol(talCoords, talXform.vol2Tal));

roiCoords = mrLoadRet2mrGray(volCoords');
% Assign a color to each ROI
ROIandColor = [roiCoords', ones(size(roiCoords,2),1)];

fid = fopen(outFile,'w');

% Indicate that there is just one entry in the color table.
fprintf(fid,'1\n');

% Write out the color lookup table.  
fprintf(fid,'%.0f %.0f %.0f\n',roiColor);

% Write out the voxels from the ROIs as Nx4
fprintf(fid,'%.0f %.0f %.0f %.0f\n',ROIandColor');
fclose(fid);

return;

