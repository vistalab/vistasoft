function view = blurPh(view,weightFlag,lambda)
%
% view = blurPh(view, [weightFlag], [lambda])
%
% Blurs the phase map using regularization within the folded gray matter.
% Works only in the volume window in gray mode.  Operates on the current
% scan, replacing VOLUME.ph for that scan only.  To save the modified ph,
% use the save correlation matrices option from the File menu.  Ignores 
% pixels below the current cothresh, treating them as if there is no data
% there and smoothly interpolates new values for those pixels.  Weighted
% blur weights by the inverse residual standard deviation map, thereby 
% giving less weight to noisy pixels.
%
% djh, 2/99
if isempty(view)
  myErrorDlg('Volume window must be open to blur phase.');
end
if ~strcmp(view.viewType,'Gray')
  myErrorDlg('Blur phase only for gray views.');
end
if (isempty(view.ph) | isempty(view.co))
   myErrorDlg('Correlation matrices not loaded.  Load them from the File menu');
end
if ~exist('weightFlag','var')
	weightFlag = 0;   
end
if ~exist('lambda','var')
   lambda = 0.1;
end
curScan = getCurScan(view);
ph = view.ph{curScan}(:);
z = exp(i*ph);
if weightFlag
    try
        view = loadResStdMap(view);
        resStd = view.map{curScan}(:);
        weights = 1./resStd;
        weights = weights/mean(weights);
        z = weights .* z;
    catch
        %Old version weighted by correlation
        co= view.co{curScan}(:);
        z = co.*exp(i*ph);
    end
end
% Pixels below correlation threshold get set to NaN so that regularizeGray
% will treat them as missing data and interpolate new values.
co = view.co{curScan}(:);
cothresh = getCothresh(view);
zthresh = z;
belowThreshIndices = find(co<cothresh);
zthresh(belowThreshIndices) = NaN;
% Regularization
zblur = regularizeGray(zthresh,view.nodes,view.edges,lambda);
% Remap phases to [0,2pi] and modify view.ph
newPh = angle(zblur);
newPh(newPh<0) = newPh(newPh<0)+pi*2;
view.ph{curScan}(:) = newPh;
return;
