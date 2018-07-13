function [status, fsHome] = mrvFreeSurferExists(varargin)
% Check whether FREESURFER_HOME is in the matlab environment
%
% Syntax
%   status = mrvFreeSurferExist;
%
% Returns true if FREESURFER_HOME is in the environment.
%
% Inputs
% Optional key/value
%   'verbose' - Prints out the FREESURFER_HOME variable
%
% Returns
% Wandell, Vistasoft Team, 2018
% 
% See also
%  mrvFreeSurferConfg (NYI)

%%
p = inputParser;
p.addParameter('verbose',false,@islogical);
p.parse(varargin{:});

%%
fsHome = getenv('FREESURFER_HOME');

if isempty(fsHome),     status = 0;
else,                   status = 1;
end

if p.Results.verbose
    fprintf('\nFREESURFER_HOME is "%s"\n',fsHome);
end

end
