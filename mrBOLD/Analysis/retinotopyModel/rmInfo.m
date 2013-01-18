function rmInfo(view, fid)
% rmInfo - get information of current loaded model
% Useful if you switch between models and you forgot which one is
% loaded, or where/how it was defined (does not need to be the
% current dataset).
%
% rmInfo(view, id);
%
% 11/2006 SOD: wrote it.
%  9/2008  JW: minor edit: added 'fid' as input argument to permit printing
%  to file

% to do: need more specific information?

if notDefined('view'), view = getCurView; end;
if notDefined('fid'), fid = 1; end
% load file
try
	rmFile = viewGet(view,'rmFile');
catch %#ok<CTCH>
	rmFile = [];
end;

% if no model is loaded exit
if isempty(rmFile),
	fprintf('[%s]:No model loaded.',mfilename);
	return;
end;

% load model
a=load(rmFile);
modelName = cell(numel(a.model,1));
for n=1:numel(a.model),
	modelName{n} = rmGet(a.model{n},'desc');
end;
stimName = cell(numel(a.params.stim,1));
for n=1:numel(a.params.stim),
	stimName{n} = a.params.stim(n).stimType;
end;

% give info:
fprintf(fid,'\n---------------------------------------\n');
fprintf(fid,'[%s]:Model file: %s\n',mfilename,rmFile);
fprintf(fid,'\tIt contains %d models:\n',numel(modelName));

% give the model names
for n=1:numel(modelName),
	fprintf(fid,'\t\tModel %d: %s\n',n,modelName{n});
end;

% report on the source data for the model 
fprintf(fid,['\tThese models were estimated using %d fMRI scans ' ...
	'containing:\n'],numel(stimName));
for n=1:numel(stimName),
	fprintf(fid,'\t\tScan %d: %s\n',n,stimName{n});
end;

% report on whether the model was a refinement of a previous model
fprintf(fid,['\tThese models were build from the following model ' ...
	'estimates:\n'],numel(stimName));
ii = numel(a.params.matFileName);
if ii==1,
	fprintf(fid,'\t\t This was an independent estimate.\n');
else
	for n=1:numel(a.params.matFileName)-1,
		fprintf(fid,['\t\t This estimate (voxels with percent variance ' ...
			'explained > %.1f%%) was refined from: \n\t\t\t%s\n'],...
			a.params.analysis.fmins.vethresh.*100,a.params.matFileName{n});
	end;
end

% report on whether the model covered all the data, or an ROI
if isequal( a.params.wData, 'roi' )
	fprintf(fid, '\tThese models were applied only to the ROI:\n');
	fprintf(fid, '\t\t%s  (%i voxels).\n', a.params.roi.name, ...
			size(a.params.roi.coords, 2));
else
	fprintf(fid,'\tThese models were applied to the whole data set.\n');
end

fprintf(fid,'---------------------------------------\n\n');

return
