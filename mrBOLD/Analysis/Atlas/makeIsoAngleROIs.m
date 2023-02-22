function vw = makeIsoAngleROIs(vw, numOfAngles, atlasAreaNum, angleRadRangePerStep, eccenPhaseRange, roiColors, wedgeRingScans, visualAreaTypes)
%
% vw = makeIsoAngleROIs(vw, numOfAngles,[atlasAreaNum], [angleRadRangePerStep], [eccenPhaseRange], [roiColors],[wedgeRingScans],[visualAreaTypes])
%
% Creates iso-angle ROIs from an Atlas. The ROIs are created based on the
% wedge map, and the coords are sorted based on the ring map, so that the 
% order of the coords is guaranteed to run from fovea to periphery.
%
% The user will be prompted for params if the atlasImage is not passed in.
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

if(nargin<1), help(mfilename); return;  end

if(~exist('numOfAngles','var') | isempty(numOfAngles)), numOfAngles = 8; end
if ieNotDefined('atlasAreaNum'), atlasAreaNum = 0; end
if ieNotDefined('visualAreaType'), visualAreaType = 'hemifield'; end

if ieNotDefined('scanNums'), scanNums = [1,2]; end

if(~exist('angleRadRangePerStep','var') | isempty(angleRadRangePerStep)), angleRadRangePerStep = 0.2; end
if(~exist('eccenPhaseRange','var') | isempty(eccenPhaseRange)), eccenPhaseRange = [0,2*pi]; end
if(~exist('roiColors','var') | isempty(roiColors)), roiColors = 'rmbcgy';end

global dataTYPES;

% Dialog box.
hemisphere = viewGet(vw, 'Current Slice');
if(hemisphere==1),  hemiString = 'left';
else   hemiString = 'right';
end

if(nargin < 7)
    prompt = {'number of ROIs:', 'atlas area number:', 'visual area type','wedge/ring scan nums','radians per step:', ...
            'eccentricity phase range (0,2pi):', 'ROI colors:'};
    default = {num2str(numOfAngles), num2str(atlasAreaNum), visualAreaType, num2str(scanNums), num2str(angleRadRangePerStep),...
            num2str(eccenPhaseRange), num2str(roiColors)};
    answer = inputdlg(prompt, 'Iso-angle Parameters', 1, default, 'on');
    if(isempty(answer))
        return;
    else
        numOfAngles = str2num(answer{1});
        atlasAreaNum = str2num(answer{2});
        visualAreaType = answer{3};
        scanNums = str2num(answer{4});
        angleRadRangePerStep = str2num(answer{5});
        eccenPhaseRange = str2num(answer{6});
        roiColors = answer{7};
    end
end

viewA = getAtlasView;
if(isempty(viewA)), myErrorDlg('Sorry- there are no Atlas FLAT windows open.'); end

wedgeAtlasScanNum = scanNums(1);
ringAtlasScanNum  = scanNums(2);

wedgeAtlasImage = squeeze(viewA.ph{wedgeAtlasScanNum}(:,:,hemisphere));
ringAtlasImage = squeeze(viewA.ph{ringAtlasScanNum}(:,:,hemisphere));
ROIsImage = squeeze(viewA.co{wedgeAtlasScanNum}(:,:,hemisphere));

%%Turned off 'Full Match' for Atlas names - AAB
atlasTypeNum = existDataType('Atlases',[],0);
if(atlasTypeNum == 0),  myErrDlg('No Atlases data type!'); end

% We need to set the phaseShift and phaseScale parameters using the
% retPhases information.  This is available in Scratch.
wedgePhaseShift = dataTYPES(atlasTypeNum).atlasParams(wedgeAtlasScanNum).phaseShift(hemisphere);
ringPhaseShift = dataTYPES(atlasTypeNum).atlasParams(ringAtlasScanNum).phaseShift(hemisphere);
ringPhaseScale = dataTYPES(atlasTypeNum).atlasParams(ringAtlasScanNum).phaseScale(hemisphere);
ringAtlasImage = mod((ringAtlasImage - ringPhaseShift)/ringPhaseScale, 2*pi);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  calculate ROI coordinates for original image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imsize = size(ROIsImage);

% force logical mask to be double array, so it can take NaNs. (matlab 6.5
% requires this)
ROIsTemplate = double(ROIsImage == atlasAreaNum);

% inflate ROIsTemplate so that iso-angle lines at the boundaries are
% correctly drawn 
im1 = ROIsTemplate;
shift1 = vShift(im1,[0 1]);
shift2 = vShift(im1,[1 0]);
shift3 = vShift(im1,[1 1]);
shift4 = vShift(im1,[0 -1]);
shift5 = vShift(im1,[-1 0]);
shift6 = vShift(im1,[-1 -1]);
shift7 = vShift(im1,[-1 1]);
shift8 = vShift(im1,[1 -1]);
ROIsTemplate = im1 + shift1 + shift2 + shift3 + shift4 + shift5 + shift6 + shift7 + shift8;

