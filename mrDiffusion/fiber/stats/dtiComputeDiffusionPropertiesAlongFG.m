function [fa, md, rd, ad, cl, SuperFiber, fgClipped, cp, cs, fgResampled] = ...
    dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes, dFallOff)
%   Compute a weighted average of a variable (FA/MD/RD/AD) in a track segment
%
%  [fa, md, rd, ad, cl, SuperFiber,fgClipped, cp, cs, fgResampled] = ...
%    dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes, [dFallOff])
%
%   From a fiber group (fg), and diffusion data (dt), compute the weighted
%   2 value of a diffusion property (taken from dt) between the two ROIS at
%   a NumberOfNodes, along the fiber track segment between the ROIs,
%   sampled at numberOfNodes point.
%
% INPUTS:
%       fg            - fiber group structure.
%       dt            - dt6.mat structure or a nifti image.  If a nifti
%                       image is passed in then only 1 value will be 
%                       output and others will be empty
%       roi1          - first ROI for the fg
%       roi2          - second ROI for the fg
%       numberOfNodes - number of samples taken along each fg
%       dFallOff      - rate of fall off in weight with distance. This can
%                       also be 'mean' or 'median' which will not do a 
%                       weighted avg.
%
% OUTPUTS:
%       fa         - Weighted fractional anisotropy
%       md         - Weighted mead diffusivity
%       rd         - Weighted radial diffusivity
%       ad         - Weighted axial diffusivity
%       cl         - Weighted Linearity
%       SuperFiber - structure containing the core of the fiber group
%       fgClipped  - fiber group clipped to the two ROIs
%       cp         - Weighted Planarity 
%       cs         - Weighted Sphericity
%       fgResampled- The fiber group that has been resampled to 
%                    numberOfNodes and each fiber has been reoriented to 
%                    start and end in a consitent location  
%
% WEB RESOURCES:
%   mrvBrowseSVN('dtiComputeDiffusionPropertiesAlongFG')
%   http://white.stanford.edu/newlm/index.php/Diffusion_properties_along_trajectory
%   See dtiFiberGroupPropertyWEightedAverage
%
% EXAMPLE USAGE:
%
% HISTORY:
%  ER wrote it 12/2009
%
% (C) Stanford University, VISTA Lab

%%
if notDefined('dFallOff'), dFallOff = 1; end
% check if the input is a nifti image rather than a dt6 structure.
if isfield(dt,'qto_ijk')
    valname = 'image';
else
    valname = 'famdadrdShape';
end
% If two rois are passed in clip the fiber group to the portion that spans
% between the ROIs
if ~notDefined('roi1') && ~notDefined('roi2')
    fgClipped = dtiClipFiberGroupToROIs(fg,roi1,roi2);
    % compute weighted averages for eigenvalues along clipped fiber tract
    [myValsFgWa, SuperFiber, ~, ~, fgResampled] = ...
        dtiFiberGroupPropertyWeightedAverage(fgClipped, dt, numberOfNodes, valname, dFallOff);
else
    % compute weighted averages for eigenvalues along full fiber tract
    [myValsFgWa, SuperFiber, ~, ~, fgResampled] = ...
        dtiFiberGroupPropertyWeightedAverage(fg, dt, numberOfNodes, valname, dFallOff);
    % There is no clipped fiber group
    fgClipped = nan;
end
% Pull out specific properties
if strcmp(valname,'famdadrdShape')
    fa = myValsFgWa(:, 1);
    md = myValsFgWa(:, 2);
    ad = myValsFgWa(:, 3);
    rd = myValsFgWa(:, 4);
    cl = myValsFgWa(:, 5);
    cp = myValsFgWa(:, 6);
    cs = myValsFgWa(:, 7);
elseif strcmp(valname,'image')
    % if an image was put in then just put the image values into the fa
    % variable and leave the other variables empty
    fa = myValsFgWa(:, 1);
    md = nan(numberOfNodes,1);
    ad = nan(numberOfNodes,1);
    rd = nan(numberOfNodes,1);
    cl = nan(numberOfNodes,1);
    cp = nan(numberOfNodes,1);
    cs = nan(numberOfNodes,1);
end

return
