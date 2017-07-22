function M = mrvMinmax(Y)
%
% M = mrvMinmax(Y);
%
% Return a 2-vector with the minimum and maximum values in a matrix.
%
% Example: Return the vector [1 100]:
%    M = mrvMinmax(magic(10));
%
% ras, 06/16/2008.
% JW: 11/30/2016 Renamed from minmax to mrvMinmax to avoid conflict with
%                the Matlab function minmax in the nnet toolbox
%

if isequal(class(Y), 'single')
	Y = double(Y);
elseif isequal(class(Y), 'cell')
    Y = double( [Y{:}] );
end

Y = Y(~isinf(Y) & ~isnan(Y));

M = [min(Y(:)) max(Y(:))];

return
