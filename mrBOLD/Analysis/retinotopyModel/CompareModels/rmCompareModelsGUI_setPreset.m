function rmCompareModelsGUI_setPreset(whichModel, M);
% For the compare retinotopy models GUI, set all pRFs to a preset pRF from
% one of the models.
%
%   rmCompareModelsGUI_setPreset([whichModel=get from popup], [M=get from figure]);
%
% This is essentially a callback function for a popup list. The first entry
% in the popup is simply a prompt (omitting the need for a text label, and
% indicating that no preset has been chosen). The remaining entries
% indicate the different models being compared in the GUI. When one of
% these models is selected, the manual pRF parameter sliders are auto-set
% to the stored pRF values for the selected voxel, and the specified model.
%
% You can also manually specify the number of the model (in the GUI) to
% use, rather than getting it from the popup.
%
% ras, 03/2009.
if notDefined('M')
	M = get(gcf, 'UserData');
end

if notDefined('whichModel')
	%% determine from popup
	% get the handle to the popup
	h = M.ui.moveToPreset;

	% get the value of the poup 
	whichModel = get(h, 'Value') - 1;
	
	% since the first entry to the popup is just a prompt we skip this
	% callback if that is the current value (0 because of the -1 above):
	if whichModel==0
		% just update, using each model's own parameters
		M.prevVoxel = 0; % this will force the default pRF values
		rmCompareModelsGUI_update(M);
		return
	end
	
% 	% now, set the popup to the prompt:
% 	set(h, 'Value', 1);
end

%% get the parameters from the selected model
v = M.voxel;  % selected voxel
x0 = M.x0{whichModel}(v);
y0 = M.y0{whichModel}(v);
sigma = M.sigma{whichModel}(v);

%% set the "adjust pRF" sliders to match these values
mrvSliderSet(M.ui.moveX, 'Value', x0);
mrvSliderSet(M.ui.moveY, 'Value', y0);
mrvSliderSet(M.ui.moveSigma, 'Value', sigma);

%% refresh the GUI
rmCompareModelsGUI_update(M);


return
