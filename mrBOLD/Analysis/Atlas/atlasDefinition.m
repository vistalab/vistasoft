function [visualField,corners,areaROI, retPhases, view] = atlasDefinition(atlasName, scans, fields, view)
%   [visualField,corners,areaROI, retPhases, view] = atlasDefinition(atlasName, scans, fields, view)
%
% Author: Wandell, Brewer
% Purpose:
%    Define the properties of a group of retinotopic visual areas that
%    will serve as an atlas for template matching.
%
%   scans are the scanNums of the ring (scans(1)) and
%   wedge (scans(2)) data.
%
%
% INPUTS:
%	atlasName: name of atlas to fit.
%
%	scans: [2 x 1] vector of [eccentricity, polar angle] scan numbers for
%	the current data type in the flat view.
%
%	fields: {2 x 1} cell array of {eccentricity, polar angle} field names
%	(out of 'ph', 'map', 'amp', 'co') from which to draw the data.
%
%	view: flat view we're using to fit.
%
%
% [visualField,corners,areaROI,retPhases,view] = atlasDefinition('ventralV2V3V4',[2,1],FLAT{2});
%
% History:
% 15/11/04  marking V1/V2/V3 changed by MMS (mark@ski.org) so that you no
% longer mark V1 then V2 then V3 but just mark V1 and V3. V2 is then assumed
% to lie between.
% see line 282, I think this deal with the problems adressed in 272 by
% Wandell or Brewer
%
% ras, 04/09: many changes. 
% (1) takes as input parameters the field name, as well of the scan, of the
% ecc / polar angle data (to allow for pRF data fitting).
% (2) broke each atlas type into its own subfunction.
%

%% check we've passed in the proper input arguments
if ~isequal(view.viewType, 'Flat')
	error('Need a flat view.')
end

% show all ROIs
view.ui.showROIs=-2;
view = refreshView(view);

% % for some reason, we need to have the flat not rotated flipped. We should
% % fix this.
% if sum(abs([view.rotateImageDegrees,view.flipLR]))~=0
%     error('The fields ''.rotateImageDegrees'' and ''.flipLR'' of the FLAT structure must be zero.');
% end

% call the appropriate subfunction to fit the specified atlas.
switch lower(atlasName)
    case {'hemifield','hf'},
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitHemifield(view, scans, fields);  
    case {'lqf','lowerquarterfield'}
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitLowerQuarterfield(view, scans, fields);  
	case {'uqf','upperquarterfield'}		
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitUpperQuarterfield(view, scans, fields);  
    case {'hemiuppervf','hV4V3'}
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitV3_hV4(view, scans, fields);  
    case {'2hemifields','VO1VO2'}		
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitVO1_VO2(view, scans, fields);  
    case 'mt/mst circular'
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitMT_MST(view, scans, fields);  
	case 'v1/v2'		
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitV1_V2(view, scans, fields);  
    case 'v1/v2/v3'
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitV1_V2_V3(view, scans, fields);  		 
    case 'v4/v8'
        error('Not yet implemented: v4/v8');
    case {'lo2/to1/to2' '2 hemifields + 2a manual without LO1'}
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitLO2_TO1_TO2(view, scans, fields);  
	case '4 hemifields'
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fit4Hemifields(view, scans, fields);    		 
	case '4 hemifields old'
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fit4HemifieldsOld(view, scans, fields);    		 
    case 'common atlas with 4 hemifields'
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fit4HemifieldsCommonAtlas(view, scans, fields);    		 
    case '2 hemifields + 2a'
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fit2HemifieldsPlus2a(view, scans, fields);    		
    case '2 hemifields + 2a common'		 
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fit2HemifieldsPlus2aCommon(view, scans, fields);    		
    case {'v1/v2/v3/lo1/lo2' 'v1ToLO2'}
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitV1_to_LO2(view, scans, fields);  		 
    case {'v1/v2/v3/lo1/lo22' 'v1ToLO2_alt'}
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitV1_to_LO2_alt(view, scans, fields);  		 
    case {'v1/v2/v3/lo1/lo2/to1/to2' 'v1ToTO2'}
		 [view, visualField, corners, retPhases, areaROI] = ...
			 fitV1_to_TO2(view, scans, fields);  
    case 'ventralv2v3v4'
        [view,visualField,corners,retPhases,areaROI] = ...
			fitVentralV2V3V4(view, scans, fields);		
    otherwise
        error(sprintf('Unknown atlas name: %s', atlasName));		
end

% Show the user what just happened.
view = refreshView(view);

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitHemifield(view, scans, fields);
% Fit an unspecified hemifield representation.

% set up a string to make the message strings easier.	
newline = sprintf('\n');   % this will make the message strings easier.
msg = ['Select Hemifield in the data to which to fit the atlas.' newline ...
	   'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
	   'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
	   'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
	   'Point 4: HIGH eccentricity and LOW polar angle. '];


visualField{1} = 'hemifield';   %V1

corners = {};
msgHndl = mrMessage(msg, 'left', [], 9);

[locs, areaROI{1}, view] = atlasGraphicDefinition('quadrilateral',view);
corners{1} = locs.corners;
delete(msgHndl);

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);
		
return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [retPhases] = fitLowerQuarterfield(view, scans, fields);
% Fit an unspecified lower-quarter field representation.
newline = sprintf('\n');   % this will make the message strings easier.
msg = ['Select a Lower Quarter Field Representation in the data.' newline ...
	   'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
	   'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
	   'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
	   'Point 4: HIGH eccentricity and LOW polar angle. '];

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'lowerquarterfield';   % Dorsal V3, for example

corners = {};
msgHndl = mrMessage(msg{1},'left',[0.8000    0.1000    0.1800    0.1000]);

[locs, areaROI{1},view] = atlasGraphicDefinition('quadrilateral',view);
corners{1} = locs.corners;
delete(msgHndl);

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [retPhases] = fitUpperQuarterfield(view, scans, fields);
% Fit an unspecified upper-quarter field representation.
newline = sprintf('\n');   % this will make the message strings easier.
msg = ['Select an Upper Quarter Field Representation in the data.' newline ...
	   'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
	   'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
	   'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
	   'Point 4: HIGH eccentricity and LOW polar angle. '];

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'upperquarterfield';   % Dorsal V3, for example

corners = {};
msgHndl = mrMessage(msg{1},'left',[0.8000    0.1000    0.1800    0.1000]);

