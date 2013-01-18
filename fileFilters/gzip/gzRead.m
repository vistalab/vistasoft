function data = gzRead(gzFp, numItems, precision)
%
% data = gzRead(gzFp, numItems, precision)
%
% HISTORY:
% 2007.02.12 RFD: wrote it.

if isempty(gzFp) || ~isfield(gzFp,'inStream') || isempty(gzFp.inStream)
    error('Can''t read file! Is it open?');
end

if(~exist('precision','var')||isempty(precision))
    precision = 'uint8';
end

% Matlab can't pass a primitive array pointer, so we have to loop!
%bytes = zeros(1,numBytes,'uint8');
%gzFp.gzipInStream.read(bufObj, startByte, numBytes);
%bytes = bufObj;
if(precision(1)=='*') precision = precision(2:end); end
if(strcmp(precision,'char')) 
    precision = 'uint8'; 
    makeChar = true;
else
    makeChar = false;
end
switch(precision)
    case {'int8','uint8','char'},
        bytesPerItem = 1;
    case {'int16','uint16'},
        bytesPerItem = 2;
    case {'int32','uint32','single'},
        bytesPerItem = 4;
    case {'int64','uint64','double'},
        bytesPerItem = 8;
    otherwise,
        error(['Precision ''' precision ''' not supported.']);
end

tmp = zeros(bytesPerItem,1,'uint8');
data = zeros(numItems,1,precision);
for(ii=1:numItems)
    for(jj=1:bytesPerItem)
        tmp(jj) = gzFp.inStream.read;
    end
    data(ii) = typecast(tmp,precision);
end
if(makeChar)
    data = char(data);
end
gzFp.curPos = gzFp.curPos + numItems*bytesPerItem;
if(gzFp.swapBytes) data = swapbytes(data); end
return;