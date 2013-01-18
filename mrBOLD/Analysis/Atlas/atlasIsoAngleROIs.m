function vw = atlasIsoAngleROIs(vw, numOfAngles, atlasAreaNum, visualAreaType, scanNums, angleRadRangePerStep, roiColors)
%
% Creates iso-angle ROIs from an Atlas. The ROIs are created based on the
% wedge map, and the coords are sorted based on the ring map, so that the 
% order of the coords is guaranteed to run from fovea to periphery.
% The user will be prompted for params if the atlasImage is not passed in.
%
% vw = atlasIsoAngleROIs([vw], [numOfAngles], [atlasAreaNum], [visualAreaType], [scanNums], [angleRadRangePerStep], [roiColors])
%
% HISTORY:
% 2002.04.01 RFD (bob@white.stanford.edu): wrote it.
%   the convention is to make the wedge atlas scan number 1 and the ring
%   atlas scan number 2
% 2002.10.22 RFD cleaned up code, fixed ROI field bug, and a matlab 6.5
%   glitch (we now have to force our logical masks to be double arrays).
% 2002.12.12 RFD cleaned up code quite a bit, added phase range option, 
%   and allowed the function to be called without a GUI (just pass at least
%   5 args in).
% 2008.7.23 KA cleaned up a bit.

global dataTYPES;

if ieNotDefined('vw'), vw = getCurView; end
if ieNotDefined('numOfAngles'), numOfAngles = 8; end
if ieNotDefined('atlasAreaNum'), atlasAreaNum = 0; end
if ieNotDefined('visualAreaType'), visualAreaType = 'hemifield'; end
if ieNotDefined('scanNums'), scanNums = [1,2]; end
if ieNotDefined('angleRadRangePerStep'), angleRadRangePerStep = 0.2; end
if ieNotDefined('roiColors'), roiColors = 'rmbcgy';end

% Dialog box.
hemisphere = viewGet(vw, 'Current Slice');

if(hemisphere==1),  hemiString = 'left';
else   hemiString = 'right';
end

if(nargin < 7)
    prompt = {'number of ROIs:', ...
            'Area ROI identifier (0,1...):', ...
            'Visual field (hemifield / hf, upperquarterfield / uqf, lowerquarterfield / lqf)',...
            'wedge/ring scan nums',...
            'radians per step:', ...
            'ROI colors:'};
    default = {num2str(numOfAngles), ...
            num2str(atlasAreaNum), ...
            visualAreaType, ...
            num2str(scanNums), ...
            num2str(angleRadRangePerStep), ...
            num2str(roiColors)};
    answer = inputdlg(prompt, 'Iso-angle Parameters', 1, default, 'on');
    if(isempty(answer))
        return;
    else
        numOfAngles = str2num(answer{1});
        atlasAreaNum = str2num(answer{2});
        visualAreaType = answer{3};
        scanNums = str2num(answer{4});
        angleRadRangePerStep = str2num(answer{5});
        % eccenPhaseRange = str2num(answer{6});
        roiColors = answer{6};
    end
end

viewA = getAtlasView;
if(isempty(viewA)), myErrorDlg('Sorry- there are no Atlas FLAT windows open.'); end

wedgeAtlasScanNum = scanNums(1);
ringAtlasScanNum  = scanNums(2);

wedgeAtlasImage = squeeze(viewA.ph{wedgeAtlasScanNum}(:,:,hemisphere));
ringAtlasImage = squeeze(viewA.ph{ringAtlasScanNum}(:,:,hemisphere));
ROIsImage = squeeze(viewA.co{wedgeAtlasScanNum}(:,:,hemisphere));

% Choose the atlas.
atlasTypeNum = atlasSelectAtlas;

% We need to set the phaseShift and phaseScale parameters using the
% retPhases information.  This is available in Scratch.
% wedgePhaseShift = dataTYPES(atlasTypeNum).atlasParams(wedgeAtlasScanNum).phaseShift(hemisphere);
% ringPhaseShift = dataTYPES(atlasTypeNum).atlasParams(ringAtlasScanNum).phaseShift(hemisphere);
% ringPhaseScale = dataTYPES(atlasTypeNum).atlasParams(ringAtlasScanNum).phaseScale(hemisphere);

