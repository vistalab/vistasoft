function rx = rxOpenRefFig(rx)
% rx = rxOpenRefFig(rx);
%
% Open a window for the reference volume.
%
% ras 02/05

rx.ui.refFig = figure('Color','w',...
                      'Name','mrRx Reference Slice',...
                      'Units','Normalized',...
                      'NumberTitle','off',...
                      'MenuBar', 'none', ...
                      'Position',[.67 .25 .3 .4]);
                  
rx.ui.refAxes = axes('Position',[0 .15 1 .75]);

% make brightness and contrast sliders
rx.ui.refBright = rxMakeSlider('Brightness',[0 1],...
                             [.35 .02 .3 .1],0,0.5);
rx.ui.refContrast = rxMakeSlider('Contrast',[0 1],...
                             [.68 .02 .3 .1],0,0.5);

% make a contrast auto-threshold checkbox as well
rx.ui.refHistoThresh = uicontrol('Style', 'checkbox', ...
                        'String', 'Auto-contrast', ...
                        'Units', 'normalized', ...
                        'Position', [.05 .05 .25 .05], ...
                        'FontSize', 10, 'BackgroundColor', 'w', ...
                        'Value', 0, 'Callback', 'rxRefresh;');                         
                         
% update the callback for the brightness/contrast
% sliders, so that they update the reference fig:
% (a bit of a hack):
cb = get(rx.ui.refBright.sliderHandle,'Callback'); 
cb = [cb(1:end-1) '([],1);'];
set(rx.ui.refBright.sliderHandle,'Callback',cb);
set(rx.ui.refContrast.sliderHandle,'Callback',cb);

cb = get(rx.ui.refBright.editHandle,'Callback'); 
cb = [cb(1:end-1) '([],1);'];
set(rx.ui.refBright.editHandle,'Callback',cb);
set(rx.ui.refContrast.editHandle,'Callback',cb);
       
return