function cinchStart()
%
% cinchStart()
%
%Author: dakers
%Purpose:
%   Start the CINCH application on your platform.  
%   Runs for PCWIN and GLNX86. 
%

switch computer
    case 'PCWIN'
        srvPath = which('CINCH.exe');
        dos([srvPath ' &']);        
    case 'GLNX86'
        srvPath = which('CINCH.glx');
        unix(sprintf('%s &', srvPath));
	case 'MAC'
		srvPath = which('CINCH.app');
		srvPath = [srvPath '/Contents/MacOS/CINCH'];
		eval(['! ' srvPath ' &']);
    otherwise
        error(['Platform "' computer '" is not supported!']);
end
if(isempty(srvPath))
    error('CINCH could not be found. See http://sirl.stanford.edu/newlm/index.php/DTI#CINCH for installation instructions.');
end

% Give it time to come up
pause(3);
if(~cinchCheckServer())
    error('CINCH was found but could not be started!');
end

return