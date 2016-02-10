function vw = contrastGUI(vw, flag)
%
% vw = contrastGUI([vw=cur view])
%
% Dialog to set parameters for a contrast map.
%
% Inputs:
%  stim: stim ('stim') structure from er_concatParfiles.
%  initParams: initial params structure specifying initial values for the
%       relevant fields (same format as output p struct below).
%
% Outputs: parameters structure p with fields:
%   active: initial list of active conditions, or weights of active conditions.
%   control:  initial list of control conditions, or weights.
%   name: contrast name.
%   options: [to be added]
%
%
% ras, 01/2007.

% first, check if this is a callback from one of the uicontrols --
% if it is, it will have a flag as the third argument, describing what to
% do next:
if exist('flag','var')
    s = get(gcf,'UserData'); % this struct will be useful for the callbacks

    switch flag
        case 1,     num = get(gcbo,'UserData');  setControlCond(s, num);
        case 2,     num = get(gcbo,'UserData');  setActiveCond(s, num);
        case 3,     setSaveNameUI(s);
        case 4,     vw = callComputeContrastMap(s, vw);
        otherwise,  error('Illegal flag entered as third param.')
    end

    return
end

if notDefined('vw'),  vw = getCurView;  end


%% open the figure
s = openFig(vw);

%% append an 'Advanced Options' params
advancedOptionsPanel(s);

return
% /---------------------------------------------------------------------/ %




%% /---------------------------------------------------------------------/ %
function s = openFig(vw)
% s = openFig(stim);
% creates the interface window and returns the GUI structure s.

stim = er_concatParfiles(vw);
nConds = length(stim.condNums);
winHeight = (30 * nConds) + 180; % do this in pixels, 30 pix per condition row
winWidth = 450;
bgColor = [.8 .8 .8];
fgColor = [0 0 0];
s.h(1) = figure('Name', 'Statistical Contrast Map', 'Color', bgColor, ...
    'Position', [300 300 winWidth winHeight],...
    'NumberTitle', 'off', 'MenuBar','none');

% add title text fields
tittxt = sprintf('Compute a Contrast Map');
uicontrol('Style','text','String',tittxt,...
    'FontName','Helvetica','FontSize',18,'FontWeight','bold',...
    'HorizontalAlignment','center',...
    'ForegroundColor', fgColor, 'BackgroundColor', bgColor, ...
    'Units','Normalized', ...
    'Position',[10/winWidth (winHeight-30)/winHeight 430/winWidth 30/winHeight]);

uicontrol('Style', 'text', 'String', viewGet(vw, 'annotation'),...
    'FontName','Helvetica','FontSize',16,'FontWeight','bold',...
    'HorizontalAlignment','center',...
    'ForegroundColor', fgColor, 'BackgroundColor', bgColor,...
    'Units','Normalized','Position',[10/winWidth (winHeight-60)/winHeight 430/winWidth 30/winHeight]);

% make a top row of labels
uicontrol('Style', 'text', 'String', 'Cond #', ...
    'ForegroundColor', fgColor, 'BackgroundColor', bgColor, ...
    'FontName', 'Helvetica', 'FontSize', 12, 'FontWeight', 'bold', ...
    'Units', 'Normalized', ...
    'Position', [30/winWidth (winHeight-90)/winHeight 60/winWidth 30/winHeight]);

uicontrol('Style','text','String','Control?', ...
    'FontName', 'Helvetica', 'FontSize', 12, 'FontWeight', 'bold', ...    
    'ForegroundColor', 'w', 'BackgroundColor', [1 0 0],...
    'Units','Normalized','Position',[360/winWidth (winHeight-90)/winHeight 60/winWidth 30/winHeight]);

uicontrol('Style','text','String','Condition Name',...
    'FontName', 'Helvetica', 'FontSize', 12, 'FontWeight', 'bold', ...    
    'ForegroundColor', fgColor, 'BackgroundColor', bgColor, ...
    'Units','Normalized','Position',[210/winWidth (winHeight-90)/winHeight 120/winWidth 30/winHeight]);

