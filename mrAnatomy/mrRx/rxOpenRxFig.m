function rx = rxOpenRxFig(rx)
% rx = rxOpenRxFig(rx);
%
% Open a window for viewing the prescription
% on the non-transformed volume.
%
% ras 02/05.

rx.ui.rxFig = figure('Color', 'w',...
                      'Name', 'mrRx Prescription on Volume',...
                      'Units', 'Normalized',...
                      'Position', [.02 .25 .3 .4],...
                      'NumberTitle', 'off',...
                      'MenuBar', 'none', ...
                      'CloseRequestFcn', 'closereq; rxRefresh;');


% make a slider for paging through slices
nSlices = size(rx.vol,3);
rx.ui.volSlice = rxMakeSlider('Slice', [1 nSlices], [.02 .12 .3 .1], ...
                              1, round(nSlices/2), 1);
                        
                         
% make brightness and contrast sliders
rx.ui.volBright = rxMakeSlider('Brightness', [0 1], ...
                             [.37 .12 .3 .1], 0, 0.5);
rx.ui.volContrast = rxMakeSlider('Contrast', [0 1], ...
                             [.7 .12 .3 .1], 0, 0.5);
                         

% make orientation buttons
orientations = {'Axi' 'Cor' 'Sag'}; % 'Orthogonal'
rx.ui.volOri = rxMakeButton(orientations, [.02 .02 .7 .1], 1);
selectButton(rx.ui.volOri, 1);
                   

% make axes
rx.ui.rxAxes = axes('Position', [.15 .22 .75 .72]);

% make a checkbox to toggle drawing Rx
rx.ui.rxDrawRx = uicontrol('Style', 'checkbox', 'String', 'Show Rx',...
          'Units', 'normalized', 'Position', [.77 .05 .2 .05], ...
          'Value', 1, 'FontSize', 10, ...
          'BackgroundColor', 'w', 'Callback', 'rxRefresh;');

      
%%%%%%%%%%%%%%%%%%%%%%%      
% add an options menu %
%%%%%%%%%%%%%%%%%%%%%%%
h = uimenu('Label', 'View Options');

% set radiological conventions toggle
uimenu(h, 'Label', 'Radiological L/R', 'Checked', 'off', ...
          'Separator', 'off', 'Tag', 'rxRadiologicalMenu', ...
          'Callback', 'umtoggle(gcbo); rxRefresh; ');
      
% zoom option
uimenu(h, 'Label', 'Zoom', 'Accelerator', 'Z', 'Callback', 'zoom');

% zoom option
uimenu(h, 'Label', 'Reset Zoom', 'Accelerator', 'R', 'Callback', 'zoom out');


% let the user toggle the regular figure menus      
addFigMenuToggle(h);


return
