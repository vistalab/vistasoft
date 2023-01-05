function found = existDataType(dataTypeName,dataTypes,fullMatch)
%
%      found = existDataType([dataTypeName],[dataTypes],[fullMatch])
%
%   Check whether a dataType with dataTypeName exists in the mrSESSION structure.
%
%   If a full match to the dataType name is not found, then we return
%   found=0.
%   
%   If a full match is found, mrSESSION.dataTypes(found) is the dataType. 
%
%   If a partial match (fullMatch = 0) is requested, then existDataType() can
%   find several matches (i.e., whenever the first part of the data type name matches
%   the dataTypeName string). In this case, found returns a list of indices
%   whose names match the dataTypeName.  If no matches are found, then
%   found = 0 is returned.
%   
%   Examples:
%       existDataType('Atlases',dataTypes,0) returns a list of partial matches
%        mrSESSION.dataTypes(found) all begin with the phrase 'Atlases', such as
%        'Atlases-1'.
%   
% dataTypes: optional dataTypes structure. Default is to use the global dataTYPES.
%
% djh, 3/2001

global dataTYPES

if ~exist('dataTypes','var') || isempty(dataTypes),  dataTypes = dataTYPES; end
if ~exist('fullMatch','var'), fullMatch = 1; end

ndataTypes = length(dataTypes);

if fullMatch
    found = 0;
    for ii=1:ndataTypes
        if strcmp(dtGet(dataTypes(ii), 'Name'),dataTypeName);
            found = ii;
            return;
        end
    end
else
    found = zeros(1,ndataTypes);
    for ii=1:ndataTypes
        found(ii) =  strncmp(dtGet(dataTypes(ii), 'Name'),dataTypeName,length(dataTypeName));
    end
    found = find(found);
    if isempty(found), found = 0; end
end


return;


