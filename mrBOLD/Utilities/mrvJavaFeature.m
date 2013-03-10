function javaFigs = mrvJavaFeature(javaFigs)
% Turn off javafigures in certain versions of Matlab
%
%    javaFigs = mrvJavaFeature(javaFigs)
%
% Rory turned off Java Figure features in versions 7 - 7.3 because java was
% buggy for Mathworks.  Starting in 7.4 (Matlab 2007a), Mathworks disabled
% this possibility. THey now think that java works great and they want you
% to report any bugs.  So, we only disable for the relevant versions.
%
% There are many places in the code where Rory did this.   Rather than
% finding them all and writing out this little bit, I wrote this routine
% which we should use to replace Rory's test code.  In the fullness of
% time, as everyone migrates beyond Matlab 7.4, we can eliminate these
% calls, too.
%
% Example - You need to alter code like this:
%
%  javaFigs = mrvJavaFeature;
%
% .... code here
%
%  mrvJavaFeature(javaFigs);
% 2007 by BAW. 
warning('You are calling an obsolote function: mrvJavaFeature. Please remove it from your code.');
javaFigs = []; 
return;

% If the person sent in a javaFigs variable, they want us to restore
if notDefined('javaFigs'), javaFigs = []; 
else feature('javafigures',javaFigs); return;
end

% Otherwise, they want us to turn it off for certain versions of Matlab,
% specified here
version = ver('Matlab');
matlabVersion = version.Version;    
mVersion = str2double(matlabVersion(1:3));
mMinorVersion = str2double(matlabVersion(3:end));

if ( (mVersion == 7) && (mMinorVersion < 4)) % version 7, < 7.4
    javaFigs = feature('javafigures');
    if ispref('VISTA', 'javaOn') % seems to work diff't for diff't machines
        feature('javafigures', getpref('VISTA', 'javaOn'));
    else
        feature('javafigures', 0);
    end
end

return

