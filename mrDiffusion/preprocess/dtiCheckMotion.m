function dtiCheckMotion(ecXformFile)
%
% dtiCheckMotion([ecXformFile=uigetfile])
%
% Plots rotations and translations from an 
% eddy-current correction transform file.
%
% HISTORY:
% 2008.04.08 RFD: wrote it.

if(~exist('ecXformFile','var') || isempty(ecXformFile))
   [f,p] = uigetfile('*.mat','Select the ecXform file');
   if(isequal(f,0)), disp('Canceled.'); retun; end
   ecXformFile = fullfile(p,f);
end
   
ec = load(ecXformFile);
t = vertcat(ec.xform(:).ecParams);
figure;
subplot(2,1,1); plot(t(:,1:3)); title('Translation'); 
xlabel('image'); ylabel('translation (voxels)'); 
legend({'x','y','z'});
subplot(2,1,2); plot(t(:,4:6)/(2*pi)*360); title('Rotation');
xlabel('image'); ylabel('rotation (degrees)'); 
legend({'pitch','roll','yaw'});
return;