ROIsTemplate(ROIsTemplate>0) = 1;
ROIsTemplate(ROIsTemplate==0) = NaN;

% get coordinates for angle (intervals) from the warped atlas image
angleRadMin = min(min(ROIsImage));
angleRadMax = max(max(ROIsImage));

ROINo = 0;
%  Originally, Bob wrote this assuming that the angles run from pi/2 to
%  3pi/2.  We wrote our standard atlases from [0,pi].  Maybe we need to
%  write them from [pi/2,3pi/2].  Or, maybe we need this routine to know
%  the range somehow.  Apparently, we must set
%

% Make this a function please.
switch lower(visualAreaType)
    case 'upperquarterfield'
        minPhase = pi; maxPhase = 3*pi/2;
    case 'lowerquarterfield'
        minPhase = pi/2; maxPhase = pi;
    case 'hemifield'
        minPhase = pi/2; maxPhase = 3*pi/2;
    otherwise
        error('Unknown visual area type.');
end

rangeLo = linspace(minPhase, maxPhase - angleRadRangePerStep, numOfAngles);
rangeHi = rangeLo + angleRadRangePerStep;
rangeLo = mod(rangeLo + wedgePhaseShift, 2*pi);
rangeHi = mod(rangeHi + wedgePhaseShift, 2*pi);
for ii=1:length(rangeLo) 
    % find coordinates   
    [yy,xx] = find( (wedgeAtlasImage.*ROIsTemplate) <= rangeHi(ii) ...
                    & wedgeAtlasImage >= rangeLo(ii) ...
                    & ringAtlasImage>=eccenPhaseRange(1) & ringAtlasImage<=eccenPhaseRange(2));
    
    numOfCoords = length(xx);
    if(numOfCoords>0)
        % we need to sort the coords so that the fovea is at the
        % beginning.
        ringPh = ringAtlasImage(sub2ind(imsize,yy,xx));
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

for ii=1:length(ROIs) 
    vw = addROI(vw, ROIs(ii));
end
refreshView(vw);
return;


% Alternative method?
% ROINo = 0;
% for angle = linspace(1/2 * pi, 3/2 * pi, numOfAngles); 
%     ROINo = ROINo + 1;
%     % find coordinates   
%     %     [yy,xx] = find( (warpedAtlasImage.*ROIsTemplate) <= angle+angleRadRangePerStep/2 & ...
%     %         warpedAtlasImage >= angle-angleRadRangePerStep/2);
%     im1 = ((atlasImage.*ROIsTemplate) <= angle) .* 5;
%     % shift to find boundary points
%     shift1 = vShift (im1,[0 1]);
%     shift2 = vShift (im1,[1 0]);
%     shift3 = vShift (im1,[1 1]);
%     shift4 = vShift (im1,[0 -1]);
%     shift5 = vShift (im1,[-1 0]);
%     shift6 = vShift (im1,[-1 -1]);
%     shift7 = vShift (im1,[-1 1]);
%     shift8 = vShift (im1,[1 -1]);
%     im2 = im1 + shift1 + shift2 + shift3 + shift4 + shift5 + shift6 + shift7 + shift8;
%     im1 = ((atlasImage.*ROIsTemplate) >= angle) .* 5;
%     % shift to find boundary points
%     shift1 = vShift (im1,[0 1]);
%     shift2 = vShift (im1,[1 0]);
%     shift3 = vShift (im1,[1 1]);
%     shift4 = vShift (im1,[0 -1]);
%     shift5 = vShift (im1,[-1 0]);
%     shift6 = vShift (im1,[-1 -1]);
%     shift7 = vShift (im1,[-1 1]);
%     shift8 = vShift (im1,[1 -1]);
%     im3 = im1 + shift1 + shift2 + shift3 + shift4 + shift5 + shift6 + shift7 + shift8;
%     
%     % get boundary points 
%     im5 = im2 .* im3;   % ('AND')
%     im5(im5>0) = 1; 
%     [yy,xx] = find( im5 == 1 );
%     if ~isempty(yy)
%         numOfCoords = length(xx);
%         xCoords=reshape(xx,1,numOfCoords);
%         yCoords=reshape(yy,1,numOfCoords);
%         
%         ROIs(ROINo).color = roiColors(mod(ROINo-1,length(roiColors))+1);
%         ROIs(ROINo).coords = [ yCoords ; xCoords ; hemisphere*ones(size(xCoords))];
%         ROIs(ROINo).name = ['angle', num2str(ROINo)];
%         ROIs(ROINo).viewType = 'FLAT';
%     else
%         ROINo = ROINo - 1;
%     end
% end
