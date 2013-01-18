function [mv, ok] = mv_removeNans(mv);
%
% [mv, ok] = mv_removeNans(mv);
%
% Remove all voxels from an mv struct which contain NaNs in any part of the
% data. Also returns a vector of indices to the original mv
% coordinates which are not NaN.
%
% ras, 01/2007. 
if notDefined('mv'), mv = get(gcf, 'UserData'); end

amps = mv_amps(mv);

[I J] = find( isnan(amps) );

ok = setdiff(1:size(mv.coords,2), I);

mv = mv_selectSubset(mv, ok, 'voxels', 0);

return
