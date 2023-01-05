function [polarAngle, eccentricity, ROIsImage] = makeRetinotopyAtlases(imsize, points, numAreas, counterClockwiseFlag, areaSizeScales);
% 
% [polarAngle, eccentricity, ROIsImage] = makeRetinotopyAtlases(imsize, points, [numAreas], [counterClockwiseFlag]), [areaSizeScales]
%
% PURPOSE:
%   Creates wedge and ring atlases given a few simple geomtrical constraints.
%   Wedge will span half the phases, while the ring will span all phases.
%
%   We are given four points- they define the boundary of V1. Like this:
%       points(1,:) = x,y: lower phase edge of V1, near fovea
%       points(1,:) = x,y: lower phase edge of V1, periphery
%       points(1,:) = x,y: upper phase edge of V1, near fovea
%       points(1,:) = x,y: upper phase edge of V1, periphery
%
%   The coordinate frame for these points has origin (0,0) at the upper%   left with 'x' = columns and 'y' = rows. Coordinates <0 or >imsize are%   outside the image. Of course, points outside the image can be used to %   define the lines.
%
%   When given only two lines, we can't be sure which way the wedge is %   supposed to run, so we need another parameter to disambiguate. If %   'counterClockwiseFlag = 1', then the wedge phases move from the lower %   phase line to the upper phase line counter-clockwise. Otherwise, it is %   clockwise.
%
%   numAreas specifies the number of visual areas to build. Note that there%   will always be an extra half-area on each side of the wedge atlas (this is%   needed to avoid edge effects with the fitting algorithm). Eg. use 1 for
%   just v1, 2 for v1+v2, 3 for v1-v3. Defaults to 3.
%
% test code:
%
% figure; image(zeros(128));% [x1,y1]=getline; [x2,y2]=getline; p=[[x1;x2],[y1;y2]]; display(p); 
% [w1,r1]=makeRetinotopyAtlases(128,p,3,0); [w2,r2]=makeRetinotopyAtlases(128,p,3,1); 
% subplot(2,2,1); imagesc(w1); colorbar; axis image; 
% subplot(2,2,2); imagesc(r1); colorbar; axis image;
% subplot(2,2,3); imagesc(w2); colorbar; axis image;
% subplot(2,2,4); imagesc(r2); colorbar; axis image;
%
% HISTORY:
%   2002.03.08 RFD (bob@white.stanford.edu): wrote it, based on Volker
%              Koch's mrFindBorders function 'makeAtlases'.
%   2002.06.03 RFD: changed visual area coding scheme from 1,-2,2,-3,3,...%              to 0,-1,1,-2,2,... I did this so that algorithms that need to %              interpolate the areas image will work properly. 
%              With the old scheme, we would sometimes get values such as 0%              and -1 due to interpolation. With the new scheme, the %              intermediate values make more sense- eg. values around 0.5 are 
%              ambiguous between area 1 and area 2, so will get rounded to%              one or the other.
% 2002.10.22 RFD: added areaSizeScales to allow better initial atlas fits.
%
% TO DO:
%   - get it working for nearly vertical lines
%

if(length(imsize)==1),  imsize = [imsize imsize]; end
if(~exist('counterClockwiseFlag','var') | isempty(counterClockwiseFlag)), counterClockwiseFlag = 0; end
if(~exist('numAreas','var') | isempty(numAreas)),  numAreas = 3; end

% Scale for the first area should always be exactly 1.
if(~exist('areaSizeScales','var') | isempty(areaSizeScales)), areaSizeScales = [1,repmat(.75,1,numAreas)]; end

% for readability:
loFov.x = points(1,1);
loFov.y = points(1,2);
loPer.x = points(2,1);
loPer.y = points(2,2);
hiFov.x = points(3,1);
hiFov.y = points(3,2);
hiPer.x = points(4,1);
hiPer.y = points(4,2);

nX = imsize(2);
nY = imsize(1);

