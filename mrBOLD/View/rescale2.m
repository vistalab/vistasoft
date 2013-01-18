function res = rescale2(mtx,mtxRng,resRng,roundflag)
%
% res = rescale(mtx,[clipMin,clipMax],[resMin,resMax],[roundflag = 1])
%
% Rescales mtx to [resMin,resMax].
% Before rescaling, clips values outside of [clipMin,clipMax].
%
% if roundflag = 1 rounds to nearest integer
%
% [clipMin,clipMax] default is [min(mtx(:)),max(mtx(:))]
% [resMin,resMax] default is [0,255]
%
% djh, 1/98
% ras, 04/05: auto-converts to double if needed
% remus, 08/07: introduced roundflag
% ras, 01/09: deals w/ NaNs (scales to low range) and Infs (high range).
if ~isa(mtx,'double')
    mtx = double(mtx);
end

if ~exist('mtxRng','var') | isempty(mtxRng)
  mtxRng=[min(mtx(:)),max(mtx(:))];
end

if ~exist('resRng','var')
  resRng=[0,255];
end

if ~exist ('roundflag')
    roundflag = 1;
end

% clip out-of-range values
mtx(mtx<mtxRng(1) | isnan(mtx)) = mtxRng(1);
mtx(mtx>mtxRng(2) | isinf(mtx)) = mtxRng(2);
resMin = resRng(1);
resMax = resRng(2);

% 3/8/2002 RFD replaced this bit of code
%   res = round((mtx-mtxMin)*((resMax-resMin)/(mtxRng(2)-mtxRng(1))) + resMin);
% with the following:
if(mtxRng(2)-mtxRng(1)==0)
    % if the requested range is 0 (min==max), then we just need to remove the
    % current offset (=mtxRng(1), which also =mtxRng(2)) and apply the new scale
    % and offset.
    if roundflag == 1
        res = round((mtx-mtxRng(1)) * (resMax-resMin) + resMin);
    else
        res = (mtx-mtxRng(1)) * (resMax-resMin) + resMin;
    end
else
    if roundflag == 1
        res = round( (mtx-mtxRng(1)) ./ ((mtxRng(2)-mtxRng(1))) * (resMax-resMin) + resMin);
    else
        res = (mtx-mtxRng(1)) ./ ((mtxRng(2)-mtxRng(1))) * (resMax-resMin) + resMin;
    end
    
end

return;


%%% Debug
mtx=[1:10]
res=rescale2(mtx)
res=rescale2(mtx,[3,7],[100,200])
