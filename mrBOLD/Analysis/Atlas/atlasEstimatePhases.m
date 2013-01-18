function retPhases = atlasEstimatePhases(vw, areaCorners, scanNum, fieldName)
% Define retinotopy phases for an angle and wedge map
%
%   retPhases = atlasEstimatePhases(vw, areaCorners, scanNum, fieldName)
%
% Lets the user interactively define the data phases corresponding to the
% fovea, periphery, upper and lower vertical meridians for the atlas and
% data fits.
%
% scanNum is the scan number of the wedge and ring in this view (and for
% the view's selected data type). fieldName is a 1 x 2 cell array
% specifying the field containing the polar angle and eccentricity data,
% respectively. (For PRF analyses, these are not necessarily loaded into
% the phase slot.)
%
if notDefined('fieldName'),		fieldName = {'ph' 'ph'};			end

nAreas = length(areaCorners);
for ii=1:nAreas
    corners = areaCorners{ii};
    retPhases(ii,1) = atlasEstimateBoundaryPhases(vw, corners(1,:), ...
							corners(2,:), scanNum(1), fieldName{1});
    retPhases(ii,2) = atlasEstimateBoundaryPhases(vw, corners(3,:), ...
							corners(4,:), scanNum(1), fieldName{1});
    retPhases(ii,3) = atlasEstimateBoundaryPhases(vw, corners(1,:), ...
							corners(4,:), scanNum(2), fieldName{2});
    retPhases(ii,4) = atlasEstimateBoundaryPhases(vw, corners(2,:), ...
							corners(3,:), scanNum(2), fieldName{2});
end

if nAreas > 1, retPhases = meanPhase(retPhases); end


%% this part of the code seems to attempt to adjust the phase difference
%% between the stored data in the flat view, and real world units. A couple
%% comments / points of confusion here:
%% (1) It seems that things would be much simplified if the downstream code
%% to this function dealt exclusively with data already in real-world
%% units.
%% (2) for traveling-wave data, the functions polarAngle and eccentricity
%% map between phase and real-world units. Perhaps this should be used?
%% (3) for pRF data, the loaded data are already in real world units.
%% (4) what exactly do the retPhases do?
%% ras, 04/09.
prompt = {'Foveal', 'Peripheral', 'Lower Phase (angle map)'};
def = {num2str(retPhases(1)), num2str(retPhases(2)), num2str(retPhases(3))};
dlgTitle = 'Adjust retinal phase estimates';
lineNo = 1;
answer = inputdlg(prompt, dlgTitle, lineNo, def);

% adjust the retPhases based on the user response
angleShift = retPhases(3) - str2double(answer{3});
for ii=1:3, retPhases(ii) = str2double(answer{ii}); end 

% We shift the fourth (UVM) by the same amount as the LVM
retPhases(4) = retPhases(4) - angleShift;

return;

%----------------------------------------------------
function meanPh = atlasEstimateBoundaryPhases(vw, p1, p2, scanNum, fieldName)
%
%   meanPh = atlasEstimateBoundaryPhases(vw, p1, p2, scanNum, fieldName)
%
% Author:  Wandell
% Purpose:
%     Estimate the average phase along a line between two points.  This
%     code is used to provide first estimates of the foveal, peripheral,
%     UVM and LVM phase in building atlases.
%
% Example:
%
%   scanNum = 1
%   retPhase(1)= atlasEstimateBoundaryPhases(vw,corners(1,:),corners(2,:),scanNum);
%
%
% ras 04/2009:  allows the field to be passed as a parameter -- not only
% confined to phase field, and doesn't require multiple different scans for
% polar angle / eccentricity. This is critical for use with pRF models.

curSlice = viewGet(vw, 'Current Slice');
[x, y] = findLinePoints([p1(1) p1(2)], [p2(1) p2(2)]);

newCoords = zeros(3,length(x));
newCoords(1,:) = y;
newCoords(2,:) = x;
newCoords(3,:) = curSlice*ones(1,length(x));

% Convert coords to canonical frame of reference
newCoords = curOri2CanOri(vw, newCoords);
ph = getCurDataROI(vw, fieldName, scanNum, newCoords);
if ~isequal( lower(fieldName), 'ph' )
	% put the data into the range [0 2*pi]. 
	% there may be a chance that it is not correct that the ph data span
	% this range -- for instance, if someone provides polar angle data in a
	% different field. I should deal with this contingency, but it might be
	% even better to have the downstream code deal with real-world-unit
	% data, and leave the conversion to these units up to the user before
	% entering this function (ras 04/09)...
	ph = normalize(ph, 0, 2*pi);
end
cxph = exp(sqrt(-1)*ph);

% We add pi to the output so that the variables run from [0,2pi] instead of
% from [-pi,pi].  This is consistent with mrLoadRet encoding of phase.
meanPh = angle(mean(cxph));

if meanPh < 0, meanPh = meanPh + 2*pi; end
if meanPh > 2*pi, meanPh = meanPh - 2*pi; end

return;
