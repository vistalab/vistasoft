function mrvInstall
%Install libraries and framework for VISTASOFT mex-files.
%
%   mrvInstall
%
% Prior to using mrVista we need to make sure that Visual Studio C
% libraries are installed on the local computer.  Matlab enables this using
% the executable vcredist_Mumble.exe.  This installation calls that
% function to make sure this computer has the libraries installed.
%
% We also require certain DLLs to be installed.  These are included with
% the VISTASOFT distribution.  If they are not present in your system
% folder, we copy them for you.
%
% To learn more about the mex-files issues - a plague on the Mathworks -
% see the Mathworks page: 
%
% http://www.mathworks.com/support/solutions/data/1-2223MW.html

disp('Checking VISATSOFT installation.');

switch(computer)
    case 'PCWIN'
        disp('Windows, 32-bit, installation');

        % Visual C redistributable library installation
        visCexe = fullfile(matlabroot,'bin','win32','vcredist_x86.exe');
        disp('Checking and possibly installing .NET framework.')
        disp('This can take several minutes')
        dos(visCexe);

        % Copy the three dll files to the system folder.  We should check
        % some day whether these are actually necessary.
        disp('Checking for visualization library (.dll) files.');
        if isempty(dir('C:\\Windows\System32\msvcp70.dll'))
            disp('You are missing msvcp70.dll.');

            s = fullfile(mrvRootPath,'Utilities','installation-dll','msvcp70.dll');
            dest = 'C:\Windows\System32\msvcp70.dll';
            [status,message] = copyfile(s,dest);
            if ~status, disp(message),disp('msvcp70.dll copy failed!!!')
            else                 disp('msvcp70.dll copied to system folder')
            end
        end

        if isempty(dir('C:\\Windows\System32\msvcr70.dll'))
            disp('You are missing msvcr70.dll.');

            s = fullfile(mrvRootPath,'Utilities','installation-dll','msvcr70.dll');
            dest = 'C:\Windows\System32\msvcr70.dll';
            [status,message] = copyfile(s,dest);
            if ~status, disp(message),disp('msvcr70.dll copy failed!!!')
            else                 disp('msvcr70.dll copied to system folder')
            end
        end

        if isempty(dir('C:\\Windows\System32\msvcr70d.dll'))
            disp('You are missing msvcr70d.dll.');

            s = fullfile(mrvRootPath,'Utilities','installation-dll','msvcr70d.dll');
            dest = 'C:\Windows\System32\msvcr70d.dll';
            [status,message] = copyfile(s,dest);
            if ~status, disp(message),disp('msvcr70d.dll copy failed!!!')
            else                 disp('msvcr70d.dll copied to system folder')
            end
        end

    case 'PCWIN64'
        disp('Windows, 64-bit, installation');
        disp('Windows, 32-bit, installation');

        % Visual C redistributable library installation
        visCexe = fullfile(matlabroot,'bin','win64','vcredist_x64.exe');
        disp('Checking and possibly installing .NET framework.')
        dos(visCexe);

        % Copy the three dll files to the system folder.  We should check
        % some day whether these are actually necessary.
        disp('Checking for visualization library (.dll) files.');
        if isempty(dir('C:\\Windows\sysWOW64\msvcp70.dll'))
            disp('You are missing msvcp70.dll.');

            s = fullfile(mrvRootPath,'Utilities','installation-dll','msvcp70.dll');
            dest = 'C:\Windows\sysWOW64\msvcp70.dll';
            [status,message] = copyfile(s,dest);
            if ~status, disp(message),disp('msvcp70.dll copy failed!!!')
            else                 disp('msvcp70.dll copied to system folder')
            end
        end

        if isempty(dir('C:\\Windows\sysWOW64\msvcr70.dll'))
            disp('You are missing msvcr70.dll.');

            s = fullfile(mrvRootPath,'Utilities','installation-dll','msvcr70.dll');
            dest = 'C:\Windows\sysWOW64\msvcr70.dll';
            [status,message] = copyfile(s,dest);
            if ~status, disp(message),disp('msvcr70.dll copy failed!!!')
            else                 disp('msvcr70.dll copied to system folder')
            end
        end

        if isempty(dir('C:\\Windows\sysWOW64\msvcr70d.dll'))
            disp('You are missing msvcr70d.dll.');

            s = fullfile(mrvRootPath,'Utilities','installation-dll','msvcr70d.dll');
            dest = 'C:\Windows\sysWOW64\msvcr70d.dll';
            [status,message] = copyfile(s,dest);
            if ~status, disp(message),disp('msvcr70d.dll copy failed!!!')
            else                 disp('msvcr70d.dll copied to system folder')
            end
        end

    case 'MACI'
        disp('Mac OSX on x86');
    case 'GLNX86'
        disp('GNU Linux on x86')
    case 'GLNXA64'
        disp('GNU Linux on x86_64-bit')
    otherwise
        disp('Unknown computer type.  No action taken');
end


