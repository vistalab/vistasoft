function rxWholeBrainAlignment(wb, ip, vanat, manualFlag);
% Compute a mrVista inplane->volume alignment using an intermediate, whole
% brain anatomy collected from the same session as the inplanes.
% 
% rxWholeBrainAlignment(wb, ip, vanat, manualFlag);
%
% BACKGROUND:
%	The main problem is to solve an xform, X, which maps from inplane to
%	volume coords:
%	
%	volCoords = X * ipCoords;
%
%	This function decomposes X into two sub transforms: inplane ->
%	local whole-brain anat (based on header information), and local
%	whole-brain anat -> volume anat (based on automated methods). So the
%	mapping becomes:
%	
%	volCoords = wb2vol * ip2wb * ipCoords;
%
%   (This is leaving out rows of 1s and other finer details.) The
%   particular algorithm used to compute wb2vol is a combination of Oscar
%   Nestares' mrAlign inhomogenity correction and SPM's mutual information
%   algorithm; it is supposed to be very effective at aligning whole
%   brains. This step was provided by Bob Dougherty.
%
%	See the wiki page at 
%	http://white.stanford.edu/newlm/index.php/Whole-brain_Alignment
%	for more details.
%
%
% OPTIONAL FLAGS:
%	Use rx = rxWholeBrainAlignment(wholeBrain, inplane) to specify the
%	location of the inplane file, if it's not in Inplane/anat.mat.
%	Use rx = rxWholeBrainAlignment(wholeBrain, inplane, vAnatomy) to
%	specify the vAnatomy location if it's not given by getVAnatomyPath.
%
% ras, 10/06/2008. 

%% still haven't decided if this will be called from an existing mRx
%% session, or will be a standalone functio that calls mrRx several times.
% if notDefined('rx')
%     cfig = findobj('Tag','rxControlFig');
%     rx = get(cfig,'UserData');
% end
% 
if notDefined('wb')
	% dialog
	ttl = 'Select a file from the whole-brain anatomy';
	wb = mrvSelectFile('r', 'dcm', ttl, 'Raw/');
end

if notDefined('ip')
	ip = 'Raw/Anatomy/Inplane';
% 	ip = 'Inplane/anat.mat';
end

if notDefined('vanat')
	vanatPath = getVAnatomyPath;
end

if notDefined('manualFlag'),	manualFlag = [1 1];  end

%% parse the inputs -- make sure they're loaded
ip = mrParse(ip);
wb = mrParse(wb);
vanat = mrParse(vanat);

% if the inplane is actually a functional image (4-D), we just align the
% temporal mean image:
if size(ip.data, 4) > 1
	ip = mrComputeMeanMap(ip);
end

%% compute the component transformations
% compute inplane -> whole brain alignment
ip2wb = rxInplane2WholeBrainXform(ip, wb, manualFlag(1));

% compute whole brain -> volume alignment
wb2vol = rxWholeBrain2VolXform(wb, vanat, manualFlag(2));

%% set the final alignment
% combine the two alignments
X = wb2vol * ip2wb;

% set in mrRx
rx = mrRx(vanat.data, ip.data, 'volRes', vanat.dims(1:3), ...
		  'refRes', ip.dims(1:3), 'volVoxelSize', vanat.voxelSize(1:3), ...
		  'refVoxelSize', ip.voxelSize(1:3));
rx = rxSetXform(rx, X);

% store the alignment
rx = rxStore(rx, 'Whole-brain alignment');

% go ahead and save the mrVista variables, if asked


return
% /------------------------------------------------------/ %



% /------------------------------------------------------/ %
function ip2wb = rxInplane2WholeBrainXform(ip, wb, manualFlag);
%% compute alignment from inplane coords -> whole-brain coords

%% compute initial "guess" xform from inplane -> wb
% this has three steps on itself:
% (1) inplane should have a 'scanner' space from the DICOM/NIFTI/mag file
% headers: this is inplane -> scanner space
ii = cellfind( {ip.spaces.name}, 'Scanner' );
ip2scanner = ip.spaces(ii).xform;

% (2) wb should also have a scanner space: take the inverse, from scanner
% -> wb coords
ii = cellfind( {wb.spaces.name}, 'Scanner' );
scanner2wb = inv( wb.spaces(ii).xform);

