function [mmPerPix,volSize,fileName,fileFormat] = readVolAnatHeader(fileName)
% [mmPerPix,volSize,fileName,fileFormat] = readVolAnatHeader([fileName])
%
% Reads the header from the vAnatomy.dat file specified by fileName (full path!).
%
% If fileName is omitted, a get file dialog appears.
%
% If the mmPerPix is not found in the vAnatomy file header, this function will look 
% for an UnfoldParams.mat file in the same dir.  If it finds it, it will get the 
% mmPerPix from there.  
%
% RETURNS:
%   * mmPerPix is the voxel size (in mm/pixel units)
%   * fileName is the full-path to the vAnatomy.dat file. (If 
%     you pass fileName in, you obviously don't need this. But 
%     it may be useful when the user selects the file.)
%   * fileFormat = 'dat' or 'nifti'
%
% 2001.02.20 RFD
% 2002.03.14 ARW Don't halt if mm per vox not found. Set to 1x1x1 and carry on with a warning.
% 2007.12.20 RFD Added support for NIFTI files.

if ~exist('fileName', 'var'), fileName = ''; end

% if fileName is empty, get the filename and path with a uigetfile
if isempty(fileName) || ~exist(fileName,'file')
    filterSpec = {'*.dat','dat files';'*.nii.gz;*.nii','NIFTI files';'*.*','All files'};
    [fname, fpath] = uigetfile(filterSpec, 'Select a vAnatomy file...');
    fileName = [fpath fname];
    if fname == 0
        % user cancelled
        return;
    end
    [fpath,fname,ext] = fileparts(fileName); %#ok<*ASGLU>
else
    [fpath,fname,ext] = fileparts(fileName);
end

% Check to see if this is a new NIFTI-format or old vAnatomy.dat format
if(strcmpi(ext,'.dat')),    fileFormat = 'dat';
else                        fileFormat = 'nifti';   end

if(strcmpi(fileFormat,'nifti'))
    % Just load the header
    ni = mrLoad(fileName, 'nifti');
    mmPerPix = ni.voxelSize(1:3);
    volSize = ni.dims(1:3);
else
    % Load old vAnatomy format

    % open file for reading
    vFile = fopen(fileName,'r');
    if vFile==-1
        myErrorDlg(['Couldn''t open ',fileName,'!'])
        return;
    end

    % set this to nan's in case the vAnatomy is old-style, in which
    % case it won't have mmPerPix in the header.
    mmPerPix = [nan,nan,nan];
    volSize = [nan,nan,nan];

    % read header: volSize and mmPerPix (if available)
    tmp = fscanf(vFile,'rows %f (%f mm/pixel)\n');
    volSize(1) = tmp(1);
    if length(tmp)>1, mmPerPix(1) = tmp(2); end;
    tmp = fscanf(vFile,'cols %f (%f mm/pixel)\n');
    volSize(2) = tmp(1);
    if length(tmp)>1, mmPerPix(2) = tmp(2); end;
    tmp = fscanf(vFile,'planes %f (%f mm/pixel)\n');
    volSize(3) = tmp(1);
    if length(tmp)>1, mmPerPix(3) = tmp(2); end;

    % Check that this is a valid header for a vAnatomy file. The next line should be '* \n'
    endOfHeader = '*';
    nextLine = fgets(vFile);
    if ~(length(nextLine)>=2 && nextLine(1)==endOfHeader)
        myErrorDlg(['vAnatomy file: ',fileName,' has invalid header']);
    end
    fclose(vFile);

    % If mmPerPix was not in the vAnatomy header, try to get it from UnfoldParams
    if(isnan(mmPerPix(1)) || isnan(mmPerPix(2)) || isnan(mmPerPix(3)))
        % Try to get the voxel size from the old UnfoldParams.mat file.
        % warning('volume_pix_size not available. Try to get it from the old UnfoldParams file.');
        eval('ufp = load(fullfile(fpath,''UnfoldParams.mat''));', 'ufp = [];');
        if(isfield(ufp, 'volume_pix_size'))
            mmPerPix = 1./ufp.volume_pix_size;
        else
            % Error: can't find mmPerPix
            %myErrorDlg('Can not determine volume voxel size. You need to create an UnfoldParams file.');
            % Display a warning and carry on:
            disp('Warning : Can not determine volume voxel size. Setting to 1x1x1mm.');
            mmPerPix=[1 1 1];
        end
    end
end

return
