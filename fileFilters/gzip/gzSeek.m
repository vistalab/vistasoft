function err = gzSeek(gzFp, skipBytes, origin)
%
% err = gzSeek(gzFp, skipBytes, origin)
%
% HISTORY:
% 2007.02.12 RFD: wrote it.

if isempty(gzFp) || ~isfield(gzFp,'inStream') || isempty(gzFp.inStream)
    disp('Can''t read file! Is it open?');
    err = -1;
    return;
end

if(~exist('origin','var')||isempty(origin))
    origin = 0;
end

if((isnumeric(origin)&&origin==-1) || strcmpi(origin,'bof'))
    if(gzFp.inStream.markSupported)
        gzFp.inStream.reset;
    elseif(skipBytes>=gzFp.curPos)
        % If we just want to go forward, then we can do that
        skipBytes = skipBytes - gzFp.curPos;
    else
        % Reset isn't supported
        disp('reset not supported- can''t skip from beginning.');
        err = -1;
        return;
    end
elseif((isnumeric(origin)&&origin==1) || strcmpi(origin,'eof'))
    disp('''eof'' option not supported.');
    err = -1;
    return;
end

if(skipBytes>0)
    gzFp.inStream.skip(int32(skipBytes));
    gzFp.curPos = gzFp.curPos+skipBytes;
elseif(skipBytes<0)
    disp('negative skip not supported.');
    err = -1;
    return;
end

return;