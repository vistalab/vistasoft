function count = writeClassFile(dataBlock,fileName,voiInfo);
% function class = writeClassFile(filename,dataBlock,commentString);
% AUTHOR:  Wade
% DATE: 03.08.02
% PURPOSE: 
%   Write out a raw data block (x*y*z) to a mrGray - readable class file.
%  This will be useful for using different segmentation systems (e.g. SureFit, Freesurfer, BV) with mrGray
% 

% Check for input variables

if (nargin < 2)
   % Get the filename from a GUI
   [fileName,filePath]=uiputfile('*.*','Save class file as...');
   fileName=[pathName,filesep,fileName];
end

[y,x,z]=size(dataBlock);

if (~exist('voiInfo','var'))
    % Assume that the VOI is the entire data block...
    disp('Making up voiInfo from dataBlock dimensions');
    
    voiInfo.xMin=0;
    voiInfo.yMin=0;
    voiInfo.zMin=0;
    voiInfo.xMax=x-1;
    voiInfo=yMaxy-1;
    voiInfo.zMax=z-1;
    
    voiInfo.xSize=x;
    voiInfo.ySize=y;
    voiInfo.zSize=z;
    
end

% Try to be a little smart here...
% Most segmentation packages just give you the white matter (not gray, csf as well).
% Of course, this can be a problem in its own right (no csf=> ambiguous grey matter growth across sulci)
% But one thing it means here is that if we find only two unique values in the dataset, we should set one to
% 'unknown' and one to 'white'

% Save the filename used to read the data
% % Set up values for different data types
% 
%class.type.unknown = (0*16);
%class.type.white   = (1*16);
%class.type.gray    = (2*16);
%class.type.csf     = (3*16);

% Find the unique vals in dataBlock
[a]=unique(dataBlock(:));
if (length(a)<3)
    % set the minimum value to 0
    minVal=min(a);
    dataBlock(dataBlock==minVal)=0;
end

        maxVal=max(a);
        dataBlock(dataBlock==maxVal)=16;

        
        disp('Unique vals=');
disp(a);

% Need to write out a class header...

% Open the file
% 
fp = fopen(fileName,'w');

% Read header information
% 
count=fprintf(fp, 'version=%d\n',2);
count=fprintf(fp, 'minor=%d\n',1);

count=fprintf(fp, 'voi_xmin=%d\n',voiInfo.xMin);
count=fprintf(fp, 'voi_xmax=%d\n',voiInfo.xMax);
count=fprintf(fp, 'voi_ymin=%d\n',voiInfo.yMin);
count=fprintf(fp, 'voi_ymax=%d\n',voiInfo.yMax);
count=fprintf(fp, 'voi_zmin=%d\n',voiInfo.zMin);
count=fprintf(fp, 'voi_zmax=%d\n',voiInfo.zMax);

%  This converts VOI from C to Matlab values.
% 
count=fprintf(fp, 'xsize=%d\n',voiInfo.xSize);
count=fprintf(fp, 'ysize=%d\n',voiInfo.ySize);
count=fprintf(fp, 'zsize=%d\n',voiInfo.zSize);


% Also write out the following:
% % csf_mean = fscanf(fp, 'csf_mean=%g\n',1);
%   gray_mean = fscanf(fp, 'gray_mean=%g\n',1);
%   white_mean = fscanf(fp, 'white_mean=%g\n',1);
%   stdev = fscanf(fp, 'stdev=%g\n',1);
%   confidence = fscanf(fp, 'confidence=%g\n',1);
%   smoothness = fscanf(fp, 'smoothness=%d\n',1);
% These are all more or less meaningless for other sorts of segmentation so we leave them blank
disp('Writing means and stats...');

count=fprintf(fp,'csf_mean=0\n');
count=fprintf(fp,'gray_mean=0\n');
count=fprintf(fp,'white_mean=0\n');
count=fprintf(fp,'stdev=0\n');
count=fprintf(fp,'confidence=0.00\n');
count=fprintf(fp,'smoothness=0\n');



% Now write out the raw data un uchar format
count=fwrite(fp,dataBlock,'uchar');
% Do a check to see if we've written out the right number of bytes

if (count~=prod([x y z]))
disp(count)
disp(prod([x y z]));

    error('Could not write the data block - check disk space and permissions');
end

fprintf('\nWritten file %s',fileName);
fprintf('\nvoiInfo structure:\n');
disp(voiInfo);

return;

