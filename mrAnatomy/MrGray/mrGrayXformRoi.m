function mrGrayXformRoi(roiFile, roiXform, newRoiFile)
% 
%  mrGrayXformRoi(roiFile, roiXform, newRoiFile)
% 
% Convert a mrVista ROI from one vAnatomy space to another. This is
% usually used to convert an ROI defined in an old vAnatomy file to one
% compatible with a new NIFTI anatomy file.
% 
% See also:
%   mrGrayConvertClassToNifti
%
% HISTORY:
% 2008.09.05 RFD wrote it.

%% Get input file names
opts = {'*.mat','mrVista ROI'; '*.*','All Files (*.*)'};
if(~exist('roiFile','var'))
    [f, p]=uigetfile(opts, 'Pick a mrVista ROI file');
    if(isequal(f,0)|| isequal(p,0)) , disp('user canceled.'); return; end
    if(isempty(p)), p = pwd; end
    roiFile = fullFile(p,f);
end

if(~exist('roiXform','var')||isempty(roiXform))
    default = fullfile(fileparts(roiFile),'t1_xformToVanat.mat');
    [f, p]=uigetfile(opts, 'Pick an ROI xform file',default);
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    roiXform = fullFile(p,f);
end

if(~exist('newRoiFile','var')||isempty(newRoiFile))
    [p,f,e] = fileparts(roiFile);
    default = fullfile(p,[f '_NEW' e]);
    [f,p] = uiputfile('*.mat','Save new ROI file as...',default);
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    newRoiFile = fullfile(p,f);
end
disp(['New ROI will be saved in ' newRoiFile]);


oldRoi = load(roiFile);
roiXform = load(roiXform);
oldImg = zeros(roiXform.vAnatSize);
oldInds = sub2ind(roiXform.vAnatSize, oldRoi.ROI.coords(1,:), oldRoi.ROI.coords(2,:), oldRoi.ROI.coords(3,:));
oldImg(oldInds) = 1;
newImg = mrAnatResliceSpm(double(oldImg), roiXform.xform, roiXform.bb, roiXform.mm, [1 1 1 0 0 0], false);
newImg = mrAnatRotateAnalyze(newImg);
newInds = find(newImg>=0.5);
[x,y,z] = ind2sub(roiXform.sz,newInds);

ROI = oldRoi.ROI;
ROI.coords = [x'; y'; z'];

save(newRoiFile,'ROI');

return;


% % For debugging:
% vAnat = readVolAnat('OLD/vAnatomy.dat');
% r = vAnat; g=r; b=r;
% r(oldInds) = 255;
% showMontage(cat(4,r,g,b)./255);
% 
% vAnatNew = readVolAnat('t1.nii.gz');
% r = vAnatNew; g=r; b=r;
% r(newInds) = 255;
% showMontage(cat(4,r,g,b)./255);
