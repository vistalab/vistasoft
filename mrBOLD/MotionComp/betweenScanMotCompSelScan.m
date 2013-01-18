function vw = betweenScanMotCompSelScan(vw, typeName)
%
%  vw = motionCompSelScan(vw, [typeName]);
%
% Opens a GUI so that the user can select the base scan and the scans
% to run the between scan motion compensation
%
% on, 06/00 - original code
% remus, 03/09 added check for overwriting datatype

baseScan = er_selectScans(vw,'Choose a single base scan');

if isempty(baseScan), return, end
baseScan = baseScan(1);

targetScans = er_selectScans(vw,'Choose scans for motion compensation');
if isempty(targetScans), return, end

% Set up new datatype for motion correction:
if (~exist('typeName', 'var') || isempty(typeName)), 
	typeName = ['MotionComp_RefScan',int2str(baseScan)]; 
end
typeName = dataTypeOverwriteCheck(typeName);


% call the motion compensation routine
[vw M] = betweenScanMotComp(vw, typeName, baseScan, targetScans);
save(fullfile('Inplane',typeName,'ScanMotionCompParams'),'M','baseScan','targetScans');

% Switch to the new view and compute new mean maps:
vw = selectDataType(vw, typeName);
saveSession; % why do we need to do this?
vw = computeMeanMap(vw, 0, 1);
vw = refreshView(vw, 1);

return