[locs, areaROI{1},view] = atlasGraphicDefinition('quadrilateral',view);
corners{1} = locs.corners;
delete(msgHndl);

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);
return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitV3_hV4(view, scans, fields);
% Fit an upper quarter field, plus a hemifield. 
% This fitting was designed to match ventral V3 and hV4.
newline = sprintf('\n');   % this will make the message strings easier.
msg{1} = ['Select the hemifield representation (e.g., hV4).' newline ...
		  'Point 1: LOW eccentricity and HIGH polar angle.' newline ... 
		  'Point 2: LOW eccentricity and LOW polar angle.' newline ...
		  'Point 3: HIGH eccentricity and LOW polar angle.' newline ...
		  'Point 4: HIGH eccentricity and HIGH polar angle. '];

msg{2}  = ['Select the quarterfield representation (e.g., V3v)' newline ...
		  'Point 1: LOW eccentricity and HIGH polar angle.' newline ... 
		  'Point 2: LOW eccentricity and LOW polar angle.' newline ...
		  'Point 3: HIGH eccentricity and LOW polar angle.' newline ...
		  'Point 4: HIGH eccentricity and HIGH polar angle. '];

visualField{1} = 'hemifield';           %hV4
visualField{2} = 'upperquarterfield';   %V3 Ventral


% load and display an example image to help guide the user in terms of
% which corners to click in which order:
codeDir = fileparts( which(mfilename) );
imgPath = fullfile(codeDir, 'Atlas_V3v_hV4_order.png');
try
	img = imread(imgPath, 'png');
	
	hGuide = figure('Color', 'w', 'Name', 'Click in this order', ...
					'Units', 'norm', 'Position', [0 .6 .3 .4], ...
					'NumberTitle', 'off');

	
	imshow(img);
	title('Select Points in the specified order.', 'FontSize', 18);
end



corners = {};
for ii=1:2

	msgHndl = mrMessage(msg{ii}, 'left', [], 9);
 
	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...
corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});

% Now replace the ROIs with the new ROIs with appropriately adjusted corners.
view = selectROI(view,areaROI{2});
view = replaceROIQuadrilateralCoords(view,corners{2});

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitVO1_VO2(view, scans, fields);
% Fit two hemifields (corresponding to VO-1 and VO-2).
newline = sprintf('\n');
msg{1} = ['Select the first hemifield representation (e.g., VO-1).' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];

msg{2}  = ['Select the second hemifield representation (e.g., VO-2)' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'hemifield';    %VO-1
visualField{2} = 'hemifield';    %VO-2

corners = {};
for ii=1:2
	msgHndl = mrMessage(msg{ii}, 'left', [], 9);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);
end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...
corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});

% Now replace the ROIs with the new ROIs with appropriately adjusted corners.
view = selectROI(view,areaROI{2});
view = replaceROIQuadrilateralCoords(view,corners{2});

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);
return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitMT_MST(view, scans, fields);
% Fit an atlas to a circular set of visual field representations around areas MT and MST (?).
newline = sprintf('\n');
msg  = ['Select fovea.' newline ...
		'Draw line one through fovea from high to low polar angle.' newline ...
		'Draw line two roughly orthogonal.'];

msgHndl = mrMessage(msg,'left', [], 9);

[x1,y1] = getline;
x1 = x1(1:2); y1 = y1(1:2);

[x2,y2] = getline;
x2 = x2(1:2); y2 = y2(1:2);

locs.x1 = x1; locs.x2 = x2; locs.y1 = y1; locs.y2 = y2;

im=makeCircularMaps(view,locs)


% Now replace the ROIs with the new ROIs with appropriately adjusted corners.
view = selectROI(view,areaROI{2});
view = replaceROIQuadrilateralCoords(view,corners{2});
view = selectROI(view,areaROI{3});
view = replaceROIQuadrilateralCoords(view,corners{3});

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);

delete(msgHndl);

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitV1_V2(view, scans, fields);
% Fit V1 (hemifield) and the two quarter fields of V2.
newline = sprintf('\n');
msg{1} = ['Select V1.' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];

msg{2}  = ['Select V2d (lower quarter field).' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];

msg{3}  = ['Select V2v (upper quarter field).' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];	  

visualField{1} = 'hemifield';   %V1
visualField{2} = 'lowerquarterfield'; %Dorsal V2
visualField{3} = 'upperquarterfield'; %Ventral V2

corners = {};
for ii=1:3

	msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.1800    0.1000]);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

	% Set view to show all ROI perimeters
	view.ui.showROIs=-2;
	view = refreshView(view);

end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...
corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});
corners{3} = atlasMergeAdjacentCorners(corners{1},corners{3});

% Now replace the ROIs with the new ROIs with appropriately adjusted corners.
view = selectROI(view,areaROI{2});
view = replaceROIQuadrilateralCoords(view,corners{2});
view = selectROI(view,areaROI{3});
view = replaceROIQuadrilateralCoords(view,corners{3});

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);
return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitV1_V2_V3(view, scans, fields);
% Fit V1, V2, and V3. 
newline = sprintf('\n');
msg{1} = ['Select V1.' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];

msg{2}  = ['Select V3v (upper quarter field).' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];

msg{3}  = ['Select V3d (lower quarter field).' newline ...
		  'Point 1: LOW eccentricity and LOW polar angle.' newline ... 
		  'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
		  'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
		  'Point 4: HIGH eccentricity and LOW polar angle. '];	  

visualField{1} = 'hemifield';   %V1
visualField{2} = 'lowerquarterfield'; % Ventral V2
visualField{3} = 'upperquarterfield'; % Dorsal V2
visualField{4} = 'lowerquarterfield'; % Ventral V3
visualField{5} = 'upperquarterfield'; % Dorsal V3

% load and display an example image to help guide the user in terms of
% which corners to click in which order:
codeDir = fileparts( which(mfilename) );
imgPath = fullfile(codeDir, 'Atlas_V1-V3_order.png');
try
	img = imread(imgPath, 'png');
	
	hGuide = figure('Color', 'w', 'Name', 'Click in this order', ...
					'Units', 'norm', 'Position', [0 .6 .3 .4], ...
					'NumberTitle', 'off');

	
	imshow(img);
	title('Select Points in the specified order.', 'FontSize', 18);
end


% get the corners of the 3 quadrilaterals (V1, V3v, V3d), which will define
% the 5 distinct field maps:
corners = {};
for ii=1:3
	msgHndl = mrMessage(msg{ii},'left',[],9);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

	% Set view to show all ROI perimeters
	view.ui.showROIs=-2;
	view = refreshView(view);
