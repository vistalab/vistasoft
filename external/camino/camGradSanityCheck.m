function camGradSanityCheck(dt_bdouble_filename, raw_filename)
%Check something or other using camino software
%
%   camGradSanityCheck(raw_bfloat_filename,scheme_filename,raw_filename)
%
%
% (c) Stanford VISTA, Sherbondy, 2010


%cmd = ['dtfit ' raw_bfloat_filename ' ' scheme_filename ' | dteig | pdview `analyzeheader -printprogargs ' raw_filename ' pdview`', ' &'];

cmd = ['cat ' dt_bdouble_filename ' | dteig | pdview `analyzeheader -printprogargs ' raw_filename ' pdview`', ' &'];
display(cmd);
system(cmd,'-echo');

return