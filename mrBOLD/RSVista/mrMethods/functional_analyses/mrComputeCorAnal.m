function [ph, co, amp] = mrComputeCorAnal(mr,params);
% Compute a Coherence Analysis on an mr object.
% 
% [ph, co, amp] = mrComputeCorAnal(mr,[params]);
%
% A coherence analysis calculates the coherence, phase, and scaled
% amplitude of a fitted sinusoid to time series (4-D MR) data. 
%
% mr: mr object (see mrLoad). Can also be a string specifying the path
% to an mr data file, or a cell-of-strings specifying many mr objects --
% in which case coherence anals will be run an each mr object in turn.
%
% The params struct, if omitted, will be specified with a dialog. 
% Otherwise, it needs the following fields:
%
% nCycles: number of cycles to apply to the whole time series.
% Default: prompt user in the command window (may replace w/ nice
% GUI later).
%
% frames: frames from the time series to analyze. If omitted or empty,
% will include all frames from the time series. But you could, e.g.,
% omit junk frames before or after the main cycles.
%
% noiseBand: a flag to specify which bands in the power spectrum to use
%            when calculating the co and ph maps. It can be specified in
%            the following format:
% 0                [Default behavior] -- use entire power spectrum
% non-zero scalar  Bandpass filter the power spectrum around the
%                  signal frequency, using this value as half-width
%                  (value is in frequency samples, e.g., 1/framePeriod)
% vector           Filter explicitly using given values. Spectral values
%                  are assumed to be zero at the signal frequency. For
%                  example, the vector [-5 -4 -3 -2 -1 0 1 2] would bandpass
%                  the values starting 5 frequency samples below the signal
%                  through 2 samples above the signal.
% pure imaginary   If vector is purely imaginary, then the number it
%                  indicates is what you take away from the full noise Band.
%                  Example: the vector [0 5 10]*sqrt(-1) means noiseIndices
%                  is 1:size(amps,1) but without [0 5 10]+nCycles 
%                  frequencies.
% 
% saveDir: directory in which to save the mr data files for co, amp, 
% and ph. Default is the same directory as the mr file. If empty or
% omitted
%
% As I understand it, the coherence analysis has also been
% referred to as a correlation analysis (hence "corAnal"),
% although technically the co field represents coherence 
% with the sinusoid rather than correlation.
%
%
% ras, 07/05.
if notDefined('mr'), mr = mrLoad;                           end

if iscell(mr),
    % run a corAnal on each mr object
    for i = 1:length(mr)
        [ph{i}, co{i}, amp{i}] = mrComputeCorAnal(mr{i},params);
    end
    return
end

% load any paths specified as strings
if ischar(mr), mr = mrLoad(mr);                             end

if notDefined('params'), params = mrParamsCorAnal(mr);      end
if isempty(params), return; end; % exit quietly

% check to make sure this is actually a time series -- the 4th dim > 1
if size(mr.data,4) <= 1
    error('Non-time-series mr data specified.')
end

% parse parameters
nCycles = params.nCycles;
detrend = params.detrend;
noiseBand = params.noiseBand;
frames = params.frames;
saveDir = params.saveDir;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detrend; get data in 2D mr.data format: time points x voxels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h = mrvWaitbar(0,'Coherence Analysis: Getting tSeries');

if detrend==1
    mr = mrDetrend(mr);
end

