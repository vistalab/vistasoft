function anatClip = getAnatClip(view)
%
% anatClip = getAnatClip(view)
%
% Gets anatomy clipping values from anatMin and anatMax sliders
% ras 01/05: made brightness/contrast sliders in place of
% anatClip -- I find this more useful, but back compatibility
% with older functions is good. 
% I notice the anatMin is not often used for inplane
% images, so I use the difference between the anatMin & anatMax
% as the contrast. 
if isequal(view.name, 'hidden')
    anatClip = [0 1];
    if isfield(view, 'anat') & ~isempty(view.anat)
        % guess threshold from anat img
        histThresh = prod(size(view.anat))/1000; % ignore bins w/ fewer voxels than this
        [binCnt binCenters] = hist(view.anat(:), 100);
        minval = binCenters(min(find(binCnt>histThresh)));
        maxval = binCenters(max(find(binCnt>histThresh)));
        anatClip = [minval maxval];
    end
else
    if isfield(view.ui,'anatMin')
        anatClip = [get(view.ui.anatMin.sliderHandle,'Value'),...
            get(view.ui.anatMax.sliderHandle,'Value')];
    elseif isfield(view.ui,'contrast')
        contrast = get(view.ui.contrast.sliderHandle,'Value');        
        a = double(min(view.anat(:)));
        b = (1-contrast)*double(max(view.anat(:)));
        anatClip = [a b];
    end
end

return
