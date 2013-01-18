function greaterThanML7=checkML7

% greaterThanML7=checkML7;
% Returns 1 if the version of matlab used is >= 7

vv = version;
v=str2num(vv(1));
greaterThanML7= (v >= 7);

return
