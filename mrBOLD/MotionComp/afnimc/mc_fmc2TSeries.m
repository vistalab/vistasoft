function mc_fmc2TSeries(view,fsd);
% mc_fmc2TSeries(view,[fsd]);
%
% convert motion-corrected data (in FS-FAST format) into tSeries stored in the
% 'MotionCorrected' dataType, creating this data type if necessary.
%
% Up to this point, I've been doing the following if I wanted to look 
% at motion corrected data: converting pmags to FS-FAST bshort files
% using pmag2bsh, motion correcting the data using FS-FAST's mc-sess
% command (which calls the afni algorithm/program 3dvolreg -- complicated,
% I know), then converting the bshorts back using convertBshortToTseries.
% This code does the last step, but also updates the dataTYPES struct and
% creates directories to do so cleanly.
%
% 'fsd' is the name of the directory containing the bshort files. It
% defaults to 'bold', which is what fs-fast defaults to naming these
% directories.
%
% Clearly motion-corrected data should be approached with caution, and
% non-motion-corrected data with small motion is always preferred. Indeed
% R.W. Cox, who designed the algorithm used, notes the algorithm is only
% useful for "small" motions of a few mm/degrees of rotation. 
% However, particularly for some of my hi-res data, motion of 2-3 mm is
% very big relative to voxel sizes, so it may be useful to try the
% motion-correction. In the future, if I continue using this, I may 
% try different algorithms, or at least directly convert from tSeries
% to afni brik format and back, saving the unnecessary bshort middle step.
% The problem is, though the algorithm is fairly good and fast, it's
% unix-only, and can't be run from windows machines.
%
% Also haven't done a formal comparison of the afni algorithm with the
% algorithm alex wade uses for the existing motion compensation tools in
% mrLoadRet -- this will be coming soon (I hope).
%
%
% 03/29/04 ras.
global dataTYPES HOMEDIR;

if ~exist('fsd','var') | isempty(fsd)
    fsd = 'bold';
end

stem = 'fmc';

cd(HOMEDIR);

% check if there's an 'MotionCorrected' data type already 
createMcDataType = 1;
for i = 1:length(dataTYPES)
    if isequal(dataTYPES(i).name,'MotionCorrected')
        createMcDataType = 0;
        series = i;
        break;
    end
end

% if necessary, make the directories for the MotionCorrected data type,
% and add the new entry to dataTYPES:
if createMcDataType==1
    cd(HOMEDIR);
    cd(view.viewType);
    mkdir('MotionCorrected');
    
    cd MotionCorrected
    mkdir('TSeries');
    
    cd(HOMEDIR);
    
    series = length(dataTYPES)+1;
    dataTYPES(series).name = 'MotionCorrected';
end

% find the appropriate scans that have fmc files in the fsd:
list = grabfields(filterdir('0',fsd),'name')
for i = 1:length(list)
    testForMcFiles = ~isempty(filterdir('fmc',fullfile(fsd,list{i})));
    if testForMcFiles==1
        whichScans(i) = str2num(list{i})
    end
end

fprintf('\n\n\t\t *****Converting motion-corrected tSeries from scans: %s into MotionCorrected data type *****\n',num2str(whichScans));


% main loop: convert
tSeriesDir = fullfile(HOMEDIR,view.viewType,'MotionCorrected','TSeries');
for scan = whichScans
    
    tgtDir = fullfile(tSeriesDir,['Scan' num2str(scan)]);
    if ~exist(tgtDir,'dir')
        cd(tSeriesDir);
        mkdir(['Scan' num2str(scan)]);
        cd(HOMEDIR);
    end
    
    srcDir = fullfile(fsd,sprintf('%03i',scan));
 
    convertBshortTotSeries(tgtDir,srcDir,stem);

    % update data types for each scan
	% (this makes the assumption that each scan # corresponds to the same scan
	% # in the original data types. There is one condition where this will be
	% in error -- when the P.mag file numbers wrap around 640000.7-00000.7 for
	% a session. In this case, a bug^B^B^B quirk of mrInitRet is that it counts
	% the scans by Pmag #, and won't go in chronological order, while the
	% bshorts are created by creation time. Rory is fixing the mrInitRet
	% quirk.)
    dataTYPES(series).scanParams(scan) = dataTYPES(1).scanParams(scan);
    dataTYPES(series).blockedAnalysisParams(scan) = dataTYPES(1).blockedAnalysisParams(scan);
    dataTYPES(series).eventAnalysisParams(scan) = dataTYPES(1).eventAnalysisParams(scan);

    save mrSESSION dataTYPES -append;
end

fprintf('\n\t\t *****Done converting motion-corrected data. *****\n');

return
