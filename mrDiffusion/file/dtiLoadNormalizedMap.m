function [handles, mapData, mapName, mmPerVox, xformImgToAcpc, labels] = dtiLoadNormalizedMap(handles)
%
%  [handles, mapData, mapName, mmPerVox, xformImgToAcpc, labels] = ...
%             dtiLoadNormalizedMap(handles);
%
% Load a normalized image and warp it to this subject's image space.
% Needs to be thought through.
%
% HISTORY:
%  2006.11.17 RFD: extracted code from dtiFiberUI.
%
%  2007.08.22 RFD: fixed this code - it was horribly broken since the
%  coordLUT normalization representation overhaul a few months ago. As a
%  bonus, the code is also now much more compact by calling
%  mrAnatResliceSpm rather than doing our own reslicing. The downside is
%  that it will now probably fail to work with old MINC (.mnc) files that
%  SPM2 used for templates.
%
%  Uses SPM interpolation.
%  We should use the best current interpolation (spm8?) and we should do
%  this interpolation in one place.  I noticed it in
%  updateStandardSpaceValue or somewhere like that.  Anyway, find all the
%  spm calls in mrDiffusion and when we normalize, do it via one function.
%
% Bob (c) Stanford VISTASOFT Team, 2006

spm_defaults;
%defaults.analyze.flip = 0;
interpMethod = [1 1 1 0 0 0];

mapData=[];mapName=[];mmPerVox=[];xform=[];labels=[];
if(isfield(handles, 't1NormParams') && length(handles.t1NormParams)>1)
	[id,OK] = selector([1:length(handles.t1NormParams)], {handles.t1NormParams.name}, 'Select the coord space...');
	if(~OK) disp('user canceled.'); return; end
else
	id = 1;
end
if(~isfield(handles, 't1NormParams')||~isfield(handles.t1NormParams(id), 'sn')||isnumeric(handles.t1NormParams(id).sn))
    warning('No normalization params- the map will be imported un-normalized. (See the "xform" menu.)');
    normParams = [];
else
    disp(['Image will be transformed from "' handles.t1NormParams(id).name '" space to native subject space.']);
    normParams = handles.t1NormParams(id);
end
defDir = fullfile(fileparts(which('mrDiffusion')), 'templates',filesep);

[fname, p] = uigetfile({'*.nii;*.nii.gz','NIFTI';'*.mnc','MINC format';'*.img','Analyze 7.5 format (*.img)'}, 'Select map file...', defDir);
if(~isnumeric(fname))
    V = mrAnatLoadSpmVol(fullfile(p,fname));
    mmPerVox = dtiGet(handles, 'defaultmmpervox');
    %mmPerVox = spm_imatrix(V.mat); mmPerVox = mmPerVox(7:9);
    bb = dtiGet(handles, 'defaultBoundingBox');
    
    if(~isfield(normParams,'coordLUT') || isempty(normParams.coordLUT))
        error('need to compute inverse deformation first.');
    end
    
    if(isempty(normParams))
        mapData = V.data;
        xformImgToAcpc = V.mat;
    else
        normParams.outMat = inv(V.mat);
        [mapData, xformImgToAcpc] = mrAnatResliceSpm(double(V.dat), normParams, bb, mmPerVox, interpMethod);
        %xformImgToAcpc = normParams.sn.VF.mat;
        
    end
    [junk,f,e]=fileparts(fname);
    mapName = f;
    p = fullfile(p,f);
    if(exist([p '.txt'],'file')) labels = readTab([p '.txt'],'\t ,');
    elseif(exist([p '.TXT'],'file')) labels = readTab([p '.TXT'],'\t ,'); end
else
    disp('Load Normalized Map cancelled.');
end
