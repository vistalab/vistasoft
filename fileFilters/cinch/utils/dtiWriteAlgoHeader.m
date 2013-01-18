function dtiWriteAlgoHeader(headers, fid)

numalgos = length( headers );

for a = 1:numalgos
    algoH = headers(a);
    
    numchars = length( algoH.name );
    for c = 1:min([numchars 255-1])
        fwrite(fid,algoH.name(c),'char');
    end
    fwrite(fid,char(0),'char');
    for c = min([numchars+2 255+1]):255
        fwrite(fid,'g','char');
    end
    
    numchars = length( algoH.comments );
    for c = 1:min([numchars 255-1])
        fwrite(fid,algoH.comments(c),'char');
    end
    fwrite(fid,char(0),'char');
    for c = min([numchars+2 255+1]):255
        fwrite(fid,'g','char');
    end
    
    fwrite(fid,algoH.unique_id,'uint');
    
    % Write garbage at end for word alignment
    garb_size = dtiGetAlgoHeaderSizeWordAligned() - dtiGetAlgoHeaderSize();
    garbV = zeros(1,garb_size);
    fwrite(fid,garbV,'char');
end
 