function [interp, ref] = rxGetComparisonImages(rx, interp, ref);
% Get an interpolated prescribed slice, and a reference slice, for
% comparison with mrRx, adjusting intensity according to the UI 
% settings.
%
% [interp, ref] = rxGetComparisonImages(rx, [interp, ref]);
%
% INPUTS:
%	rx: mrRx structure. [default: get from cur figure]
%
%	interp: interpolated slice image. [default: get from rxInterpSlice]
%
%	ref: reference slice image. [Default: get cur reference slice]
%
%
% ras, 01/06.
if ~exist('rx', 'var') | isempty(rx), 
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end 
if notDefined('interp'), interp = rxInterpSlice(rx);             end
if notDefined('ref')
    rxSlice = round(get(rx.ui.rxSlice.sliderHandle, 'Value'));
    ref = rx.ref(:,:,rxSlice);   
elseif ndims(ref)>2
    ref = ref(:,:,1);
end

% check if the mrAlign intensity-normalization
% pref is set
hcorrect = findobj('Label', 'Use mrAlign Intensity Correction');
if isempty(hcorrect)
	correct = 0;
else
	correct = isequal(get(hcorrect(end), 'Checked'), 'on');
end

if correct==1
    [interp ref] = rxCorrectIntensity(interp, ref);
elseif ishandle(findobj('Tag', 'rxCompareSlider'))
    % use info from the brightness sliders to adjust relative intensity
    % (x2 factor doubles dynamic range of brightness sliders)
    dA = 2 * get(findobj('Tag', 'rxCompareSlider'), 'Value');
    dB = 2 * get(findobj('Tag', 'refCompareSlider'), 'Value');
    interp = brighten(interp, dA-0.6); % 0.6 offset so that a slider value 
    ref = brighten(ref, dB-0.6);       % of 0.3 (x2) causes no change
end    

interp = normalize(histoThresh(interp), 0, 1);
ref = normalize(histoThresh(ref), 0, 1);

return
