function [interpImg, interpImg3D] = rxInterpSlice(rx, rxSlice, ori);
%
% [interpImg, interpImg3D] = rxInterpSlice(rx, rxSlice, [ori=3]);
%
% Given the transform matrix and slice specified by
% the mrRx GUI, compute an interpolated slice.
%
% The optional third argument, ori, specifies the orientation of the slice
% to take relative to the prescription:
%	3 [default] - prescribed slice (corresponds to the slices shown in the
%					Rx window)
%	2 - slice corresponds to a column of the prescription. (e.g., if the
%					prescription is sagittal, this is coronal.)
%	1 - slice corresponds to a row of the prescription. (e.g., if the
%					prescription is sagittal, this is axial.)
%
%
% Returns two images: interpImg is a 2D matrix
% with the raw interpolated values; interpImg3D
% is a 3D TrueColor image, with the brightness
% and contrast settings of the GUI taken into
% account.
%
%
% ras 03/05.
% ras, 02/08/08: added orientation flag.
if ~exist('rx', 'var') | isempty(rx), 
	rx = get(findobj('Tag','rxControlFig'), 'UserData'); 
end
if ~exist('ori', 'var') | isempty(ori), ori = 3;				 end
if ~exist('rxSlice', 'var') | isempty(rxSlice)
    rxSlice = get(rx.ui.rxSlice.sliderHandle, 'Value'); 
end

ysz = rx.rxDims(1);
xsz = rx.rxDims(2);
zsz = rx.rxDims(3);

%% get the sampling range for each dimension
switch ori
	case 1,	 % row
		yRange = rxSlice;
		xRange = 1:xsz;
		zRange = 1:zsz;
		imgSize = [xsz zsz];

	case 2,  % column
		yRange = 1:ysz;
		xRange = rxSlice;
		zRange = 1:zsz;
		imgSize = [ysz zsz];
		
	case 3,  % slice
		yRange = 1:ysz;
		xRange = 1:xsz;
		zRange = rxSlice;
		imgSize = [ysz xsz];
		
	otherwise, error('Invalid orientation flag.')
end

% build up coords for interp vol slice
% here we flip: x->cols, y->rows
[X Y Z] = meshgrid(xRange, yRange, zRange); 
coords = [X(:) Y(:) Z(:) ones(size(Z(:)))]';
coords = double(coords);

% get new coords for the interp slice
newCoords = rx.xform * coords;

% interpolate
interpVals = myCinterp3(rx.vol, rx.volDims(1:2), rx.volDims(3), ...
						newCoords(1:3,:)', 0);
interpImg = reshape(interpVals, imgSize);

% convert to truecolor if requested
if nargout >= 2
	if ishandle(rx.ui.interpBright.sliderHandle)
		brightness = rx.ui.interpBright;
	else
		brightness = 0.5;
	end
	
	if ishandle(rx.ui.interpContrast.sliderHandle)
		contrast = rx.ui.interpContrast;
	else
		contrast = .7;
	end
	
	if ishandle(rx.ui.interpHistoThresh)
		histoThresh = rx.ui.interpHistoThresh;
	else
		histoThresh = 1;
	end
	 
    interpImg3D = rxClip(interpImg, [], brightness, contrast, histoThresh);
end

return
