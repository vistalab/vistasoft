function view=fsl_MLR_anat2Analyze(view)
% view=fsl_MLR_anat2Analyze(view)
% PURPOSE: Generates a 3D analyze files from the Inplane/anat.mat data
% See also fsl_preprocessMLRTSeries, fsl_motionCorrectMLR
% ARW 121604
% $Author: wade $
% $Date: 2004/12/17 23:24:23 $

mrGlobals;

thisDir=pwd;

fslBase='/raid/MRI/toolbox/FSL/fsl';

if (ispref('VISTA','fslBase'))
   disp('Settingn fslBase to the one specified in the VISTA matlab preferences:');
   fslBase=getpref('VISTA','fslBase');
   disp(fslBase);
end

fslPath=fullfile(fslBase,'bin'); % This is where FSL lives - should also be able to get this from a Matlab pref

if (~exist('view','var')  | (isempty(view)))
    view=getSelectedInplane;
end


view=loadAnat(view);
thisAnat=view.anat;

% For consistnecy, use save_avw to save this to disk.
% This whole thing could be a function makeInplaneAnalyzeAnatomy... 

adim=mrSESSION.inplanes.voxelSize;
anatfName='./Inplane/avw_anat';
save_avw(thisAnat,anatfName,'s',[adim(:);0]);
% That was fun. But generally we collect functional data at a lower
% resolution
% That means that we need to downsample anat to the size of the functional
nSlices=size(thisAnat,3);
loresAnat=zeros(size(thisAnat,1)/2,size(thisAnat,2)/2,nSlices);

for thisSlice=1:nSlices
    %a=decimateNd(thisAnat(:,:,thisSlice),2);
    loresAnat(:,:,thisSlice)=decimateNd(thisAnat(:,:,thisSlice),2);
end

loresAnatfName=[anatfName,'_lores'];
loresDim=adim(:).*[3; 3; 1];
save_avw(loresAnat,loresAnatfName,'s',[loresDim(:);0]);
