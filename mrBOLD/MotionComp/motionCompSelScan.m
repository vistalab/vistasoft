function vw = motionCompSelScan(vw, typeName, scanList, baseFrame, nSmooth, baseScan)
%
%  vw = motionCompSelScan(vw, typeName, scanList, baseFrame, nSmooth, baseScan);
%
% Opens a GUI so that the user can select the scans to run the motion
% compensation, and then runs the motion compensation (3D rigid) on the
% scans selected
%
% on, 12/23/99 - original code
% Ress, 5/04 - Now creates a new datatype, and gets smoothing and base
% frame data from user. Produces plots of typical motion detected.
% ras, 09/08 -- cleanup / made more readable.
% remus, 03/09 added check for overwriting datatype
% hh, 09/10 -- added new parameter - baseScan, which inidicates a referece
%               scan if you want to align all frames in all scans to a
%               single frame in a single scan (thereby avoiding the need
%               for sequential  motion compensation, first between- and
%               then within-scans)
%
mrGlobals;

if notDefined('typeName'),      typeName = dataTypeOverwriteCheck('MotionComp'); end
if notDefined('scanList'),      scanList = selectScans(vw);     end
if notDefined('vw'),            vw       = getSelectedInplane;  end
if notDefined('baseScan'),      baseScan = [];                  end

if notDefined('baseFrame') || notDefined('nSmooth')
	% Prompt user for smoothing and baseFrames:
	prompt    = {'Smoothing (odd number)', 'Base frame'};
	dTitle    = 'Motion compensation parameters';
	defVal    = {'1', ''};
	response  = inputdlg(prompt, dTitle, 1, defVal);
	nSmooth   = str2num(response{1}); %#ok<*ST2NM>
	baseFrame = str2num(response{2});
end
% record the data type from the source (pre-correction) data
srcDt = vw.curDataType;
%TODO: Replace with viewGet

%% open a figure for the motion estimate report
h_report = figure;

% figure out the # of rows and columns we'll need in the report figure (one
% suplot for each scan)
ny = ceil( sqrt(length(scanList)) );
nx = ceil( length(scanList) / ny );

%% main loop
for iScan = 1:length(scanList)
	%% initialize the scan
	srcScan = scanList(iScan);
	
    %[mcView, tgtScan, tgtDt] = initScan(vw, typeName, srcScan, {srcDt srcScan});
    [vw, tgtScan, tgtDt] = initScan(vw, typeName, srcScan, {srcDt srcScan});
    vw = viewSet(vw, 'curdt', srcDt);
	% 	% make sure the mcView has the new data type selected
	% 	mcView.curDataType = tgtDt;
    %
    %  what is mcView? why can't we just use a single view structure (vw)?
    
	%% run the motion compensation
	motion = motionComp(vw, tgtDt, srcScan, nSmooth, baseFrame, baseScan);

	%% report on motion; record motion estimates in dataTYPES
	figure(h_report);
	subplot(ny, nx, iScan);
	t = 1:size(motion, 2);
	plot(t, motion(1, :), t, motion(2, :), t, sqrt(sum(motion(1:2, :).^2))); drawnow
	title(['Motion for scan ', num2str(srcScan)])
	if iScan==1
		xlabel('Time (frames)')
		ylabel('Motion (voxels)')
    end
    
    dataTYPES(tgtDt) = dtSet(dataTYPES(tgtDt), 'Within Scan Motion', motion, tgtScan);
	%dataTYPES(tgtDt).scanParams(tgtScan).WithinScanMotion = motion; %TODO: Use dtSet
end
saveSession;

%% save the report figure
legendPanel({'Rotation' 'Translation' 'Total'});
if ~exist(fullfile(pwd, 'Images'), 'dir'), mkdir Images; end
savePath = fullfile(pwd, 'Images', 'Within_Scan_Motion_Est');
saveas(h_report, [savePath '.fig']);
saveas(h_report, [savePath '.jpg']);
fprintf('Saved estimated motion figure as %s.fig and %s.jpg. All Done! \n', ...
	savePath, savePath);


%% Event-related scan grouping
try
	er_groupScans(newView, 1:numScans(mcView), 2);
catch ME
	% don't worry about it
end


return

