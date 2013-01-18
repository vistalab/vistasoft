function dt = dtiImgToInd(dt, mask)
%Convert dti image to an alternative format
%
%    Yind = dtiImgToInd(Y, [MASK])
%
% Takes a XxYxZxpxN array as input and converts it to indexed form nxpxN,
% where n corresponds to a list of coordinates given by find(MASK).
%
% The form DT = dtiImgToInd(DT) works on the entire structure DT and
% implements the inverse of dtiIndToImg.m, in which case DT.mask is used as default.
% This results in a compression factor of about 50.
%
% See also:
%   dtiLoadTensorSubjects.m, dtiIndToImg.m
%
% HISTORY:
%   2004.11.24 Armin Shwartzmann wrote it

% If not struct
if ~isstruct(dt),
    Y = dt;
    sz = size(Y);
    L = prod(sz(1:3));
    N = sz(4:end);
    if isempty(N), N = 1; end
    Yind = reshape(Y, [L N]);
    imask = find(mask);
    Yind = Yind(imask,:);
    Yind = reshape(Yind, [length(imask) N]);
    dt = Yind;
    return
end

% If struct
if ~isfield(dt,'format'),
    error('Format field does not exist')
end
if strcmp(dt.format, 'Ind'),
    error('Data already in Ind format')
end
if ~exist('mask'),
    mask = dt.mask;
end

L = numel(mask);
imask = find(mask);

if isfield(dt,'fa'),
    N = size(dt.fa,4);
    Y = reshape(dt.fa, [L N]);
    dt.fa = Y(imask,:);
end
if isfield(dt,'val'),
    if (size(dt.val,4)~=3), error('Wrong "val" format'), end
    N = size(dt.val,5);
    Y = reshape(dt.val, [L 3 N]);
    dt.val = Y(imask,:,:);
end
if isfield(dt,'vec'),
    if (size(dt.vec,4)~=3 | size(dt.vec,5)~=3), error('Wrong "vec" format'), end
    N = size(dt.vec,6);
    Y = reshape(dt.vec, [L 3 3 N]);
    dt.vec = Y(imask,:,:,:);
end
if isfield(dt,'dt6'),
    if (size(dt.dt6,4)~=6), error('Wrong "val" format'), end
    N = size(dt.dt6,5);
    Y = reshape(dt.dt6, [L 6 N]);
    dt.dt6 = Y(imask,:,:);
end

dt.format = 'Ind';

return

