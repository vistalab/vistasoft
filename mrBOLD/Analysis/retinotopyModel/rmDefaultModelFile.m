function rmfile = rmDefaultModelFile(view, dataType);
% Find the most recent and complete retinotopy model for a given data type,
% and return the path to the file.
%
%  rmfile = rmDefaultModelFile([view], [dataType=cur data type]);
%
% BACKGROUND:
% There are different types of pRF models created in the solution process.
% Models ending in '-gFit' are grid fit models, and are the least
% preferred. Models ending in '-sFit' are search fit models; up until
% recently, they were the most preferred. Around August 2008, Serge updated
% the code to produce a third type of model, '-fFit', for 'final fit', in
% which the results of the search fit are applied back to the original
% data. (I take it, for '-sFit' models, the variance explained was based on
% the residual left over from the grid fit stage).
%
% This code first checks for any 'fFit' models, and if it finds them, loads
% the most recently-created one. Failing that, it checks the 'sFit', then
% the 'gFit' models. If any file is found, it loads the model as well as
% the default maps ('rmLoadDefault'). Otherwise, it errors.
%
% The code also preferentially checks for models solved on the whole data
% set, rather than just an ROI.
%
% ras, 03/2009.
if notDefined('view'),		view = getCurView;				end
if notDefined('dataType'),	dataType = view.curDataType;	end

% ensure dataType is a string
if isnumeric(dataType)
	mrGlobals;
	dataType = dataTYPES(dataType).name;
end

% find the most recent final-fit pRF model ('-fFit')
modelDir = fullfile(viewDir(view), dataType);
pattern = fullfile(modelDir, '*-fFit.mat');
w = dir(pattern);

if isempty(w) 
	% check for a simple search fit '-sFit':
	altPattern = fullfile(modelDir, '*-sFit.mat');
	w = dir(altPattern);
end

if isempty(w)  % still empty? try grid fit 
	altPattern2 = fullfile(modelDir, '*-gFit.mat');
	w = dir(altPattern2);
end

if length(w) > 1
	% first, see if we can sub-select models solved on 'all' the data,
	% rather than restricted to an 'roi'
	for ii = 1:length(w)
		tmp = load( fullfile(modelDir, w(ii).name), 'params' );
		whichData{ii} = tmp.params.wData;
	end
	ok = cellfind(whichData, 'all');
	if ~isempty(ok)
		w = w(ok);
	end
	
	% now, sort the remaining files by date, and take the most recent:
	for ii = 1:length(w)
		val(ii) = datenum(w(ii).date);
	end
	[tmp tmp_I] = sort(val);
	w = w(tmp_I(end));
	
elseif isempty(w)
	error( sprintf('No model found: %s %s.', pwd, dataType) );
	
end

rmfile = fullfile(modelDir, w.name);

return
