function vw = cmapPolarAngleRGB(vw, visualField, extend, restrict, ipsiColors)
% Set a view's phase mode colorbar to be a rotated RGB color map
% for the specified visual field.
%
% vw = cmapPolarAngleRGB(vw, [visualField='both'], [extend=0.4],, [restrict = true], [ipsiColors]);
%
% visualField should be a string out of 'left', 'right', or 'both'.
% ['both' is the default value]. This function sets the color map such
% that: 
%   blue is always the upper vertical meridian;
%   green (and yellow) is always the horizontal meridian;
%   red is always the lower vertical meridian.
%
% This is a function of the retinotopy parameters set by 
% retinoSetParams (menu 'Color Map' | 'Set Retinotopy Parameters...' |
% 'Current Scan'). If the parameters for the view's current scan
% are not set to 'polar_angle', this function will throw a warning and
% return without changing anything.
%
% For 'left' or 'right' mapping, the RGB cmap is set to an extended
% colormap in which the RGB range covers the specified field, while the
% other visual hemifield is grayscale. There is a degree of 'overhang'
% into the other visual field, determined by the optional
% 'extend' argument, which ranges from 0 (no extension / 180� colors)
% to 1 (full extension / 360� colors). [default value: 1/3, or 240� of 
% colors and 120� of grays, extending 30� on either side.]  
%
% The ipsilateral grayscale region can be resticted (if restrict = true) so
% that this voxels with phases in this range will be clipped, or it can be
% shown in grayscale (if restrict = false). If 'ipsiColors' is an input
% arg, and restrict = false, then voxels in the clipped region will be
% shown with the color triplet 'ipsiColors'
%
% For 'both' mapping, green is mapped to the left horizontal meridian and
% yellow is mapped to the right horizontal meridian.
%
% Example 1: 
%   % Set left visual field map. Use default arguments.
%   VOLUME{1} = cmapPolarAngleRGB(VOLUME{1}, 'left');
%
% Example 2: 
%   % Set left visual field map, no overhang, show ipsilateral
%   % colors in yellow
%   VOLUME{1} = cmapPolarAngleRGB(VOLUME{1}, 'left', 0, false, [255 255 0]);
%
% ras, 07/2007.
% jw   08/2009: added option for ipslilateral color coding


if notDefined('vw'),                vw = getCurView;            end
if notDefined('visualField'),       visualField = 'both';       end
if notDefined('extend'),			extend = 1/3;				end
if notDefined('restrict'),			restrict = true;            end
if notDefined('ipsiColors'),        ipsiColors = [255 255 255]; end
%% check that retinotopy params are set
params = retinoGetParams(vw);
if isempty(params) || ~isequal(params.type, 'polar_angle')
    msg = ['Need to have a Polar Angle scan and set retinotopy params. ' ...
           'Select Set Retinotopy Params... from the Colormap menu. '];
    warning(msg); %#ok<WNTAG>
    return
end


%% initialize basic cmap in view
switch lower(visualField)
    case 'both', hemiFlag = 1;
    case {'left' 'right'}, hemiFlag = 2;               
    otherwise, error('Invalid value for visualField argument.')
end
vw = cmapRedgreenblue(vw, 'ph', hemiFlag);

% set extended color range if needed (hemifields)
if ismember(lower(visualField), {'left' 'right'})
	% need to figure the appropriate range parameter for this
	% function:  
	% This is complex; I solved it from:
	%   nDesiredColors = nColors/range = nColors/2 * (1+extend)
	range = 2 / (1 + extend);  
    vw = cmapExtended(vw, range, ipsiColors);
end


%%%%% get cmap from view, adjust as needed
% get cmap from view
cmap = viewGet(vw, 'PhaseColormap')';
nColors = size(cmap, 1);

% compute the polar angle represented by each color in the cmap
ph = linspace(0, 2*pi, nColors+1);
ph = ph(1:nColors);  % wraps around, don't use both 0 and 2*pi
theta = polarAngle(ph, params);
    
