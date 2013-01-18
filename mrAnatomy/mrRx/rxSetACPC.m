function rx = rxSetACPC(rx, whichPoint, loc);
%
% rx = rxSetACPC([rx], [whichPoint='ac'], [loc=get from 3-view]);
%
% Set points for rotating a volume into AC/PC space.
%
% BACKGROUND: AC/PC space is a standard way of bringing different brains 
% into a comparable coordinate system without distorting or skewing the 
% brains. In this space, the anterior commissure (AC) is set at point
% (0, 0, 0), and the brain is rotated such that the posterior commissure
% (PC) in the same axial slice. Because this is a rigid-body rotation,
% without scaling, the (y) or coronal coordinate of the PC varies, but the
% x (sag) and z (axial) dimensions are defined as 0, as with the AC. 
% The rotation also usually uses a third point (mid-sagittal), in the same 
% coronal slice as the AC, but along the mid-sagittal line, to rotate
% the brain such that the plane which best separates cortical hemispheres 
% runs along (x,0,0). 
%
% This function allows the user to set the locations corresponding to the AC,
% PC, and mid-sagittal points. The function rxAlignACPC then sets the
% current alignment to bring the prescription into AC/PC space based on
% those points. 
%
% More information on AC/PC alignment is available at:
%	http://white.stanford.edu/newlm/index.php/Anatomical_Methods
%
%
% INPUTS:
%	rx: mrRx rx struct; searches for a GUI if omitted.
%
%	whichPoint: flag to specify whether the AC, PC, or mid-sagittal point
%	is being set. Can be an integer flag or string, out of the following:
%		1 or 'ac': set the anterior commissure (AC).
%		2 or 'pc': set the posterior commissure (PC).
%		3 or 'midsag': set the mid-sagittal point in the same coronal as
%						the AC.
%
%	loc: [row col slice] in the prescription corresponding to the point
%	being set. If omitted, the code will assume that a interpolated 3-view
%	window is open (see rxOpenInterp3ViewFig), and that the location of the
%	crosshairs corresponds to the location to be set.
%
% OUTPUTS:
%	rx: the modified rx struct will have the field rx.acpcPoints set.
%		This field is a 3x3 matrix; the first, second, and third columns
%		respectively specify the AC, PC, and mid-sag points. Points in 
%		this field that	haven't yet been specified are set to NaN.
%
% ras, 02/08/2008.
cfig = findobj('Tag','rxControlFig');

if ~exist('rx', 'var') | isempty(rx),    rx = get(cfig,'UserData'); end

if notDefined('whichPoint'),	whichPoint = 'ac';	end

if notDefined('loc'),
	%% get location from 3-view GUI
	if ~checkfields(rx, 'ui', 'interpLoc') | ~ishandle(rx.ui.interpLoc(1))
		error('Need to open an interpolated 3-view window.')
	end
	
	for i = 1:3, 
		loc(i) = str2num( get(rx.ui.interpLoc(i), 'String') ); 
	end
end

%% convert string specifications for whichPoint into an integer 
if ischar(whichPoint)
	switch lower(whichPoint)
		case 'ac', whichPoint = 1;
		case 'pc', whichPoint = 2;
		case 'midsag', whichPoint = 3;
		otherwise, error('Invalid value for whichPoint.')
	end
end

%% ensure the rx.acpcPoints field is initialized
if ~isfield(rx, 'acpcPoints')
	rx.acpcPoints = repmat(NaN, [3 3]);
end

%% set the point
% we store the points relative to the location in the volume:
% this way, when the user adjusts the prescription, the points move
% along with it.
rx.acpcPoints(:,whichPoint) = rx2vol(rx, loc(:));

% If there's a GUI running, refresh
if ishandle(cfig)
	rxRefresh(rx);
end

return
