function [val1,val2,val3,val4,val5,val6,val7] = dtiGetValFromTensors(dt6, coords, xform, valName, interpMethod)
% Interpolates dt6 tensor field and computes stats at each of the coords
%
%  [val1,val2,val3,val4,val5,val6,val7] = ...
%     dtiGetValFromTensors(dt6, coords, [xform], [valName], [interpMethod])
%
% This  also works for a scalar image in place of the dt6. In that case,
% 'valName' is ignored. (OK, but what does it do in that case? BW)
%
% Inputs:
%  xform: the transform that converts coords to dt6 indices. Default is
%    eye(4) (ie. no xform).  As an example,
%    dtiFiberGroupPropertyWeightedAverage sets the xform to
%    inv(dt.xformToAcpc).  This is the inverse of the transform from coords
%    to acpc, suggesting that the coords in there are acpc and the xform
%    maps from acpc to image space.
%  coords: Nx3 matrix of coords. The returned val will be of length N.  The
%    coords are often in ACPC space while the dt6 indices are in image
%    space.  So xform would move from ACPC to image, typically.
%  interpMethod: 'nearest', 'trilin' (default), 'spline'
%
% The values returned (val1, val2, etc.) differ depending on the string in
% valName.  The current valnaem options are:
%    - 'fa' (fractional anisotropy) (DEFAULT)
%    - 'md' (mean diffusivity)
%    - 'eigvals' (triplet of values for 1st, 2nd and 3rd eigenvalues)
%    - 'shapes' (triplet of values indicating linearity, planarity and
%              spherisity)
%    - 'dt6' (the full tensor in [Dxx Dyy Dzz Dxy Dxz Dyz] format
%    - 'pdd' (principal diffusion direction)
%    - 'linearity'
%    - 'fa md pdd', 'fa md ad rd', 'fa md pdd dt6'
%    - 'fa md ad rd shape'
%
% HISTORY:
% 2005.03.18 RFD (bob@white.stanford.edu) wrote it.
% 2006.08.07 RFD: we no longer set NaNs to 0. If there are missing
%   data, the caller should know about it and deal with as they wish.
% 2012.09 BW - Coments and consistency with other methods
%
% Bob (c) Stanford VISTA Team

%% Parameter initialization
if(~exist('xform','var') || isempty(xform)),  xform = eye(4); end
if(~exist('valName','var') || isempty(valName)),  valName = 'fa'; end
if(~exist('interpMethod','var') || isempty(interpMethod))
    interpMethod = 'trilin';
end
if(size(coords,2)~=3), coords = coords'; end
if(size(coords,2)~=3), error('coords must be an Nx3 array!'); end

% The coordinates are in YYY space. The data are in XXX space. We convert
% the coordinates from YYY space to XXX space. The parameter xfrom is the
% way to do the conversion, and this is sent in. Hence, this routine has no
% way to know what the coordinate frames are. Typically, the coordinates
% are in ACPC and we convert to image. A comment from someone who really
% knows would be nice (BW).
if(~all(all(xform==eye(4))))
    coords = mrAnatXformCoords(xform, coords);
end

%% Data volumetric interpolation
% We use the SPM interpolation interpolating the measurements to the
% sampling resolution of the coordinates.This requires some parameters that
% depend on the method.  Those parameters are set here.  A comment would be
% nice (BW).
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
val_dt6 = zeros(size(coords,1), size(dt6,4));
for ii=1:size(dt6,4)
    bsplineCoefs  = spm_bsplinc(dt6(:,:,:,ii), interpParams);
    val_dt6(:,ii) = spm_bsplins(bsplineCoefs, coords(:,1), coords(:,2), coords(:,3), interpParams);
end
clear dt6 coords;

%% Initialize the returns.  Not all are used.
val1 = []; val2 = []; val3 = []; val4 = []; val5 = []; val6 = [];
if(size(val_dt6,2)~=6)
    % This might be the scalar case?  (BW)
    val1 = val_dt6(:,1);
    return;
end

% The user passes in with spaces and upper/lower variation.  We squeeze out
% the spaces and force to lower here.  That makes the switch easier.
valName = mrvParamFormat(valName);
switch lower(valName)
    case 'dt6'
        val1 = val_dt6(:,1);
        val2 = val_dt6(:,2);
        val3 = val_dt6(:,3);
        val4 = val_dt6(:,4);
        val5 = val_dt6(:,5);
        val6 = val_dt6(:,6);
    case 'eigvals'
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [nil, eigVal] = dtiSplitTensor(val_dt6);
        val1 = squeeze(eigVal(:,:,:,1));
        val2 = squeeze(eigVal(:,:,:,2));
        val3 = squeeze(eigVal(:,:,:,3));
    case 'fa'
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [nil, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
    case 'md'
        % mean diffusivity: trace/3, where trace is the sum of the diagonal
        % elements (ie. the first three dt6 values)
        val1 = sum(val_dt6(:,1:3),2)./3;
    case {'shapes','linearity'}
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        [val1, val2, val3] = dtiComputeWestinShapes(eigVal);
    case 'pdd'
        % principal diffusion direction
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = squeeze(eigVec(:,:,:,[1 2 3],1)); % Should be [1 3 2]?
        %val(isnan(val)) = 0;
    case 'famdpdd'
        % FA, Mean diffusivity, PDD
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;
        val3 = squeeze(eigVec(:,:,:,[1 2 3],1)); % Should be [1 3 2]?
        %val3(isnan(val3)) = 0;
    case 'famdadrd'
        % FA, mean diffusivity, axial diffusivity, radial diffusivity
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);  % FA
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;  % Mean diffusivity
        val3 = squeeze(eigVal(:,:,:,1));  % Axial diffusivity
        val4 = squeeze(eigVal(:,:,:,2)+eigVal(:,:,:,3))./2; % Radial
    case 'famdpdddt6'
        % FA MD PDD DT6
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;
        val3 = squeeze(eigVec(:,:,:,[1 2 3],1)); % Should be [1 3 2]?
        %val3(isnan(val3)) = 0;
        val4 = val_dt6;
    case 'famdadrdshape'
        % FA MD AD RD shape
        val_dt6 = reshape(val_dt6, [size(val_dt6,1) 1 1 6]);
        [eigVec, eigVal] = dtiSplitTensor(val_dt6);
        val1 = dtiComputeFA(eigVal);
        %val(isnan(val)) = 0;
        val2 = sum(val_dt6(:,1:3),2)./3;
        val3 = squeeze(eigVal(:,:,:,1));
        val4 = squeeze(eigVal(:,:,:,2)+eigVal(:,:,:,3))./2;
        %val5=linearity (cp); val6=planarity (cp); val7=sphericity (cs)
        [val5, val6, val7] = dtiComputeWestinShapes(eigVal);
        
        
    otherwise
        error(['Unknown tensor value "' valName '".']);
end

return
