function scanParams = GetScanParams(dirName)
% Reads Efile headers, and loads information into the scanParams struct 
%
%  scanParams = GetScanParams(dirName);
%
% DBR 3/99
% RAS 8/04 added a sorting, so that scans are listed
% in order of the time of scanning (or recon), rather than
% the Pmag number -- useful when the numbers wrap around to 0.

scanParams = [];
pfDir = fullfile(dirName, 'Pfiles');
if ~exist(pfDir, 'dir')
  Alert('No Pfile directory found');
  return
end

[nFiles, fileList, seqNums] = CountMagFiles(pfDir);
if ~nFiles
  Alert(['No mag files (P#####.7.mag) found in: ', pfDir]);
  return
end

% We require that that the count and sequence number of Efiles must agree
% with the mag files
[nEfiles, eFileList, eSeqNums, exams] = CountEfiles(pfDir);

% sort the files by time created, not by seq # -- in case the sequence
% number wraps around.
[fileList, eFileList, seqNums, eSeqNums] = SortMagFiles(fileList,eFileList,seqNums,eSeqNums,pfDir);

ok = (nEfiles == nFiles);
if ok
  ok = all(seqNums == eSeqNums);
end

for iScan=1:nFiles
  name = fullfile(pfDir, eFileList{iScan});
  rP = ReadEfileHeader(name);
  
  scanParams(iScan).PfileName = fileList{iScan};
  scanParams(iScan).totalFrames = rP.nframes;
  fullname=rP.name;
  
  % Split this into first and last
  spaceLocation=findstr(fullname,' ');
  if(spaceLocation)
      scanParams(iScan).firstName= fullname(1:(spaceLocation-1));
      scanParams(iScan).lastName = fullname((spaceLocation+1):end);
  else
      scanParams(iScan).firstName='';
      scanParams(iScan).lastName=fullname;
  end
  
  scanParams(iScan).date=rP.date;
  scanParams(iScan).time=rP.time;
  
  scanParams(iScan).junkFirstFrames = 0;
  scanParams(iScan).nFrames = rP.nframes;
  scanParams(iScan).slices = (1:rP.slquant);
  scanParams(iScan).fullSize = [rP.imgsize, rP.imgsize];
  scanParams(iScan).cropSize = [];
  scanParams(iScan).crop = [];
  dxy = rP.FOV / rP.imgsize;
  scanParams(iScan).voxelSize = [dxy, dxy, rP.sliceThickness];
  effRes = rP.FOV/rP.equivMatSize;
  scanParams(iScan).effectiveResolution = [effRes, effRes, rP.sliceThickness];
  scanParams(iScan).framePeriod = rP.tAcq/1000;
  scanParams(iScan).reconParams = rP;
end  

return;
