function volROI2mrGray(outFile, ROI, writeDirectory, overlayColor)
%
%            volROI2mrGray(outFile, ROI, writeDirectory, [overlayColor])
% 
% AUTHOR:   Dougherty
% DATE:     02.17.99
% PURPOSE:  Write ROI in a format that mrGray can read.
% 
% 
% CHANGES:  
%     BW/HAB 08.09.99 Put in mrLoadRet2mrGray.
% 

if(~exist('overlayColor','var') | isempty(overlayColor))
    switch ROI.color
        case 'r'
            overlayColor = [255 0 0];
        case 'g'
            overlayColor = [0 255 0];
        case 'b'
            overlayColor = [0 0 255];  
        case 'y'
            overlayColor = [255 255 0];
        case 'm'
            overlayColor = [255 0 255];
        case 'c'
            overlayColor = [0 255 255];
        case 'k'
            overlayColor = [0 0 0];
        otherwise
            overlayColor = [255 255 255];
    end
end

% swap columns one and two, cause this is how mrGray likes it

% replaced by stuff below. 
% roiCoords = [ROI.coords(2,:); ROI.coords(1,:); ROI.coords(3,:)]';
% 
roiCoords = mrLoadRet2mrGray(ROI.coords)';
ROIandColor = [roiCoords, ones(size(ROI.coords,2),1)];

curDir = pwd;
if ~isempty(writeDirectory)
  chdir(writeDirectory);
end

fid = fopen(outFile,'w');
fprintf(fid,'1\n');

% Assign a color to each ROI and write out the color lookup
% table.  Ordinarily there can be several colors.  But again, we
% are just writing out one.
%
fprintf(fid,'%.0f %.0f %.0f\n',overlayColor(1),overlayColor(2),overlayColor(3));

%Write out the voxels from the ROIs as Nx4
%
fprintf(fid,'%.0f %.0f %.0f %.0f\n',ROIandColor(:,1:4)');

% Close the output file
%
fclose(fid);

% Go back where you started
% 
chdir(curDir);

return;

