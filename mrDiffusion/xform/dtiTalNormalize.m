function dt6 = dtiTalNormalize(dt6file,destinationDir)
% dt6 = dtiTalNormalize(dt6file,destinationDir)
%
% Talirach Normalization:
% Takes in a dt6 filename and scales according to the talScale factors
% stored within.
%
% Outputs new file of form originalFileName_tal.mat in destination
% directory
%
% dtiTalNormalize uses mrAnatResliceSpm
% 

load(dt6file);

% Get a bounding box in talairach space that is the same size as the input
% image.
origin  = anat.xformToAcPc\[0 0 0 1]';
origin  = origin(1:3)';
bb = [-anat.mmPerVox .* (origin-1) ; anat.mmPerVox .*(size(anat.img)-origin)]';

ts = anat.talScale;
ts.talScaleDir = 'tal2acpc';
% warp T1 to tal space
ts.outMat = inv(anat.xformToAcPc);
[anat.img,newT1Xform] = mrAnatResliceSpm(anat.img, ts, bb', [1 1 1], [7 7 7 0 0 0]);

ts.outMat = inv(anat.xformToAcPc*xformToAnat);
[b0,newB0Xform]  = mrAnatResliceSpm(b0, ts, bb', mmPerVox, [7 7 7 0 0 0]);
[dt6, newDt6Xform, def] = mrAnatResliceSpm(dt6, ts, bb', mmPerVox, [1 1 1 0 0 0]);
dt6(isnan(dt6)) = 0;

%PPD Correction
dt6 = dtiXformTensorsPPD(dt6,def,1);


anat.xformToAcPc = newT1Xform;
xformToAcPc = anat.xformToAcPc*xformToAnat;

b0(isnan(b0)) = 0;
b0 = int16(b0);
[subDir subFile x xx] = fileparts(dt6file);
save([destinationDir,subFile,'_tal'],'b0','xformToAcPc','xformToAnat','anat','notes','mmPerVox','dt6');
if(nargout==0)
    clear dt6;
end
return
