function vw = atlasIsoEccROIs(vw, ringAtlasScanNum, numOfEccens, ROISelection, eccenRadRangePerStep)
%
% Creates iso-eccentricity ROIs from an Atlas. The ROIs are created based
% on the ring map. The user will be prompted for params if the atlasImage
% is not passed in.
%   
% vw = atlasIsoEccROIs([vw], [ringAtlasScanNum], [numOfEccens], [ROISelection], [eccenRadRangePerStep])
%
% Examples:
%
%  FLAT{1} = atlasIsoEccROIs(FLAT{1})
%
% the convention is to make the wedge atlas scan number 1 and the ring
% atlas scan number 2
% 
% HISTORY:
%  2002.04.01 RFD (bob@white.stanford.edu): wrote it.
%  2002.10.22 RFD cleaned up code, fixed ROI field bug, and a matlab 6.5
%  glitch (we now have to force our logical masks to be double arrays).
%  2008.7.23 KA cleaned up a bit.

global dataTYPES;

if ieNotDefined('vw'), vw = getCurView; end
if ieNotDefined('ringAtlasScanNum'), ringAtlasScanNum = 2; end
if ieNotDefined('numOfEccens'), numOfEccens = 8; end
if ieNotDefined('ROISelection'), ROISelection = 0; end
if ieNotDefined('eccenRadRangePerStep'), eccenRadRangePerStep = 0.2; end

hemisphere = viewGet(vw, 'Current Slice');

if(hemisphere==1), hemiString = 'left';
else               hemiString = 'right';
end

if(nargin < 5)    
    prompt = {'Ring scan num',...
        'num ROIs:', ...
        'Area ROI identifier (0,1...):', ...
        'Eccentricity Range Per Step (Radians):'};
    default = {'2','8','0','0.2'};
    answer = inputdlg(prompt, 'Iso-eccentricity Parameters', 1, default, 'on');

    if ~isempty(answer)
        viewA = getAtlasView;
        if(isempty(viewA))
            myErrorDlg('Sorry- there are no Atlas FLAT windows open.');
        end
        ringAtlasScanNum = str2num(answer{1});
        numOfEccens = str2num(answer{2});
        ROISelection = str2num(answer{3});
        eccenRadRangePerStep = str2num(answer{4});
        atlasImage = squeeze(viewA.ph{ringAtlasScanNum}(:,:,hemisphere));
        ROIsImage = squeeze(viewA.co{ringAtlasScanNum}(:,:,hemisphere));
    else
        myErrorDlg('You need to provide some valid parameters!');
    end
end

% Choose the atlas.
atlasTypeNum = atlasSelectAtlas;

% phaseShift = dataTYPES(atlasTypeNum).atlasParams(ringAtlasScanNum).phaseShift(hemisphere);
retPhases = dataTYPES(atlasTypeNum).atlasParams(ringAtlasScanNum).retPhases(hemisphere,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  calculate ROI coordinates for original image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imsize = size(ROIsImage);
colorList = {'yellow','magenta','cyan','red','green','blue'};
colorChar = char(colorList)';
colorChar = colorChar(1,:);

% force logical mask to be double array, so it can take NaNs. (matlab 6.5
% requires this)
ROIsTemplate = double(ROIsImage == ROISelection);
ROIsTemplate(ROIsTemplate>0) = 1;
ROIsTemplate(ROIsTemplate==0) = NaN;

% get coordinates for angle (intervals) from the warped atlas image
% eccenRadMin = min(min(ROIsImage));
% eccenRadMax = max(max(ROIsImage));

ROINo = 0;

% We set the eccen spacing to approximate cortical magnification.
% eccenRangeLo = logspace(log10(.1), log10(2*pi-eccenRadRangePerStep), numOfEccens);
% eccenRangeHi = logspace(log10(.1+eccenRadRangePerStep), log10(2*pi), numOfEccens);
tmpPhases = shiftPhase([retPhases(1),retPhases(2)],-retPhases(1))
eccenRangeLo = linspace(0,tmpPhases(2),numOfEccens);
eccenRangeLo = shiftPhase(eccenRangeLo,retPhases(1));
eccenRangeHi = mod(eccenRangeLo + eccenRadRangePerStep, 2*pi);

for ii=1:length(eccenRangeLo)
    
    if eccenRangeHi(ii) < eccenRangeLo(ii)
        %  Note:  Check that Hi > Lo.  If not, we are at a 2pi boundary, so we
        %  shift that pair down a little bit so that it doesn't cross the 2pi
        %  boundary.
        eccenRangeLo(ii) = eccenRangeLo(ii) - eccenRangeHi(ii);
        eccenRangeHi(ii) = 2*pi;
    end
    
    % find coordinates 
    [yy,xx] = find( (atlasImage.*ROIsTemplate) <= eccenRangeHi(ii) & ...
        atlasImage >= eccenRangeLo(ii));
    numOfCoords = length(xx);
    if numOfCoords == 0
        fprintf('No atlas data in range %.02f to %.02f\n',eccenRangeLo(ii), eccenRangeHi(ii));
    else 
        ROINo = ROINo + 1;
        xCoords=reshape(xx,1,numOfCoords);
        yCoords=reshape(yy,1,numOfCoords);
        
        % circle through the given colors
        ROIs(ROINo).color = colorChar(mod(ROINo-1,length(colorChar))+1);
        % store coordinates in ROIs structure
        ROIs(ROINo).coords = [ yCoords ; xCoords ; hemisphere*ones(size(xCoords))];
        ROIs(ROINo).name = [hemiString,'_eccen', num2str(ROINo)];
        ROIs(ROINo).viewType = 'FLAT';
    end
end

for(ii=1:length(ROIs)), vw = addROI(vw, ROIs(ii)); end

refreshView(vw);

return;
