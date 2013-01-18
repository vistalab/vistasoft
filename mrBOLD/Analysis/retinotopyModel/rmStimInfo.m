function rmStimInfo(view, fid);
% rmStimInfo - get information of current loaded rm stimulus
% Useful if you want to predict the reponses to a scan using a previously
% solved rm and a new stimulus. Loading the model generally also loads the
% stimulus associated with the model, which may be different from the
% stimulus associated with the current scan.
%
% rmStimInfo(view, id);
%
% 11/2006 SOD: wrote it.
%  9/2008  JW: added 'fid' as input argument to permit printing to file

% to do: need more specific information?

if notDefined('view'), view = getCurView; end;
if notDefined('fid'), fid = 1; end

% load params
try
    params = viewGet(view,'rmparams');
catch,
    params = [];
end;

% if no parameters are loaded exit
if isempty(params),
    disp(sprintf('[%s]:No stimulus parameters loaded.',mfilename));
    return;
end;

nscans = numel(params.stim);

% give info:
fprintf(fid,'\n---------------------------------------\n');
fprintf(fid,'[%s]:There are stimulus descriptions for %d scan(s).\n',mfilename, nscans);


for n=1:nscans,
    fprintf(fid,'\tScan %d: %s\n',    n,params.stim(n).stimType);
    
    fprintf(fid,'\t\tStim size: %d deg (radius)\n',  params.stim(n).stimSize);
    
    fprintf(fid,'\t\tNumber of frames: %d\n', params.stim(n).nFrames);

    if strcmpi(params.stim(n).stimType, 'stimfromscan')
        fprintf(fid,'\t\tFilter Type: %s\n',     params.stim(n).imFilter);
        fprintf(fid,'\t\tImage file:\n\t\t\t%s\n',     params.stim(n).imFile);
        fprintf(fid,'\t\tParameter file:\n\t\t\t%s\n', params.stim(n).paramsFile);
    end


end
fprintf(fid,'---------------------------------------\n\n');

return
