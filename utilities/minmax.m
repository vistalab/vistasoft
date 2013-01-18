function M = minmax(Y)
%
% M = minmax(Y);
%
% Return a 2-vector with the minimum and maximum values in a matrix.
%
%
% ras, 06/16/2008.
if isequal(class(Y), 'single')
	Y = double(Y);
elseif isequal(class(Y), 'cell')
    Y = double( [Y{:}] );
end

Y = Y(~isinf(Y) & ~isnan(Y));

M = [min(Y(:)) max(Y(:))];

return
