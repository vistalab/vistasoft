function [dt,t1] = dtiLoadDt6(fname, applyBrainMask)
%Load a dt6 (tensor) data file.
%
%  [dt,t1] = dtiLoadDt6(fname, [applyBrainMask=true]);
%
% Optionally, you can also load the T1 data file and apply a brain mask.
%
% The six entries are the diffusion tensor values, derived from the raw
% data.  The raw data can be in many different directions.  The diffusion
% tensor is a 3x3, symmetric, positive-definite matrix, D.  The six
% independent entries in the matrix are stored in a vector: (Dxx Dyy Dzz
% Dxy Dxz Dyz)
%
% The project-style dt6- contain no data, just pointers to data files.  The
% directory architecture of the data should be:
%   
%
% HISTORY:
%  2007.10.29 RFD: wrote it, pulling parts from dtiLoadDT6. The dt6 loading
%  was a mess. Hopefully it is better now. 
%
% (c) Stanford VISTA Team

%% Initialize the variables
dt = [];   % This is the main dt structure.
t1 = [];
if(~exist('fname','var') || isempty(fname))
    fname = [pwd filesep];
end
if(isdir(fname))
    [f,p] = uigetfile({'*.mat'}, 'Select a dt6 file...',fname);
    if(isequal(f,0)), disp('Load dt6 canceled.'); return; end
    fname = fullfile(p,f);
end
if(~exist('applyBrainMask','var') || isempty(applyBrainMask))
    applyBrainMask = true;
end

%% Load the dt6 information. 
%  This information describes things like where the data files are.
[dt6Struct, dt.dataFile, defaultPath, dataDir] = dtiLoadDt6Info(fname);
[p,n] = fileparts(dataDir);
dt.subName = n;
[p,n] = fileparts(p);
if(~isempty(n))
    dt.subName = [n '_' dt.subName];
    [p,n] = fileparts(p);
    if(~isempty(n))
        dt.subName = [n '_' dt.subName];
    end
end

% Decide whether we will output the T1 data
if(nargout>1) 
    loadT1 = true;
    t1.talairachScale = [];
else
    loadT1 = false;
end

%% Read the data
% We support both new NIFTI-based dt6 files and the old dt6 file format. 
if(isfield(dt6Struct,'files'))   % Test whether new dt6 stye
    %
    % New project-style dt6- contains no data, just pointers to data files.
    %
    [dt.dt6, dt.xformToAcpc, dt.mmPerVoxel] = dtiLoadTensorsFromNifti(dt6Struct.files.tensors);
    dt.adcUnits = '';

    clear ni;
    ni = niftiRead(dt6Struct.files.b0);
    ni.data(isnan(ni.data)) = 0;
    dt.b0 = ni.data;

    clear ni;
    ni = niftiRead(dt6Struct.files.brainMask);
    dt.brainMask = ni.data;

    if(loadT1 && isfield(dt6Struct.files,'t1'))
        t1Fname = dt6Struct.files.t1;
        if(exist(t1Fname,'file'))
            ni = niftiRead(t1Fname);
            t1.img = ni.data;
            t1.xformToAcpc = ni.qto_xyz;
            t1.mmPerVoxel = ni.pixdim(1:3);
        else
            % try another level up
            t1Fname = dt6Struct.files.t1;
            if(exist(t1Fname,'file'))
                ni = niftiRead(t1Fname);
                t1.img = ni.data;
                t1.xformToAcpc = ni.qto_xyz;
                t1.mmPerVoxel = ni.pixdim(1:3);
            else
                disp(['Couldn''t load t1 file "' t1Fname '".']);
            end
        end
        % look for a t1 brain mask in there too
        t1MaskName = fullfile(fileparts(t1Fname),'t1_mask.nii.gz');
		if(~exist(t1MaskName,'file'))
		  t1MaskName = fullfile(fileparts(t1Fname),'t1_brain_mask.nii.gz');
		end
        if(exist(t1MaskName,'file'))
            ni = niftiRead(t1MaskName);
            t1.brainMask = ni.data;
            t1.brainMaskXform = ni.qto_xyz;
        end
    end
    dt.files = dt6Struct.files;
