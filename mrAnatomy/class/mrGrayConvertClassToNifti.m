function mrGrayConvertClassToNifti(leftClassFile, rightClassFile, vAnatFile, t1NiftiFile)
% Convert mrGray class files to the NIFTI format used by ITKGray
% 
%   mrGrayConvertClassToNifti(leftClassFile, rightClassFile, vAnatFile, t1NiftiFile)
% 
% The vAnatFile and the t1NiftiFile may not align.  The NIFTI data are
% always in AC-PC coordinate frame and the old vAnatomy.dat files were not
% placed in this frame.  Hence, we find the transformation between the
% vAnatomy.dat and the new T1-NIFTI and apply that to the classifiction
% data. 
%
% The left and right classification data are stored in a single file.
% 
% See also:
%   analyze2mrGray, mrGray2Analyze
%
% Example:
%   mrGrayConvertClassToNifti - User is queried for files
%
% HISTORY:
% 2007.09.19 RFD wrote it.


labels = mrGrayGetLabels;

% false here will do 6-parameter rigid body alignment, true will do
% 9-parameter aligninment to account for scale differences.
adjustScales = true;

%% Get input file names
if(~exist('leftClassFile','var'))
    opts = {'*.class;*.Class;*.CLASS', 'Class files (*.class)'; '*.*','All Files (*.*)'};
    [f, p]=uigetfile(opts, 'Pick a mrGray class file for the left hemisphere');
    if(isequal(f,0)|| isequal(p,0)) 
        leftClassFile = ''; 
    else
        if(isempty(p)), p = pwd; end
        leftClassFile = fullFile(p,f);
    end
end
if(~exist('rightClassFile','var'))
    default = fullfile(fileparts(leftClassFile),'right.class');
    opts = {'*.class;*.Class;*.CLASS', 'Class files (*.class)'; '*.*','All Files (*.*)'};
    [f, p]=uigetfile(opts, 'Pick a mrGray class file for the right hemisphere',default);
    if(isequal(f,0)|| isequal(p,0)) 
        rightClassFile = '';
    else
        if(isempty(p)), p = pwd; end
        rightClassFile = fullFile(p,f);
    end
end
if(~exist('vAnatFile','var')||isempty(vAnatFile))
    default = fullfile(fileparts(rightClassFile),'vAnatomy.dat');
    opts = {'*.dat;*.Dat;*.DAT', 'MrGray dat files (*.dat)'; '*.nii;*.nii.gz', 'NIFTI files (*.nii,*.nii.gz)'; '*.*','All Files (*.*)'};
    [f, p]=uigetfile(opts, 'Pick a mrGray vAnatomy file',default);
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    vAnatFile = fullFile(p,f);
end

if(~exist('t1NiftiFile','var')||isempty(t1NiftiFile))
    default = fullfile(fileparts(vAnatFile),'vAnatomy.nii.gz');
    opts = {'*.nii;*.nii.gz', 'NIFTI files (*.nii,*.nii.gz)'; '*.*','All Files (*.*)'};
    [f, p]=uigetfile(opts, 'Pick a NIFTI anatomy file',default);
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    t1NiftiFile = fullFile(p,f);
end

[p,f,e] = fileparts(t1NiftiFile);
if(isempty(p)), p = pwd; end
if(strcmpi(e,'.gz')), [junk,f] = fileparts(f); end
outFileBaseName = fullfile(p, f);
outFileName = [outFileBaseName '_class.nii.gz'];
if(exist(outFileName,'file'))
    [f,p] = uiputfile('*.nii.gz','Save new NIFTI class file as...',outFileName);
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    outFileName = fullfile(p,f);
    [p,f,e] = fileparts(outFileName);
    if(strcmpi(e,'.gz')), [junk,f] = fileparts(f); end
    outFileBaseName = fullfile(p, f);
end
disp(['NIFTI classification will be saved in ' outFileName]);

%% Read the data
% Allow t1NiftiFile and mrGrayClassFile to be passed as either filenames or
% structs that have already been loaded from file.
if(~isstruct(t1NiftiFile))
    t1NiftiFile = niftiRead(t1NiftiFile);
end

[vAnat,vAnatMm] = readVolAnat(vAnatFile);
if(all(vAnatMm==0)) 
    warning('vAnat voxel size is indeterminate - using [1 1 1]...'); %#ok<WNTAG>
    vAnatMm = [1 1 1]; 
end

%% Find the xForm between the vAnatomy data and the T1 NIFTI file data
[xformVAnatToAcpc] = dtiXformVanatCompute(t1NiftiFile.data, t1NiftiFile.qto_xyz, vAnat, vAnatMm, [], adjustScales);

% Create a bounding box identical to the nifti file bb.
bb = mrAnatXformCoords(t1NiftiFile.qto_xyz, [1 1 1; t1NiftiFile.dim]);
xform    = inv(xformVAnatToAcpc);
mm       = t1NiftiFile.pixdim;
interp   = [1 1 1 0 0 0];
outXform = t1NiftiFile.qto_xyz;
sz       = t1NiftiFile.dim;
vAnatSize = size(vAnat); %#ok<NASGU>
save([outFileBaseName '_xformToVanat.mat'],'sz','bb','mm','xform','vAnatSize');

% If you are concerned and want to check the alignments at this point use:
% newAnat = mrAnatResliceSpm(vAnat, xform, bb, mm, interp);
% showMontage(mrAnatHistogramClip(double(newAnat),0.4,0.99)-mrAnatHistogramClip(double(t1NiftiFile.data),0.4,0.99));
clear t1NiftiFile vAnat;
newClass = zeros(sz,'uint8');
 
% Get the left class file
if(~isempty(leftClassFile))
    if(~isstruct(leftClassFile))
        leftClassFile = readClassFile(leftClassFile, 0, 0);
    end
    disp('Resampling the left classification volumes...');
    cd = permute(leftClassFile.data,[2 1 3]);
    clear leftClassFile;
    types = unique(cd(:));
    types(types==0) = [];
    newTypes = mrGrayConvertClassTypeToLabel(types, 'l', labels);
    for(ii=1:numel(types))
    	c = double(cd==types(ii));
        c = mrAnatResliceSpm(c, xform, bb, mm, interp, false);
        newClass(c>=0.5) = newTypes(ii);
    end
    clear cd type newTypes;
end

% Get the right class file
if(~isempty(rightClassFile))
    if(~isstruct(rightClassFile))
        rightClassFile = readClassFile(rightClassFile, 0, 0);
    end
    disp('Resampling the right classification volumes...');
    cd = permute(rightClassFile.data,[2 1 3]);
    clear rightClassFile;
    types = unique(cd(:));
    types(types==0) = [];
    newTypes = mrGrayConvertClassTypeToLabel(types, 'r', labels);
    for(ii=1:numel(types))
    	c = double(cd==types(ii));
        c = mrAnatResliceSpm(c, xform, bb, mm, interp, false);
        newClass(c>=0.5) = newTypes(ii);
    end
    clear cd type;
end

% Both the right and left classification data are saved in a single file.
% They are transformed into the T1 NIFTI format.
disp(['Saving ' outFileName '...']);
dtiWriteNiftiWrapper(newClass, outXform, outFileName, 1, 'mrGray2 segmentation');

return;
