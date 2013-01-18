function atlasStore(vw, images, whichAtlas, curSlice)
% Store angle and ecc atlas data into an atlas datatype in a flat view
% (incorporated from "atlasCreate.m").
%  
% atlasStore(vw, images, whichAtlas, curSlice)
%
% Example
%   vw = FLAT{1};
%   atlasStore(vw,images,[],[]);
%
% Author: KA, BW

global dataTYPES

% Check arguments
if notDefined('vw'),            vw = getCurView; end
if notDefined('images'),        error('images must be defined'); end
if notDefined('whichAtlas'),    whichAtlas = atlasSelectAtlas; end
if notDefined('curSlice'),      curSlice = viewGet(vw, 'Current Slice'); end

sz = viewGet(vw,'anatSize');
atlasAngle = imresize(images.dA2,sz(1)/size(images.dA2,1),'Method','nearest');
atlasEcc = imresize(images.dA1,sz(1)/size(images.dA1,1),'Method','nearest');
areasImg = imresize(double(images.dareasImg),sz(1)/size(images.dareasImg,1),'Method','nearest');

atlasTypeList = {'angle', 'eccentricity'};
nAtlases = length(atlasTypeList);
atlasDim = dataSize(vw,1);

% If needed, create a new atlas.  Otherwise take the existing atlas
if whichAtlas == 0   % Create a new Atlas    
    % Build the atlas sub-directory and data type.
    [atlasName,whichAtlas] = addAtlas2DataTYPE;
else
    atlasName = dataTYPES(whichAtlas).name;
end

% update dataTYPES
% Copy the params from the first scan of the current data type (usually
% Averages or some other readl data) into the dataTYPE we will use for the
% new atlas. 
wedgePhaseShift=0;
ringPhaseShift = 0;
retPhases = [0 pi*2 pi/2 pi];

dtCopy(vw.curDataType,whichAtlas,atlasTypeList,curSlice,...
    [wedgePhaseShift,ringPhaseShift],retPhases);

% Init the atlasView with the data in the currently selected atlas view.
atlasView = atlasInit(vw,atlasName,nAtlases,whichAtlas,atlasDim); 

% These are the atlas data.  There is a problem with the atlasAngle at one
% edge.  Look into why.
atlasView.ph{1}(:,:,curSlice) = atlasAngle;
atlasView.ph{2}(:,:,curSlice) = atlasEcc;

% This is the shape which gets deformed as the atlas fitting proceeds.  The
% edges are used as an overlay on the data so you can see the boundaries.
atlasView.co{1}(:,:,curSlice) = round(areasImg);
atlasView.co{2}(:,:,curSlice) = round(areasImg);

atlasView.amp{1}(:,:,curSlice) = zeros(size(atlasAngle));
atlasView.amp{2}(:,:,curSlice) = zeros(size(atlasEcc));

% Save files and update information in the atlas view.
saveSession;
saveCorAnal(atlasView,[],[],[],1);

return;
