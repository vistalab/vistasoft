function stim = stimParse(stim, mr);
% Parse a stimulus argument specification, loading files as they're
% necessary, and returning a single struct with information for 
% all the specified runs.
%
% stim = stimParse(stim, [mr]);
%
% stim can be specified as (1) a stim struct; (2) a path to 
% a stimulus file (.par file); (3) a cell array of paths. 
% This code parses the format and always returns
% a struct containing the concatenated stimulus information for all
% runs specified.
%
% mr is an optional mr struct which can be used when calling stimLoad.
%
% ras, 10/2005.
if ischar(stim) | iscell(stim)
    if exist('mr', 'var')
        stim = stimLoad(stim, mr);
    else
        stim = stimLoad(stim);
    end
elseif ~isstruct(stim),
    help(mfilename);
    error('stim is specified in the wrong format');
end
return
