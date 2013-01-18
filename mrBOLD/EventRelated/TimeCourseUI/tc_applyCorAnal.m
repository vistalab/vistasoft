function tc = tc_applyCorAnal(tc,params);
%
% tc = tc_applyCorAnal(tc,params);
%
% Apply a traveling-wave sinusoid analysis
% (corAnal) to the time course, and store
% the results in the tc.corAnal substruct.
%
% params: struct w/ params for the corAnal:
%   nCycles: # of cycles per scan for the fitted sinusoid.
%   frames: frames to use from the wholeTc. Default: use all frames.
% Pops up a dialog if omitted.
%
%
% ras, 09/05
if notDefined('tc'), tc = get(gcf,'UserData'); end

if notDefined('params')
    % put up dialog
    dlg(1).fieldName = 'nCycles';
    dlg(1).style = 'edit';
    dlg(1).string = '# Cycles per scan?';
    dlg(1).value = '8';

    dlg(2).fieldName = 'frames';
    dlg(2).style = 'edit';
    dlg(2).string = 'Frames to analyze in each run? (''all'' selects all)';
    dlg(2).value = 'all';
    params = generalDialog(dlg,'Apply corAnal to ROI time course...');

    params.nCycles = round(str2num(params.nCycles));
    if ~isempty(str2num(params.frames))
        params.frames = str2num(params.frames);
    else
        params.frames = 'all';
    end
end

nCycles = params.nCycles;
keepFrames = params.frames;

% get an index of those frames which are included in the analysis
if isequal(keepFrames, 'all')
    frames = 1:length(tc.wholeTc);
else
    frames = [];
    trs =  1:length(tc.wholeTc);
    runPerTR = er_resample(tc.trials.onsetFrames, tc.trials.run, trs)';
    runPerTR(runPerTR==0) = 1;  % gum
    for run = unique(runPerTR)
        framesInRun = trs(runPerTR==run);
        ok = intersect(keepFrames, 1:length(framesInRun));
        frames = [frames framesInRun(ok)];
    end
end

% update the 'frames' field to include these only
params.frames = frames;



%%%%%%%%%%%%%%%%%%%%
% COMPUTE COR ANAL %
%%%%%%%%%%%%%%%%%%%%
% get tSeries
tSeries = tc.wholeTc(params.frames)';

% figure out the # of scans this represents
nScans = length(unique(tc.trials.run));

% Compute Fourier transform
ft = fft(tSeries);
ft = ft(1:1+fix(size(ft, 1)/2), :);

% This quantity is proportional to the amplitude
scaledAmp = abs(ft);

% This is, in fact, the correct amplitude
amp = 2*(scaledAmp(nCycles*nScans+1,:))/size(tSeries,1);

% We use the scaled amp here which is OK for computing the
% correlation. Note that the noiseBand defines the portion
% of the spectrum to use for the noise metric. As such, this
% calculation now corresponds to the correlation of the fundamental
% stimulus sinusoid with a FILTERED version of the data, where
% noiseBand determines the passband of a square-edged bandpass
% filter.
noiseBand = 0; % check old code for more info
noiseIndices = CreateNoiseIndices(scaledAmp, nCycles, noiseBand);
sqrtsummagsq = sqrt(sum(scaledAmp(noiseIndices, :).^2));
co = scaledAmp(nCycles+1,:)./sqrtsummagsq;

clear scaledAmp

% Calculate phase:
% 1) add pi/2 so that it is in sine phase.
% 2) minus sign because sin(x-phi) is shifted to the right by phi.
% 3) Add 2pi to any negative values so phases increase from 0 to 2pi.
ph = -(pi/2) - angle(ft(nCycles+1,:));
ph(ph<0) = ph(ph<0)+pi*2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save Results in tc.corAnal field %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tc.corAnal.co = co;
tc.corAnal.amp = amp;
tc.corAnal.ph = ph;
tc.corAnal.nCycles = nCycles;
tc.corAnal.frames = frames;
tc.corAnal.tSeries = tSeries;
tc.corAnal.predictor = ...
    amp*sin((frames-1)*2*pi*nScans*nCycles/(frames(end))-ph);

if checkfields(tc, 'ui', 'fig') & ishandle(tc.ui.fig)
    set(tc.ui.fig, 'UserData', tc);
end

return


