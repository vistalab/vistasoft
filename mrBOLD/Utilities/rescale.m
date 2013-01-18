function res = rescale(mtx,mtxRng,resRng)
%
% res = rescale(mtx,[clipMin,clipMax],[resMin,resMax])
%
% Rescales mtx to [resMin,resMax] and rounds to integer values.
% Before rescaling, clips values outside of [clipMin,clipMax].
%
% [clipMin,clipMax] default is [min(mtx(:)),max(mtx(:))]
% [resMin,resMax] default is [0,255]
%
% djh, 1/98
% ras, 04/05: auto-converts to double if needed
% ras, 07/05: imported into mrVista2 toolbox, renamed
% rescale from rescale2
% ras, 01/06: added back to mrVista1 Utilities, so that I can write
% code for either code base that doesn't run into a conflict.
if isempty(mtx), res = []; return;               end
if ~isa(mtx,'double'), mtx = double(mtx);        end
if ~exist('resRng','var'), resRng=[0 255];       end
if ~exist('mtxRng','var') | isempty(mtxRng),
    mtxRng=[min(mtx(:)) max(mtx(:))];
end
% clip out-of-range values
mtx(mtx<mtxRng(1)) = mtxRng(1);
mtx(mtx>mtxRng(2)) = mtxRng(2);
resMin = resRng(1);
resMax = resRng(2);
% 3/8/2002 RFD replaced this bit of code
%   res = round((mtx-mtxMin)*((resMax-resMin)/(mtxRng(2)-mtxRng(1))) + resMin);
% with the following:
if(mtxRng(2)-mtxRng(1)==0)
    % if the requested range is 0 (min==max), then we just need to remove the
    % current offset (=mtxRng(1), which also =mtxRng(2)) and apply the new scale
    % and offset.
    res = round((mtx-mtxRng(1)) * (resMax-resMin) + resMin);
else
    res = round( (mtx-mtxRng(1)) ./ ((mtxRng(2)-mtxRng(1))) * (resMax-resMin) + resMin);
end
% get rid of NaNs
res(isnan(res)) = resRng(1);
return