end

% close the guide figure as well
close(hGuide);

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...

% this old merging of corner  becomes obsolet
% corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});
% corners{3} = atlasMergeAdjacentCorners(corners{1},corners{3});
% corners{4} = atlasMergeAdjacentCorners(corners{2},corners{4});
% corners{5} = atlasMergeAdjacentCorners(corners{3},corners{5});

%instead get V2 corners from V1 and V3
%first copy corners of V3ventral and dorsal to pos 4 ad 5
corners{4}=corners{2};
corners{5}=corners{3};

%V2v
corners{2}(1,1:2)=corners{4}(1,1:2); %from V3v
corners{2}(2:3,1:2)=corners{1}(2:3,1:2); %from V1
corners{2}(4,1:2)=corners{4}(4,1:2); %from V3v

%V2d
corners{3}(1,1:2)=corners{1}(1,1:2); %from V1
corners{3}(2:3,1:2)=corners{5}(2:3,1:2); %from V1
corners{3}(4,1:2)=corners{1}(4,1:2);%from V1

%add the ROIS 4 and 5 to the ROI-List and to the "areaROI"-variable
%---- maybe there is a more elegant way to perform this....

found = roiExistName(view,'Quad',0)
if found == 0, num = 1; else num = length(found)+1; end
roiName = sprintf('Quad-%.0f',num);
view=newROI(view,roiName,1,[0 0 0]);
areaROI=cat(2,areaROI,{roiName});
roiName = sprintf('Quad-%.0f',num+1);
view=newROI(view,roiName,1,[0 0 0]);
areaROI=cat(2,areaROI,{roiName});

% Now replace the ROIs with the new ROIs with appropriately
% adjusted corners.  Simplified...
for jup=2:5
	view = selectROI(view,areaROI{jup});
	view = replaceROIQuadrilateralCoords(view,corners{jup});
end


% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);
retPhases = [0 pi*2 pi*0.5 pi*1.5];

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitLO2_TO1_TO2(view, scans, fields);
% select MT, MST, LO2 amd the wall of MST
msg{1}  = ['Select hemifield (e.g., TO1)' newline pointSpec];

msg{2}  = sprintf('Select hemifield (e.g., TO2)\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

msg{3}  = sprintf('Select quarterfield next to the first hemifield (e.g., LO2)\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{3},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{3} = addText(msg{3},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{3} = addText(msg{3},newText);

msg{4}  = sprintf('Select quarterfield next to the second hemifield\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{4},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{4} = addText(msg{4},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{4} = addText(msg{4},newText);

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'hemifield';    % TO1
visualField{2} = 'hemifield';    % TO2
visualField{3} = 'hemifield';    % LO2
visualField{4} = 'hemifield';    % wall
visualField{5} = 'hemifield';    % wall
visualField{6} = 'hemifield';    % wall
visualField{7} = 'hemifield';    % LO1

corners = {};
for ii=1:4
	msgHndl = mrMessage(msg{ii}, 'left', [], 9);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);
end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...
%         corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});
%         corners{3} = atlasMergeAdjacentCorners(corners{1},corners{3});
%         corners{4} = atlasMergeAdjacentCorners(corners{2},corners{4});

tmp=round((corners{1}(1,1:2)+corners{3}(1,1:2))/2);
corners{1}(1,1:2)=tmp;
corners{3}(1,1:2)=tmp;
tmp=round((corners{1}(4,1:2)+corners{3}(4,1:2))/2);
corners{1}(4,1:2)=tmp;
corners{3}(4,1:2)=tmp;

corners{7}(2:3,:) = corners{3}(2:3,:);
corners{7}(1,:) = corners{7}(2,:) + (corners{7}(2,:)-corners{3}(1,:));
corners{7}(4,:) = corners{7}(3,:) + (corners{7}(3,:)-corners{3}(4,:));

tmp=round((corners{1}(2:3,1:2)+corners{2}(2:3,1:2))/2);
corners{1}(2:3,1:2)=tmp;
corners{2}(2:3,1:2)=tmp;

tmp=round((corners{2}(1,1:2)+corners{4}(1,1:2))/2);
corners{2}(1,1:2)=tmp;
corners{4}(1,1:2)=tmp;

tmp=round((corners{2}(4,1:2)+corners{4}(4,1:2))/2);
corners{2}(4,1:2)=tmp;
corners{4}(4,1:2)=tmp;

corners{5}(1,1:2)=corners{1}(1,1:2);
corners{5}(2,1:2)=corners{2}(1,1:2);
corners{5}(3:4,1:2)=round([corners{5}(2,1:2); corners{5}(1,1:2)]*1.5-[corners{2}(4,1:2);corners{1}(4,1:2)]*0.5);
corners{5}(1,1:2)=corners{5}(1,1:2)+round((corners{5}(1,1:2)-corners{5}(4,1:2))*0.2);
corners{5}(2,1:2)=corners{5}(2,1:2)+round((corners{5}(2,1:2)-corners{5}(3,1:2))*0.2);

corners{6}(3,1:2)=corners{1}(4,1:2);
corners{6}(4,1:2)=corners{2}(4,1:2);
corners{6}(1:2,1:2)=round([corners{6}(4,1:2); corners{6}(3,1:2)]*1.5-[corners{2}(1,1:2);corners{1}(1,1:2)]*0.5);
corners{6}(3,1:2)=corners{6}(3,1:2)+round((corners{6}(3,1:2)-corners{6}(2,1:2))*0.2);
corners{6}(4,1:2)=corners{6}(4,1:2)+round((corners{6}(4,1:2)-corners{6}(1,1:2))*0.2);

found = roiExistName(view,'Quad',0)
if found == 0, num = 1; else num = length(found)+1; end

for newroi=1:3
	roiName = sprintf('Quad-%.0f',num+newroi-1);
	view=newROI(view,roiName,1,[0 0 0]);
	areaROI=cat(2,areaROI,{roiName});
end

% Now replace the ROIs with the new ROIs with appropriately
% adjusted corners.  Simplyfied...
for jup=1:7
	view = selectROI(view,areaROI{jup});
	view = replaceROIQuadrilateralCoords(view,corners{jup});
end

