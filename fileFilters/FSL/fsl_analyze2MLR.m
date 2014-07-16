function vw=fsl_analyze2MLR(vw,scansToProcess,processedDataType,newDataTypeName)
% vw=fsl_analyze2MLR(vw,scansToProcess,processedDataType,newDataTypeName)
% PURPOSE: Generates MLR tSeries from analyze data
% The analyze files are typically the result of running fsl to do either motion correction or ICA noise removal or both.
% They are placed into a new dataType in the MLR session.
% If processedDataType is a number, it is interpreted as follows:
% 1: Look for an original data set ('data.hdr') in the 'Analyze' directory
% 2: Look for a motion corrected data set ('data_mcf.hdr') 
% 3: Look for an ICA filtered, motion corrected file in
% 'Analyze/data_mcf_remixed/melodic_ICAfiltered.hdr'
% 4: Look for an ICA filtered file in 
% 'Analyze/data_remixed/melodic_ICAfiltered.hdr'
% If it is a string, then just interpret it as the path to the
% data file relative to the 'Analyze' directory.
% NOTE: all these fsl_xxx routines expect you to work on the Original
% datatype. 
% Example call: vw=fsl_analyze2MLR(INPLANE{1},1:12,4,'filteredMCC_Orig')
% AUTHOR: ARW 12/16/04 
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

if (vw.curDataType~=1) % In general, there's no reason to enforce this but it makes everythign a little simpler.
                         % In version 2 of these routines we'll allow you to work on any dataTYPE. 
    error('The data type must be Original (dataTYPE == 1)');
end

if (~exist('vw','var')  || (isempty(vw)))
    vw=getSelectedInplane;
end

if (~exist('scansToProcess','var')  || (isempty(scansToProcess)))
    disp('Select scans to process');
    scansToProcess=selectScans(vw,'Scans to process');
end

nSlices=mrSESSION.inplanes.nSlices;
nScansToProcess=length(scansToProcess);

% Take a look at processedDataType. If it's a string, it's interpreted as
% the file name relative to the 'Analyze' directory for all scans.
% Otherwise it's a number representing one of a few analysis types.
if (ischar(processedDataType))
    relativePath=processedDataType;
else
    switch processedDataType
        case 1
            relativePath='data';
            disp('Unprocessed data type');
            
        case 2
            relativePath='data_mcf';   
            disp('MCF data type');
        case 3
            relativePath='data_remixed/melodic_ICAfiltered';
            disp('ICA/ non-MCF data type');
        case 4
            relativePath='data_mcf_remixed/melodic_ICAfiltered';  
            disp('ICA & MCF data type');
        otherwise
            error('Invalid setting for variable processedDataType');
    end
end


% Generate the new dataTYPE
if ~existDataType(newDataTypeName), addDataType(newDataTypeName); end

% Switch to it.
vw = selectDataType(vw,existDataType(newDataTypeName));

% Get the tSeries directory for that dType
tSerDir=tSeriesDir(vw);
disp(tSerDir)

 
% We have to populate the dataTYPES structure
% for the new dataTYPE with reasonable numbers

curDt = viewGet(vw,'Cur Dt');

for thisScan=1:nScansToProcess
    dataTYPES(curDt) = dtSet(dataTYPES(curDt),'Scan Params',dtGet(dataTYPES(1),'Scan Params'),thisScan);
    dataTYPES(curDt) = dtSet(dataTYPES(curDt),'Annotation',['From original scan ',int2str(scansToProcess(thisScan))],thisScan);
    dataTYPES(curDt) = dtSet(dataTYPES(curDt),'Block Params',dtGet(dataTYPES(1),'B Params',1), thisScan);
    dataTYPES(curDt) = dtSet(dataTYPES(curDt),'Event Params',dtGet(dataTYPES(1),'E Params',1), thisScan);
end

saveSession;

for thisScanIndex=1:nScansToProcess
    
    thisScan=scansToProcess(thisScanIndex);
    avw_dirName=['Inplane',filesep,'Original',filesep,'TSeries',filesep,'Scan',int2str(thisScan),filesep,'Analyze'];
    % Three options here: 
    
    fName=[avw_dirName,filesep,relativePath];
    disp(fName);
    [img, dims,scales,bpp,endian]=read_avw(fName);
    
    % Make the tSeries directory if it doesn't already exist
    % Make the Scan subdirectory for the new tSeries (if it doesn't exist)
    scandir = fullfile(tSerDir,['Scan',num2str(thisScan)]);
    if ~exist(scandir,'dir')
        fprintf('\nMaking scan directory %s\n',scandir);
        mkdir(tSerDir,['Scan',num2str(thisScan)]);
    end
    thisTSerFull = [];
    dimNum = 0;
    % Here, add option to crop leading frames
    for thisSlice=1:nSlices
        thisTSer=img(:,:,thisSlice,:);
        thisTSer=reshape(thisTSer,(dims(1)*dims(2)),dims(4));
        thisTSer=thisTSer';
        dimNum = numel(size(thisTSer));
        % Cast to 16bit  signed ints to save space
        thisTSer=thisTSer./max(abs(thisTSer(:)));
        thisTSer=int16(thisTSer*32767);
        
        thisTSerFull = cat(dimNum + 1, thisTSerFull, thisTSer);
        disp(thisSlice);
    end
    
    if dimNum == 3
        thisTSerFull = reshape(thisTSerFull,[1,2,4,3]);
    end %if
    
    savetSeries(thisTSerFull,vw,thisScan);
    
end
