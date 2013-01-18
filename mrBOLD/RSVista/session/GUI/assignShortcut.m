function [label, callback] = assignShortcut(obj);
%
% [label, callback] = assignShortcut(<obj=gcbo>);
%
% Put up a dialog to allow the user to change a uicontrol's
% callback / string properties. Returns the string for the label 
% and callback, and assigns the relevant properties to the object.
%
% ras, 07/06.
if nargin<1, obj = gcbo; end

label = get(obj, 'String');
callback = get(obj, 'Callback');

fig = figure('Name', 'Assign Shortcut', 'Color', [.9 .9 .9], 'Units', 'normalized', ...
       'Position', [.2 .6 .6 .3], 'NumberTitle', 'off', 'MenuBar', 'none', ...
       'CloseRequestFcn', 'ok = 0; uiresume;');
   
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [.05 .9 .3 .1], ...
          'BackgroundColor', get(gcf, 'Color'), ...
          'String', 'Button Label:', 'HorizontalAlignment', 'left', 'FontSize', 10);

h1 = uicontrol('Style', 'edit', 'Units', 'normalized', 'Position', [.05 .7 .9 .2], ...
          'String', label, 'HorizontalAlignment', 'left', 'FontSize', 11);
      
          
str = 'Enter Some code to execute (in the command line) when you press this button:';        
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [.05 .6 .3 .1], ...
          'BackgroundColor', get(gcf, 'Color'), ...
          'String', str, 'HorizontalAlignment', 'left', 'FontSize', 10);

h2 = uicontrol('Style', 'edit', 'Units', 'normalized', 'Position', [.05 .15 .9 .4], ...
          'String', callback, 'Max', 7, 'HorizontalAlignment', 'left', 'FontSize', 10);
      
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [.05 .05 .3 .1], ...
          'String', 'OK', 'HorizontalAlignment', 'left', 'FontSize', 12, ...
          'BackgroundColor', [.7 .1 .1], ...
          'Callback', 'ok = 1; uiresume;');
          
uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [.55 .05 .3 .1], ...
          'String', 'Cancel', 'HorizontalAlignment', 'left', 'FontSize', 12, ...
          'BackgroundColor', [.2 .5 .2], ...
          'Callback', 'ok = 0; delete(gcf); return;');
          
uiwait; % will resume on figure close       

label = get(h1, 'String');
callback = get(h2, 'String')';
          
delete(fig);      
          
set(obj, 'String', label, 'Callback', callback);

return


% dlg(1).fieldName = 'string';
% dlg(1).style = 'edit';
% dlg(1).string = 'Button Name:';
% dlg(1).value = '';
% 
% dlg(2).fieldName = 'callback';
% dlg(2).style = 'edit';
% dlg(2).string = 'Callback text for button:';
% dlg(2).value = '';
% 
% resp = generalDialog(dlg, 'Set Button Callback', [.2 .6 .6 .3]);
