function createNoInfoPDF(subDir)

% Usage: createNoInfoPDF(subDir)
% Example: createNoInfoPDF('full/path/to/subDir')
%
% This function creates and saves a pdfNoInfo.nii.gz in subDir/dti30/bin
% in which we change the tensor information such that there is maximal
% uncertainty in shape (we replace original tensors with spheres) and 
% maximal data uncertainty (we replace the dispersion with maximal
% dispersion - which is 54.4 degrees - see  See Schwartmann 2005 for
% explanation) hence "NoInfo". 
%
% It is a more specific and easy to implement case of the createDegradedPDF
% function that I hope to write soon. Hence, we create PARAMS and OPTS
% struct variables (see below)that in a future version can be passed in as
% input arguments to allow parametric tensor degradation. For now, we just
% set these variables to fixed valued, the value that would result in a
% "NoInfo" pdf nifti. Since conTrack only knows about and uses the
% pdf.nii.gz file during tracking and scoring, we only have to modify this
% file, not tensors.nii.gz or anything else, etc. Note that if you want to
% make measurements on the tracts from this analysis - use the
% pdfNoInfo.nii.gz instead of the tensors.nii.gz which is unchanged
% 
% PDF.NII.GZ structure:
% X x Y x Z x 14, where each voxel has 14 values
% v1-3: EigVec3 (x,y,z) or Radial
% v4-6: EigVec2 (x,y,z) or Radial
% v7-9: EigVec1 (x,y,z) or Longitudinal Vector
% v10: -Concentration about EigVec1 from DTI data -> this converts the
% dispersion from the bootstrapping to a parameter (concentration) used in
% the Watson distribution 
% v11: - Concentration about EigVec1 from DTI data (10/11 are the same
% thing - this is a  hack) 
% v12: Linearity; cl=(eig1-eig2)/(eig2+eig3);  see westin shapes as those
% computed by dtiComputeWestinShapes(method='westinShapes_lsum') v13:
% EigenValue2 v14: EigenValue3
%
% KEY VARIABLES (potential input structs):
% in all these params 0 will leave the same value as the data and 1 will
% change it according to defaults we set. In the future we plan to
% parametrize this across the range;
% * params.tensorShapeSphericity:
%           0 do nothing
%           1 changes the tensor shape to that of a perfect sphere
%           (default)
% * params.volumeOfTensor:
%           0 do nothing (default)
%           1 changes original volume of each tensor to value you set in OPTS 
% * params.dataDispersionUncertainty:
%           0 do nothing
%           1 resets the data dispersion estimate (measure of uncertainty in the data, potential
%           to maximum (dispersion on a sphere, 54.4 degrees). (default)
%          
% in the future we can degrade the volume of the tensor.
% see dtiDegradeTensorShape function for more information
% however conTrack does not make any computations based on volume, so at the moment we don't
% really change opts.volumeOfTensorMatching value
% * opts.volumeOfTensorMatching:
%           'mean'= use mean volume of all tensors, no other options are
%           implemented yet
% History
% 2009/02/07: DY wrote it
% 2009/02/23: DY & KGS cleaned it up comments/variablenames


% Set PARAMS and OPTS this way for "No Info" spherical tensor shape case.
% Check implementation before setting params/opts for volume (commented
% out). Also, params.dataDispersionUncertainty is not fully implemented,
% currently on case in which it works is if it's set to the maximum=1.
% [params.tensorShapeSphericity, params.dataDispersionUncertainty] =deal(0); % no change, for debugging
params.tensorShapeSphericity=1; % set shape to sphere
params.dataDispersionUncertainty=1; % "max dispersion"

% opts.volumeMatchingMethod='mean'; params.volumeOfTensor=1;
opts.shapeSpherizingMethod='westinShapes_l1';
opts.pdf=1;

% The function takes the data from an X x Y x Z x6 matrix 
dt=dtiLoadDt6(fullfile(subDir,'dti30','dt6.mat'));

% Degrade the tensors
fprintf('\n We are about to use dtiDegradeTensorShape.m\n');
[dtDegraded, tmp] = dtiDegradeTensorShape(dt.dt6, params.tensorShapeSphericity,...
    opts.shapeSpherizingMethod);

% fprintf('\n We have just finished using dtiDegradeTensorShape.m\n');
if params.dataDispersionUncertainty==1
    % Turn dispersion to maximum (54.4 degrees)
    [X Y Z tensorEntries]=size(dt.dt6);
    dtDispersion=repmat(deg2rad(54.4),[X Y Z]);
else
    error('option to keep original dispersion needs to be implemented \n');
end

% If the subject doesn't already have a pdf.nii.gz create one
p.dt6Dir=fullfile(subDir,'dti30');
if ~exist(fullfile(p.dt6Dir,'bin','pdf.nii.gz'))
    ctrPDFFile(p);
end

% Then write the "no info" PDF
params.dt6=dtDegraded;
params.pdfName='pdfNoInfo.nii.gz';
params.eig1Concentration= - 1 ./ sin(dtDispersion).^2;  % convert dispersion to "concentration"
ctrPDFFile(p,params);

return;

% for debugging purposes only 
% To check degraded tensors
nonzeros=find(dtDegraded);
[x y z sixes]=ind2sub(size(dtDegraded),nonzeros);

% dt.dt6 and dtDegraded should be identical if params = 0, original
%dt.dt6(x(200),y(200),z(200),:)
%dtDegraded(x(200),y(200),z(200),:)

% all eigVals should be equal to each other if params = 1 sphericize
[eigVec, eigVal] = dtiEig(dtDegraded);
noinfoeig=reshape(eigVal, x*y*z,3);
% check that max and min differences are close to zero
max(noinfoeig(:,1)-noinfoeig(:,2))
max(noinfoeig(:,1)-noinfoeig(:,3))
min(noinfoeig(:,1)-noinfoeig(:,2))
min(noinfoeig(:,1)-noinfoeig(:,3))
 
 