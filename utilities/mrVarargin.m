function yourStruct = mrVarargin(yourStruct,varArgIn)
%  
%  fucntion yourStruct = mrVarargin(yourStruct,varArgIn)
% 
%  This funciton is a wrapper/loop for varargin that takes as input a
%  structure and 'varargin' from the calling function and loops over
%  varargin to set the input structure's fields and check to make sure that
%  the field names in varargin are valid.
%  
% INPUT:
%       yourStruct - a structure with fields
%       varArgIn   - varargin argument from the calling funciton.
%       
% OUTPUT:
%       yourStruct - your original structure with fields set by varargin
% 
% EXAMPLE USAGE:
%       Pass the 'varargin' variable from the calling function to this
%       function from within the original funciton.
%       # Given the call to ctrInitBatchParams:
%         'ctrParams = ctrInitBatchParams(varargin)'
%       # The last line of that function will be:
%         'ctrParams = mrVarargin(ctrParams,varargin);'
%       # This will return ctrParams with the proper fields set by the
%         original varargin input.
%       IN ctrInitBatchParams:
%       'ctrParams = mrVarargin(ctrParams,varargin);'
%       Replaces the following lines of code:
%           if ~isempty(varargin)
%               for ii = 1:2:numel(varargin)-1
%                   if isfield(ctrParams,varargin{ii})
%                   ctrParams = setfield(ctrParams, varargin{ii}, varargin{ii+1}); %#ok<*SFLD>
%                   else
%                       warning('"%s" is not a valid field name!\n',varargin{ii}); %#ok<WNTAG>
%                   end
%               end
%           end
% 
% SEE ALSO:
%       ctrInitBatchParams (uses this function)
%       dtiInitParams (uses this function)
% 
% WEB RESOURCES:
%       mrvBrowseSVN('mrVarargin');
% 
% (C) Stanford University, VISTA 2011 [lmp]
% 

%% Varargin

if ~isempty(varArgIn)
    for ii = 1:2:numel(varArgIn)-1
        if isfield(yourStruct,varArgIn{ii})
        yourStruct = setfield(yourStruct, varArgIn{ii}, varArgIn{ii+1}); %#ok<*SFLD>
        else
            warning('"%s" is not a valid field name.\n',varArgIn{ii}); %#ok<WNTAG>
        end
    end
end

return