uicontrol('Style','text','String','Active?', ...
    'FontName', 'Helvetica', 'FontSize', 12, 'FontWeight', 'bold', ...    
    'ForegroundColor', 'w', 'BackgroundColor', [0 0 1],...
    'Units','Normalized','Position',[120/winWidth (winHeight-90)/winHeight 60/winWidth 30/winHeight]);


% make labels for each cond num
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.condNumHandles(i) = uicontrol('Style', 'text', ...
        'String', num2str(stim.condNums(i)), ...
        'FontName', 'Helvetica', 'FontSize', 12, ...
        'ForegroundColor', fgColor, 'BackgroundColor', bgColor,...
        'Units', 'Normalized', ...
        'Position', [30/winWidth ypos 60/winWidth 30/winHeight]);
end

% make control checkboxes for each cond
cbstr = sprintf('contrastGUI(%s, 1);', vw.name);
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.controlHandles(i) = uicontrol('Style','checkbox','Value',0,...
        'FontName','Helvetica','FontSize',12,...
        'ForegroundColor',fgColor,'BackgroundColor',bgColor,...
        'UserData',i,'Callback',cbstr,...
        'Units','Normalized','Position',[360/winWidth ypos 60/winWidth 30/winHeight]);

    % add a weights control
    s.controlWeightEdits(i) = uicontrol('Style', 'edit', 'String','',...
        'FontName', 'Helvetica', 'FontSize', 8,...
        'ForegroundColor', [0 0 0], 'BackgroundColor', [1 1 1],...
        'UserData', i, 'Callback', cbstr, 'Enable', 'off', ...
        'Visible', 'off', 'Units', 'Normalized', ...
        'Position', [(380/winWidth) (ypos + 8/winWidth) 40/winWidth 20/winHeight]);

end

% make text fields for each cond name
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.condNameHandles(i) = uicontrol('Style', 'text', ...
        'String', stim.condNames{i},...
        'FontName', 'Helvetica', 'FontSize', 12,...
        'ForegroundColor', fgColor, 'BackgroundColor', [1 1 1],...
        'Units', 'Normalized', ...
        'Position',[210/winWidth ypos 120/winWidth 30/winHeight]);
end

% make active checkboxes for each cond
cbstr = sprintf('contrastGUI(%s, 2);', vw.name);
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.activeHandles(i) = uicontrol('Style','check','Value',0,...
        'FontName','Helvetica','FontSize',12,'FontWeight','bold',...
        'ForegroundColor', fgColor, 'BackgroundColor',bgColor,...
        'UserData',i,'Callback',cbstr,...
        'Units', 'Normalized', ...
        'Position', [120/winWidth ypos 60/winWidth 30/winHeight]);

    s.activeWeightEdits(i) = uicontrol('Style', 'edit', 'String', '', ...
        'FontName', 'Helvetica', 'FontSize', 8, ...
        'ForegroundColor', fgColor, 'BackgroundColor', [1 1 1],...
        'UserData', i, 'Callback', cbstr, 'Enable', 'off', ...
        'Visible', 'off', 'Units', 'Normalized', ...
        'Position', [(140/winWidth) (ypos + 8/winWidth) 40/winWidth 20/winHeight]);

end

% make button to set save file path
cbstr = sprintf('contrastGUI(%s, 3);', vw.name);
s.setPathHandle = uicontrol('Style', 'pushbutton', 'String', 'Name:',...
    'FontName', 'Helvetica', 'FontSize',12,...
    'ForegroundColor', 'k', 'BackgroundColor', [.8 .8 .8],...
    'Callback', cbstr, 'Enable', 'off', ...
    'Units', 'Normalized', ...
    'Position', [120/winWidth 50/winHeight 60/winWidth 30/winHeight]);