nVoxels = prod(mr.dims(1:3));
nFrames = size(mr.data,4);
mr.data = permute(mr.data,[4 1 2 3]);
mr.data = reshape(mr.data,[nFrames nVoxels]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute Fourier transform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mrvWaitbar(1/5,h,'Coherence Analysis: Applying Fourier Transform');

ft = fft(mr.data);
ft = ft(1:1+fix(size(ft, 1)/2), :);

mrvWaitbar(1/4,h,'Coherence Analysis: Computing Amplitude');

% This quantity is proportional to the amplitude
scaledAmp = abs(ft);

% This is in fact, the correct amplitude
amp = 2*(scaledAmp(nCycles+1,:))/size(mr.data,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We use the scaled amp here which is OK for computing the
% correlation. Note that the noiseBand defines the portion
% of the spectrum to use for the noise metric. As such, this
% calculation now corresponds to the correlation of the fundamental
% stimulus sinusoid with a FILTERED version of the data, where
% noiseBand determines the passband of a square-edged bandpass 
% filter.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mrvWaitbar(2/5,h,'Coherence Analysis: Computing Coherence');
noiseIndices = createNoiseIndices(scaledAmp, nCycles, noiseBand);
sqrtsummagsq = sqrt(sum(scaledAmp(noiseIndices, :).^2));
co = scaledAmp(nCycles+1,:)./sqrtsummagsq;

clear scaledAmp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate phase:
% 1) add pi/2 so that it is in sine phase.
% 2) minus sign because sin(x-phi) is shifted to the right by phi.
% 3) Add 2pi to any negative values so phases increase from 0 to 2pi.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mrvWaitbar(3/5,h,'Coherence Analysis: Computing Phase');
ph = -(pi/2) - angle(ft(nCycles+1,:));
ph(ph<0) = ph(ph<0)+pi*2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert each field into an mr object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mrvWaitbar(4/5,h,'Coherence Analysis: Creating mr objects');
fields = setdiff(fieldnames(mr),'data'); % all fields except data field

tmp = co;
clear co;
co.data = reshape(tmp,mr.dims(1:3));
for i = fields, co.(i{1}) = mr.(i{1});   end
co.name = sprintf('Coherence, %s',mr.name);
co.path = fullfile(saveDir,'ph');
co.dataUnits = 'Normalized Units';
co.dataRange = [min(co.data(:)) max(co.data(:))];
co.params = params;

tmp = ph;
clear ph;
ph.data = reshape(tmp,mr.dims(1:3));
for i = fields, ph.(i{1}) = mr.(i{1});   end
ph.name = sprintf('Phase %s',mr.name);
ph.path = fullfile(saveDir,'ph');
ph.dataUnits = 'Radians';
ph.dataRange = [-pi pi];
ph.params = params;

tmp = amp;
clear amp;
amp.data = reshape(tmp,mr.dims(1:3));
for i = fields, amp.(i{1}) = mr.(i{1});  end
amp.name = sprintf('Amplitude, %s',mr.name);
amp.path = fullfile(saveDir,'ph');
amp.dataRange = [min(amp.data(:)) max(amp.data(:))];
amp.params = params;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save separate co, amp, ph files, if a directory is selected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mrvWaitbar(5/5,h,'Coherence Analysis: Saving if necessary');
if ~isempty(saveDir)
    mrSave(co,fullfile(saveDir,'co'));
    mrSave(ph,fullfile(saveDir,'ph'));
    mrSave(amp,fullfile(saveDir,'amp'));
end    

close(h)

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function noiseIndices = createNoiseIndices(amps, nCycles, noiseBand)
% noiseIndices = createNoiseIndices(amps, nCycles, noiseBand);
%
% Creates noise indices corresponding to a frequency band to 
% be used for later processing / analyses (like detrending). The
% noiseBand input has the following forms:
%
% 0                Default behavior -- use entire power spectrum
% non-zero scalar  Bandpass filter the power spectrum around the
%                  signal frequency, using this value as half-width
% vector           Filter explicitly using given values. Spectral values
%                  are assumed to be zero at the signal frequency. For
%                  example, the vector [-5 -4 -3 -2 -1 0 1 2] would 
%                  bandpass the values starting 5 frequency samples below 
%                  the signal through 2 samples above the signal.
%    JL add 11/04  If vector is purely imaginary, then the number it
%                  indicates is what you take away from the full noise Band.
%                  Example: the vector [0 5 10]*sqrt(-1) means noiseIndices
%                  is 1:size(amps,1) but without [0 5 10]+nCycles 
%                  frequencies.
%
% Ress, 8/02
% Sayres, 7/05 imported into mrVista 2.0, as part of mrComputeCorAnal.
nAmps = size(amps, 1);
if length(noiseBand) > 1
    if isreal(noiseBand);
        noiseIndices = 1 + nCycles + noiseBand;
    else
        noiseIndices = setdiff(1:nAmps, imag(noiseBand) + nCycles + 1);
    end
elseif noiseBand == 0
  noiseIndices = 1:nAmps;
else
  nB = fix(noiseBand/2);
  noiseIndices = 1 + nCycles + (-nB:nB);
end

noiseIndices = noiseIndices((noiseIndices <= nAmps) & (noiseIndices > 0));

return
