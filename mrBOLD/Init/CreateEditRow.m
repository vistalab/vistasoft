function h = CreateEditRow(data, initPos, cPos, topH, fontSize, callbk, width)

% function h = CreateEditRow(data, initPos, cPos, topH, ...
%                            fontSize, callbk);
%
% Create a pair of ui fields that correspond to one row of the
% session edit. The first is the label, and the second is the
% current contents of the session structure. These data a
% provided by the input data cell array. The position of the
% label string must be provided by the input initPos. The content
% ui will be editable if the appropriate flag in the data array
% is set. The handle of the content field is returned as h. See
% GetReconEdit.m for more information.
% 'width' specifies the width of the content field, in characters. If
% omitted, figures out a nice value based on the size of the content.
%
% DBR 4/99
% DBR 6/99  Modified to allow selectable callback string
% ras, 03/06 made width an input argument.
if notDefined('callbk'), callbk = 'UpdateEdit'; end

bkColor = get(topH, 'color');
label = data.label;
content = data.content;

if ~exist('width', 'var'), 
    width = length(content) + 5;
end

uicontrol( ...
    'Style', 'text', ...
    'Units', 'char', ...
    'String', label, ...
    'BackgroundColor', bkColor, ...
    'Position', initPos, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', fontSize ...
    );
if data.edit
  style = 'edit';
  cString = [callbk, '(', num2str(topH), ');'];
  cColor = [1., 0.9, 0.6];
else
  style = 'text';
  cString = '';
  cColor = bkColor;
end

contentPos = [cPos, initPos(2), width, initPos(4)];
h = uicontrol( ...
    'Style', style, ...
    'Units', 'char', ...
    'String', content, ...
    'BackgroundColor', cColor, ...
    'Position', contentPos, ...
    'HorizontalAlignment', 'left',...
    'FontSize', fontSize, ...
    'Callback', cString ...
    );

return