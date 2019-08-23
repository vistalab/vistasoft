function headers = dtiGetFgParams(fg)
%
%  Parse fg.params into a struct of key/value pairs. fg.params is a bit awkward to parse out 
%  because all key/values are stored in a single dimention array as a second element of an 
%  cell array. This function makes it much easier to access those parameters.
%
% INPUTS:
%     fg - vistasoft fiber group structure
% 
% OUTPUT:
%     headers -	struct containing the key/values
%

headers = struct();

if ~isempty(fg.params)
    if size(fg.params,1) == 1
        fg.params = fg.params';
    end
    hdr = fg.params{2, 1};
    if strfind(hdr{1}, 'mrtrix tracks')

        % for all the header fields
        for ii = 2:length(hdr)

            % for each element
            tmp = hdr{ii};

            % split string and value at delimiter
            nvpair = strsplit(tmp, ': ');

            % skip 'file' field to exactly match the mrtrix header
            if strcmp(nvpair{1}, 'file')
                continue;
            end

            % add header info to output structure
            headers.(nvpair{1}) = nvpair{2};
        end
    else
        % print warning if there is no mrtrix header information
        warning('The TCK file HEADER information was not found in fg.params.')
    end
end