retPhases = dataTYPES(atlasTypeNum).atlasParams(wedgeAtlasScanNum).retPhases(hemisphere,:);
wedgePhaseShift = retPhases(3);
ringPhaseShift =  retPhases(1);
eccenPhaseRange = [retPhases(1),retPhases(2)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  calculate ROI coordinates for original image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imsize = size(ROIsImage);

% force logical mask to be double array, so it can take NaNs. (matlab 6.5
% requires this)
ROIsTemplate = double(ROIsImage == atlasAreaNum);

% inflate ROIsTemplate so that iso-angle lines at the boundaries are
% correctly drawn.
se = strel('square',3);
ROIsTemplate = imdilate(ROIsTemplate,se);
ROIsTemplate(ROIsTemplate>0) = 1;
ROIsTemplate(ROIsTemplate==0) = NaN;

switch lower(visualAreaType)
    case {'lqf','lowerquarterfield'}
        minPhase = pi; maxPhase = 3*pi/2;
    case {'uqf','upperquarterfield'}
        minPhase = pi/2; maxPhase = pi;
    case {'hf','hemifield'}
        minPhase = pi/2; maxPhase = 3*pi/2;
    otherwise
        error('Unknown visual area type.');
end

% The atlases have been shifted in phase to match the data.  We know the
% amounts of the shifts because they are stored in dataTYPES (see above).
% Here, we shift the atlases back down into their canonical range, as
% defined in the case statement above.  We pick out the ROIs in this
% canonical range.
wedgeAtlasImageShifted = shiftPhase(wedgeAtlasImage,-wedgePhaseShift + minPhase);
ringAtlasImageShifted  = shiftPhase(ringAtlasImage,-ringPhaseShift);
eccenPhaseRange = shiftPhase(eccenPhaseRange,-ringPhaseShift);

% We want to deal with the atlasWedgeImage in the canonical range between pi/2 
% and 3pi/2.  So, just use those numbers to set up the ROI range.
rangeLo = linspace(minPhase, maxPhase - angleRadRangePerStep, numOfAngles);
rangeHi = rangeLo + angleRadRangePerStep;

ROINo = 0;
for ii=1:length(rangeLo) 
    
    % find coordinates   
    [yy,xx] = find( ...
          (wedgeAtlasImageShifted.*ROIsTemplate) <= rangeHi(ii) ...
        & wedgeAtlasImageShifted >= rangeLo(ii) ...
        & ringAtlasImageShifted  >= eccenPhaseRange(1) ...
        & ringAtlasImageShifted  <= eccenPhaseRange(2));
    
    numOfCoords = length(xx);
    if numOfCoords == 0
        fprintf('No atlas data in range %.02f to %.02f\n',rangeLo(ii), rangeHi(ii));
    else
        % we need to sort the coords so that the fovea is at the
        % beginning.
        ringPh = ringAtlasImageShifted(sub2ind(imsize,yy,xx));
        [ringPh, sortIndex] = sort(ringPh);
        yy = yy(sortIndex);
        xx = xx(sortIndex);
        ROINo = ROINo + 1;
        xCoords=reshape(xx,1,numOfCoords);
        yCoords=reshape(yy,1,numOfCoords);
        
        % circle through the given colors
        ROIs(ROINo).color = roiColors(mod(ROINo-1,length(roiColors))+1);
        % store coordinates in ROIs structure
        ROIs(ROINo).coords = [ yCoords ; xCoords ; hemisphere*ones(size(xCoords))];
        ROIs(ROINo).name = [hemiString,'_angle', num2str(ROINo)];
        ROIs(ROINo).viewType = 'FLAT';
    end
end

for(ii=1:length(ROIs)), vw = addROI(vw, ROIs(ii)); end

refreshView(vw);

return;