retPhases = [0 pi*2 pi/2 pi];
%         retPhases = [0 pi*2 pi/2 -pi/2];

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fit4HemifieldsOld(view, scans, fields);
% old version of the 4 hemifields fitting code (?).
% select MT, MST, LO2 amd LO1

        msg{1}  = sprintf('Select hemifield (e.g., TO1)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');  msg{1} = addText(msg{1},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{1} = addText(msg{1},newText);
        newText = sprintf('Continue to complete the quadrilateral');      msg{1} = addText(msg{1},newText);

        msg{2}  = sprintf('Select hemifield (e.g., TO2)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{2},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
        newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

        msg{3}  = sprintf('Select hemifield (e.g., LO2)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{3},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{3} = addText(msg{3},newText);
        newText = sprintf('Continue to complete the quadrilateral');  msg{3} = addText(msg{3},newText);

        msg{4}  = sprintf('Select hemifield (e.g., LO1)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{4},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{4} = addText(msg{4},newText);
        newText = sprintf('Continue to complete the quadrilateral');  msg{4} = addText(msg{4},newText);

        % This becomes, say, the V1/V2 function.
        % It gets its own message box and is a template for the creation of other
        % atlas creation routines.
        visualField{1} = 'hemifield';    % TO1
        visualField{2} = 'hemifield';    % TO2
        visualField{3} = 'hemifield';    % LO2
        visualField{4} = 'hemifield';    % wall
        visualField{5} = 'hemifield';    % wall
        visualField{6} = 'hemifield';    % wall
        visualField{7} = 'hemifield';    % LO1

        corners = {};
        for ii=1:4
            msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.1800    0.1000]);

            [locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
            corners{ii} = locs.corners;

            delete(msgHndl);

        end

        % We need a GUI for deciding who goes with what.  This ordering of the code
        % assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
        % We might make sure that we always get a certain corner match.  Sometimes,
        % two corners end up being matched to the same one ...
        %         corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});
        %         corners{3} = atlasMergeAdjacentCorners(corners{1},corners{3});
        %         corners{4} = atlasMergeAdjacentCorners(corners{2},corners{4});
        
        corners{7}=corners{4};
        
        % LO1 LO2 border
        tmp=round((corners{7}(2:3,1:2)+corners{3}(2:3,1:2))/2);
        corners{7}(2:3,1:2)=tmp;
        corners{3}(2:3,1:2)=tmp;
        
        % LO2 MT border
        tmp=round((corners{3}(1,1:2)+corners{1}(1,1:2))/2);
        corners{3}(1,1:2)=tmp;
        corners{1}(1,1:2)=tmp;
        tmp=round((corners{3}(4,1:2)+corners{1}(4,1:2))/2);
        corners{3}(4,1:2)=tmp;
        corners{1}(4,1:2)=tmp;
        
        % MT MST border
        tmp=round((corners{1}(2:3,1:2)+corners{2}(2:3,1:2))/2);
        corners{1}(2:3,1:2)=tmp;
        corners{2}(2:3,1:2)=tmp;
        
        % wall of MST
        corners{4}(1,:) = corners{2}(1,:);
        corners{4}(4,:) = corners{2}(4,:);
        corners{4}(2,:) = corners{4}(1,:) + round((corners{2}(1,:)-corners{2}(2,:))*0.3);
        corners{4}(3,:) = corners{4}(4,:) + round((corners{2}(4,:)-corners{2}(3,:))*0.3);

        % wall of MT, MST
        corners{5}(1,1:2)=corners{1}(1,1:2);
        corners{5}(2,1:2)=corners{2}(1,1:2);
        corners{5}(3:4,1:2)=round([corners{5}(2,1:2); corners{5}(1,1:2)]*1.3-[corners{2}(4,1:2);corners{1}(4,1:2)]*0.3);
        corners{5}(1,1:2)=corners{5}(1,1:2)+round((corners{5}(1,1:2)-corners{5}(4,1:2))*0.2);
        corners{5}(2,1:2)=corners{5}(2,1:2)+round((corners{5}(2,1:2)-corners{5}(3,1:2))*0.2);

        % wall of MT, MST
        corners{6}(3,1:2)=corners{1}(4,1:2);
        corners{6}(4,1:2)=corners{2}(4,1:2);
        corners{6}(1:2,1:2)=round([corners{6}(4,1:2); corners{6}(3,1:2)]*1.3-[corners{2}(1,1:2);corners{1}(1,1:2)]*0.3);
        corners{6}(3,1:2)=corners{6}(3,1:2)+round((corners{6}(3,1:2)-corners{6}(2,1:2))*0.2);
        corners{6}(4,1:2)=corners{6}(4,1:2)+round((corners{6}(4,1:2)-corners{6}(1,1:2))*0.2);
        
        % not to exceed the area
        corners{4}(find(corners{4}<1))=1;
        corners{4}(find(corners{4}>size(view.anat,1)))=size(view.anat,1);
        corners{5}(find(corners{5}<1))=1;
        corners{5}(find(corners{5}>size(view.anat,1)))=size(view.anat,1);
        corners{6}(find(corners{6}<1))=1;
        corners{6}(find(corners{6}>size(view.anat,1)))=size(view.anat,1);

%         for i=1:4
%             if norm(corners{5}(i,:)-(size(view.anat,1)+1)/2)>(size(view.anat,1)-1)/2*sqrt(2);
%                 corners{5}(i,:) = floor(corners{5}(i,:)/norm(corners{5}(i,:)-(size(view.anat,1)-1)/2)*(size(view.anat,1)+1)/2)
%             end
%         end
        
        found = roiExistName(view,'Quad',0)
        if found == 0, num = 1; else num = length(found)+1; end

        for newroi=1:3
            roiName = sprintf('Quad-%.0f',num+newroi-1);
            view=newROI(view,roiName,1,[0 0 0]);
            areaROI=cat(2,areaROI,{roiName});
        end

        % Now replace the ROIs with the new ROIs with appropriately
        % adjusted corners.  Simplyfied...
        for jup=1:7
            view = selectROI(view,areaROI{jup});
            view = replaceROIQuadrilateralCoords(view,corners{jup});
        end

        retPhases = [0 pi*2 pi/2 pi];
        %         retPhases = [0 pi*2 pi/2 -pi/2];

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view, visualField, corners, retPhases, areaROI] = fit4Hemifields(view, scans, fields)
% Fit 4 adjacent hemifields -- designed as a model for
% TO1, TO2, LO2 amd LO1 + wall of LO1 and MST
        clear msg

        msg{1}  = sprintf('Select hemifield (e.g., LO1)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');  msg{1} = addText(msg{1},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{1} = addText(msg{1},newText);
        newText = sprintf('Continue to complete the quadrilateral');      msg{1} = addText(msg{1},newText);

        msg{2}  = sprintf('Select hemifield (e.g., LO2)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{2},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
        newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

        msg{3}  = sprintf('Select hemifield (e.g., TO1)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{3},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{3} = addText(msg{3},newText);
        newText = sprintf('Continue to complete the quadrilateral');  msg{3} = addText(msg{3},newText);

        msg{4}  = sprintf('Select hemifield (e.g., TO2)\n');
        newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{4},newText);
        newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{4} = addText(msg{4},newText);
        newText = sprintf('Continue to complete the quadrilateral');  msg{4} = addText(msg{4},newText);

        % This becomes, say, the V1/V2 function.
        % It gets its own message box and is a template for the creation of other
        % atlas creation routines.
        visualField{1} = 'hemifield';    % LO1
        visualField{2} = 'hemifield';    % LO2
        visualField{3} = 'hemifield';    % TO1
        visualField{4} = 'hemifield';    % TO2
        visualField{5} = 'upperquarterfield';    % wall of LO1
        visualField{6} = 'upperquarterfield';    % wall of TO2

        corners = {};
        for ii=1:4
            msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.1800    0.1000]);

            [locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
            corners{ii} = locs.corners;

            delete(msgHndl);

        end

        % LO1 LO2 border
        tmp=round((corners{1}(2:3,1:2)+corners{2}(2:3,1:2))/2);
        corners{1}(2:3,1:2)=tmp;
        corners{2}(2:3,1:2)=tmp;
        
        % LO2 TO1 border
        tmp=round((corners{2}(1,1:2)+corners{3}(1,1:2))/2);
        corners{2}(1,1:2)=tmp;
        corners{3}(1,1:2)=tmp;
        tmp=round((corners{2}(4,1:2)+corners{3}(4,1:2))/2);
        corners{2}(4,1:2)=tmp;
        corners{3}(4,1:2)=tmp;
        
        % TO1 TO2 border
        tmp=round((corners{3}(2:3,1:2)+corners{4}(2:3,1:2))/2);
        corners{3}(2:3,1:2)=tmp;
        corners{4}(2:3,1:2)=tmp;
        
        % wall of LO1
        corners{5}(1,:) = corners{1}(1,:);
        corners{5}(4,:) = corners{1}(4,:);
        corners{5}(2,:) = corners{5}(1,:) + round((corners{1}(1,:)-corners{1}(2,:))*0.5);
        corners{5}(3,:) = corners{5}(4,:) + round((corners{1}(4,:)-corners{1}(3,:))*0.5);

        % wall of TO2
        corners{6}(1,:) = corners{4}(1,:);
        corners{6}(4,:) = corners{4}(4,:);
        corners{6}(2,:) = corners{6}(1,:) + round((corners{4}(1,:)-corners{4}(2,:))*0.5);
        corners{6}(3,:) = corners{6}(4,:) + round((corners{4}(4,:)-corners{4}(3,:))*0.5);
        
        % not to exceed the area
        corners{5}(find(corners{5}<1))=1;
        corners{5}(find(corners{5}>size(view.anat,1)))=size(view.anat,1);
        corners{6}(find(corners{6}<1))=1;
        corners{6}(find(corners{6}>size(view.anat,1)))=size(view.anat,1);
       
        found = roiExistName(view,'Quad',0)
        if found == 0, num = 1; else num = length(found)+1; end

        for newroi=1:2
            roiName = sprintf('Quad-%.0f',num+newroi-1);
            view=newROI(view,roiName,1,[0 0 0]);
            areaROI=cat(2,areaROI,{roiName});
        end

        % Now replace the ROIs with the new ROIs with appropriately
        % adjusted corners.  Simplyfied...
        for jup=1:6
            view = selectROI(view,areaROI{jup});
            view = replaceROIQuadrilateralCoords(view,corners{jup});
        end

        retPhases = [0 pi*2 pi/2 pi];
        %         retPhases = [0 pi*2 pi/2 -pi/2];

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fit4HemifieldsCommonAtlas(view, scans, fields);


        % select MT, MST, LO2 amd LO1

        visualField{1} = 'hemifield';    % TO1
        visualField{2} = 'hemifield';    % TO2
        visualField{3} = 'hemifield';    % LO2
        visualField{4} = 'hemifield';    % wall
        visualField{5} = 'hemifield';    % wall
        visualField{6} = 'hemifield';    % wall
        visualField{7} = 'hemifield';    % LO1

        corners = {};
        
        corners{1} = [40 50; 40 65; 80 65; 80 50];
        corners{2} = [40 80; 40 65; 80 65; 80 80];
        corners{3} = [40 50; 40 35; 80 35; 80 50];
        corners{4} = [40 80; 40 95; 80 95; 80 80];
        corners{5} = [40 50; 40 80; 20 80; 20 50];
        corners{6} = [100 80; 100 50; 80 50; 80 80];
        corners{7} = [40 20; 40 35; 80 35; 80 20];
        
        num=1;
        areaROI=[];
        for newroi=1:7
            roiName = sprintf('Quad-%.0f',num+newroi-1);
            view=newROI(view,roiName,1,[0 0 0]);
            areaROI=cat(2,areaROI,{roiName});
        end
        
        % Now replace the ROIs with the new ROIs with appropriately
        % adjusted corners.  Simplyfied...
        for jup=1:7
            view = selectROI(view,areaROI{jup});
            view = replaceROIQuadrilateralCoords(view,corners{jup});
        end

        retPhases = [0 pi*2 pi/2 pi];

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fit2HemifieldsPlus2a(view, scans, fields);
% Don't know what this means. It was specified as case '2 hemifields +  2a'
% at top. I'm guessing it's just TO-1 and TO-2?
msg{1}  = sprintf('Select hemifield (e.g., TO1)\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');  msg{1} = addText(msg{1},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{1} = addText(msg{1},newText);
newText = sprintf('Continue to complete the quadrilateral');      msg{1} = addText(msg{1},newText);

msg{2}  = sprintf('Select hemifield (e.g., TO2)\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'hemifield';    %TO-1
visualField{2} = 'hemifield';    %TO-2
visualField{3} = 'upperquarterfield';    %LO2
visualField{4} = 'upperquarterfield';    %MST2
%         visualField{3} = 'hemifield';    %LO2
%         visualField{4} = 'hemifield';    %MST2
visualField{5} = 'hemifield';    %V3d
visualField{6} = 'hemifield';    %MST2

corners = {};
for ii=1:2
	msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.1800    0.1000]);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...
%         corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});
%         corners{3} = atlasMergeAdjacentCorners(corners{1},corners{3});
%         corners{4} = atlasMergeAdjacentCorners(corners{2},corners{4});


