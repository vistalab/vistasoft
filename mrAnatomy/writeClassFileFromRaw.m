function count = writeClassFileFromRaw(dataBlock,fileName,classInfo,voiInfo);
% function class = writeClassFile(dataBlock,fileName,classInfo,voiInfo);
% AUTHOR:  Wade
% DATE: 03.08.02
% PURPOSE: 
%   Write out a raw data block (x*y*z) to a mrGray - readable class file.
%  This will be useful for using different segmentation systems (e.g. SureFit, Freesurfer, BV) with mrGray
%  voiInfo is a structure containing information about the location of the classification in a larger block.
%  classInfo is a vector that lists the classification values in the dataBlock: 
% In mrGray, 0 is unknown, 16 is white matter, 32 is gray, and 48 is CSF
% So classInfo=[0,0; 240,0; 235,16] means that all voxels that have a val of 0 or 240 
% are set unknown and all xocxels with a val of 235 are set to white matter.
    
% Check for input variables

if (nargin < 2)
   % Get the filename from a GUI
   [fileName,filePath]=uiputfile('*.*','Save class file as...');
   fileName = fullfile(pathName, fileName);
end

% 
% Swap rows and columns
[y,x,z]=size(dataBlock);
tmp = zeros(x,y,z);
for ii=1:z
   tmp(:,:,ii) = dataBlock(:,:,ii)';
end
dataBlock = tmp;
[y,x,z]=size(dataBlock);

if (~exist('voiInfo','var') | isempty(voiInfo))
    % Assume that the VOI is the entire data block...
    disp('Making up voiInfo from dataBlock dimensions');
    
    voiInfo.xMin=0;
    voiInfo.yMin=0;
    voiInfo.zMin=0;
    voiInfo.xMax=x-1;
    voiInfo.yMax=y-1;
    voiInfo.zMax=z-1;
    
    voiInfo.xSize=x;
    voiInfo.ySize=y;
    voiInfo.zSize=z;
    
end

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
%[a]=[0 1 2 3];

if (exist('classInfo','var'))
    %     if (length(classInfo(:))<length(a(:)))
    %         error('More unique voxel intensities than classification levels');
    %     end
    dataBlock=uint8(dataBlock);
    disp('Setting class values in dataBlock');
    disp(classInfo);
    for(ii=1:size(classInfo,1))
        dataBlock(dataBlock==classInfo(ii,1)) = classInfo(ii,2);
    end
else
    disp('No classification values passed in : assuming a binary class volume');
    a = unique(dataBlock(:));
    % If we didn't get a set of classification values, assume we've just got white and unknown
%     if (length(a)<3)
        % set the minimum value to 0
        minVal=min(a);
%         dataBlock(dataBlock==minVal)=0;
%     end
    maxVal=max(a);
    dataBlock(dataBlock==minVal)=0;
    dataBlock(dataBlock==maxVal)=16;     
    disp('Unique vals = ');
    disp(a);
end
% Need to write out a class header...
% Open the file
% 
fp = fopen(fileName,'w');

% Read header information
% 
count=fprintf(fp, 'version=%d\n',2);
count=count+fprintf(fp, 'minor=%d\n',1);

count=count+fprintf(fp, 'voi_xmin=%d\n',voiInfo.xMin);
count=count+fprintf(fp, 'voi_xmax=%d\n',voiInfo.xMax);
count=count+fprintf(fp, 'voi_ymin=%d\n',voiInfo.yMin);
count=count+fprintf(fp, 'voi_ymax=%d\n',voiInfo.yMax);
count=count+fprintf(fp, 'voi_zmin=%d\n',voiInfo.zMin);
count=count+fprintf(fp, 'voi_zmax=%d\n',voiInfo.zMax);

%  This converts VOI from C to Matlab values.
% 
count=count+fprintf(fp, 'xsize=%d\n',voiInfo.xSize);
count=count+fprintf(fp, 'ysize=%d\n',voiInfo.ySize);
count=count+fprintf(fp, 'zsize=%d\n',voiInfo.zSize);


% Also write out the following:
% % csf_mean = fscanf(fp, 'csf_mean=%g\n',1);
%   gray_mean = fscanf(fp, 'gray_mean=%g\n',1);
%   white_mean = fscanf(fp, 'white_mean=%g\n',1);
%   stdev = fscanf(fp, 'stdev=%g\n',1);
%   confidence = fscanf(fp, 'confidence=%g\n',1);
%   smoothness = fscanf(fp, 'smoothness=%d\n',1);
% 
disp('Writing means and stats...');

count=count+fprintf(fp,'csf_mean=%d\n',0);
count=count+fprintf(fp,'gray_mean=%d\n',1);
count=count+fprintf(fp,'white_mean=%d\n',classInfo(2));
count=count+fprintf(fp,'stdev=0\n');
count=count+fprintf(fp,'confidence=0.00\n');
count=count+fprintf(fp,'smoothness=0\n');


% Now write out the raw data un uchar format
dataCount=fwrite(fp,dataBlock,'uchar');
% Do a check to see if we've written out the right number of bytes
fclose(fp);


if (dataCount~=prod([x y z]))
disp(count)
disp(prod([x y z]));

    error('Could not write the data block - check disk space and permissions');
end

fprintf('\nWritten file %s',fileName);
fprintf('\nvoiInfo structure:\n');
disp(voiInfo);

fprintf('\n%d header bytes and %d data bytes\n',count,dataCount);


return;

