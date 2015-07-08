function sdmFile = sdmGet(pLink,uName,sdmFile)
% Retrieve a file from an sdm instance
%
%   sdmFile = sdmGet(pLink,uName,[sdmFile])
%
% Inputs
%  pLink:  Permalink from the SDM
%  uName:  The sdm user name with appropriate permission
%  sdmFile: Location to write the file
%
% Return
%  sdmFile:  Returned file
%
% Example:
%
% LMP/BW Vistasoft Team, 2015

link = [pLink,uName];

%% Use urlwrwite to retrieve the data and store it
if notDefined('sdmFile')
    sdmFile = [tempname,'.nii.gz'];
end

urlwrite(link,sdmFile);

end