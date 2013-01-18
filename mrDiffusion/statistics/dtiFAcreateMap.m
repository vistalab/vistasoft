function dtiFAcreateMap(dt6File,fName)
% function ni = dtiFaCreateMap([dt6File],[fName])
% 
% Computes and saves an FA Map as a nifti image. By default the image is
% named 'faMap.nii.gz' and is saved in the same directory as the dt6.mat
% file used to create it.
%  
%  HISTORY:
% 04.19.2011 LMP wrote the thing. 

if ~exist('dt','var')
    [a b]  = uigetfile('*.mat',pwd);
    dt6File = [b a];
end
[a b] = fileparts(dt6File);
if ~exist('fName','var')
    fName = fullfile(a, 'faMap');
end

dt = dtiLoadDt6(dt6File);
%[vec val] = dtiEig(dt.dt6);
fa = dtiComputeFA(dt.dt6);

fprintf('Writing %s.nii.gz...',fName);
dtiWriteNiftiWrapper(fa,dt.xformToAcpc,fName);
fprintf('Done.\n');
return