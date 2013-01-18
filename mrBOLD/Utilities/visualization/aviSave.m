function [mov ok aviPath] = aviSave(M, aviPath, fps, varargin);
% Export a 3D matrix to an AVI file. 
% 
% USAGE:
%	[mov ok aviPath] = aviSave(M, [aviPath], [fps], [options]);
%
% INPUTS:
% M: image matrix. Can either be a 3D matrix, in which every slice is a
% frame of the movie (converted to uint8), or a 4D M x N x 3 x frames matrix, 
% in which each 3D subvolume is a truecolor ([R G B] slice) image.
%
% aviPath: save path for the .avi file. Will append .avi if it's not there.
% [pops up a dialog if omitted.] 
%
% fps: frames per second for the movie. [Default 6]
%
% Options include:
%	'compression': select a compression for the movie. [Defaults based on
%	computer type: 'Indeo5' for windows OS, 'none' otherwise.]
%
%	'cmap': colormap for converting 3D matrices to color.
%
%	'description': descriptive name for the AVI file (will be saved as
%	metadata.)
%	
%	other options found in HELP MOVIE2AVI will be supported here.
%
% OUTPUTS:
%	mov: matlab movie structure of the movie.
%
%	ok: flag indicating whether the save was successful.
%
%	aviPath: save path (useful in case a dialog is brought up.)
%
% ras, 07/18/2008.
if notDefined('M'),		error('Need image matrix.');		end
if notDefined('fps'),	fps = 6;							end
if notDefined('aviPath')
	aviPath = mrvSelectFile('w', 'avi', 'Save .AVI file as...');
end

%% default params
quality = 100;
description = aviPath;
keyframe = fps;
if ispc
	compression = 'Indeo3';
	cmap = gray(236);  % max allowed by compressor
else
	compression = 'None';
	cmap = gray(256);
end

%% parse options
for ii = 1:2:length(varargin)
	switch lower(varargin{ii})
		case 'compression', compression = varargin{ii+1};
		case 'description', description = varargin{ii+1};
		case {'cmap' 'colormap'}, cmap = varargin{ii+1};
		case 'quality', quality = varargin{ii+1};
		case 'keyframe', keyframe = varargin{ii+1};
	end
end

%% make the movie structure
if ndims(M)<=3 
	nFrames = size(M, 3);
	
	% enforce uint8 data type 
	nCmap = size(cmap, 1);
	if min(M(:)) < 1 | max(M(:)) > nCmap | any(mod(M(:), 1) ~= 0)
		warning('Matrix not uint8: rescaling to be uint8');
		M = uint8( rescale2(M, [], [0 nCmap-1]) ); 
	end
	
elseif ndims(M)==4
	if size(M, 3) ~= 3
		error('For 4-D matrices, third dimension must be [R G B] slices.');
	end
	nFrames = size(M, 4);
	
else
	error('Inappropriate movie size.');
	
end

for f = 1:nFrames
	if ndims(M) <= 3
		mov(f) = im2frame(M(:,:,f), cmap);
	else
		mov(f) = im2frame(M(:,:,:,f));
	end
end

%% export to AVI
% enfore .avi extension
[p f ext] = fileparts(aviPath);
if ~isequal( lower(ext), '.avi' )
	aviPath = fullfile(p, [f '.avi']);
end

% export
try
	movie2avi(mov, aviPath, 'FPS', fps, 'Compression', compression, ...
		  'Quality', quality, 'Videoname', description, 'Keyframe', keyframe);
	ok = 1;
	fprintf('[%s]: Saved movie as %s.\n', mfilename, aviPath);
catch
	disp(lasterr);
	ok = 0;
end
	  
return
