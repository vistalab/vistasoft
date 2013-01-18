function Yimg = dtiIndToImg(Y, mask, pad)

% function Yimg = dtiIndToImg(Y, [MASK], [PAD])
%
% Takes an nxpxN array as input and converts it to image size XxYxZxpxN.
% The size XxYxZ is given by MASK. The locations are given by find(mask).
% The voxels not in the mask are padded with the value PAD (default = 0);
%
% The form DT = dtiIndToImg(DT) works on the entire structure DT and
% implements the inverse of dtiImgToInd.m, in which case DT.mask is used.
%
% See also:
%   dtiImgToInd.m
%
% HISTORY:
%   2004.11.24 ASH wrote it

if ~exist('pad'),
    pad = 0;
end

if ~isstruct(Y),
    Yimg = IndToImg(Y, mask, pad);
else
    dt = Y;
    if strcmp(dt.format, 'Img'),
        error('Data already in Img format')
    end
	
	if isfield(dt,'fa'),
        dt.fa = IndToImg(dt.fa, dt.mask, pad);
	end
	if isfield(dt,'val'),
        dt.val = IndToImg(dt.val, dt.mask, pad);
	end
	if isfield(dt,'vec'),
        dt.vec = IndToImg(dt.vec, dt.mask, pad);
	end
	if isfield(dt,'dt6'),
        dt.dt6 = IndToImg(dt.dt6, dt.mask, pad);
	end
    Yimg = dt;
end

return


%--------------------------------------------------------------------------

function Yimg = IndToImg(Y, mask, pad)

sz = size(Y);
Yimg = pad * ones([numel(mask) sz(2:end)]);
imask = find(mask);
Yimg(imask,:) = Y(1:end,:);
Yimg = reshape(Yimg, [size(mask) sz(2:end)]);

return