% (3) multiply the two xforms
init_ip2wb = scanner2wb * ip2scanner;

%% plug the initial alignment into mrRx, and call the mutual information
%% alignment tool
if manualFlag==1
	rx = mrRx(wb.data, ip.data(:,:,:,1), 'volRes', wb.dims(1:3), ...
			  'refRes', ip.dims(1:3), 'volVoxelSize', wb.voxelSize(1:3), ...
			  'refVoxelSize', ip.voxelSize(1:3));
	rx = rxSetXform(rx, inv(init_ip2wb));
else
	rx = rxInit(wb.data, ip.data, 'volRes', wb.dims(1:3), ...
			  'refRes', ip.dims(1:3), 'volVoxelSize', wb.voxelSize(1:3), ...
			  'refVoxelSize', ip.voxelSize(1:3));
	rx.xform = init_ip2wb;
end

%% do the mutual-information based xform
rx = rxFineMutualInf(rx, 1, 1, 1, [4 2]);

%% now, check for user feedback:
% if we want this to be a manual step, we insert a uiwait, give the user a
% button to press to proceed (allowing for manual adjustments), and then
% grab the updated xform. Otherwise, we just return the current xform
if manualFlag==1
	uicontrol('Style', 'pushbutton', 'Units', 'normalized', ...
			  'Position',[.18 .45 .18 .18], 'String', 'Proceed to Step 2', ...
			  'BackgroundColor', [.4 1 .8], 'ForegroundColor', 'k', ...
			  'Callback', 'uiresume');	
	uiwait
end

ip2wb = rx.xform;

return
% /------------------------------------------------------/ %



% /------------------------------------------------------/ %
function wb2vol = rxWholeBrain2VolXform(wb, vanat, manualFlag);
%% compute alignment from whole-brain -> volume coords

%% compute initial "guess" xform from wb -> volume
%% this has three steps on itself:
% (1) wb should have a 'Scanner' space from the DICOM/NIFTI/mag file
% headers: this is wb -> scanner space
ii = cellfind( {wb.spaces.name}, 'Scanner' );
wb2scanner = wb.spaces(ii).xform;

% (2) vanat should have an 'R|A|S' space xform: this is the same
% orientation rotation as 'scanner', but may have different translations.
% Convert this to a 'scanner' space by setting the translations to be half
% the vanat dimensions (so it centers on (0, 0, 0)).
ii = cellfind( {vanat.spaces.name}, 'R|A|S' );
vanat2ras = vanat.spaces(ii).xform;
scanner2vanat = inv(vanat2ras);
scanner2vanat(1:3,4) = vanat.dims(1:3) ./ 2;

% (3) multiply the two xforms: 
init_wb2vol = wb2scanner * scanner2vanat;

%% plug the initial alignment into mrRx, and call the mutual information
%% alignment tool
if manualFlag==1
	rx = mrRx(vanat.data, wb.data, 'volRes', vanat.dims(1:3), ...
			  'refRes', wb.dims(1:3), 'volVoxelSize', vanat.voxelSize(1:3), ...
			  'refVoxelSize', wb.voxelSize(1:3));
	rx = rxSetXform(rx, init_wb2vol);
else
	rx = rxInit(vanat.data, wb.data, 'volRes', vanat.dims(1:3), ...
		  'refRes', wb.dims(1:3));
	rx.xform = init_wb2vol;
end

%% do the mutual-information based xform
rx = rxFineMutualInf(rx, 1, 1, 1, [4 2]);

%% now, check for user feedback:
% if we want this to be a manual step, we insert a uiwait, give the user a
% button to press to proceed (allowing for manual adjustments), and then
% grab the updated xform. Otherwise, we just return the current xform
if manualFlag==1
	uicontrol('Style', 'pushbutton', 'Units', 'normalized', ...
			  'Position',[.18 .45 .18 .18], 'String', 'Proceed to Step 2', ...
			  'BackgroundColor', [.4 1 .8], 'ForegroundColor', 'k', ...
			  'Callback', 'uiresume');	
	uiwait
end

wb2vol = rx.xform;

return


