function ni = mrAnatFixT1HeaderOriginFlip(niftiT1,t1Name,saveNi)

% function mrAnatFixT1HeaderOriginFlip(niftiFile,[t1Name],[saveNi])

% This function takes a t1 nfti file (or struct) and modifies the header so
% that the origin is set to [0,0,0]. The resulting file will also be saved
% in the t1Dir.
% 
% This code was developed for T1 anatomicals that were run through N3 and
% thusly had their L/R flipped in the header for some reason.
%
% History:
% 08.25.2009 -  LMP wrote the thing.
% 11.30.2009 -  RFD provided a fix
%               for left/right flips not being accounted for in the header.
% 01.27.2011 -  LMP Wrote the funciton

if ~exist('niftiT1','var')
    [f, p]   = uigetfile({'*.nii.gz';'*.*'}, 'Please choose a T1 Nifti File', pwd);
    niftiT1 = fullfile(p,f);
    if(isnumeric(f)); disp('User canceled.'); return; end
    ni = niftiRead(niftiT1);
end

if isstruct(niftiT1); ni = niftiT1; end

if  exist('t1Name','var') && ~isempty(t1Name)
    ni.fname = t1Name;
end
if  ~exist('saveNi','var') 
    saveNi = 1;
end

% NOTE: Assume that data are left-right flipped:
scale = [-ni.pixdim(1) ni.pixdim(2:3)];
origin = [ni.dim(1)+1-97 140 128];

ni = niftiSetQto(ni, inv(affineBuild(origin, [0 0 0], scale)), true);

% We only modify the header, so it is safe to overwrite the original. 

if saveNi == 1
    d = pwd; cd(mrvDirup(niftiT1));
    writeFileNifti(ni);
    cd(d);
end

return
