function class=fixTopology(classFile,datFile,outFile)
%
% class=fixTopology(classFile,datFile,outFile)
%
% Function: Given a mrGray .Class file and the corresponding unsegmented
% data from a .dat file, fixes the topology and writes the result to a new
% .Class file.  
%
%
% Requires:  
% removeBridgesMex (in Matlab path)
%
% HISTORY:
%   110202 ISS wrote it.
%   2002.11.13 RFD (bob@white.stanford.edu) cleaned up and updated to use
%   the new bridgeRemovalMex file.
%
%

warndlg('fixTopology has been replaced by mrgRemoveBridges.  Calling that program for you.')
mrgRemoveBridges(classFile,datFile,outFile);
return;

if ~exist('classFile','var')
    [f,p]=uigetfile('*.class;*.Class', 'Select a class file...');
    if(isnumeric(f) & f==0) return; end
    classFile = fullfile(p,f);
    disp(['Class file: ',classFile]);
end
if ~exist('datFile','var')
    [f,p]=uigetfile('*.dat;*.DAT', 'Select corresponding vAnatomy...');
    if(isnumeric(f) & f==0) return; end
    datFile = fullfile(p,f);
    disp(['Anatomy file: ',datFile]);
end
if(~exist('outFile','var') | isempty(outFile))
    [f,p]=uiputfile('*.class;*.Class', 'When finished, save Class file as...');
    if(isnumeric(f) & f==0) return; end
    outFile = fullfile(p,f);
    disp(['Output Class file: ',outFile]);
end


%-----------------------Read in presegmented data----------------------------
% Data is coming in permuted!
preSegClass = readClassFile(classFile,0,0);
preSegWhite = preSegClass.data;
preSegWhite(preSegClass.data~=16)=0;
% The handle removal function sets all non-zero values to white matter, so
% we can leave the 16's in there. We just need to set all non-white matter
% to zero.

%-----------------------Read in unsegmented data-----------------------------

[imageData,mmPerVox,img_dim]=readVolAnat(datFile);
% [ysize,xsize,zsize]=size(imageData);
% imageData=reshape(imageData,[ysize,xsize,zsize]);

% Permuting to match preseg data
imageData=permute(imageData,[2 1 3]);
scale = 225/256;
imageData = uint8(double(imageData)*scale);

%-----------------------Call removeBridgesMex----------------------------

if(isfield(preSegClass.header,'params') & length(preSegClass.header.params)>=6)
    % the 6 classification params are csf mean, gray mean, white mean,
    % noise stdev, confidence and smoothness.
    avgWhite = preSegClass.header.params(3)*scale;
    avgGray = preSegClass.header.params(2)*scale;
    threshold = mean([avgWhite,avgGray]);
else
    warning('Classification parameters not found in class file header- making some guesses...');
    avgWhite = mean(imageData(preSegWhite==16));
    threshold = 0.9*avgWhite;
    avgGray = 0.8*avgWhite;
end
tic;
corrected = removeBridgesMex(preSegWhite,imageData,avgWhite,threshold,avgGray);
toc;
% Voxels marked with 236 should be removed (make a cut).
% Voxels marked with 245 should be added.
% Voxels marked with 226 are 'alternative' voxels (what are they?).
% Voxels marked with 225 are unchanged voxels.
%preSegClass.data(corrected==236)=0;
%preSegClass.data(corrected==245 | corrected==225) = 16;

% For some reason, this works better than the previous, even though they
% *should* be equivalent. I suspect that the bridge removal code doesn't 
% properly mark all the removed voxels. However, we need to put the CSF
% back in.
preSegWhite = uint8(corrected==225 | corrected==245);
preSegWhite(preSegWhite>0) = preSegClass.type.white;
preSegWhite(preSegClass.data==preSegClass.type.csf) = preSegClass.type.csf;
preSegClass.data = preSegWhite;

class = writeClassFile(preSegClass, outFile);

% class = writeClassFileFromRaw(preSegClass.data, outFile, [0,0; 16,16; 32,32; 48,48]);