tmp=round((corners{1}(2:3,1:2)+corners{2}(2:3,1:2))/2);
corners{1}(2:3,1:2)=tmp;
corners{2}(2:3,1:2)=tmp;

%         corners{1}(2,1:2)=corners{1}(2,1:2)+abs(corners{1}(2,1:2)-corners{1}(3,1:2));
%         corners{1}(3,1:2)=corners{1}(3,1:2)+abs(corners{1}(3,1:2)-corners{1}(2,1:2));
%         corners{2}(2,1:2)=corners{2}(2,1:2)+abs(corners{2}(2,1:2)-corners{2}(3,1:2));
%         corners{2}(3,1:2)=corners{2}(3,1:2)+abs(corners{2}(3,1:2)-corners{2}(2,1:2));

corners{3}(1,1:2)=corners{1}(1,1:2);
corners{3}(4,1:2)=corners{1}(4,1:2);
corners{3}(2:3,1:2)=[corners{1}(1,1:2);corners{1}(4,1:2)]*2-corners{1}(2:3,1:2);

corners{4}(1,1:2)=corners{2}(1,1:2);
corners{4}(4,1:2)=corners{2}(4,1:2);
corners{4}(2:3,1:2)=[corners{2}(1,1:2);corners{2}(4,1:2)]*2-corners{2}(2:3,1:2);

