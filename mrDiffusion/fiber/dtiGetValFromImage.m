function [val1] = dtiGetValFromImage(Im, coords, xform, interpMethod)
%
% val = dtiGetValFromImage(Im, coords, [xform], [interpMethod])
%
% Interpolates the tensor field in dt6 and returns a set of values computed
% from the interpolated tensors. This will also work for a scalar image in
% place of the dt6. In that case, 'valName' is ignored.
%
% Input parameters:
% xform: the transform that converts coords to Im indices. Default is
%        eye(4) (ie. no xform)
% coords: a Nx3 list of coords for which you want values (val will be of
%         length N)
% interpMethod: 'nearest', 'trilin' (default), 'spline'
%
% HISTORY:
% 2005.03.18 RFD (bob@white.stanford.edu) wrote it.
% 2006.08.07 RFD: we no longer set NaNs to 0. If there are missing
% data, the caller should know about it and deal with as they wish.

if(~exist('xform','var') || isempty(xform))
    xform = eye(4);
end

if(~exist('interpMethod','var') || isempty(interpMethod))
    interpMethod = 'trilin';
end
if(size(coords,2)~=3) coords = coords'; end
if(size(coords,2)~=3) error('coords must be an Nx3 array!'); end

if(~all(all(xform==eye(4))))
    coords = mrAnatXformCoords(xform, coords);
end

switch lower(interpMethod)
    case 'nearest'
        interpParams = [0 0 0 0 0 0];  
    case 'trilin'
        interpParams = [1 1 1 0 0 0];
    case 'spline'
        interpParams = [7 7 7 0 0 0];
    otherwise
        error(['Unknown interpMethod "' interpMethod '".']);
end

val1 = zeros(size(coords,1),1);% size(Im));

    bsplineCoefs = spm_bsplinc(Im, interpParams);
    val1 = spm_bsplins(bsplineCoefs, coords(:,1), coords(:,2), coords(:,3), interpParams);

clear Im coords;

return