% make field with save filename
s.saveHandle = uicontrol('Style', 'edit', 'String', 'V ',...
    'FontName', 'Helvetica', 'FontSize',12, 'FontWeight', 'bold', ...
    'ForegroundColor', [0 0 0], 'BackgroundColor', [1 1 1], ...
    'Enable','off',...
    'Units', 'Normalized', ...
    'Position', [120/winWidth 20/winHeight 210/winWidth 30/winHeight]);

% make 'GO' button
cbstr = sprintf('%s = contrastGUI(%s, 4);',vw.name, vw.name);
s.goHandle = uicontrol('Style','pushbutton', 'String', 'GO',...
    'FontName', 'Helvetica', 'FontSize', 24, 'FontWeight', 'bold',...
    'ForegroundColor',[1 1 1],'BackgroundColor',[.1 .7 .1],...
    'UserData', stim.condNums,...
    'Callback', cbstr, 'Enable', 'off', ...
    'Units', 'Normalized', ...
    'Position', [360/winWidth 20/winHeight 60/winWidth 60/winHeight]);

% put the s struct, containing important info, in the figure UserData
s.condNames = stim.condNames;
s.condNums = stim.condNums;
set(gcf, 'UserData', s);

return
% /---------------------------------------------------------------------/ %



 

% /---------------------------------------------------------------------/ %
function s = advancedOptionsPanel(s)
% Add a uipanel containing advanced controls for a contrast map,
% such as setting the type of statistical test (F or T), the
% units of the resulting map (-log(p), T, F, p, ces, etc), and
% whether to activate the weights edit controls.

s.optsPanel = mrvPanel('below', .25);

% popup menu to set test type
s.testPopup = uicontrol('Parent', s.optsPanel, 'Style', 'popup', ...
    'Units', 'normalized', 'Position', [.1 .4 .2 .15], ...
    'FontName', 'Arial', 'FontSize', 12, ...
	'BackgroundColor', get(gcf, 'Color'), ...
    'String', {'T test' 'F test'}, 'Value', 1);

uicontrol('Parent', s.optsPanel, 'Style', 'text', ...
    'Units', 'normalized', 'Position', [.1 .6 .2 .1], ...
    'String', 'Test Type', 'FontName', 'Helvetica', ...
	'BackgroundColor', get(gcf, 'Color'), ...
    'FontSize', 10, 'FontWeight', 'bold', 'FontAngle', 'italic');

% popup menu to set units of map
vals = {'-log(p)' 'p' 'T' 'F' 'Contrast Effect Size'};
s.unitPopup = uicontrol('Parent', s.optsPanel, 'Style', 'popup', ...
    'Units', 'normalized', 'Position', [.4 .4 .2 .15], ...
    'FontName', 'Arial', 'FontSize', 12, ...
	'BackgroundColor', get(gcf, 'Color'), ...
    'String', vals, 'Value', 1);

uicontrol('Parent', s.optsPanel, 'Style', 'text', ...
    'Units', 'normalized', 'Position', [.4 .6 .2 .1], ...
    'String', 'Units For Map?', 'FontName', 'Helvetica', ...
	'BackgroundColor', get(gcf, 'Color'), ...
    'FontSize', 10, 'FontWeight', 'bold', 'FontAngle', 'italic');

% checkbox to toggle visibility of edit fields for condition weights
cb = ['TMP = get(gcf, ''UserData''); ' ...
      'vis = get(gcbo, ''Value'') + 1; ' ...
      'onoff = {''off'' ''on''}; ' ...
      'set(TMP.activeWeightEdits, ''Visible'', onoff{vis}); ' ...
      'set(TMP.controlWeightEdits, ''Visible'', onoff{vis}); ' ...
      'clear TMP vis onoff '];
uicontrol('Parent', s.optsPanel, 'Style', 'checkbox', ...
    'Units', 'normalized', 'Position', [.1 .1 .5 .15], ...
    'String', 'Set Condition Weights', 'FontName', 'Helvetica', ...
	'BackgroundColor', get(gcf, 'Color'), ...
    'FontSize', 10, 'Callback', cb);