% find the vertical meridian (theta==0 deg CW from 12-o-clock)
% (min, so we get the closest to 0)
up = find(theta==min(theta));


%% Do we need to flip the cmap? 
% This depends on two factors: how we're mapping (left, right, or both)
% and whether the current parameters are causing the theta estimate 
% to linearly increase along with the cmap.
if isequal(lower(visualField), 'right')
    flipFlag = isequal( lower(params.direction), 'counterclockwise' );
else
    flipFlag = isequal( lower(params.direction), 'clockwise' );
end
    
if flipFlag==1
    cmap = flipud(cmap);
end

cwFlag = isequal(lower(params.direction), 'clockwise');

%% Compute rotation amount
% compute the necessary shift to put this at 12-o-clock
% (the redgreenblue cmap has blue as the last entry, so
% target that one:)

% get minimum value index
iMinVal = find(theta==min(theta));

% Figure out the final rotation amount, N:
% For hemifields ('left' 'right'), this is a little complex, since it
% depends on how much the color part of the cmap 'overhangs' into the
% visual field. If there's some overhang (extend > 0), then the first
% cmap color (blue) won't map exactly to up (0 degrees); it'll be a little 
% bit in the ipsilateral visual field. If we need to adjust by this, 
% figure out the appropriate factor:
% 
if isequal(lower(visualField), 'both') || extend==0
    % This is simple; we just shift so that iMinVal rotates to 1:
    N = iMinVal - 1;   
    
else
    % more complex: first, how many cmap rows are unmapped (gray)?
    nGrays = (nColors / 2) * (1 - extend);
    
    % next, how many colors extend into the ipsilateral visual field?
    % (this is half the total colors, minus the # grays):
    nOverhang = round( (nColors / 2) - nGrays );

    % we adjust by half this amount, in the appropriate direction
    % depends on both the wedge direction and the visual field
    
    leftFlag = isequal(lower(visualField), 'left');    
    if cwFlag==leftFlag
        dirFlag = +1;
    else
        dirFlag = -1;
    end
    overhangAdjust = dirFlag * nOverhang / 2;
    
    % finally, compute the final rotation amount:
    N = round(iMinVal - 1 + overhangAdjust);
end

% rotate the color map the appropriate amount:
cmap = circshift(cmap, [N 0]);  % shift by [rows dim: N, cols dim: 0]

  
%% set updated cmap in the view
vw = viewSet(vw, 'PhaseColormap', cmap');


%%%%% set the phase window in the view to only include the selected hemifield
if ismember( lower(visualField), {'left' 'right'} )
	% Compute degrees overhang on each side
	overhangDegrees = 180 * extend / 2;
	
	% angle of start and end of color map in color wheel (measured CW)
	if isequal(lower(visualField), 'left')
		% left vis field runs from 180 - 360�, plus overhang adjust
		startTheta = 180 - overhangDegrees; 
		endTheta   = overhangDegrees;
	else
		% right vis field runs from 0 - 180�, plus overhang adjust
		startTheta = -overhangDegrees;
		endTheta   = 180 + overhangDegrees;		
	end
	
	%% find the phases which correspond most closely to start and end theta
	delta = (theta - startTheta) .^ 2;
	a = ph( find( delta == min(delta) ) );
	
	delta = (theta - endTheta) .^ 2;
	b = ph( find( delta == min(delta) ) );
    
    % the limits a and b, above, are the min and max phase if we're going
    % clockwise, but it's reversed if the stimulus moved CCW:
    if cwFlag==1, phWin = [a b]; else phWin = [b a]; end 

	%% set phase window accordingly
    if restrict, vw = viewSet(vw, 'phaseWindow', phWin);
    else         vw = viewSet(vw, 'phaseWindow',  [0 2*pi]); end

else
	vw = viewSet(vw, 'phaseWindow',  [0 2*pi]);
end


return

