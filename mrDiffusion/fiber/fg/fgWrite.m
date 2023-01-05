function fgWrite(fg,name,type)
% Write out a fiber group structure for use with Quench. Pdb format.
%
%  fgWrite(fg,[name],[type]) 
%
% INPUTS:
%     fg - Fiber group structure.
%   name - Name used to save the fiber group. Can bee a full path
%          terminating in a name. Defaults to the current directory with
%          the name in the fg.name field. 
%   type - File type to save as. 
%            Options are:
%             'pdb'    - quench file format [DEFAULT]
%             'quench' - same as 'pdb'                      
%             'mat'    - matlab file format
%             'tck'    - MRTRIX file format (also 'mrtrix'/'.tck')
%
%          * If "name" ends in either .pdb or .mat the correct file type
%            will be used.
%
% WEB RESOURCES:
%   mrvBrowseSVN('fgWrite');
%
% EXAMPLE USAGE:
%   fgWrite(fg,fg.name,'pdb');
% 
% See Also:
%   fgRead.m
% 
% 
% (C) Stanford VISTA, 2011
%     
%     Brent McPherson and Franco Pestilli 
%     Indiana University 2017

%% Check inputs

% Check that fg is a structure
if ~isstruct(fg) || ~isfield(fg, 'fibers')
    error('fg must be a fiber group structure with a fibers field.'); 
end

% Should we do this?  
% This will set fg.params = [] and fg.pathwayInfo = [].
% fg = dtiClearQuenchStats(fg);

% Check for name input variable and use fg.name if empty
if ~exist('name','var') || isempty(name) 
    name = fgGet(fg,'name'); 
end

% Check type and set to pdb by default
if ~exist('type','var') || isempty(type)
    type = 'pdb';
end

% If the name ends in '.mat' set type to 'mat'
[p n e] = fileparts(name);
if strcmp(e,'.mat')
    type = 'mat';
end

%% Write out the fibers
switch type
    case {'pdb', 'quench'}
        % Arguments are:
        % fg, fileName, xformToAcPc, xform, fiberToStrFlag, version
        mtrExportFibers(fg, name, [], [], [], 3);
    case 'mat'
        dtiWriteFiberGroup(fg, name);
    case {'tck', 'mrtrix', '.tck'}
        dtiExportFibersMrtrix(fg, name);
end

return
