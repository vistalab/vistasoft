function byteStream = mrMeshTcpSerializeParams(params)
%
%    byteStream = mrMeshTcpSerializeParams(params)
%
% Turns the Matlab structure params into a byte-stream suitable for
% TCP transmission using the mrMesh protocol.  That protocol uses pnet.
%
% See also:  mrMesh, pnet_WriteMsg and pnet_ReadMsg
%
% HISTORY
% 2007.04.12 RFD wrote it.


if(~isstruct(params))
    byteStream=params;
    return;
end

byteStream = [];
if(~isempty(params))
    % the termination char is a new-line
    termSeq = uint8(sprintf('\n'));
    eq = uint8(' = ');
    % arrays (non-scalars) are sent in raw for and are enclodes in
    % single-quotes. Scalars are sent in text (sprintf) form.
    sq = uint8('''');
    fnStr = fieldnames(params);
    
    for(ii=1:length(fnStr))
        data = getfield(params,fnStr{ii});
        sz = size(data);
        data = data(:)';
        fn = uint8(fnStr{ii});
        if(ischar(data))
            fn = uint8(fnStr{ii});
            byteStream = [byteStream fn eq sq data sq termSeq];
            
        elseif(length(data)>1)
            % *** FIX ME ***
            % The current mrMesh server expects all numeric arrays to be
            % sent as doubles. This sends 8x more data than necessary when
            % sending uint8's! We should fix the server so that it can
            % accept various data types.
            dimStr = sprintf('%d,',sz);
            fn = uint8(sprintf('%s[%s]',fnStr{ii},dimStr(1:end-1)));
            byteStream = [byteStream fn eq sq typecast(double(data),'uint8') sq termSeq];
        else
            fn = uint8(fnStr{ii});
            if(isinteger(data))
                byteStream = [byteStream fn eq uint8(sprintf('%d',data)) termSeq];
            else
                byteStream = [byteStream fn eq uint8(sprintf('%f',data)) termSeq];
            end
        end
    end
end

byteStream(end+1) = 0;

return
