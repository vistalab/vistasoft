function format = mrParseFormat(pth);
% Figure out the format of a mrVista 2.0 mr struct, based on 
% the path name.
%
% format = mrParseFormat(pth);
%
% ras, 12/05.

% get list of possible file formats
[formats, filters, strPatterns] = mrLoadFormats;

[p, f, ext] = fileparts(pth);
ind = [];
if ~isempty(ext) & ~isempty(strmatch(ext, strPatterns))
    % found the format based on extension
    ind = strmatch(ext, strPatterns);
elseif ~isempty(f) & ~isempty(strmatch(p,strPatterns))
    % This would work for I-files and 1.0 anat files
    ind = strmatch(p, strPatterns);
elseif exist(pth, 'dir')
	% DICOM / I-files check
	dicomCheck = dir( fullfile(pth, '*.dcm') );
	if ~isempty(dicomCheck)
		format = 'dicom';
		return
	end
	
	ifileCheck = dir(fullfile(pth,'I*'));
	if ~isempty(ifileCheck)
		format = 'ifile';
		return
	end
end

% since there are several .mat file options, disambiguate
if isequal(lower(ext), '.mat')
    % check for 2.0 mat file format
    mr = load(pth);
	
    if isfield(mr, 'data')
        ind = cellfind(formats, 'mat');
		
    elseif isfield(mr, 'tSeries') 
        ind = cellfind(formats, '1.0tSeries');
		
    elseif isfield(mr, 'anat') % strncmp(f,'anat',4)
        ind = cellfind(formats, '1.0anat');
		
    elseif isfield(mr, 'map')
        tmp = load(pth);
        if isfield(tmp, 'map')
			ind = cellfind(formats, '1.0map');
		end
		
    elseif isequal(f, 'corAnal')
        ind = cellfind(formats, '1.0corAnal');

    else
        error('Unknown file format!');
		
    end
end

% also several .img options (single ANALYZE vs. many files), disambiguate
if isequal(lower(ext), '.img')
	% 07/07: assumption: if you specify a file with .img, you want to load
	% just that file. If you want to load a directory of ANALYZE images,
	% you'll need to specify the directory name, and/or manually specify
	% the 'vfiles' format. So, for the purpose of this function, if we
	% got here, assume it's one ANALYZE file (may need to check other
	% files to make this consistent):
	ind = cellfind(formats, 'analyze');
	ind = ind(1);
end

% if no format found, or too many, ask for disambiguation
if isempty(ind) | length(ind) > 1
    ui.style = 'listbox';
    ui.string = sprintf('Select a format for %s:',pth);
    ui.list = filters(2:end,2); % remove 'all files' option
    ui.value = 1;
    ui.fieldName = 'format';
    resp = generalDialog(ui);
    format = formats{cellfind(ui.list,resp.format{1})};
else
    format = formats{ind(1)};        
end

return
