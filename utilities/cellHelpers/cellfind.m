function I = cellfind(C,pattern)
% I = cellfind(cellArray,[pattern])
%
% Returns index vector I of cells containing a 
% desired pattern. Pattern can be anything that
% would be in a cell: a num, string, struct, another
% cell, etc. If pattern is omitted, I returns the
% indices of non-empty cells.
%
% Note the algorithm for finding a pattern isn't
% optimized to be fast, just convenient.
%
% ras 11/04: updated to include pattern finding
% bw/ab    : caught empty Cell condition

if isempty(C), I = []; return; end
if ndims(C) > 2, error('Cellfind doesn''t work on arrays > 2 dimensions.'); end

if ~iscell(C)
    help cellfind
    error('First argument must be a cell.')
end

if nargin < 2
    % no pattern, just find non-empty cells
	I=zeros(size(C));
	
	for t = 1:size(C,1)
        for u = 1:size(C,2)
            a = C{t,u};
            I(t,u)=~isempty(a);
        end
	end
else
    % find pattern
    for j = 1:size(C,1)
        for k = 1:size(C,2)
            I(j,k) = isequal(C{j,k},pattern);
        end
    end
end

I = find(I);

return
