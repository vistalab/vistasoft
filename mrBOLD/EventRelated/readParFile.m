function [onsets, conds, labels, colors] = readParFile(parFileName);
% [onsets, conds, labels, colors] = readParFile(parFileName);
% read information from a .par file.
%
% PAR FILE FORMAT:
% parfiles are simple tab-delimited ASCII text files which contain
% experiment information. All rows in a par file should have the
% following format:
%   onset time, secs [TAB] condition number [TAB] label [TAB] color
%
% The onset time and condition numbers are required, the labels and colors
% are optional. label can be any string, color should be of the format
% [R G B] (though you don't need the brackets). 
%
% For both label and colors, you only need to set the value for the 
% first trial of a given condition; you don't need to set it for each
% trial.
% 
%
% 9/02 by ras
% 01/04 ras: added ability to read labels/comments as a third column, and 
% made all outputs in row rather than column format.
% 04/05 ras: sorts all rows by onset time.
% 02/06 ras: now reads in colors as well.
if ~exist(parFileName,'file') & ~strncmp(parFileName(end-3:end),'.par',4)
    parFileName = [parFileName '.par'];
end

% if the file still isn't found, it may be given relative to 
% the directory pwd/stim/parFiles (this is how I reference them
% in mrLoadRet -- ras):
if ~exist(parFileName,'file')
    parFileName = fullfile(pwd,'stim','parfiles',parFileName);
end

% if still can't find it, give up
if ~exist(parFileName,'file')
    [a b c] = fileparts(parFileName);
    error(sprintf('%s%s does not exist',b,c));
end

[fidPar message] = fopen(parFileName,'r');

if fidPar==-1
  disp(message)
  error(['ERROR: problem reading .par file ' parFileName '.']);
end

onsets = []; conds = []; labels = {}; colors = {};
while ~feof(fidPar)
    ln = fgetl(fidPar);
    if isempty(ln) | isempty(findstr(sprintf('\t'),ln)), break; end
    ln(ln==sprintf('\n')) = '';
    
    vals = explode(sprintf('\t'), ln);
    
    vals{1} = str2num(vals{1});
    vals{2} = str2num(vals{2});

    % make sure we have an onset time and condition number, otherwise the
    % line we read is invalid and we should break out of loop without error
    if isempty(vals{1}) || isempty(vals{2}), break; end

    %sscanf(ln,'%f\t%i\t%s %s %s');
    onsets(end+1) = vals{1};
    conds(end+1)  = vals{2};
    
        
    if (length(vals) > 2) & (nargout > 2)
        labels{end+1} = vals{3};
    else
        labels{end+1} = [];
    end
    
    if (length(vals) > 3) & (nargout > 3)
        colors{end+1} = str2num(vals{4});
    else
        colors{end+1} = [];
    end    
end

% sort by onsets, so rows need not
% be in chronological order
[onsets I] = sort(onsets);
conds = conds(I);
if ~isempty(labels),   labels = labels(I);  end
if ~isempty(colors),   colors = colors(I);  end
    
fclose(fidPar);

return
