function dummy=mrInitRetAnalyze(dataPath,functHeader,rawFuncScans,analyzeOrient,rotateFlag,flipudFlag)
% dummy=mrInitRetAnalyze(sessionName,inplanePath,rawFuncScanDirs,framesToKeep)
% 
% mrInitRetAnalyze
% Similar to mrInitRet except that it operates on Analyze format
% data sets as output by, say, the CHUV Phillips scanners.
% We assume that the Analyze data is in 4d format . All files are in the same directory
% and are named [someHeader]nnn.hdr where nn is a number in 00x format.
%
% The anatomical inplane should be in the same directory and called simply
% anat.hdr
%
%
% Does the following step:
% - crop inplanes (This is a legacy stage and may be omitted in later versions) - generate
% anat.mat file
% - build mrSESSION (& modify if necessary?)
% - build dataTYPES
% - modify analysis parameters in dataTYPES 
% - create Readme
% - extract time series from analyze files.
% - corAnal
% Last modified $Date: 2006/03/07 22:55:15 $
% The function computes the number of slices + TRs from the analyze header. 
% You can specify the number of junk frames etc in the GUI later
% The mrSESSION folder is constructed in the current directory.


 
mrGlobals

% Construct the directories we need
disp('Making directories');
mkdir('Inplane');
mkdir('Gray');
mkdir('Volume');
mkdir('Flat');
mkdir('Raw');
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Opening dialogs

% initOptions = {'Create/edit data structures',...
%         'Extract time series'};
% 
% initReply = buttondlg('mrInitRet', initOptions);
% if length(find(initReply)) == 0, return; end

doDBQuery=0;
doCrop = 0; 
doSession = 1;%initReply(1);
doTSeries = 1;%nitReply(2);
doCorrel = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the inplane anatomies 
% We can read the volume siye from the header. Maybe other info as well.
% The inplane data should be in the dataPath named anat.hdr/img
fname=[dataPath,filesep,'anat'];


firstAnalyzeFile=[dataPath,filesep,functHeader,sprintf('%03d',rawFuncScans(1)),'.hdr'];
    
scanParams = GetScanParamsAnalyze(firstAnalyzeFile,rawFuncScans,analyzeOrient,rotateFlag,flipudFlag)
[anat, dims,scales,bpp,endian] = read_avw(fname);

% The problem here is that the analyze files can be in any orientation. dims is a 4x1 with the 4th entry being the number of TRs
% The first 3 entries should be x,z,nSlices
% However...
% From the variable analyzeOrient we are given the index of the x,y,z
% directions where X is l-R, y is sup-inf, and z is the slice order.
% Using this we can reshape dims, scales to be correct
% Then we can re-arrange anat (and ultimately the functional data) to be
% correct as well.
% Since MLR expects the INPLANE views to be in radiological convention
% (Left hemisphere on screen right) we can also perform a rotate and flip.
dims=dims(analyzeOrient);
scales=scales(analyzeOrient);

if (analyzeOrient(3)~=3)
    anat=shiftdim(anat,analyzeOrient(3)); % So if the slices are dimension 2, we shift left by 2 to put them at the end.
end


% After this, we assume that the dimensions of the anatomy are x*y*nSlices

for thisSliceIndex=1:size(anat,3)
    % Now we loop over the anatomy doing rotates and flips. In that order.
    thisSlice=squeeze(anat(:,:,thisSliceIndex));
    thisSlice=rot90(thisSlice,rotateFlag);
    if(flipudFlag)
        thisSlice=flipud(thisSlice);
    end
    anat(:,:,thisSliceIndex)=thisSlice;
end


    
    
% Do check on image size later
dims
scales


% Populate the INPLANES struct
  inplanes.FOV = dims([1,2])*scales(1);
  inplanes.fullSize = dims([1,2]);
  inplanes.voxelSize = scales([1,2]);
  inplanes.spacing = 0;
    % We already checked hdr.image.slquant==nList, not again -- Junjie
  inplanes.nSlices = dims(3);

  inplanes.examNum = 'Dummy';
  inplanes.crop = [0,0;[dims([1,2])-1]']
  inplanes.cropSize = [dims([1,2])']
  
% Load the inplane-anatomy images and initialize the inplanes structure
%[anat, inplanes, doCrop] = InitAnatomyDicom(HOMEDIR, rawDir,rawInplaneDir, doCrop);
 
if isempty(anat)
    disp('Aborted')
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% From now on we never crop. Memory and disk space are cheap enough...
% 
% 


% Save anat
anatFile = fullfile(HOMEDIR, 'Inplane', 'anat.mat');
save(anatFile, 'anat', 'inplanes');
mrSESSION.inplanes = inplanes;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create/load mrSESSION and dataTYPES, modify them, and save

% If mrSESSION already exits, load it.
sessionFile = fullfile(HOMEDIR, 'mrSESSION.mat');
if exist(sessionFile, 'file')
    loadSession;
    % if docrop, make sure that the mrSESSION is up-to-date
    if doCrop
        mrSESSION.inplanes = inplanes;
        mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams);
        saveSession;
    end
end

if doSession
    % If we don't yet have a session structure, make a new one.
  

     
   
        mrSESSION = CreateNewSession(HOMEDIR, inplanes, mrLoadRetVERSION);
    
    
     
    % Update mrSESSION.functionals with scanParams corresponding to any new Pfiles.
    % Set mrSESSION.functionals(:).crop & cropSize fields
    mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams);
    disp('mrSESSION...');
    disp(mrSESSION)
    disp('Entering EditSession');
    
    % Dialog for editing mrSESSION params:
    [mrSESSION,ok] = EditSession(mrSESSION);
    if ~ok
        disp('Aborted'); 
        return
    end
    
    % Create/edit dataTYPES
    if isempty(dataTYPES)
        dataTYPES = CreateNewDataTypes(mrSESSION);
    else
        dataTYPES = UpdateDataTypes(dataTYPES,mrSESSION);
    end
    dataTYPES(1) = EditDataType(dataTYPES(1));
    
    % Save any changes that may have been made to mrSESSION & dataTYPES
    saveSession;
    
    % Create Readme.txt file
    %mrCreateReadmeDicom(mrSESSION);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract time series & perform corAnal


% At this point, we can open up a mlr view and 
% Create time series files
mrvista('inplane');
v=getSelectedInplane;


if doTSeries
   % GetAnalyzeRecon(dataDir,functHeader,rawFuncScans); % Set this fleg to 0 for no roation or 1 for 90 degrees of CW rotation.
   % We can read in the Analyze format data files and write them out very quickly. Since we are not cropping, there is no reason
   % to have a big complicated function here. 
   for thisScan=1:length(rawFuncScans)
    inFile=[dataPath,filesep,functHeader,sprintf('%03d',rawFuncScans(thisScan)),'.hdr'];
    disp(inFile)
    
      volsToSkip=mrSESSION.functionals(thisScan).junkFirstFrames;
      scaleFact=[1];
      flipudFlag=0;
      rotateFlag=1;
        v=analyze4d_2mrLoadRetTSer(v,inFile,thisScan,volsToSkip,rotateFlag,scaleFact,flipudFlag,analyzeOrient,0);
        %v=analyze4d2mrLoadRet3TSeries(v,inFile,thisScan,volsToSkip,rotateFlag,scaleFact,flipudFlag);
   end
   
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up

clear all
