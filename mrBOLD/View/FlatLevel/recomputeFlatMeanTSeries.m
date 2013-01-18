function recomputeFlatMeanTSeries(view,scans,levels);
% recomputeFlatMeanTSeries(view,[scans],[levels]);
%
% For a flat level view, recompute the mean 
% tSeries across view levels, asking the 
% user which levels to use for the computation.
%
% ras 10/04.
promptUserFlag = 0;

if ieNotDefined('scans')
    % default to all scans in view
    scans = 1:numScans(view);
    promptUserFlag = 1;
end

if ieNotDefined('levels')
    % default to all scans in view
    levels = 1:max(view.numLevels);
    promptUserFlag = 1;
end

% if any args were left implicit, put up
% a dialog to let the user modify / confirm:
% if they were all specified, I figure it's part
% of a script.
if promptUserFlag==1
	prompt={'Scans to recompute' 'Gray levels to use for mean tSeries'};
	def={num2str(scans) num2str(levels)};
	dlgTitle='Recompute the mean tSeries across gray levels?';
	lineNo=1;
	answer=inputdlg(prompt,dlgTitle,lineNo,def);
    scans = str2num(answer{1});
    levels = str2num(answer{2});
end

% run through the selected scans, recomputing the mean
% tSeries across gray levels
meanTSeriesFlatLevels(view,scans,levels);

return
