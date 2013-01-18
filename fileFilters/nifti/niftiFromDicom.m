function niftiPath = niftiFromDicom(dicomDir, outDir, studyId, sortByFilenameFlag, makeAxialFlag, mergeAcqsFlag)
%
% niftiPath = niftiFromDicom(dicomDir, [outDir=dicomDir/..], [studyId=''], [sortByFilenameFlag=false], [makeAxialFlag=true])
%
% Loads all the dicom files found in the specified dicomDir and packs
% the data from each individual series into a nifti file. All the
% nifti files are saved in outDir, named with the studyID
% (ie. exam number) and series number.
%
% If studyID (a string) is provided, then only series with a
% matching StudyID tag will be returned. Otherwise, all series
% matching the studyID of the very first image encountered in the
% dir will be loaded. (You usually will only have one study per
% dicomDir.)
%
% Dicom slices within a series are by default sorted by the DICOM
% header InstanceNumber (effectively the slice number). In this 
% case, the filenames of individual DICOM files are ignored.
% However, if you think the InstanceNumber might be wrong (e.g.,
% you replaced a corrupt or missing image with a copy of another
% comparable slice), then you can have the code sort by the
% filename and ignore the InstanceNumber in the header by setting
% sortByFilenameFlag to true.
%
% If makeAxialFlag is true, niftiApplyCannonicalXform will be applied. This
% essentailly reorders your voxels to be as close to axial (transverse) as
% they can be and such that left-is-left and right-is-right for most NIFTI
% viewers. (See niftiApplyCannonicalXform for details.)
% 
% HISTORY:
% 2007.10.24 RFD: wrote it.

if(~exist('dicomDir','var')||isempty(dicomDir))
  dicomDir = uigetdir(pwd,'Select a directory of DICOM files for input...');
  if(isequal(dicomDir,0)), disp('User canceled.'); return; end
end
if(~exist('outDir','var')||isempty(outDir))
    outDir = fileparts(dicomDir);
    if(isempty(outDir)) outDir = pwd; end
    disp(['Setting output directory to ' outDir '.']);
end
if(~exist('studyId','var'))
    studyId = [];
end
if(~exist('sortByFilenameFlag','var')||isempty(sortByFilenameFlag))
    sortByFilenameFlag = false;
end
if(~exist('makeAxialFlag','var')||isempty(makeAxialFlag))
    makeAxialFlag = true;
end
if(~exist('mergeAcqsFlag','var')||isempty(mergeAcqsFlag))
    mergeAcqsFlag = false;
end

if(~exist(outDir,'dir')) mkdir(outDir); end

s = dicomLoadAllSeries(dicomDir,studyId,sortByFilenameFlag);
seriesNums = unique([s(:).seriesNum]);
for(ii=1:length(s))
    if(strcmpi(s(ii).phaseEncodeDir,'ROW')) fpsDim = [2 1 3];
    else fpsDim = [1 2 3]; end
    TR = s(ii).TR/1000;
    if(mergeAcqsFlag)
        warning('mergeAcqs is NOT YET IMPLEMENTED');
    end
    ni = niftiGetStruct(s(ii).imData, s(ii).imToScanXform, 1, s(ii).seriesDescription, [], [], fpsDim, [], TR);
    if(makeAxialFlag)
        ni = niftiApplyCannonicalXform(ni);
    end
    ni.fname = fullfile(outDir,sprintf('%s_%d-%d.nii.gz', s(ii).studyID, s(ii).seriesNum, s(ii).acqNum));
    writeFileNifti(ni);
	
	% return the file path if requested
	if nargout > 0
		niftiPath = fullpath(ni.fname);
	end
	
	% report what we saved.
	if prefsVerboseCheck
		fprintf('[%s]: Wrote NIFTI file %s.\n', mfilename, ni.fname);
	end
		
    clear ni;
end

return;
