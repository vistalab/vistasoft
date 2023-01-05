function b = mrvFileNameExt(f)
% Return the  name and extension from the full path, f
%
%     b = mrvFileNameExt(f)
%
% Example:
%
%  b = mrvFileNameExt(mrvSelectFile);
%

[p,n,e] = fileparts(f);
b = [n e];

return