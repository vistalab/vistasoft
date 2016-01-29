function env  = mrvGetEvironment()
% function env  = mrvGetEvironment()
%
% Copyright Stanford team, mrVista, 2011
%
% FP, 6/30/2011
%
% See also mrvValidate.m and mrvValidateAll.m

% save the matlab version being used
env.matlabVer = ver;

% save the architecture
env.computer = computer;

% vistasoft revision number
env.vistaDir = mrvRootPath;
if ~strncmp(computer,'PC',2)
    [status, env.vistaVer] = system(['svnversion ', mrvRootPath]); %#ok<ASGLU>
else
    env.vistaVer = 'PC. Figure it out';
end

return