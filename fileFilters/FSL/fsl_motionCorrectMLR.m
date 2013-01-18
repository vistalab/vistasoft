function view=fsl_motionCorrectMLR(view,scansToProcess)
% PURPOSE: Does mcflirt (and one day slice time correction) on time series data in MLR
% See also fsl_runMelodicMLRTSeries
% ARW 120604
% 
% Script to do FLIRT on tSERIES data
% held in mlr.
% This routine is designed to be called from mlr (in the project directory)
% and so it requires mrSESSION
% In overview:
% All the FSL routines require a set of 3D analyze-format files or a single
% 4D analyze format file. 
% 1: First stage is to convert all the tSeries into 4d analyze format.
% 2: Then feed those analyze files through flirt to do motion correction.
%   the resulting analyze files are called 'xxx_mcf'
% NOTE: For now all these fsl_xxx routines are designed for use on 
% 'Original' dataTYPE only. 

mrGlobals;

thisDir=pwd;

fslBase='/raid/MRI/toolbox/FSL/fsl';

if (ispref('VISTA','fslBase'))
    disp('Setting fslBase to the one specified in the VISTA matlab preferences:');
    fslBase=getpref('VISTA','fslBase');
    disp(fslBase);
end

fslPath=fullfile(fslBase,'bin'); % This is where FSL lives - should also be able to get this from a Matlab pref
reconPath='/raid/MRI/toolbox/Recon'; % required for the recon program to convert .mag files into Analyze format
dataDir=[thisDir,filesep,'Raw']; % The raw directory containing the e-files and .mag files
if (~exist('view','var')  | (isempty(view)))
    view=getSelectedInplane;
end

if (view.curDataType~=1)
    error('The data type must be Original (dataTYPE == 1)');
end
if (~exist('scansToProcess','var')  | (isempty(scansToProcess)))

disp('Select scans to process');

scansToProcess=selectScans(view,'Scans to process');
end

nSlices=mrSESSION.inplanes.nSlices;
nScansToProcess=length(scansToProcess);



% Now run motion correction

for thisScanIndex=1:nScansToProcess
    % This will align within scans
    thisScan=scansToProcess(thisScanIndex);
    avw_dirName=['Inplane/Original/TSeries/Scan',int2str(thisScan),'/Analyze'];
    fName=[avw_dirName,filesep,'data'];
    % Here we need to check that the analyze files have been generated in 
    % Each INPLANE / tSeries directory
    if (~exist([fName,'.hdr'],'file'))
        disp(fName);
        disp('NIFTI file not found for this scan : Making it...');      
        view=fsl_MLR2Analyze(view,thisScan,'s'); % Make sure that we save data as 'short int' type: 2 bytes.
    end
    
    shellCmd=[fslPath,filesep,'mcflirt -in ',fName,' -stats -report -verbose 3 -mats'];
    disp(shellCmd);
    system(shellCmd);
end

