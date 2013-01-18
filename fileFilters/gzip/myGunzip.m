function myGunzip(gzippedFile)
%
% myGunzip(gzippedFile)
% 
% Simple wrapper for matlab's gzip function, which requires the JVM. If you
% are not running the JVM and are unix, then a system call to gunzip is
% done.
%
% HISTORY:
% 2006 .07.17 RFD: wrote it.

if(isempty(dir(gzippedFile)))
  return;
end

if(usejava('jvm'))
    gunzip(gzippedFile);
else
    if(isunix)
        unix(['gunzip ' gzippedFile]);
    else 
        error('Sorry- requires either the JVM or unix.')
    end
end
return
