function [vw corners] = atlasCreate(atlasName, ringWedgeScans, vw, ringWedgeFields)
% [vw corners] = atlasCreate(atlasName, ringWedgeScans, vw, ringWedgeFields)
%
% Author: Wandell, Brewer
% Purpose:
%    Create a set of quadrilaterals to define the visual areas.  The
%    collection of quadrilaterals and their format are selected by the
%    atlasName. Only one is currently implemented
%
%    atlasName = 'V1V2'
%    Others to come
%
% Example:
%   ringWedgeScans = [2,1];
%   atlasCreate('ventralV2V3V4', ringWedgeScans,FLAT{1});
%
%   atlasName = 'V1V2';
%   ringWedgeScans = [2,1];   % The ring scan num and the wedge scan num
%   FLAT{1} = atlasCreate(atlasName, [],FLAT{1});
% 
% History:
% 12/04/04 the part from line 46 to 67 rewritten by Mark Schira (mark@ski.org),
% using a projection which preserves the spatial distribution (for example of eccentricities)
% as a result isoeccenricity lines of two adjacent areas co-align, and the
% eccentricity profile of the original atlas is preserved.
% Author: Brewer, Wandell
%
% 04/09 ras added the 'ringWedgeFields' parameter. This lets us use data
% from a pRF model to fit an atlas (even if the data type only has one scan). 
if notDefined('atlasName'), error('You must define an atlas name.'); end
if notDefined('ringWedgeScans') | notDefined('ringWedgeFields'),
	[ringWedgeScans ringWedgeFields] = readRingWedgeScans; 
end
if notDefined('vw'), vw = getCurView; end
    
% Define the atlas that we will use for fitting
[visualField, corners, areaROI, retPhases, vw] = atlasDefinition(atlasName, ringWedgeScans, ringWedgeFields, vw);
nAreas = length(visualField);

% Save an intermediate copy of the atlas
save atlasintermed; 

% clear stdAtlasE stdAtlasA atlasCorners
atlasE = -1*ones(size(vw.ui.image));
atlasA = -1*ones(size(vw.ui.image));

