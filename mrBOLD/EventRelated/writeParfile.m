function status = writeParfile(par,parPath);
%
% status = writeParfile(par,[parPath]);
%
% writes a .par file (used by freesurfer and Rory's 
% mrVista tools using the information specified
% in the struct par.
%
% par should have at least 2 fields: 'onset',  specifying
% the onset times of each trial/block, and 'cond',  specifying
% number for the condition. These fields should be numeric arrays.
% They'll be the 1st and 2nd columns in the ASCII-text parfile.
% par may also have a 'label' field, which is a string cell; if present
% it will write the contents of each entry in the 3rd column of the 
% par file.
% 
% There is an alternate way of specifying condition labels and colors:
% If par has no field for 'label' or 'color' (or if these are empty), 
% but it has fields 'condNames' or 'condColors',  which contain a sequential
% list of the names/colors for each condition (starting from null),  then it
% will automatically fill out the label and/or color fields. 
%
% if parPath is omitted, will prompt a dialog asking where to save.
%
% ras 06/04.
% ras 10/06: figures out condition names, colors without needing to specify
% for each trial.
if ~exist('parPath') | isempty(parPath)
    [fname pth] = uiputfile('*.par', 'Name your saved parfile...');
    parPath = fullfile(pth,fname);
end

if ~isfield(par,'onset') | ~isfield(par,'cond')
    help writeParfile;
    return
end

if (~isfield(par, 'label') | isempty(par.label)) & (isfield(par, 'condNames'))
    % fill out each trial according to cond names 
    conds = unique(par.cond);
    for j = 1:length(par.condNames)
        I = find(par.cond==conds(j));    
        par.label(I) = repmat({par.condNames{j}}, size(I));
    end
end

if (~isfield(par, 'color') | isempty(par.color)) & (isfield(par, 'condColors'))
    % fill out each trial according to cond names
    conds = unique(par.cond);    
    for j = 1:length(par.condColors)
        I = find(par.cond==conds(j)); 
        par.color(I) = repmat({par.condColors{j}}, size(I));
    end
end

fid = fopen(parPath,'w');

for i = 1:length(par.onset)
    fprintf(fid, '%3.2f\t', par.onset(i));
    fprintf(fid, '%i\t', par.cond(i));
    
    if isfield(par,'label') && length(par.label) >= i
        fprintf(fid,'%s', par.label{i});
    end
    
    if isfield(par,'color') && length(par.color) >= i
        if ischar(par.color{i}), 
            par.color{i} = colorLookup(par.color{i});
        end
        fprintf(fid,'\t%s', num2str(par.color{i}));
    end
    
    fprintf(fid, '\n');
end

status = fclose(fid);
fprintf('Wrote parfile %s.\n',parPath);

return