corners{5}(1,1:2)=corners{1}(1,1:2);
corners{5}(2,1:2)=corners{2}(1,1:2);
corners{5}(3:4,1:2)=round([corners{5}(2,1:2); corners{5}(1,1:2)]*1.5-[corners{2}(4,1:2);corners{1}(4,1:2)]*0.5);
corners{5}(1,1:2)=corners{5}(1,1:2)+round((corners{5}(1,1:2)-corners{5}(4,1:2))*0.2);
corners{5}(2,1:2)=corners{5}(2,1:2)+round((corners{5}(2,1:2)-corners{5}(3,1:2))*0.2);

corners{6}(3,1:2)=corners{1}(4,1:2);
corners{6}(4,1:2)=corners{2}(4,1:2);
corners{6}(1:2,1:2)=round([corners{6}(4,1:2); corners{6}(3,1:2)]*1.5-[corners{2}(1,1:2);corners{1}(1,1:2)]*0.5);
corners{6}(3,1:2)=corners{6}(3,1:2)+round((corners{6}(3,1:2)-corners{6}(2,1:2))*0.2);
corners{6}(4,1:2)=corners{6}(4,1:2)+round((corners{6}(4,1:2)-corners{6}(1,1:2))*0.2);


found = roiExistName(view,'Quad',0)
if found == 0, num = 1; else num = length(found)+1; end

for newroi=1:4
	roiName = sprintf('Quad-%.0f',num+newroi-1);
	view=newROI(view,roiName,1,[0 0 0]);
	areaROI=cat(2,areaROI,{roiName});
end

% Now replace the ROIs with the new ROIs with appropriately
% adjusted corners.  Simplyfied...
for jup=1:6
	view = selectROI(view,areaROI{jup});
	view = replaceROIQuadrilateralCoords(view,corners{jup});
end

retPhases = [0 pi*2 pi/2 pi];

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fit2HemifieldsPlus2aCommon(view, scans, fields);
% Don't know what this means. It was specified as case '2 hemifields +  2a common'
% at top. I'm guessing it's just TO-1 and TO-2, sharing a common boundary?
msg{1}  = sprintf('Select hemifield (e.g., TO1)\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');  msg{1} = addText(msg{1},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{1} = addText(msg{1},newText);
newText = sprintf('Continue to complete the quadrilateral');      msg{1} = addText(msg{1},newText);

msg{2}  = sprintf('Select hemifield (e.g., TO2)\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'hemifield';    %TO-1
visualField{2} = 'hemifield';    %TO-2
visualField{3} = 'upperquarterfield';    %LO2
visualField{4} = 'upperquarterfield';    %MST2
visualField{5} = 'hemifield';    %V3d
visualField{6} = 'hemifield';    %MST2

corners = {};
for ii=1:2
	msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.1800    0.1000]);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

end

corners{1}=[50 50; 50 65; 70 65; 70 50];
corners{2}=[50 80; 50 65; 70 65; 70 80];

corners{3}(1,1:2)=corners{1}(1,1:2);
corners{3}(4,1:2)=corners{1}(4,1:2);
corners{3}(2:3,1:2)=[corners{1}(1,1:2);corners{1}(4,1:2)]*2-corners{1}(2:3,1:2);

corners{4}(1,1:2)=corners{2}(1,1:2);
corners{4}(4,1:2)=corners{2}(4,1:2);
corners{4}(2:3,1:2)=[corners{2}(1,1:2);corners{2}(4,1:2)]*2-corners{2}(2:3,1:2);

corners{5}(1,1:2)=corners{1}(1,1:2);
corners{5}(2,1:2)=corners{2}(1,1:2);
corners{5}(3:4,1:2)=round([corners{5}(2,1:2); corners{5}(1,1:2)]*1.5-[corners{2}(4,1:2);corners{1}(4,1:2)]*0.5);
%         corners{5}(1,1:2)=corners{5}(1,1:2)+round((corners{5}(1,1:2)-corners{5}(4,1:2))*0.2);
%         corners{5}(2,1:2)=corners{5}(2,1:2)+round((corners{5}(2,1:2)-corners{5}(3,1:2))*0.2);

corners{6}(3,1:2)=corners{1}(4,1:2);
corners{6}(4,1:2)=corners{2}(4,1:2);
corners{6}(1:2,1:2)=round([corners{6}(4,1:2); corners{6}(3,1:2)]*1.5-[corners{2}(1,1:2);corners{1}(1,1:2)]*0.5);
%         corners{6}(3,1:2)=corners{6}(3,1:2)+round((corners{6}(3,1:2)-corners{6}(2,1:2))*0.2);
%         corners{6}(4,1:2)=corners{6}(4,1:2)+round((corners{6}(4,1:2)-corners{6}(1,1:2))*0.2);


