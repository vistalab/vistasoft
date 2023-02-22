function createAtlas(vw, numAreas)
%
%    createAtlas(vw, [numAreas])
%
% Creates a new dataType 'Atlases-XX'
% There can be several Atlases-XX directories, each with its own coranal.
% Each can be opened in its own separate FLAT window.
% To simply open one, select its dataTYPE pull down on the upper-right of
% the FLAT window.
%
% TODO:
%   Be more flexible in terms of atlas geometry.
%   Allow the phases to be set by clicking on the data in the flat view.
%   Write a GUIDE interface window for doing all of the Atlas fitting.
% HISTORY:
%   2002.03.07 RFD (bob@white.stanford.edu) wrote it.
%   2003.03.10 RFD fixed a bug that caused an incorrect image size when 
%   the atlas was created with the atlas window already open.
%   2003.09.11 BW Introduced sub-routines towards generalizing to a
%   larger variety of possible atlases.

if ~strcmp(vw.viewType,'Flat'), myErrorDlg([mfilename,' only for Flat view.']); end
if ~exist('numAreas','var') | isempty(numAreas), queryNumAreas = 1; end

mrGlobals;
global HOMEDIR;

% Check which, if any, the atlases exist.  Then create a new Atlases with a
% name specified by the user.
atlasTypeNum = existDataType('Atlases',[],0);
atlasName = addAtlas2DataTYPE(atlasTypeNum);

% Return if the user canceled when entering the name.
if isempty(atlasName),    
    return; 
else  
    newAtlasNum = existDataType(atlasName); 
end;

% addDataType doesn't make the new dir for us, so we make it
% This is a point at which we should consider whether we can have multiple
% data types.  Or should we treat each Atlas as a new FLAT data directory.
flatDir = fullfile(HOMEDIR, vw.subdir);
if ~exist(fullfile(flatDir, atlasName),'dir'), mkdir(flatDir, atlasName); end

% Build the atlas and store it in fullfile(flatDir, 'Atlases', 'corAnal.mat')
% We should offer the user various alternative options concerning the method
% of specifying the visual area templates.
areaSizeScales = [1,1,.75,.75];
slice = viewGet(vw, 'Current Slice');

if queryNumAreas
    answer = inputdlg({'Number of visual areas:','Area size scales:'}, ...
        'Atlas Num Areas', 1, {'3',num2str(areaSizeScales)});
    if(isempty(answer))
        myErrorDlg([mfilename,': User cancelled.']);
        return;
    end
    numAreas = max(1, str2num(answer{1}));
    areaSizeScales = str2num(answer{2});
end
atlasTypeList = {'polar angle', 'eccentricity'};
nAtlases = length(atlasTypeList);

% update dataTYPES
% Copy the params from the first scan of the current data type into the atlas dataTypes.
% Most of these parameters aren't meaningful with an atlas.  We copy them
% anyway because, we are not sure what other code relies on these fields being set.
dtCopy(vw.curDataType,newAtlasNum,atlasTypeList,slice);

atlasDim = dataSize(vw,1);

% getAtlasView could become existDataType call?
atlasView = getAtlasView;
if(isempty(atlasView)),
    hidden = 1;
    atlasView = atlasInit(vw,atlasName,nAtlases,newAtlasNum,atlasDim); 
else
    hidden = 0;
end
                
locs = atlasGraphicDefinition('default');
x1 = locs.x1; x2 = locs.x2; y1 = locs.y1; y2 = locs.y2;

% There are two options for how to interpret the data.  We build them both
% and then graphically let the user decide which one. 
[polar{1}, eccen{1}, areasMask{1}] = makeRetinotopyAtlases(atlasDim, [[x1;x2],[y1;y2]], numAreas, 0, areaSizeScales);
[polar{2}, eccen{2}, areasMask{2}] = makeRetinotopyAtlases(atlasDim, [[x2;x1],[y2;y1]], numAreas, 0, areaSizeScales);

atlasNum = atlasChoose(polar,eccen)

atlasView.ph{1}(:,:,slice) = polar{atlasNum};
atlasView.ph{2}(:,:,slice) = eccen{atlasNum};
atlasView.co{1}(:,:,slice) = areasMask{atlasNum};
atlasView.co{2}(:,:,slice) = areasMask{atlasNum};

% amp field will store the deformation info when the atlas is warped.
atlasView.amp{1}(:,:,slice) = zeros(size(polar{atlasNum}));
atlasView.amp{2}(:,:,slice) = zeros(size(polar{atlasNum}));

% Save files and update information in the atlas view.
saveSession

saveCorAnal(atlasView);

if(~hidden), atlasView = refreshView(atlasView); end

return;

%-----------------------------------------------
function atlasNum = atlasChoose(polar,eccen)
% Display the atlas and let user choose which of the two orientations is
% appropriate.
h = figure(99);
set(h, 'MenuBar', 'none');
for(ii=1:length(polar))
    figure(99);
    subplot(2,length(polar),ii);
    imagesc(polar{ii}, 'Tag', sprintf(' %d', ii)); axis equal; axis off;
    title(['Atlas ',num2str(ii),' (angle)']);
    subplot(2,length(polar),ii+length(polar));
    imagesc(eccen{ii}, 'Tag', sprintf(' %d', ii)); axis equal; axis off;
    title(['Atlas ',num2str(ii),' (eccen)']);
end
set(h,'NumberTitle','off');
set(h,'Name','Click the atlas that you want');
atlasNum = 0;
while atlasNum == 0
    waitforbuttonpress
    tag = get(gco, 'Tag');
    if ~isempty(tag)
        atlasNum = str2num(tag);
    end
end
close(h);

return;
