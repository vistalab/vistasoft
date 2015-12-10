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
%  fName:  Path to file saved on disk
%
% Example:
%   fName = sdmGet('https://sni-sdm.stanford.edu/api/acquisitions/55adf6956c6e/file/9999.31469779911316754284_nifti.bval?user=', ...
%                  'lmperry@stanford.edu', '/tmp/nifti.nii.gz')
%
% LMP/BW Vistasoft Team, 2015


%% Combine permalink and username to generate the download link

% Handle new permalinks which don't have '?user='
if isempty(strfind(pLink, '?user='))
    pLink = [pLink, '?user='];
end

link = [pLink, uName];


%% Parse fName from the permalink if 'fName' was not provided.
if notDefined('fName') 
    [~, f, e] = fileparts(pLink);
    t_e = explode('?', e);
    out_dir = tempname;
    mkdir(out_dir);
    fName = fullfile(out_dir, [ f, t_e{1}]);
end


%% Use urlwrwite to retrieve the data and store it
urlwrite(link, fName);

return
