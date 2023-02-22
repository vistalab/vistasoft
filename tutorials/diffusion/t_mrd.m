%% t_mrd
%
% Illustrates how to initiate mrDiffusion with scripts.  
%
% There are several examples of loading data or adjusting the view by using
% the window handles and refreshing the screen.
% 
% Additional mrDiffusion tutorial scripts are named t_mrd<XXXXX>.
%
% See also: t_mrdFibers, t_mrdTensor, t_mrdViewFibers, t_mrdDWI, dtiSet, dtiGet, dwiGet,
% dwiSet, dwiCreate
%
% (c) Stanford VISTA Team, 2011


%% You can initiate a mrDiffusion window with no data

% We use dtiF to store the figure number and dtiH to store the window
% handles. 
[dtiF, dtiH] = mrDiffusion;

% Close the figure.  This  renders the dtiH
% (handles to objects in the window) dead.
close(dtiF);
clear dtiH

% You can also get the handles this way
dtiF = mrDiffusion;
dtiH = guidata(dtiF);

% When you make a change to the data in the figure, by adjusting the dtiH
% (window handles), you reset the data by the call
guidata(dtiF,dtiH);

% Let's start again
close(dtiF);

%% Vistadata contains a sample data set with a calculated dt6

% Load the sample data set and set the window to invisible 
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
[dtiF, dtiH] = mrDiffusion('off',dt6Name);

% Make the window visible 
figure(dtiF)

% Normally, we interact with the diffusion data using dtiGet/Set or
% dwiGet/Set.  In this case, we have opened only a diffusion tensor imaging
% structure through this window.  Hence, we interact with the data using
% dtiGet.  We can find out which image is displayed in the background using
dtiGet(dtiH,' background name')
d = dtiGet(dtiH,' background data');
showMontage(d)

% Close the window, clear the handles
close(dtiF)

%% You can open the data and leave the window visible this way
[dtiF,dtiH] = mrDiffusion('on',dt6Name);

% Reset
close(dtiF)

%% Load some fibers

% Open the window
[dtiF,dtiH] = mrDiffusion('on',dt6Name);

% Load a sample fiber group
fgName = fullfile(mrvDataRootPath,'diffusion','sampleData','fibers','leftArcuate.pdb');
fg = mtrImportFibers(fgName);

% Attach the fiber group to the handles
dtiH = dtiSet(dtiH,'current fiber group',fg);

% We interact with the window handles using the Matlab set/get functions
% applied to the handles.
set(dtiH.cbShowFibers,'Value',1)
guidata(dtiF,dtiH)

% After setting and attaching, you refresh the window this way
dtiH = dtiRefreshFigure(dtiH);

%% Make the fibers invisible
set(dtiH.cbShowFibers,'Value',0)
guidata(dtiF,dtiH)
dtiH = dtiRefreshFigure(dtiH);

% See the script t_mrdViewFibers for examples of viewing the fibers with
% the mrMesh viewer

%% Read mrDiffusion figure handle settings

overlayThresh = get(dtiH.slider_overlayThresh, 'Value');
overlayAlpha = str2double(get(dtiH.editOverlayAlpha, 'String'));
curOvNum = get(dtiH.popupOverlay,'Value');

%% Find a mrDiffusion window
dtiF = dtiGet([],'main figure');
close(dtiF)

%% End