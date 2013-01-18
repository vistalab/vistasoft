function scanParams = GetScanParamsDicom(dirName,sessionName,scanList,nFrames,nSlices)
% function scanParams = GetScanParamsDicom(dirName,scanList,nFrames,nSlices);
% Populates the scanParams structure based on information read from the 
% dicom headers of the first file in each directory mentioed in 'scanList'
% Note that scanList is a list of directories (found under RawDicom)
% That contain the functional data - so it might be [3,4,5,6,7]
% ARW 043004 : Wrote it based on GetScanParams

scanParams = [];

if ~exist(dirName, 'dir')
  Alert('No raw data directory found');
  return
end

% Loop through checking that each sub dir exists. It's better to discover
% this now rather than halfway through the function
nFuncScans=length(scanList);
if(nFuncScans==0)
    error('No functional scan directories specified');
end

for t=1:length(scanList)
    thisDir=[dirName,filesep,int2str(scanList(t))];
    if (~exist(thisDir,'dir'))
       fprintf('\nLooked for dir %s\n',thisDir);
       error('Can''t find directory');
   end
end


for iScan=1:nFuncScans
   scanID=scanList(iScan)
   
    % Get the DICOM header of the first file to extract file information
  fileSearchPath=[dirName,filesep,int2str(scanID),filesep,'*I1.DCM'];
  sampleFileName=dir(fileSearchPath);
  filePath=fullfile(dirName,int2str(scanID),sampleFileName.name);
  dicomHeader=dicominfo(filePath);
   
  scanParams(iScan).PfileName = ['no pfile : DICOM series ',int2str(scanID)];
  scanParams(iScan).totalFrames = nFrames;
  scanParams(iScan).firstName='';
  
  % In some versions of matlab (6?) the following header
  % is'PatientName' in others it's 'PatientsName'.
  % Go figure...
  
try   %in Matlab7 it extract PatientName while in matlab 6 Patient!s!Name 
  scanParams(iScan).lastName=dicomHeader.PatientsName.FamilyName;
 catch 
      scanParams(iScan).lastName=dicomHeader.PatientName.FamilyName;
end

  scanParams(iScan).date=dicomHeader.StudyDate;
  scanParams(iScan).time=dicomHeader.StudyTime;
  
  scanParams(iScan).junkFirstFrames = 0;
  scanParams(iScan).nFrames = nFrames;
  scanParams(iScan).slices = [1:nSlices];
  scanParams(iScan).fullSize = [dicomHeader.Height, dicomHeader.Width];
  scanParams(iScan).cropSize = [];
  scanParams(iScan).crop = [];
  dxy = dicomHeader.PixelSpacing(1);
  
  scanParams(iScan).voxelSize = [dxy, dxy, dicomHeader.SliceThickness];
  
  scanParams(iScan).effectiveResolution = scanParams(iScan).voxelSize;
  
  scanParams(iScan).framePeriod = dicomHeader.RepetitionTime/1000;
  scanParams(iScan).reconParams.slquant=nSlices;
  scanParams(iScan).reconParams.TE=dicomHeader.EchoTime;
  scanParams(iScan).reconParams.TR=dicomHeader.RepetitionTime/1000;
  scanParams(iScan).reconParams.nshots=dicomHeader.NumberOfAverages;
  scanParams(iScan).reconParams.FOV=dicomHeader.Width*dicomHeader.PixelSpacing(1);
  scanParams(iScan).reconParams.equivMatSize=dicomHeader.Rows;
  scanParams(iScan).reconParams.sliceThickness=dicomHeader.SliceThickness;
  scanParams(iScan).reconParams.nframes=nFrames;
  
  scanParams(iScan).dicomHeader=dicomHeader;
  
end  
