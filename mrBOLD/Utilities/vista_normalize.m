function outmat = normalize(inmat, lo, hi)
% function outval = normalize(inmat, [lo=0], [hi=1])
%
% Normalises the matrix in inmat to between lo (for example 0)
% and hi (for example 1).
%
% Unlike rescale2, normalize does not round the values to the nearest
% integer; therefore this is more useful for rescaling double matrices.
%
% ras, 04/05: automatically converts to double if needed
% ras, 02/07: some formatting, more flexible arg specification (a la
%			  rescale2). Also, allows single precision by testing against
%			  integers at the top (instead of non-doubles)
if isinteger(inmat)
    inmat = single(inmat);
end

if (nargin<=1)
   lo = 0;
   hi = 1;
elseif nargin==2 & length(lo)>1 % [lo hi]
	hi = lo(2);
	lo = lo(1);
end

minval = min(inmat(:)); % only want matrices up to 3D

% subtract the min: will run from 0 - maxval
inmat = inmat - minval;
maxval = max(inmat(:));
if (maxval==0)	% need a non-zero denominator in line 36 below
   maxval = 0.000001;
end

% now make it range from 0 to (hi - lo)
inmat = inmat * (hi - lo) / maxval;

% add offset (=lo), so now it ranges from lo -> hi
outmat = inmat + lo;

return