function quenchStart()
%
% cinchStart()
%
%Author: dakers
%Purpose:
%   Start the Quench application on your platform.  
%   Runs for PCWIN and GLNX86. 
%

switch computer
    case 'PCWIN'
        srvPath = which('QUENCH.exe');
        dos([srvPath ' &']);        
    case 'GLNX86'
        srvPath = 'Quench';
        unix(sprintf('%s &', srvPath));
    case 'GLNXA64'
        srvPath = 'Quench';
        unix(sprintf('%s &', srvPath))    case 'MAC'
	srvPath = which('Quench.app');
	srvPath = [srvPath '/Contents/MacOS/Quench'];
	eval(['! ' srvPath ' &']);
    otherwise
        error(['Platform "' computer '" is not supported!']);
end
if(isempty(srvPath))
    error('Quench could not be found. See http://white.stanford.edu/ for installation instructions.');
end

% Give it time to come up
pause(3);
if(~quenchCheckServer())
    error('Quench was found but could not be started!');
end

return
