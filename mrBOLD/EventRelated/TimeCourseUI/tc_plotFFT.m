function tc = tc_plotFFT(tc,stimFreq,pos, parent);
%
% tc = tc_plotFFT(tc, <stimFreq>, <pos>, <parent=tc.ui.plot panel>);
%
% Plot Fourier Transform of time course from
% ROI. Note that this plots the average of the
% time series averaged across voxels; if you're
% concerned about phase differences across voxels
% affecting the FFT, use plotMeanFFTSeries.
%
% stimFreq: frequency of stimuli (trials or cyclic stimuli). 
% Default: figures out from event timings.
%
% pos: position of axes to plot. Default: fills figure, w/ margins.
%
%
% ras 04/05.
if notDefined('tc'),      tc = get(gcf,'UserData');           end
if notDefined('pos'),     pos = [.15 .15 .7 .7];              end
if notDefined('parent'),  parent = tc.ui.plot;                end
if parent==gcf | parent==get(gcf, 'CurrentAxes')
    % make a uipanel to fit on the target
    parent = uipanel('Parent', parent, ...
        'Units', 'normalized', ...
        'BackgroundColor', get(gcf, 'Color'), ...
        'Position', [0 0 1 1])
end

% Calulate the FFT.
absFFT  = 2*abs(fft(tc.wholeTc)) / size(tc.wholeTc,1);
angleFFT = angle(fft(tc.wholeTc));

% delete legend, if it's been put up
other = findobj('Type','axes','Parent',gcf);
delete(other);

% b/c we want the TCUI to be independent of
% mrVista (not worry about keeping the view
% set to the right scan, etc), we'll want to infer
% the relevant cycle duration from the trial
% structure in each run. Calculate the max
% cycles as 1/2 the # of frames in a run:
firstRun = find(tc.trials.run==1);
nFrames = tc.trials.onsetFrames(firstRun(end));
maxCycles = round(nFrames/2);

% calculate cycles per scan of each element
% in absFFT (different from cycles per whole 
% time course, if it's the concatenation of 
% several scans):
nScans = length(unique(tc.trials.run));
step = max(1/4,1/nScans); % choose a nice step size
x = 1:step:maxCycles;
y = absFFT(round(nScans*x + 1));


% plot overall spectrum.
% cla;
% set(gca,'Position',pos);
axes('Position', pos, 'Parent', parent);
hold on;
plot(x,y,'--bo','LineWidth',2);
xlabel('Cycles Per Scan','FontSize',14);
ylabel('Percent modulation','FontSize',14) 

if notDefined('stimFreq')
	%% compute stimulus frequency in cycles/scan 
			
    % try to estimate trial frequency, highlight
    % those entries in the spectrum.
    tmp = diff(tc.trials.onsetFrames(tc.trials.cond>0)); % get time b/w trials
    tmp = tmp(tmp>1); % ignore single-trial changes
    if ~isempty(tmp)
        isi = unique(tmp);      % inter-stimulus interval
        if length(isi)>1
            count = hist(tmp,isi);  % find how often each isi occurs
            isi = isi(count==max(count)); % choose most frequent isi
            isi = isi(1);
		end
		
		% special case: if every other event is a baseline (cond==0),
		% then the stimulus frequency is probably determined by estimating
		% every other block (baseline+other); otherwise, a cycle is once
		% every block...
		if all(tc.trials.cond(1:2:end)==0) | all(tc.trials.cond(2:2:end)==0)
			stimFreq = floor(.5 * nFrames / isi); 
		else
	        stimFreq = floor(nFrames / isi); 
		end
    else
        % just guess...
        stimFreq = 8;
    end
end
ind = find(x>=stimFreq); % index of center pt.
rng = ind(1)-1:ind(1)+1;   % add a thickness
plot(x(rng), y(rng), 'ro-', 'LineWidth', 2);
set( gca, 'XTick', stimFreq:stimFreq:(max(x)+1) );
grid on

if tc.params.legend==1
    legend('Spectrum','Event Frequency');
end

% Compute the mean and std of the non-signal amplitudes.  Then compute the
% z-score of the signal amplitude w.r.t these other terms.  This appears as
% the Z-score in the plot.  This measures how many standard deviations the
% observed amplitude differs from the distribution of other amplitudes.
bsl = logical(ones(size(x)));
peak = ind(1);
bsl(peak) = 0;
zScore = (y(peak) - mean(y(bsl))) / std(y(bsl));
str = sprintf('Z-score: %0.2f',zScore);
text(x(peak)+2, max(y)*0.5, str, 'FontSize', 14, 'HorizontalAlignment', 'left');

% add the spectrum information to the tc struct
tc.fft.x = x;
tc.fft.y = y;
tc.fft.stimFreq = stimFreq;
tc.fft.peakIndex = peak;
tc.fft.zScore = zScore;
set(gcf,'UserData',tc);

return