function h = dtiLoadDt6Gui(h, fname)
% Load a dt6 (tensor) data file into the mrDiffusion GUI handle structure.
%
%    handles = dtiLoadDt6Gui(handles, dt6fname);
%
% This routine adds a number of background images and data values from a
% dt6 file and adds them to the window handle struct. 
%
% The name of the main figure is adjusted to be mrdMain <subName>
%
% If you want to load a dt6 struct without attaching the data to the GUI
% (like in a batch script), use dtiLoadDt6.
%
% Example:
%
% To load a file and attach it to the window, but without bringing up the
% load GUI, use
%
%  dtiFiberUI;
%  dt6Name = fullfile(mrvDataRootPath,'diffusion','sampleData','dti40','dt6.mat')
%  f = dtiGet; h = guidata(f);
%  h = dtiLoadDt6Gui(h, dt6Name);
%  guidata(f, h);
%  h = dtiRefreshFigure(h);
%
% See also:  dtiLoadDt6, dtiFiberUI, t_mrd
%
% (c) Stanford VISTA Team

% TODO
% There is another function, handles = updateStandardSpaceValue(handles);
% that Bob calls.  I am not sure why it is there as well. I didn't put it
% in the example.
% Perhaps this routine should include the guidata() call to attach the
% updated handles, rather than have that be done on the return.
%


% Always apply the brain mask
applyBrainMask = true;

% Load the data from the file and apply the mask
if(~exist('fname','var')), fname = []; end
[dt, t1] = dtiLoadDt6(fname, applyBrainMask);
if(isempty(dt)), return; end

% Clear old data
if(isfield(h, 'bg')), h = rmfield(h, {'bg'}); end
set(h.popupBackground, 'String', {'loading...'});
set(h.popupOverlay, 'String', {'loading...'});

% Go through the dt field names and replace the data in handles. This
% attaches the dt6 structure and many other parameters to the figure
% handle. 
fn = fieldnames(dt);
for ii=1:length(fn)
    h.(fn{ii}) = dt.(fn{ii});
end
clear dt;

h.dataDir = fileparts(h.dataFile);
h.defaultPath = h.dataDir;

% Add the b=0 image data
h = dtiAddBackgroundImage(h, double(h.b0), 'b0', h.mmPerVoxel, h.xformToAcpc, [0.4 0.99], 1, 'arb');
h = rmfield(h,'b0');

% The dt6 was attached to h above.
[eigVec, eigVal] = dtiSplitTensor(h.dt6);
eigVal(isnan(eigVal)|eigVal<0) = 0;
md = mean(eigVal,4);
h = dtiAddBackgroundImage(h, md, 'Mean Diffusivity', h.mmPerVoxel, h.xformToAcpc, [], 0, h.adcUnits, [0 5 1]);

fa = dtiComputeFA(eigVal);
fa(isnan(fa)) = 0; fa(fa>1) = 1; fa(fa<0) = 0;
[h, faNum] = dtiAddBackgroundImage(h, fa, 'FA', h.mmPerVoxel, h.xformToAcpc, [0 1], 0, 'ratio');
set(h.popupOverlay, 'Value', faNum);

img = squeeze(eigVec(:,:,:,[1 2 3],1));
img(isnan(img)) = 0;
img = abs(img);
for ii=1:3, img(:,:,:,ii) = img(:,:,:,ii).*fa; end
h = dtiAddBackgroundImage(h, img, 'vectorRGB', h.mmPerVoxel, h.xformToAcpc, [0 1], 0, '');

% For some reason, the t1 data are handled separately.
if(~isempty(t1) && isfield(t1,'img'))
	h = dtiAddBackgroundImage(h, double(t1.img), 't1', t1.mmPerVoxel, t1.xformToAcpc, [0.4 0.99], 1, 'arb');
    if(isfield(t1,'brainMask'))
        h.brainMask = t1.brainMask;
        h.brainMaskXform = t1.brainMaskXform;
    end
end

if(isfield(t1,'talairachScale'))
    h.talairachScale = t1.talairachScale;
    h = dtiSet(h, 'addStandardSpace', 'Talairach');
end

if(isfield(t1,'t1NormParams'))
    h.t1NormParams = t1.t1NormParams;
    if(isfield(h.t1NormParams,'name'))
        for ii=1:length(h.t1NormParams)
            h = dtiSet(h, 'addStandardSpace', h.t1NormParams(ii).name);
        end
        if(~isempty(strmatch('MNI',{h.t1NormParams.name})))
            labels = dtiGetBrainLabel;
            for ii=1:length(labels)
                h = dtiSet(h, 'addStandardSpace', labels{ii});
            end
        end
    end
end

% Add the subject name to the figure name.
h.title =  sprintf('mrdMain%d %s',h.fig,h.subName);
set(h.fig,'Name',h.title);

return;

