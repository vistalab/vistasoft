function gzFp = gzOpen(filename,permission,endian)
%
% gzFp = gzOpen(filename,permission,machineFormat)
%
% HISTORY:
% 2007.02.12 RFD: wrote it.

if ~usejava('jvm')
    error([mfilename ' requires Java to run.']);
end

if(~exist('permission','var')||isempty(permission))
    permission = 'r';
end
if(~exist('endian','var')||isempty(endian))
    endian = 'native';
end
[c,mxsz,native] = computer;

if(permission~='r')
    error(['Permission ''' permission ''' is not supported.']);
end

try
   gzFp.fileInStream = java.io.BufferedInputStream(java.io.FileInputStream(java.io.File(filename)));
catch
   % Unable to access file
   if exist('gzFp','var') && ~isempty(gzFp.fileInStream)
     gzFp.fileInStream.close;
   end
   eid = sprintf('%s:javaOpenError',mfilename);
   error(eid,'Could not open file "%s" for reading.',filename);
end

try
   gzFp.inStream = java.util.zip.GZIPInputStream(gzFp.fileInStream);
catch
   % Not in gzip format
   gzFp.inStream = gzFp.fileInStream;
end
gzFp.fileName = filename;
gzFp.permission = permission;
gzFp.curPos = 0;
if(gzFp.inStream.markSupported)
    % Mark the beginning of the stream so that we can seek from the
    % beginning by using 'reset'.
    % Unfortunately, this doesn't work! We get no excpetion, but 'reset'
    % does nothing.
    gzFp.inStream.mark(1000);
end

if(strcmpi(endian,'n') || strcmpi(endian,'native') || (strcmpi(native,'l') ...
        && (strcmpi(endian,'l')||strcmpi(endian,'ieee-le')||strcmpi(endian,'ieee-le.l64'))))
    gzFp.swapBytes = false;
else
    gzFp.swapBytes = true;
end
return;