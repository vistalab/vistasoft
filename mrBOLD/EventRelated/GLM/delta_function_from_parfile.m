function s = delta_function_from_parfile(parName,tr,nFrames)
% s = delta_function_from_parfile(parName,[tr],[nFrames])
% 
% Given the name of a parfile, reads in the info
% and produces a matrix s that has as rows frames
% and as columns conditions (stimulus types). Each
% column is a delta function of onsets.
%
% (If a cell-of-strings is provided for parName,
% will load a list of parfiles, adding each run 
% as the 3rd dimension.)
%
% 11/04 ras.
if notDefined('tr')
    tr = [];
end

if notDefined('nFrames')
    nFrames = [];
end

s = [];

if iscell(parName)
	% recursively get delta functions for each file, returning a 
	% 3D matrix (slices = runs, deals w/ different-length runs)
	onsets = [];  conds = [];  offset = 0;
    for p = 1:length(parName)
		s_sub = delta_function_from_parfile(parName{p}, tr, nFrames);
		if p==1
			s = s_sub;
		elseif size(s, 1)==size(s_sub, 1)
			s(:,:,p) = s_sub;
		elseif size(s, 1) > size(s_sub, 1)
			s(1:size(s_sub, 1),:,p) = s_sub;
		elseif size(s, 1) < size(s_sub, 1)
			s(size(s_sub, 1),end,p-1) = 0;
			s(:,:,p) = s_sub;
		end
	end
	return
else
	[onsets conds] = readParFile(parName);
end

% 'shifting' parfile onsets, e.g. to correct for variations in
% when the scan started, may produce negative onsets, which we 
% don't need:
ok = find(onsets>=0);
onsets = onsets(ok);
conds = conds(ok);
if isempty(tr)
    % estimate from parfile
    tr = onsets(2) - onsets(1);
end
whichConds = unique(conds);
nConds = length(whichConds);
if isempty(nFrames)
    nFrames = ceil(onsets(end) ./ tr);
end

% initialize s
s = zeros(nFrames, nConds);

% insert 1s at onset frames
for c = 1:nConds
    trials = onsets(conds==whichConds(c)) / tr;
    s(trials+1,c) = 1;
end

% truncate if it goes over
s = s(1:nFrames,:);

return
