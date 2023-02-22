function [b0,dt6] = dtiInterpDt6(mmPerVoxOut, dt6PathName, outPathName)
%
% [b0,dt6] = dtiInterpDt6(mmPerVoxOut, b0PathName, outPathName)
%
% Takes dt6 file and upsamples b0 and dt6 data to desired resolution
% Uses C versions of pajevic and interp3 algorithms.
% The input file should be already preped using dtiMakeDt6 to 
% some resolution
%
% HISTORY:
% 2004.02.27 GSM (gmulye@white.stanford.edu) wrote it (based on
% dtiMakeDt6)

if ~exist('mmPerVoxOut','var') | isempty(mmPerVoxOut)
    mmPerVoxOut = [1 1 1];
end

if ~exist('dt6PathName','var') | isempty(dt6PathName)
   [f, p] = uigetfile({'*.mat','dt6 files (*.mat)';'*.*','All files'}, 'Select one of the dt6 files...');
   if(isnumeric(f)) error('Need a dt6 file to continue...'); end
   dt6PathName = fullfile(p, f);
   disp(dt6PathName);
end

% Upsampling tensors
disp('Interpolating tensors...');
oldDt6File = load(dt6PathName);
dt6 = oldDt6File.dt6;
xform = oldDt6File.xformToAcPc;
mmPerVoxIn = oldDt6File.mmPerVox;
sz = size(dt6);
boundingBox = [0 0 0; sz(1:3).*mmPerVoxIn-1]; %with this config, A(i) = A(2i-2)
%===================================
%Ripped from dtiResliceTensorAffine
%===================================
%We leave out all the transforms in dtiTensorAffine
%Tensors do not have to be rotated or brought to image space
x = (boundingBox(1,1):mmPerVoxOut(1):boundingBox(2,1));
y = (boundingBox(1,2):mmPerVoxOut(2):boundingBox(2,2));
z = (boundingBox(1,3):mmPerVoxOut(3):boundingBox(2,3));

[X,Y,Z] = meshgrid(x, y, z);
clear x y z;
coords = [X(:) Y(:) Z(:)]; %coords is Nx3
newSize = size(X);
clear X Y Z;
% HACK TO FIND CORRECT PAJEVIC LIBRARY
old = pwd;
cd(fileparts(which('dtiTensorInterp_Pajevic')));
dt6 = dtiTensorInterp_Pajevic(dt6, coords, mmPerVoxIn, 1, mmPerVoxIn./2);
cd(old);
dt6 = reshape(dt6, [newSize, 6]);


% Upsampling B0 grid
disp('Interpolating B0...');
% mmPerVox = b0.cannonical_mmPerVox;
% notes = b0.notes;
% xformToAnat = b0.anatXform;
% xformToTal = b0.talXform;
% xformToAcPc = b0.acpcXform;
% b0 = int16(round(b0.cannonical_img));
% anat.img = int16(t1.cannonical_img);
% anat.mmPerVox = t1.cannonical_mmPerVox;
% anat.xformToTal = t1.talXform;
% anat.xformToAcPc = t1.acpcXform;
% save(fullfile(outPathName,'dt6'), 'dt6', 'mmPerVox', 'notes', 'xformToAnat', 'xformToTal', 'xformToAcPc', 'b0', 'anat');

%============================
%Ripped from dtiResliceVolume
%============================
% myCinterp3 likes [rows,columns,slices], so we need a permute here
% myCinterp3 also wants pure image space, so we remove the mmPerVox.
coords(:,1) = coords(:,1)./mmPerVoxIn(1);
coords(:,2) = coords(:,2)./mmPerVoxIn(2);
coords(:,3) = coords(:,3)./mmPerVoxIn(3);
b0 = oldDt6File.b0;
b0 = double(permute(b0,[2,1,3]));
interpedb0 = myCinterp3(b0, [size(b0,1) size(b0,2)], size(b0,3), coords, 0.0); 
b0 = squeeze(reshape(interpedb0,newSize));
clear interpedb0;

if(~exist('outPathName','var') | isempty(outPathName))
    [fullpath fName] = fileparts(dt6PathName);
    outPathName = fullfile(fullpath, [fName sprintf('%dx%dx%dmm',mmPerVoxIn) '_upto_' sprintf('%dx%dx%dmm',mmPerVoxOut)]);
end

%Find new transform to anatomy image
oldXformToAnat = oldDt6File.xformToAnat;
anat = oldDt6File.anat;
scale = mmPerVoxOut./anat.mmPerVox;
scale = diag([scale 1]);
xformToAnat = scale*oldXformToAnat;

mmPerVox = mmPerVoxOut;
notes = oldDt6File.notes;
b0 = int16(round(b0));
b0 = permute(b0,[2,1,3]); %Undo earlier permute
dt6 = permute(dt6,[2 1 3 4]); %Undo permute from earlier


disp(['Saving to ' outPathName '...']);
save(outPathName, 'b0', 'xformToAnat','anat','notes','mmPerVox','dt6');
save([outPathName '_anon'], 'b0', 'xformToAnat','anat','notes','mmPerVox','dt6');

return