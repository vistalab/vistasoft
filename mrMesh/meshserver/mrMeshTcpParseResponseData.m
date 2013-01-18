function respStruct = mrMeshTcpParseResponseData(respByteStream)
%
% respStruct = mrMeshTcpParseResponseData(respByteStream)
%
% Parses the mrMesh-encoded byteStream into a matlab structure.
%
% HISTORY
% 2007.04.12 RFD wrote it.

respStruct = [];
if(isempty(respByteStream))
    return;
end

done = false;
while(~done)
    % max param name length is 200
    numBytesLeft = length(respByteStream);
    eq = strfind(respByteStream(1:min(204,numBytesLeft)),' = ');
    if(isempty(eq))
        done = true;
    else
        fn = char(respByteStream(1:eq(1)-1));
        if(fn(end)==']')
            % then it's an array
            sep = strfind(fn,'[');
            dims = str2num(fn(sep(1):end));
            fn = fn(1:sep(1)-1);
            % read all the returned bytes as doubles (8 bytes per element)
            dataEnd = eq+3+prod(dims)*8+1;
            data = respByteStream(eq+3:dataEnd);
            % the data block should begin and end with a ' (ascii=39)
            if(data(1)~=39||data(end)~=39)
                done = true;
                warning('response parsing teminated abnormally.');
            else
                data = typecast(data(2:end-1),'double');
                if(length(dims)>1)
                    data = reshape(data,dims);
                end
                respStruct = setfield(respStruct, fn, data);
                respByteStream = respByteStream(dataEnd(1)+2:end);
            end
        else
            % scalar
            % MaxDoubleAsString = 40
            dataEnd = strfind(respByteStream(1:min(245,numBytesLeft)),sprintf('\n'));
            data = char(respByteStream(eq+3:dataEnd(1)));
            respStruct = setfield(respStruct, fn, str2double(data));
            respByteStream = respByteStream(dataEnd(1)+1:end);
        end
    end
end
if isempty(respStruct)
    respStruct=respByteStream;
end