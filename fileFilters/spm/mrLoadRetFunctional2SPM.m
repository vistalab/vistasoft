function mrLoadRetFunctional2SPM(fileRoot,examNum)
% Convert functional data to SPM Analyze files
%
% mrLoadRetFunctional2SPM([fileRoot],[examNum])
%
%
%Updated by JL 9/17/04

mrGlobals;

if (~exist('INPLANE','var'))
    error('INPLANE Structure must exist');
end
% if (isempty(INPLANE.anat))
%     error('INPLANE.anat must contain data: select view->croppedAnatomy in mrLoadRet to get the anatomies up');
% end
if (~exist('fileRoot','var'))
    warning('trying to use pwd as working fileRoot');
    fileRoot = pwd;
end

if (~exist('examNum','var'))
    warning('Will use the current scan');
    examNum = [];
end

if isfield(mrSESSION,'mrLoadRetVersion');
    if mrSESSION.mrLoadRetVersion >= 3;
        outDat=getTSeriesInAnalyzeForm(INPLANE{1},examNum);
    end
else
    outDat=getTSeriesInAnalyzeForm(INPLANE,examNum);
end

% Comes out as nVols*x*y*nSlices
                            
% Now, just call writeVFileSet
writeVFileSet(outDat,fileRoot);

return
