function vw = setReferencePhase(vw)
% function vw = setReferencePhase(vw);
% Prompt to ask reference phase, which is saved as vw.refPh
%JL

ttltxt = sprintf('Enter the Projection Reference Phase, to be saved as vw.refPh: ');
if isfield(vw,'refPh');
    def = {num2str(vw.refPh)};
else
    def = {'0'};
end;

answer = inputdlg('between 0 and 2*pi, or ROI',ttltxt,1,def);
if strcmpi(answer,'roi'),
    % compute mean value in ROI and set that to be reference phase
    amp  = getCurDataROI(vw,'amp');
    ph   = getCurDataROI(vw,'ph');
    inds = isfinite(amp) & isfinite(ph); % remove nans
    amp  = amp(inds);
    ph   = ph(inds);
    vals = -amp.*exp(1i*ph);
    vw.refPh = angle(mean(vals(:)))+pi;
else
    vals = str2num(answer{1});
    if isempty(vals)
        fprintf('[%s]:WARNING:You did not set reference phase.\n',mfilename);
        return;
    elseif ischar(vals) & strcmpi(vals,'roi'),
    else
        vw.refPh = vals(1);
    end
end
fprintf('[%s]:Reference phase: %.2frad.\n',mfilename,vw.refPh);
return
