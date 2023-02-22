function  sParams = rmCreateStim(vw,curStim)
%Create default the retinotopy model stimulus parameter structure
%
%  sParams = rmCreateStim([vw],[curStim]);
%
% This is the modern one.  The older form is rmStimCreate - which is used
% by the older GUI (rmEditStimulusParameters).  When that goes away
% rmStimCreate can also go away. This one works with rmEditStimParams).
%
%Example:
%    sParams = rmCreateStim;   % Create an array with the default
%    sParams = rmCreateStim(vw,myStimParams); % Overlay myStimParams values
%
% JW Jan, 2008
% SD: getCurView is order dependent (gets inplanes first and since we
% typically use the volume/gray view it gets the incorrect one if you have
% an inplane open. Safer to propogate the view structure.
% JW: added argin curStim so that a stim template can be made from just a
% single scan if requested. and not necessarily all the scans in the view's
% current dataTYPE

if ~exist('vw','var') || isempty(vw)
    vw = getCurView; % careful getCurView is unreliable (order dependent)
end

if ~exist('curStim', 'var') || isempty(curStim)
    sParams = rmStimTemplate(vw);
    curStim = length(sParams);
else
    sParams = rmStimTemplate(vw, length(curStim));
end

% Loop through each of the curStim fields and copy the values into the
% sParams fields.
s = fieldnames(sParams(1));
for ii=1:length(curStim)
    for jj=1:length(s)
        if isfield(curStim(ii),s{jj})
            sParams(ii).(s{jj}) = curStim(ii).(s{jj});
        end
    end
end

return;
