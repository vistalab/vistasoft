function view=fsl_MLR2Analyze(view,scansToProcess,avw_data_type)
% view=fsl_MLR2Analyze(view,scansToProcess,avw_data_type)
% PURPOSE: Generates analyze files from MLR data. 
% Specifically, it makes 4D analyze files from the tSeries 
% 010806: Added optional avw_data_type flag (see save_avw)
% See also fsl_MLR_anat2Analyze, fsl_preprocessMLRTSeries, fsl_motionCorrectMLR
% ARW 120604
% $Author: wade $
% $Date: 2006/03/08 01:33:08 $

mrGlobals;


thisDir=pwd;

fslBase='/raid/MRI/toolbox/FSL/fsl';

if (ispref('VISTA','fslBase'))
   disp('Setting fslBase to the one specified in the VISTA matlab preferences:');
   fslBase=getpref('VISTA','fslBase');
   disp(fslBase);
end

fslPath=fullfile(fslBase,'bin'); % This is where FSL lives - should also be able to get this from a Matlab pref

if (~exist('view','var')  | (isempty(view)))
    view=getSelectedInplane;
end


if (~exist('scansToProcess','var')  | (isempty(scansToProcess)))

disp('Select scans to process');

scansToProcess=selectScans(view,'Scans to process');
end


if (ieNotDefined('avw_data_type'))
  % You can ask for any data type compatible with save_avw. We default to
  % 'f'
  avw_data_type='f';
end
    
nSlices=mrSESSION.inplanes.nSlices;
nScansToProcess=length(scansToProcess);

% Generate 4d Analyze files from the tSeries data. 
for thisScanIndex=1:nScansToProcess

    thisScan=scansToProcess(thisScanIndex);
    cropSize=mrSESSION.functionals(thisScan).cropSize;
    nFrames=mrSESSION.functionals(thisScan).nFrames;
    
    dataBlock=zeros(cropSize(1),cropSize(2),nSlices,nFrames); % Pre-allocate a large data array

    for thisSlice=1:nSlices
        thistSeries = loadtSeries(view,thisScan,thisSlice);
        % For historical reasons, tSeries come in as nFrames*(y*x)
        % So a 128*128 pixel by 72 frame data set for a single slice would
        % come out as size=72*16384
        % When we make the big data block, we need it to be
        % x*y*nSlices*nFrames
        ts=reshape(thistSeries',cropSize(1),cropSize(2),nFrames);
        dataBlock(:,:,thisSlice,:)=ts;
        fprintf('.');    
    end
    
    fprintf('\nCreated data block %d\n',thisScan);
    
    % Now save that 4d avw file out somewhere...
    % We're going to create a subdirectory in the Inplane/xxxx/TSeries
    % folder
    
    curDataType=view.curDataType;   
    avw_dirName=['Inplane/',dataTYPES(curDataType).name,'/TSeries/Scan',int2str(thisScan),'/Analyze'];
    if (~isdir(avw_dirName))
        fprintf('\nCreating directory %s\n',avw_dirName);
        mkdir(avw_dirName);
    end
    % And save it out...
    fName=[avw_dirName,filesep,'data'];
    voxSize=mrSESSION.functionals(1).effectiveResolution;
    
    % Here we check the range of the data. If it's small anough to fit in a
    % short int, then we let save_avw >save< it as 's'. Otherwise , we use
    % the 'f' type. The only exception is if the avw_data_type flag is set.
    % Then we use that...
    
    %dType='f'; 
 

    save_avw(dataBlock,fName,avw_data_type,voxSize);
    disp(thisScan);
end % Do the next one

