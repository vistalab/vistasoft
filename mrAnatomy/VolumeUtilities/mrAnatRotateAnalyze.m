function img = mrAnatRotateAnalyze(img)
% Rotate an MR image from default ANALYZE / NIFTI orientations to 
% mrVista easy-to-display orientation.
%
% USAGE:
%		img = mrAnatRotateAnalyze([img]);
%
% img should be a 3-D (or 4-D) image matrix, or a path to an mr file.
% If omitted, prompts the user with a dialog.
%
% BACKGROUND: 
%	The default orientation for Analyze images is R | A | S, in which
%	(rows, cols, slices) run from 
%	(left --> _R_ight, posterior --> _A_nterior, inferior --> _S_uperior).
%
%	This doesn't display well, so this function reorients them to an 
%	I | P | R convention, in which
%	(rows, cols, slices) run from 
%	(superior--> _I_nferior, anterior --> _P_osterior, left --> _R_ight).
% 
%	I|P|R is easier to understand when displayed as a straight matrix, and
%	is the convention used in vAnatomy.dat files. While the .dat format may
%	go away, this is a useful orientation to display.
%
% ras, 02/07/2008.
if notDefined('img'), % get a user-defined file path
	img = mrvSelectFile('r', {'img' 'nii' 'nii.gz' '*'}, ...
						'Select an Analyze or NIFTI file'); 
end

if ischar(img)	% load file path
	img = mrLoad(img);
	img = img.data;
end

% for 4-D images, recursively rotate through each subvolume
if ndims(img)==4
	for t = 1:size(img, 4)
		tmp(:,:,:,t) = mrAnatRotateAnalyze(img(:,:,:,t));
	end
	img = tmp;
	return
end

% at heart, what this does is very simple...
img = permute(img, [3 2 1]);

if verLessThan('matlab', '8.2'),
    img = flipdim(flipdim(img, 2), 1);
else
    img = flip(flip(img, 2), 1);
end


return
