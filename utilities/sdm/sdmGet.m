function fName = sdmGet(pLink,uName,fName)
% Retrieve a file from an sdm instance
%
%   sdmFile = sdmGet(pLink,uName,[sdmFile])
%
% Inputs
%  pLink:  Permalink from the SDM
%  uName:  The sdm user name with appropriate permission
%  fName:  Location and/or filename to write the file
%
% Return
%  fName:  Returned file
%
% Example:
%
% LMP/BW Vistasoft Team, 2015

link = [pLink,uName];

%% Use urlwrwite to retrieve the data and store it
if notDefined('sdmFile') 
    [~, f, e] = fileparts(pLink);
    t_e = explode('?',e);
    fName = fullfile(tempdir,[ f, t_e{1}]);
end

urlwrite(link,fName);

return