found = roiExistName(view,'Quad',0)
if found == 0, num = 1; else num = length(found)+1; end

for newroi=1:4
	roiName = sprintf('Quad-%.0f',num+newroi-1);
	view=newROI(view,roiName,1,[0 0 0]);
	areaROI=cat(2,areaROI,{roiName});
end

% Now replace the ROIs with the new ROIs with appropriately
% adjusted corners.  Simplyfied...
for jup=1:6
	view = selectROI(view,areaROI{jup});
	view = replaceROIQuadrilateralCoords(view,corners{jup});
end

retPhases = [0 pi*2 pi/2 pi];
%         retPhases = [0 pi*2 pi/2 -pi/2];

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitV1_to_TO2(view, scans, fields);
% Fit 7 visual field maps: V1, V2, V3, LO-1, LO-2, TO-1, TO-2.
clear msg

newline = sprintf('\n');
pointsOrder = ['Point 1: LOW eccentricity and LOW polar angle.' newline ... 
				'Point 2: LOW eccentricity and HIGH polar angle.' newline ...
				'Point 3: HIGH eccentricity and HIGH polar angle.' newline ...
				'Point 4: HIGH eccentricity and LOW polar angle. '];

msg{1}  = ['Select V1.' newline pointsOrder];
msg{2}  = ['Select V3v.' newline pointsOrder];
msg{3}  = ['Select V3d.' newline pointsOrder];
msg{4}  = ['Select LO2.' newline pointsOrder];
msg{5}  = ['Select TO2.' newline pointsOrder]

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'hemifield';   % V1
visualField{2} = 'lowerquarterfield'; % V3v
visualField{3} = 'upperquarterfield'; % V3d
visualField{4} = 'hemifield';   % LO2
visualField{5} = 'hemifield';   % TO2
visualField{6} = 'lowerquarterfield'; % V2v
visualField{7} = 'upperquarterfield'; % V2d
visualField{8} = 'hemifield';   %LO1
visualField{9} = 'hemifield';   %TO1

corners = {};
for ii=1:5
	msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.200    0.1200]);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

	% Set view to show all ROI perimeters
	view.ui.showROIs=-2;
	view = refreshView(view);
end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...

%V2v
corners{6}(1,1:2)=corners{2}(1,1:2); %from V3v
corners{6}(2:3,1:2)=corners{1}(2:3,1:2); %from V1
corners{6}(4,1:2)=corners{2}(4,1:2); %from V3v

%V2d
corners{7}(1,1:2)=corners{1}(1,1:2); %from V1
corners{7}(2:3,1:2)=corners{3}(2:3,1:2); %from V3d
corners{7}(4,1:2)=corners{1}(4,1:2);%from V1

%LO1
corners{8}(1,1:2)=corners{3}(1,1:2); %from V3d
corners{8}(2:3,1:2)=corners{4}(2:3,1:2); %from LO2
corners{8}(4,1:2)=corners{3}(4,1:2);%from V3d

%TO1
corners{9}(1,1:2)=corners{4}(1,1:2); %from LO2
corners{9}(2:3,1:2)=corners{5}(2:3,1:2); %from TO2
corners{9}(4,1:2)=corners{4}(4,1:2);%from LO2

%add the ROIS 6-9 to the ROI-List and to the "areaROI"-variable
%---- maybe there is a more elegante way to perform this....

found = roiExistName(view,'Quad',0)
if found == 0, num = 1; else num = length(found)+1; end

for newroi=1:4
	roiName = sprintf('Quad-%.0f',num+newroi-1);
	view=newROI(view,roiName,1,[0 0 0]);
	areaROI=cat(2,areaROI,{roiName});
end

% Now replace the ROIs with the new ROIs with appropriately
% adjusted corners.  Simplyfied...
for jup=2:9
	view = selectROI(view,areaROI{jup});
	view = replaceROIQuadrilateralCoords(view,corners{jup});