% initialize panel to invisible
mrvPanelToggle(s.optsPanel, 'off');

% add a button to the main GUI to toggle this panel
cb = ['TMP = get(gcf, ''UserData''); ' ...
      'mrvPanelToggle(TMP.optsPanel); ' ...
      'clear TMP '];
s.panelToggle = uicontrol('Style', 'pushbutton', ...
    'String', 'More...', 'Units', 'norm', 'Position', [.1 .03 .15 .06], ...
    'BackgroundColor', [.9 .9 .9], 'ForegroundColor', 'k', ...
    'Callback', cb);

% update userdata of GUI to include this info
set(gcf, 'UserData', s);

return
% /---------------------------------------------------------------------/ %

% /---------------------------------------------------------------------/ %
function setControlCond(s,num)
% set the specified num condition as a control condition,
% highlighting the selected condition number and checking if ready to
% proceed

[active control w] = loadActiveControl(s);

bgColor = get(gcf, 'Color'); 

if get(s.controlHandles(num),'Value')==1
	set(s.controlHandles(num),'BackgroundColor',[1 0 0]);
	set(s.activeHandles(num),'Value',0,'BackgroundColor',bgColor);
    set(s.condNameHandles(num),'ForegroundColor','w','BackgroundColor',[1 0 0]);
    set(s.condNumHandles(num),'ForegroundColor','w','BackgroundColor',[1 0 0]);
    set(s.controlWeightEdits(num),'Enable','On');
    set(s.activeWeightEdits(num),'Enable','Off','String','');

    if isempty(get(s.controlWeightEdits(num),'String'))
        set(s.controlWeightEdits(num),'String','1');
    end

else
	set(s.controlHandles(num),'BackgroundColor',bgColor);
    set(s.condNameHandles(num),'ForegroundColor','k','BackgroundColor',[1 1 1]);
    set(s.condNumHandles(num),'ForegroundColor','k','BackgroundColor',bgColor);
    set(s.controlWeightEdits(num),'Enable','Off','String','');

end

setEvenWeights(s);

checkIfReady(s);

return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function setActiveCond(s,num)
% set the specified num condition as an active condition,
% highlighting the selected condition number and checking if ready to
% proceed

[active control w] = loadActiveControl(s);

bgColor = get(gcf, 'Color'); 

if get(s.activeHandles(num),'Value')==1
	set(s.activeHandles(num),'BackgroundColor',[0 0 1]);
    set(s.controlHandles(num),'Value',0,'BackgroundColor',bgColor);
    set(s.condNameHandles(num),'ForegroundColor','w','BackgroundColor',[0 0 1]);
    set(s.condNumHandles(num),'ForegroundColor','w','BackgroundColor',[0 0 1]);
    set(s.activeWeightEdits(num),'Enable','On');
    set(s.controlWeightEdits(num),'Enable','Off','String','');

    if isempty(get(s.activeWeightEdits(num), 'String'))
        set(s.activeWeightEdits(num), 'String', '1');
    end

else
	set(s.activeHandles(num),'BackgroundColor',bgColor);
    set(s.condNameHandles(num),'ForegroundColor','k','BackgroundColor',[1 1 1]);
    set(s.condNumHandles(num),'ForegroundColor','k','BackgroundColor',bgColor);
    set(s.activeWeightEdits(num),'Enable','Off','String','');
    
end

setEvenWeights(s);

checkIfReady(s);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function checkIfReady(s)
% update the name of the save file based on the highlighted conditions, and
% check if at least one control and one active condition are selected -- if
% so, enable the GO button.
atLeast1C = 0; atLeast1A = 0;

for i = 1:length(s.condNameHandles)
    s.condNames{i} = get(s.condNameHandles(i),'String');
end

saveName = '';
for i = 1:length(s.activeHandles)
    if get(s.activeHandles(i),'Value')==1
        saveName = [saveName rmBlanks(s.condNames{i})];
        atLeast1C = 1;
    end
end

