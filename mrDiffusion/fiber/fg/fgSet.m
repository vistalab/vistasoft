function fg = fgSet(fg,param,val,varargin)
%Set data in a fiber group
%
%  fgSet(fg,param,val,varargin)
%
% Parameter list
%
%     case 'name'
%     case 'type'
%     case {'colorrgb','color'}
%     case 'thickness'
%     case 'visible'
%         
%         % Fibers
%     case 'fibers'
%     case 'coordspace'
%         % In some cases, the fg might contain information telling us in which
%         % coordinate space its coordinates are set. This information is set
%         % as a struct. Each entry in the struct can be either a 4x4 xform
%         % matrix from the fiber coordinates to that space (with eye(4) for
%         % the space in which the coordinates are defined), or (if the xform
%         % is not know) an empty matrix.

%     case 'fibernames'
%     case 'fiberindex'
%     case 'tensors'
%         
%
% See also
%   fgCreate, fgGet
%
% Examples:
%
% (c) Stanford VISTA Team, 2011

% Check for input parameters
if notDefined('fg'),    error('fg structure required'); end
if notDefined('param'), error('param required'); end
if ~exist('val','var'), error('Value required'); end

% Squeeze out spaces and force lower case
param = mrvParamFormat(param);

switch param
    case 'name'
        fg.name = val;
    case 'type'
        fg.type = val;
    case {'colorrgb','color'}
        fg.colorRgb = val;
    case 'thickness'
        fg.thickness = val;
    case 'visible'
        fg.visible = val;
        
        % Fibers
    case 'fibers'
        % The fibers are set as
        fg.fibers = val;
    case 'coordspace'
        % In some cases, the fg might contain information telling us in which
        % coordinate space its coordinates are set. This information is set
        % as a struct. Each entry in the struct can be either a 4x4 xform
        % matrix from the fiber coordinates to that space (with eye(4) for
        % the space in which the coordinates are defined), or (if the xform
        % is not know) an empty matrix.
        
        % So there are two options:
        if length(varargin)==0
            % Either we want to set this one verbatim:
            fg.coordspace = val;
        else
            % Or we just want to set one of them, provided by name. For example: 
            % fgSet(fg, 'coordspace', 'acpc', eye(4))):
            fg.coordspace = setfield(fg.coordspace, val, varargin{1});
        end
        
        
    case 'fibernames'
        fg.fiberNames = val;
    case 'fiberindex'
        fg.fiberIndex = val;
    case 'tensors'
        fg.tensors  = val;
        
    otherwise
        error('Unknown fg parameter %s\n',param);
end

return