% First, we must find our virtual center, which is generally the% intersection of the two lines that we are given. To find this, % we get the equations of the lines (in "aX + bY = c" form) and% solve them simultaneously (use matlab's '\').
%
a1 = loFov.y - loPer.y;
b1 = -loFov.x + loPer.x;
c1 = a1*loFov.x + b1*loFov.y;
a2 = hiFov.y - hiPer.y;
b2 = -hiFov.x + hiPer.x;
c2 = a2*hiFov.x + b2*hiFov.y;
vCenter = [a1, b1; a2, b2] \ [c1; c2];
if(any(isinf(vCenter)))
    % The lines are parallel. If they define the same line, we can handle it.
    if(loFov.x == hiFov.x)
        vCenter = [loFov.x;0];
    elseif(loFov.y == hiFov.y)
        vCenter = [0;loFov.y];
    else
        % we may want to allow this as a special case. Perhaps just
        % place the center really far away?
        error('Lines defined by the four points are parallel! Try again.');
    end
end

% maxRadius is the distance from vCenter to the farthest periphery point
maxRadius = max(sqrt((vCenter(1)-loPer.x).^2 + (vCenter(2)-loPer.y).^2), ...
    sqrt((vCenter(1)-hiPer.x).^2 + (vCenter(2)-hiPer.y).^2));
% minRadius is the distance from vCenter to the nearest fovea point
minRadius = min(sqrt((vCenter(1)-loFov.x).^2 + (vCenter(2)-loFov.y).^2), ...
    sqrt((vCenter(1)-hiFov.x).^2 + (vCenter(2)-hiFov.y).^2));

% Make X and Y meshgrids, centered around vCenter
%
[X Y] = meshgrid(1:nX,1:nY);
% Center the grid around zero
X = X - 1; 
Y = Y - 1;

%
% Find the radial distance from vCenter for each of the X,Y points.
% This will form the basis of the ring map.
% Note that we square the distance to approximate cortical magnification.
%
eccentricity = (sqrt((X-vCenter(1)).^2 + (Y-vCenter(2)).^2)-minRadius) ./ (maxRadius-minRadius);
% the eccentricity map now goes from 0 to 1 in the region of interest, so% we can make our mask now.
nanMask = eccentricity > 1 | eccentricity < 0;
% now we want to make the values meaningful phases:
eccentricity = eccentricity.^2 * 2*pi;
% Here we create the wedge map. This is a bit more complicated.
% We want values that go from 0.5*pi thru 2.5*pi so that we avoid phase-wrapping issues.
% We also want them in a patten that goes pi - pi/2 - pi - pi/2 - 3*pi/2 - pi - 3*pi/2 -% pi - 3*pi/2
%
polarAngle = zeros(size(X));

% create a finely-sampled line of expected phases.
% this rather arbitrary sampling density seems to work OK:
n = max(imsize);

% Define standard phase values for horizontal and vertical meridia
horizontal = pi;
upperVert = horizontal+pi/2;
lowerVert = horizontal-pi/2;

% visualAreasMap coding scheme:
% first area = 0.0, second area = 1.0 and -1.0, third area = 2.0 and -2.0, etc

% Create the first area (typically V1- goes through a full-pi sweep)
numPoints = n*areaSizeScales(1);
angleLine = [linspace(upperVert, lowerVert, 2*numPoints)];
visualAreasMap = [zeros(1,numPoints*2)];

% Add other areas- half-pi sweeps on either side, cumulative with number of% areas
for(ii=1:numAreas)
    % even areas (eg. V2) go horizontal-to-upper, odd areas go the other way
    numPoints = n*areaSizeScales(ii+1);
    if(mod(ii+1,2)==0)
        angleLine = [linspace(horizontal, upperVert, numPoints), angleLine, ...
                     linspace(lowerVert, horizontal, numPoints)];
    else
        angleLine = [linspace(upperVert, horizontal, numPoints), angleLine, ...
                     linspace(horizontal, lowerVert, numPoints)];
    end
    visualAreasMap = [ones(1,numPoints)*ii*-1, visualAreasMap, ones(1,numPoints)*ii];
end

% We now define the angles that form the start and end of the atlas (in
% polar coords). 
%
% We start by defining the first area, since that's what the input points
% define.
startAngle = atan2(loPer.x-vCenter(1), loPer.y-vCenter(2));
endAngle = atan2(hiPer.x-vCenter(1), hiPer.y-vCenter(2));
if(endAngle>startAngle)
    endAngle = endAngle-2*pi;
end
angleRange = endAngle-startAngle;
% Now add the other areas.
startAngle = startAngle - sum(angleRange/2 .* areaSizeScales(2:end));
endAngle =  endAngle + sum(angleRange/2 .* areaSizeScales(2:end));

% Find the polar angle from vCenter for each of the X,Y points.
% This will form the basis of the wedge map.
polarAngle = atan2(X-vCenter(1), Y-vCenter(2));

% rotate the angle map so that startAngle is at 0 rad and all other
% phases are below it (ie. negative)
polarAngle(polarAngle>startAngle) = polarAngle(polarAngle>startAngle)-2*pi;
polarAngle = polarAngle-startAngle;
endAngle = endAngle-startAngle;
startAngle = 0;
% merge the wedge nan mask with the existing ring nanMask
nanMask = nanMask | (polarAngle > startAngle | polarAngle < endAngle);

if(counterClockwiseFlag)
    angleLine = fliplr(angleLine);
    visualAreasMap = fliplr(visualAreasMap);
end

% now, scale the polar angles so that they form valid indices into% angleLine
polarAngle = round(polarAngle ./ (endAngle-startAngle) .* (length(angleLine)-1)) + 1;
% for now, set the non-ROI values to a valid index (these values will get% Nan'ed out below)
polarAngle(nanMask) = 1;
ROIsImage = visualAreasMap(polarAngle);
polarAngle = angleLine(polarAngle);

ROIsImage(nanMask) = NaN;
polarAngle(nanMask) = NaN;
eccentricity(nanMask) = NaN;

return;


% Make hemifield
% Make hemifield and adjacent quarterfield
% Take hemifield and place quarterfield adjacent
% Take hemifield and place quarterfield orthogonal


% TODO:  Fix atlas phase by clicking on data.
% TODO:  Think harder about error measures.