else
    %
    % It's an old dt6 file- the data are already loaded, but we need to
    % check things and pack the relevant structs.
    %
    if(~isfield(dt6Struct, 'xformToAcPc')), dt.xformToAcpc = eye(4);
    else dt.xformToAcpc = dt6Struct.xformToAcPc; end
    dt.dt6 = dt6Struct.dt6;
    dt.mmPerVoxel = dt6Struct.mmPerVox;

    dt6Struct.b0(isnan(dt6Struct.b0)) = 0;
    dt.b0 = dt6Struct.b0;

    if(isfield(dt6Struct,'brainMask'))
        dt.brainMask = dt6Struct.brainMask;
    elseif(isfield(dt6Struct,'dtBrainMask'))
        dt.brainMask = dt6Struct.dtBrainMask;
    else
        dt.brainMask = [];
    end

    if(isfield(dt6Struct, 'adcUnits'))
        dt.adcUnits = dt6Struct.adcUnits;
    else
        dt.adcUnits = '';
    end

    if(loadT1 && isfield(dt6Struct,'anat'))
        t1.img = double(dt6Struct.anat.img);
        t1.xformToAcpc = dt6Struct.anat.xformToAcPc;
        t1.mmPerVoxel = dt6Struct.anat.mmPerVox;
        if(isfield(dt6Struct.anat, 'brainMask'))
            t1.brainMask = dt6Struct.anat.brainMask;
            t1.brainMaskXform = dt6Struct.anat.xformToAcPc;
        end

        if(isfield(dt6Struct.anat, 'talScale'))
            t1.talairachScale = dt6Struct.anat.talScale;
        end
    end
    dt.files = [];
end

%% Set up the T1 data
if(loadT1 && isempty(t1.talairachScale) && isfield(t1,'brainMask') && ~isempty(t1.brainMask))
    % Approximate Talairach scales using brain mask
    disp('Computing Talairach scales from brain mask...');
    t1.talairachScale = mrAnatGetTalairachScalesFromMask(t1.brainMask, t1.brainMaskXform);
end

%% NaN's take forever on Pentium 4 CPUs!
% (eg. http://www.psychology.nottingham.ac.uk/staff/cr1/simd.html)
dt.dt6(isnan(dt.dt6)) = 0;

%% Apply the brain mask, if it exists
if(applyBrainMask && ~isempty(dt.brainMask))
    for ii=1:6 
        tmp = dt.dt6(:,:,:,ii);
        tmp(~dt.brainMask) = 0;
        dt.dt6(:,:,:,ii) = tmp;
    end
end
if(isempty(dt.brainMask))
    dt.brainMask = dt.dt6(:,:,:,1)>0;
end

%% Convert adc units to our standard micrometers^2 / millisecond
if(isempty(dt.adcUnits))
    [dt.adcUnits,dt.adcScale,stdUnitStr] = dtiGuessDiffusivityUnits(dt.dt6);
    if(dt.adcScale~=1)
        dt.dt6 = dt.dt6*dt.adcScale;
    end
    dt.adcUnits = stdUnitStr;
end

%% Apply a spatial transformation
if(isfield(dt6Struct,'xformVAnatToAcpc'))
    dt.xformVAnatToAcpc = dt6Struct.xformVAnatToAcpc;
elseif(isfield(dt6Struct,'xformToMrVista') && exist('t1','var') && ~isempty(t1))
    % try to use an old vanatXform
    warning('mrDiffusion:deprecated','Using old xformToMrVista field- you may want to recompute this using Xform->Compute mrVista xform');
    dt.xformVAnatToAcpc = t1.xformToAcpc*dt6Struct.xformToMrVista;
end
if(loadT1 && isfield(dt6Struct,'t1NormParams'))
    t1.t1NormParams = dt6Struct.t1NormParams;
end

%% Set the default bounding box
dt.bb = sort(mrAnatXformCoords(dt.xformToAcpc, [1 1 1; size(dt.brainMask)]));
if(any(dt.mmPerVoxel<1))
    dt.renderMm = dt.mmPerVoxel;
else
    dt.renderMm = [1 1 1];
end

return;

