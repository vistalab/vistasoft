function anatClip = getAnatClip(vw)
%
% anatClip = getAnatClip(vw)
%
% Gets anatomy clipping values from anatMin and anatMax sliders
% ras 01/05: made brightness/contrast sliders in place of
% anatClip -- I find this more useful, but back compatibility
% with older functions is good. 
% I notice the anatMin is not often used for inplane
% images, so I use the difference between the anatMin & anatMax
% as the contrast. 

anat = double(viewGet(vw, 'anat'));

if isequal(vw.name, 'hidden')
    
    % guess threshold from anat img
    histThresh = numel(anat)/1000; % ignore bins w/ fewer voxels than this
    [binCnt, binCenters] = hist(anat(:), 100);
    minval = binCenters(find(binCnt>histThresh, 1 ));
    maxval = binCenters(find(binCnt>histThresh, 1, 'last' ));
    anatClip = [minval maxval];
    
else
    if isfield(vw.ui,'anatMin')
        anatClip = [get(vw.ui.anatMin.sliderHandle,'Value'),...
            get(vw.ui.anatMax.sliderHandle,'Value')];
    elseif isfield(vw.ui,'contrast')
        contrast = get(vw.ui.contrast.sliderHandle,'Value');
        a = double(min(anat(:)));
        b = (1-contrast)*double(max(anat(:)));
        anatClip = [a b];
    end
end

return