for i=1:nAreas  
    if strcmp(atlasName, '2 hemifields + 2a') || strcmp(atlasName, '2 hemifields + 2a manual') || strcmp(atlasName, '4 hemifields')
        ii=nAreas+1-i;
    else
        ii=i;
    end
    
    % Create ideal atlaspieces into the Atlas containing
    [atlasPieceA,atlasPieceE] = perfectAtlaspiece(corners{ii}',char(visualField{ii}),retPhases);
    
    % Insert ideal atlaspeices into the Atlas containing
    atlasE = atlasMapPieceToDest_m(atlasE,atlasPieceE,min(corners{ii}),max(corners{ii}));
    atlasA = atlasMapPieceToDest_m(atlasA,atlasPieceA,min(corners{ii}),max(corners{ii}));
    
    %figure; imagesc(atlasE); colormap(hsv); colorbar('horiz'); axis image; title(num2str(ii)); grid on; hold
   
    % The mask values run from 0 ... nAreas-1
    % The values must be NaNs outside of the mask because of the
    % requirements in the fitting algorithm (warpXXX).    
     mask{ii} = NaN(vw.ui.imSize);
     mask{ii} = atlasMapPieceToDest_m(mask{ii},atlasPieceA,min(corners{ii}),max(corners{ii}));
     maskValue(ii) = ii - 1;
     mask{ii}(~isnan(mask{ii})) = maskValue(ii);
end


maskAll = NaN(vw.ui.imSize);
if strcmp(atlasName, '2 hemifields + 2a') || strcmp(atlasName, '2 hemifields + 2a manual') || strcmp(atlasName, '4 hemifields')
    for ii=1:nAreas
        maskAll(~isnan(mask{nAreas+1-ii})) = maskValue(nAreas+1-ii);
    end
else
    for ii=1:nAreas
        maskAll(~isnan(mask{ii})) = maskValue(ii);
    end
end

%filling possible little holes, to make the Atlas continuous
[atlasA,atlasE,maskAll]=atlasAjustHoles(atlasA,atlasE,maskAll);

atlasA = medfilt2(atlasA,[5,5]);   atlasA(isnan(maskAll)) = NaN;
atlasE = medfilt2(atlasE,[5,5]);   atlasE(isnan(maskAll)) = NaN;

% Now we use retPhases to adjust the standard atlas phases to match the
% data phases.  In the case of a collection of visual areas that includes a
% hemifield angular atlas, the base phase begins at pi/2.  So we subtract
% pi/2 from the atlas and add in retPhases(3). In the case of a
% quarterfield, the minimum phase can be either pi or pi/2.  So, we must
% subtract out either pi or pi/2 and then add back in the retPhases(3).
% minPhase = min(atlasA(atlasA > 0));
basePhase = atlasWedgePhases(visualField);

wedgePhaseShift = -basePhase + retPhases(3);
atlasAngle = shiftPhase(atlasA,wedgePhaseShift);
atlasAngle(isnan(maskAll)) = NaN;

% In the case of the eccentricity atlas, the base phase begins at zero.  So
% we simply add in retPhases(1).
ringPhaseShift = retPhases(1);
atlasEcc = shiftPhase(atlasE,ringPhaseShift);
atlasEcc(isnan(maskAll)) = NaN;
% figure; image(atlasEcc*(128/(2*pi))); colormap(hsv(128)); colorbar('horiz'); axis image

whichAtlas = atlasSelectAtlas;
if isempty(whichAtlas), return; end

hemisphere =  viewGet(vw, 'Current Slice');
atlasTypeList = {'angle', 'eccentricity'};
nAtlases = length(atlasTypeList);
atlasDim = dataSize(vw,1);

% If needed, create a new atlas.  Otherwise take the existing atlas
if whichAtlas == 0   % Create a new Atlas
    
    % Build the atlas sub-directory and data type.
    [atlasName,whichAtlas] = addAtlas2DataTYPE;

else
    % the previous code didn't seem to work; the function 'getAtlasView'
    % only returns a view if the Atlases data type is already selected.
    % Instead, we just replicate the input view, but select the Atlases
    % data type.
	
    % 
%     % We need to figure out which figure is showing the atlases
%     atlasView = getAtlasView;
    
    % Then we want to make sure it is showing the atlas the user is
    % editing.
    atlasView = selectDataType(vw, whichAtlas);

end

% update dataTYPES
% Copy the params from the first scan of the current data type (usually
% Averages or some other data) into the dataTYPE we will use for the
% new atlas. 
dtCopy(vw.curDataType, whichAtlas, atlasTypeList, hemisphere,...
		[wedgePhaseShift,ringPhaseShift], retPhases);

% Init the atlasView with the data in the currently selected atlas view.
atlasView = atlasInit(vw,atlasName,nAtlases,whichAtlas,atlasDim); 

% These are the atlas data.  There is a problem with the atlasAngle at one
% edge.  Look into why.
atlasView.ph{1}(:,:,hemisphere) = atlasAngle;
atlasView.ph{2}(:,:,hemisphere) = atlasEcc;

% This is the shape which gets deformed as the atlas fitting proceeds.  The
% edges are used as an overlay on the data so you can see the boundaries.
atlasView.co{1}(:,:,hemisphere) = round(maskAll);
atlasView.co{2}(:,:,hemisphere) = round(maskAll);

atlasView.amp{1}(:,:,hemisphere) = zeros(size(atlasAngle));
atlasView.amp{2}(:,:,hemisphere) = zeros(size(atlasEcc));

% Save files and update information in the atlas view.
saveSession;

saveCorAnal(atlasView,[],[],[],1,corners);

%% also save an atlas params file with all the parameters used to generate
%% the atlas.
srcDataType = getDataTypeName(vw);
atlasDataType = getDataTypeName(atlasView);

paramsFile = fullfile(dataDir(atlasView), 'atlasParams.mat');
save(paramsFile, 'atlasName', 'srcDataType', 'atlasDataType', 'corners', ...
	'retPhases', 'hemisphere', 'ringPhaseShift', 'wedgePhaseShift');
fprintf('[%s]: Saved parameters in %s.\t(%s)\n', mfilename, paramsFile, ...
		datestr(now));

return;