saveName = [saveName 'V'];

for i = 1:length(s.controlHandles)
    if get(s.controlHandles(i),'Value')==1
        saveName = [saveName rmBlanks(s.condNames{i})];
        atLeast1A = 1;
    end
end

set(s.saveHandle,'String',saveName);

if atLeast1C && atLeast1A
    set(s.setPathHandle,'Enable','on');
    set(s.saveHandle,'Enable','on');
    set(s.goHandle,'Enable','on');
else
    set(s.setPathHandle,'Enable','off');
    set(s.saveHandle,'Enable','off');
    set(s.goHandle,'Enable','off');
end

return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function str = rmBlanks(str)
% removes all the blanks from str.
ok = ones(size(str));
loc = findstr(' ',str);
ok(loc) = 0;
str = str(find(ok));
return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function setSaveNameUI(s,num)
[fname,pth] = myUIPutFile('Inplane/Original/','*.mat','Select a save file name / path: ' );
saveName = fullfile(pth,fname);
set(s.saveHandle,'String',saveName);
return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function setEvenWeights(s)
% make the weights for all selected active and control conditions
% equal. (sum of active weights = 1; sum of control weights = -1).

[active control w] = loadActiveControl(s);

if sum(w) ~= 0
    if ~isempty(active)
        w(active) = 1 / length(active);
    end
    
    if ~isempty(control)
        w(control) = -1 / length(control);
    end
end

for i = 1:length(s.activeHandles)
    if get(s.activeHandles(i),'Value')==1
        set(s.activeWeightEdits(i), 'String', num2str(w(i)));
        
    elseif get(s.controlHandles(i),'Value')==1
        set(s.controlWeightEdits(i), 'String', num2str(w(i)));
        
    end
end

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function [active, control, w] = loadActiveControl(s)
% [active, control, w] = loadActiveControl(s)
% get the active and control conditions based on the GUI settings.
% active: list of active conditions.
% control: list of control conditions.
% w: weights vector, where graded weights can be used for 
% each condition. (+ weight = active, -weight = control).

active = zeros(1,length(s.activeHandles));
control = zeros(1,length(s.activeHandles));
w = zeros(1, length(s.activeHandles));

for i = 1:length(s.activeHandles)
    if get(s.activeHandles(i),'Value')==1
        active(i) = 1;
        
        if ~isempty( get(s.activeWeightEdits(i), 'String') )
            w(i) = str2num(get(s.activeWeightEdits(i),'String'));
        end
    elseif get(s.controlHandles(i),'Value')==1
        control(i) = 1;
        
        if ~isempty( get(s.controlWeightEdits(i), 'String') )
            w(i) = -str2double(get(s.controlWeightEdits(i),'String'));
        end
    end
end

active = find(active);
control = find(control);


return
% /---------------------------------------------------------------------/ %






% /---------------------------------------------------------------------/ %
function vw = callComputeContrastMap(s, vw)
% callback for the big 'GO' button; this takes the UI info
% contained in the s struct, and calls the computeContrastMap
% function:
hgui = gcf;

[active control w] = loadActiveControl(s);

% account for null condition: -1 offset to get to condNums
active = active - 1;
control = control - 1;

% get advanced options (test type, units)
testList = {'T' 'F'};
test = testList{ get(s.testPopup, 'Value') };
unitList = {'log10p' 'p' 't' 'f' 'ces'};
units = unitList{ get(s.unitPopup, 'Value') };


saveName = get(s.saveHandle,'String');
if isempty(findstr(filesep,saveName)) % check that absolute path not specified
    %     savePath = fullfile(dataDir(vw),['contrastMap_' saveName]);
    savePath = fullfile(dataDir(vw),saveName);
else
    savePath = saveName;
end

condNums = get(gcbo,'UserData');

% to do: use weights vector
vw = computeContrastMap2(vw, active, control, saveName, ...
                           'test', test, 'mapUnits', units);

close(hgui);

return
% /---------------------------------------------------------------------/ %

