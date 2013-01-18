function analyzeConditions(conditions,sessions,ROIs,viewType,dataType,fileNamePrefix,fileNameSuffix)
%
% analyzeConditions(datadr,conditions,sessions,ROIs,[viewType],[dataType],[fileNamePrefix],[fileNameSuffix])
%
% Loops through conditions to compute test scan responses
% Saves results in file in dir you're in when you call this function.
%
% conditions: struct array with fields name, sessions, and scans,
% e.g., 
%   conditions(1).name = 'foo';
%   conditions(1).sessions = [1];
%   conditions(1).scans =    [1];
%   conditions(2).name = 'bar';
%   conditions(2).sessions = [1];
%   conditions(2).scans =    [2];
% sessions and scans specify the repeats of each condition.
%
% sessions: struct array with fields subdir and referenceScans, e.g.,
%     sessions(1).subdir = '121897';
%     sessions(1).referenceScans = [1:10];
% The referenceScans field is used in calling computeReferencePhase.m
%
% ROIs: cell array of roiNames
%   ROIs{1} = 'V1';
%   ROIs{2} = 'V1r7';
%   ROIs{3} = 'MT';
%
% viewType: either 'Inplane' or 'Gray' (default: 'Inplane')
%
% dataType: optional for specifying data type (default: 'Original')
%
% fileNameSuffix: to specify unique filenames (filenames default
% to ROI.name. Must be the same as that used to call analyzeSessions.
%
% fileNamePrefix: to further specify a unique filename for the output
% of this function. Default is ''.
%
% Output data structure responses is struct array with fields
%   name: copied from conditions
%   sessions: copied from conditions
%   scans: copied from conditions
%   amp: mean response amp (computed via vector mean from the
%     individual repeats.
%   ph: mean response phase
%   projectedAmp: mean projected amplitude, computed by projecting onto 
%     mean reference phase line
%   repeats: vector of complex amp/ph for individual repeats
%   projectedAmps: vector of projected amps for individual repeats
%   bivariateSE:
%   projectedAmpSD:
%   projectedAmpSE:
%   refPhase: from computeReferencePhase.m
%
% 10/30/98 - written by djh
% 9/24/99 - wap added constrainAnalysisFlag
% 08/25/2000 huk added weighted projected amps
% 9/27/2000 heeger removed weighted projected amps
% 2/5/2001 - heeger, major revision
%   - removed constrainAnalysisFlag (to analyze the referenceScans only, set up a separate
%     condition and call it separately).
%   - computes the reference phase using computeReferencePhase
%   - see update of analyzeConditions.m for add'l changes that I made at the same time.
% djh, 3/6/2001, updated to mrLoadRet-3.0
% den, 8/26/02, added a line to update the global variable HOMEDIR as the code loads each session

mrGlobals;

if ~exist('viewType','var')
    viewType = 'Inplane';
end
if ~exist('dataType','var')
    dataType = 'Original';
end
if ~exist('fileNamePrefix','var')
    fileNamePrefix = '';
end
if ~exist('fileNameSuffix','var')
    fileNameSuffix = '';
end

for r = 1:length(ROIs) 
    disp('---------');
    roiName = ROIs{r};
    disp(['ROI: ',roiName]);
    fileName = [roiName,fileNameSuffix];
    clear ref responses
    
    % Compute reference phase
    refPh = computeReferencePhase(sessions,roiName,viewType,dataType,fileNameSuffix);
    % refZ with amp=1, used below for computing projected amplitudes.
    refZ = exp(j*refPh);
    
    % Loop through conditions to get responses
    for c = 1:length(conditions)
     
        condition = conditions(c);
        responses(c).name = condition.name;
        responses(c).sessions = condition.sessions;
        responses(c).scans = condition.scans;
        
        disp(['condition: ',condition.name]);
        if (length(condition.sessions) ~= length(condition.scans))
            myErrorDlg('condition.sessions and condition.scans must have same length');
        end
        
        clear repeats
        for s = 1:length(condition.scans)
            sessionNum = condition.sessions(s);
            scanNum = condition.scans(s);
            
            sessiondr = sessions(sessionNum).path;
            loadSession(sessiondr);
            HOMEDIR = sessiondr;
            disp(['session: ',sessions(sessionNum).path,', scan',num2str(scanNum)]);
            
            % Open hidden view of the chosen viewType (either 'Inplane' or 'Gray')
            switch viewType
            case 'Inplane'
                view = initHiddenInplane;
            case 'Gray'
                view = initHiddenGray;
            otherwise
                error('analyzeSessions: supports only Inplane and Gray views.');
            end
            
            % Select chosen data type
            view = selectDataType(view,existDataType(dataType));
            
            % Load data and extract the relevant scans
            fileName = [roiName,fileNameSuffix];
            load(fullfile(dataDir(view),'Analysis',fileName));
            amp = analysis.amps(scanNum);
            ph = analysis.phs(scanNum);
            repeats(s) = amp * exp(j*ph);
        end
        responses(c).repeats = repeats;
        meanZ = mean(repeats);
        responses(c).amp = abs(meanZ);
        responses(c).ph = angle(meanZ);
        responses(c).bivariateSE = bivariateSE(repeats);
        projAmps = real(repeats.*conj(refZ));
        responses(c).projectedAmps = projAmps;
        responses(c).projectedAmp = mean(projAmps);
        responses(c).projectedAmpSD = std(projAmps);
        responses(c).projectedAmpSE = std(projAmps)/sqrt(length(projAmps));
        responses(c).refPh = refPh;
    end
    
    fileName = [fileNamePrefix,roiName,fileNameSuffix];
    save(fileName,'responses');
    
end
