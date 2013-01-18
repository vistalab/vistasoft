function gzClose(fp)
%
% gzClose(fp)
%
% HISTORY:
% 2007.02.12 RFD: wrote it.

if ~isempty(fp.inStream)
     fp.inStream.close;
end
if ~isempty(fp.fileInStream)
     fp.fileInStream.close;
end

return;