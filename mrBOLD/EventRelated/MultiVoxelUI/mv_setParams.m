function mv_setParams(mv,params);
%
% mv_setParams([mv],[params]);
%
% Set the parameters in a multiVoxelUI struct.
% If the params arg is passed, the mv struct adopts
% whatever fields are attached into its own parameters.
% If it's omitted, presents a user dialog. Right now,
% this dialog doesn't set all event-related analysis
% params (see er_getParams/er_setParams for more general
% parameters), but focuses on ones specific to MultiVoxelUI.
% 
%
% ras 05/05
if notDefined('mv')
    mv = get(gcf,'UserData');
end

if notDefined('params')
    % present dialog, get params
    ui(1).string = 'Method to Calculate Amplitudes?';
    ui(1).fieldName = 'ampType';
    ui(1).list = {'Peak-Bsl Difference' 'GLM Betas' ...
                  'Z Score' 'Deconvolved Amps'};
	opts = {'difference' 'betas' 'zscore' 'deconvolved'};
    ui(1).style = 'popup';
    ui(1).value = ui(1).list{cellfind(opts, mv.params.ampType)};

    ui(2).string = 'Font to use for Plots?';
    ui(2).fieldName = 'font';
    ui(2).list = listfonts;
    ui(2).style = 'popup';
    ui(2).value = ui(2).list{cellfind(listfonts, mv.params.font)};

    ui(3).string = 'Standard Font Size for Plots?';
    ui(3).fieldName = 'fontsz';
    ui(3).list = {'10' '12' '14' '16' '18'};
    ui(3).style = 'popup';
    ui(3).value = cellfind(ui(3).list, num2str(mv.params.fontsz));
    
    params = generalDialog(ui,'Set MultiVoxel Parameters');
    params.fontsz = str2num(params.fontsz);
	ampInd = cellfind(ui(1).list,params.ampType);
	params.ampType = opts{ampInd};
end

% have mv.params substruct 'eat' whatever
% fields are in the params struct:
fields = fieldnames(params);
for i = 1:length(fields)
    mv.params.(fields{i}) = params.(fields{i});
end

% if a UI exists, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
    figure(mv.ui.fig)
    multiVoxelUI; % refresh UI
end

return
