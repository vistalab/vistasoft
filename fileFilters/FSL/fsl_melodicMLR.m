function view=fsl_melodicMLR(view,scansToProcess,options)
% view=fsl_melodicMLR(view,scansToProcess,options)
% PURPOSE: Runs FSL Melodic on MLR data.
% You need to have run fsl_MLRtSeriesTo4dAnalyze first
%
% See also fsl_preprocessMLRTSeries
% ARW 120604
% 
% Script to do FLIRT and MELODIC time series denoising on tSERIES data
% held in mlr.
% This routine is designed to be called from mlr (in the project directory)
% and so it requires mrSESSION
% In overview:
% All the FSL routines require a set of 3D analyze-format files or a single
% 4D analyze format file. 
% 1: First stage is to convert all the tSeries into 4d analyze format.
% 2: Then feed those analyze files through flirt to do motion correction.
%   the resulting analyze files are called 'xxx_mcf'
% 3: Then feed those motion corrected files through melodic to generate the
%   ICA independent components
% A second script / function (fsl_filterICAComponents) 
% Can then be used to reconstruct a new set of tSeries based on the
% pre-computed ICA components
% Note - we use read_avw and save_avw functions to do the reading and
% writing (instead of the spm functions).
% Remixed data sets are saved out to a new datatype RemixedOrig
mrGlobals;

thisDir=pwd;

fslBase='/raid/MRI/toolbox/FSL/fsl';
if (ispref('VISTA','fslBase'))
    disp('Settingn fslBase to the one specified in the VISTA matlab preferences:');
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
if (~exist('options','var'))
    options='';
end

nSlices=mrSESSION.inplanes.nSlices;
nScansToProcess=length(scansToProcess);

% Some issues:

a=now;
% Now run MELODIC
for thisScanIndex=1:nScansToProcess
    thisScan=scansToProcess(thisScanIndex);
    avw_dirName=['Inplane/Original/TSeries/Scan',int2str(thisScan),'/Analyze'];
    fNameMC=[avw_dirName,filesep,'data_mcf'];  
    fNameNonMC=[avw_dirName,filesep,'data'];
    
    % We can run MELODIC on either motion corrected or original data.
    % Check which we have. If neither then generate 4D analyze...
    if (~exist([fNameMC,'.hdr'],'file'))
        if (~exist([fNameNonMC,'.hdr'],'file'))
            disp(fNameNonMC);
            disp('Analyze file not found for this scan : Making it...');      
            view=fsl_MLR2Analyze(view,thisScan);
            fName=fNameMC;
        else
            fName=fNameNonMC;
        end
    else
        fName=fNameMC;
    end
    
    % Get the TR from mrSESSION.functionals
    TR=num2str(mrSESSION.functionals(1).reconParams.TR);
    
    %shellCmd=[fslPath,filesep,'melodic -i ',fName,' --report --nobet --no_mm --outdir=''',avw_dirName,'/ica',''' -v 3 --tr=',TR,' ',options];
    shellCmd=[fslPath,filesep,'melodic -i ',fName,' --report  --outdir=''',avw_dirName,'/ica',''' -v 3 --tr=',TR,' ',options];
    
    disp(shellCmd);
    tic;
    system(shellCmd);
    toc;
end
fprintf('\nFinished after %d seconds',datestr(now-a));
