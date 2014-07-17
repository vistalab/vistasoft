function [fh, figurename] = dtiCheckMotion(ecXformFile,visibility)
% Plots rotations and translations from an eddy-current correction
% transform file.
%
% fh = dtiCheckMotion([ecXformFile=uigetfile],visibility)
%
% INPUTS:
%   ecXformFile - Eddy Current correction trasformation infromation. This
%                 file is generally generated and saved by dtiInit.m. See
%                 dtiInit.m and also dtiRawRohdeEstimateEddyMotion.m
%
%   visibility  - A figure with the estimates of rotation and translation
%                 will be either displayed (visibility='on') or not
%                 (visibility='off'). The figure will be always saved in
%                 the same directory of the ecXformFile.mat file.
%
% OUTPUTS:
%   fh - Handle to the figure of the motion estimae. Note, this figure
%        might be set to invisible using 'visibility'. To display the
%        figure invoke the following command: set(fh,'visibility','on').
%
%   figurename - Full path to the figure saved out to disk showing the
%                motion estimates. 
%
% Franco Pestilli & Bod Dougherty Stanford University

if notDefined('visibility'), visibility = 'on'; end
if(~exist('ecXformFile','var') || isempty(ecXformFile))
   [f,p] = uigetfile('*.mat','Select the ecXform file');
   if(isequal(f,0)), disp('Canceled.'); retun; end
   ecXformFile = fullfile(p,f);
end
   
% Load the stored trasformation file.
ec = load(ecXformFile);
t = vertcat(ec.xform(:).ecParams);

% We make a plot of the motion correction during eddy current correction
% but we do not show the figure. We only save i to disk.
fh = mrvNewGraphWin('visibility',visibility);
subplot(2,1,1); 
plot(t(:,1:3)); 
title('Translation'); 
xlabel('image'); 
ylabel('translation (voxels)'); 
legend({'x','y','z'});

subplot(2,1,2); 
plot(t(:,4:6)/(2*pi)*360); 
title('Rotation');
xlabel('image'); 
ylabel('rotation (degrees)'); 
legend({'pitch','roll','yaw'});

% Save out a PNG figure with the same filename as the Eddy Currents correction xform. 
[p,f,~] = fileparts(ecXformFile);
figurename = fullfile(p,[f,'.png']);
printCommand = ...
    sprintf('print(%s, ''-painters'',''-dpng'', ''-noui'', ''%s'')', ...
    num2str(fh),figurename);
fprintf('[%s] Saving Eddy Currenct correction figure: \n %s \n', ...
         mfilename,figurename)
eval(printCommand);

% Delete output if it was nto requested
if (nargout < 1), close fh;end

return;

