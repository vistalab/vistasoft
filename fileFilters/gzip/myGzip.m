function myGzip(inFile)
%
% myGzip(inFile)
% 
% Simple wrapper for matlab's gzip function, which requires the JVM. If you
% are not running the JVM and are unix, then a system call to gunzip is
% done.
%
% HISTORY:
% 2006 .07.17 RFD: wrote it.

if(usejava('jvm'))
    gzip(inFile);
else
    if(isunix)
        unix(['gzip ' inFile]);
    else 
        error('Sorry- requires either the JVM or unix.')
    end
end
return