end

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitV1_to_LO2_alt(view, scans, fields);
% I'm guessing this is an alternate version of the V1->LO2 fitting?
% It fits v1/v2/v3/lo1/lo2. 
msg{1}  = sprintf('Select V1.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');  msg{1} = addText(msg{1},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{1} = addText(msg{1},newText);
newText = sprintf('Continue to complete the quadrilateral.\n');      msg{1} = addText(msg{1},newText);
newText = sprintf('NEW: After marking V1, continue with marking V3v, just with the same scheme.\n');msg{1} = addText(msg{1},newText);

msg{2}  = sprintf('Select V3v.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

msg{3}  = sprintf('Select V3d.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{3} = addText(msg{3},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{3} = addText(msg{3},newText);
newText = sprintf('Continue to complete the quadrilateral');   msg{3} = addText(msg{3},newText);

msg{4}  = sprintf('Select LO2.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{4} = addText(msg{4},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{4} = addText(msg{4},newText);
newText = sprintf('Continue to complete the quadrilateral');   msg{4} = addText(msg{4},newText);

visualField{1} = 'hemifield';   % V1
visualField{2} = 'lowerquarterfield'; % V3v
visualField{3} = 'upperquarterfield'; % V3d
visualField{4} = 'hemifield';   % LO2
visualField{5} = 'lowerquarterfield'; % V2v
visualField{6} = 'upperquarterfield'; % V2d
visualField{7} = 'hemifield';   %LO1

corners = {};
for ii=1:4
	msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.200    0.1200]);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

	% Set view to show all ROI perimeters
	view.ui.showROIs=-2;
	view = refreshView(view);
end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...

%V2v
corners{5}(1,1:2)=corners{2}(1,1:2); %from V3v
corners{5}(2:3,1:2)=corners{1}(2:3,1:2); %from V1
corners{5}(4,1:2)=corners{2}(4,1:2); %from V3v

%V2d
corners{6}(1,1:2)=corners{1}(1,1:2); %from V1
corners{6}(2:3,1:2)=corners{3}(2:3,1:2); %from V3d
corners{6}(4,1:2)=corners{1}(4,1:2);%from V1

%LO1
corners{7}(1,1:2)=corners{3}(1,1:2); %from V3d
corners{7}(2:3,1:2)=corners{4}(2:3,1:2); %from LO2
corners{7}(4,1:2)=corners{3}(4,1:2);%from V3d


%add the ROIS 6-9 to the ROI-List and to the "areaROI"-variable
%---- maybe there is a more elegante way to perform this....

found = roiExistName(view,'Quad',0)
if found == 0, num = 1; else num = length(found)+1; end

for newroi=1:3
	roiName = sprintf('Quad-%.0f',num+newroi-1);
	view=newROI(view,roiName,1,[0 0 0]);
	areaROI=cat(2,areaROI,{roiName});
end

% Now replace the ROIs with the new ROIs with appropriately
% adjusted corners.  Simplyfied...
for jup=2:9
	view = selectROI(view,areaROI{jup});
	view = replaceROIQuadrilateralCoords(view,corners{jup});
end

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);
return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view visualField corners retPhases areaROI] = fitV1_to_LO2(view, scans, fields);
% fits V1, V2, V3, LO1, and LO2.
msg{1}  = sprintf('Select V1.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');  msg{1} = addText(msg{1},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{1} = addText(msg{1},newText);
newText = sprintf('Continue to complete the quadrilateral.\n');      msg{1} = addText(msg{1},newText);
newText = sprintf('NEW: After marking V1, continue with marking V3v, just with the same scheme.\n');msg{1} = addText(msg{1},newText);

msg{2}  = sprintf('Select lower quarter field of V3.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

msg{3}  = sprintf('Select upper quarter field of V3.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{3} = addText(msg{3},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{3} = addText(msg{3},newText);
newText = sprintf('Continue to complete the quadrilateral');   msg{3} = addText(msg{3},newText);

msg{4}  = sprintf('Select LO2.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');msg{4} = addText(msg{4},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{4} = addText(msg{4},newText);
newText = sprintf('Continue to complete the quadrilateral');   msg{4} = addText(msg{4},newText);

% This becomes, say, the V1/V2 function.
% It gets its own message box and is a template for the creation of other
% atlas creation routines.
visualField{1} = 'hemifield';   % V1
visualField{2} = 'lowerquarterfield'; % V3v
visualField{3} = 'upperquarterfield'; % V3d
visualField{4} = 'hemifield';   % LO2
visualField{5} = 'lowerquarterfield'; % V2v
visualField{6} = 'upperquarterfield'; % V2d
visualField{7} = 'hemifield';   %LO1

corners = {};
for ii=1:4
	msgHndl = mrMessage(msg{ii}, 'left', [], 9);

	[locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
	corners{ii} = locs.corners;

	delete(msgHndl);

	% Set view to show all ROI perimeters
	view.ui.showROIs=-2;
	view = refreshView(view);

end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...

%V2v
corners{5}(1,1:2)=corners{2}(1,1:2); %from V3v
corners{5}(2:3,1:2)=corners{1}(2:3,1:2); %from V1
corners{5}(4,1:2)=corners{2}(4,1:2); %from V3v

%V2d
corners{6}(1,1:2)=corners{1}(1,1:2); %from V1
corners{6}(2:3,1:2)=corners{3}(2:3,1:2); %from V3d
corners{6}(4,1:2)=corners{1}(4,1:2);%from V1

%LO1
corners{7}(1,1:2)=corners{3}(1,1:2); %from V3d
corners{7}(2:3,1:2)=corners{4}(2:3,1:2); %from LO2
corners{7}(4,1:2)=corners{3}(4,1:2);%from V3d

%add the ROIS 6-9 to the ROI-List and to the "areaROI"-variable
%---- maybe there is a more elegante way to perform this....

found = roiExistName(view,'Quad',0)
if found == 0, num = 1; else num = length(found)+1; end

for newroi=1:3
	roiName = sprintf('Quad-%.0f',num+newroi-1);
	view=newROI(view,roiName,1,[0 0 0]);
	areaROI=cat(2,areaROI,{roiName});
end

% Now replace the ROIs with the new ROIs with appropriately
% adjusted corners.  Simplyfied...
for jup=2:7
	view = selectROI(view,areaROI{jup});
	view = replaceROIQuadrilateralCoords(view,corners{jup});
end

% Use the data to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);

return
% /-----------------------------------------------------------------/ %
	

	

% /-----------------------------------------------------------------/ %	
function [view, visualField, corners, retPhases, areaROI] = fitVentralV2V3V4(view, scans, fields)
% Fit the ventral V2/V3/hV4 atlas.

msg{1}  = sprintf('Select ventral V2.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n');  msg{1} = addText(msg{1},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{1} = addText(msg{1},newText);
newText = sprintf('Continue to complete the quadrilateral');      msg{1} = addText(msg{1},newText);

msg{2}  = sprintf('Select ventral V3.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n'); msg{2} = addText(msg{2},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n');msg{2} = addText(msg{2},newText);
newText = sprintf('Continue to complete the quadrilateral');  msg{2} = addText(msg{2},newText);

msg{3}  = sprintf('Select ventral V4.\n');
newText = sprintf('Point 1: low eccentricity and angle phases.\n'); msg{3} = addText(msg{3},newText);
newText = sprintf('Point 2: low eccentricity phase and high angle phase.\n'); msg{3} = addText(msg{3},newText);
newText = sprintf('Continue to complete the quadrilateral');   msg{3} = addText(msg{3},newText);

visualField{1} = 'upperquarterfield';   % Ventral V2
visualField{2} = 'upperquarterfield';   %Ventral V3
visualField{3} = 'upperquarterfield';   %Ventral V4

corners = {};

% Set view to show all ROI perimeters
view.ui.showROIs=-2;
view = refreshView(view);
for ii=1:3
    msgHndl = mrMessage(msg{ii},'left',[0.8000    0.1000    0.1800    0.1000]);

    [locs, areaROI{ii},view] = atlasGraphicDefinition('quadrilateral',view);
    corners{ii} = locs.corners;

    delete(msgHndl);
    view = refreshView(view);
end

% We need a GUI for deciding who goes with what.  This ordering of the code
% assumes that visualArea{1} is in the middle and 2 and 3 are surrounding it.
% We might make sure that we always get a certain corner match.  Sometimes,
% two corners end up being matched to the same one ...
corners{2} = atlasMergeAdjacentCorners(corners{1},corners{2});
corners{3} = atlasMergeAdjacentCorners(corners{2},corners{3});

% Now replace the ROIs with the new ROIs with appropriately adjusted corners.
view = selectROI(view,areaROI{2});
view = replaceROIQuadrilateralCoords(view,corners{2});
view = selectROI(view,areaROI{3});
view = replaceROIQuadrilateralCoords(view,corners{3});

% Use the data in the first one to estimate the phases
c{1} = corners{1};
retPhases = atlasEstimatePhases(view, c, scans, fields);

return;
