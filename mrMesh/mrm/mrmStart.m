function windowID = mrmStart(windowID,host)
% Start the mrMesh server on your platform.
%
%    windowID = mrmStart(windowID,host)
%
% Runs for PCWIN OSX GLNX86 and GLNX86_64.
%
% Examples:
%
%  To start the server without opening a window, use
%       windowID = mrmStart(-1,'localhost')
%  or   mrmStart;
%
%  To start the server and open window 3, use
%       windowID = mrmStart(3,'localhost')
% or    windowID = mrmStart(3);
%
%
% BW (c) Stanford Vista, 2008

if ieNotDefined('windowID'), windowID = -1; end
if ieNotDefined('host'), host = 'localhost'; end

switch computer
    case {'PCWIN', 'PCWIN64'}
        srvPath = which('mrMeshSrv.exe');
        dos([srvPath ' &']);
    case {'GLNX86'}
        srvPath = which('mrMeshSrv.glx');
        unix(sprintf('%s &', srvPath));
    case {'GLNXA64'}
        % check whether we are using fedora, and if so, what version
        [s,r]=unix('cat /proc/version | grep fc14.x86_64'); %#ok<*ASGLU>
        [t v] = unix('cat /proc/version | grep centos'); %#ok<*ASGLU>
        [x y] = unix('cat /proc/version | grep Ubuntu'); %#ok<*ASGLU>
        if ~isempty(strfind(r,'fc14.x86_64')),
            srvPath = which('mrMeshSrv_FC14.glxa64');
         elseif ~isempty(strfind(v,'centos'))
             srvPath = which('mrMeshSrv_Centos.glxa64');
        elseif ~isempty(strfind(y,'Ubuntu'))
            disp('Ubuntu system detected: Loading mrMeshSrv for Ubuntu 12.04')
            srvPath = which('mrMeshSrv_Ubuntu1204.glxa64');
        else
            srvPath = which('mrMeshSrv.glxa64');
        end
        %unix(sprintf('%s &', srvPath));
        %eval(sprintf('! %s &', srvPath))
        eval(['! ' srvPath ' &']);
    case {'MACI64','MACI','MAC'}
        %  srvPath = vistaRootPath;
        srvPath = mrvDirup(which('mrMeshSrv.glx'),2);
        srvPath = [srvPath '/mrMeshMac.app/Contents/MacOS/mrMeshSrv'];
        cmd = ['! ' srvPath ' &'];
        system(cmd);
    otherwise
        error(['Platform "' computer '" is not supported!']);
end

if windowID >= 0
    % Some annoying inter-process communication pause.  Do not remove.  Ask
    % Ress or Bob about this.
    pause(2);
    windowID = mrMesh(host, windowID, 'refresh');
    pause(1);
else
    windowID = -1;
end

return
