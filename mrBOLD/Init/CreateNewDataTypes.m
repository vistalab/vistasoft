function dataTYPES = CreateNewDataTypes(mrSESSION)
% Create top-level dataTYPES strycture.
%
%  dataTYPES = CreateNewDataTypes(mrSESSION);
%
% We should use the dtGet/Set/Create suite.
%
% We shouldn't set such specific parameters for the default; we should set
% the values empty.  Also, it is awkward to have the same values
% represented in dataTYPES and mrSESSION because the two may lose
% synchronization. (BW)
%
% See also:
% 
% Programming Notes
% djh 9/26/2001
% ras, 03/04: added more eventAnalysisParams, since it's assumed they'll
% be created anyway down the line (e.g., if detrend option is 2, mrLoadRet
% looks for the detrendFrames in eventAnalysisParams).
% ras, 02/06: also added the parfile and scanGroup fields for event-
% related analyses, so they're there even if they're not used.

disp('CreateNewDataTypes is obsolete:  Use dtCreate');
evalin('caller','mfilename')

dataTYPES.name = 'Original';

for iScan = 1:length(mrSESSION.functionals)
    dataTYPES.scanParams(iScan).annotation = '';
    dataTYPES.scanParams(iScan).nFrames = mrSESSION.functionals(iScan).nFrames;
    dataTYPES.scanParams(iScan).framePeriod = mrSESSION.functionals(iScan).framePeriod;
    dataTYPES.scanParams(iScan).slices = mrSESSION.functionals(iScan).slices;
    dataTYPES.scanParams(iScan).cropSize = mrSESSION.functionals(iScan).cropSize;
    dataTYPES.scanParams(iScan).PfileName = mrSESSION.functionals(iScan).PfileName;
    dataTYPES.scanParams(iScan).parfile = '';
    dataTYPES.scanParams(iScan).scanGroup = '';
    dataTYPES.blockedAnalysisParams(iScan).blockedAnalysis = 1;
    dataTYPES.blockedAnalysisParams(iScan).detrend = 1;
    dataTYPES.blockedAnalysisParams(iScan).inhomoCorrect = 1;
    dataTYPES.blockedAnalysisParams(iScan).temporalNormalization = 1;
    dataTYPES.blockedAnalysisParams(iScan).nCycles = 8;
    dataTYPES.eventAnalysisParams(iScan) = er_defaultParams;
end

dataTYPES.retinotopyModelParams = [];

return
