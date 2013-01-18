function view = er_mkcontrast(view,scans,flag);
% er_mkcontrast(view,[scans]): interface for calling mrVista-compatible
% stxgrinder code (e.g., for making a contrast map by running a GLM).
%
% This code takes the selected scans (prompts a dialog to choose 'em 
% if they're not entered as arguments, or takes the view's current scan
% if 0 is entered), checks that they each have parfiles
% assigned, then scans the parfiles for the conditions and labels present.
% It then pops up a nice window for choosing active and control conditions,
% as well as choosing a name for the resulting contrast map (though there
% are also automated naming conventions for this), then calls up
% er_stxgrinder, which creates the contrast map and saves it as a
% mrLoadRet-style parameter map.
%
% scans: which scans in the current data type to use. Default is
%        to prompt for it. If 0, use current scan, if set to -1,
%        it will use the scans assigned in the 'scanGroup' field
%        of that scan's scanParams (in dataTYPES; see er_groupScans).
% 
%
% 02/18/04 ras: started writing it.
% 03/10/04 ras: just about finished.
% 03/11/04 ras: re-added null condition as an option.
% 04/08/04 ras: added option to use pre-assigned scan groups
%               for the analysis (see er_groupScans).
% 09/30/04 ras: now no longer appends 'contrastMap_' before
%               the contrast name, shorter names are nicer.
% 04/20/05 gb : Edit boxes have been added to let the user enter the 
%               coefficients of each condition.

global dataTYPES HOMEDIR;

% first, check if this is a callback from one of the uicontrols --
% if it is, it will have a flag as the third argument, describing what to
% do next:
if exist('flag','var')
    s = get(gcf,'UserData'); % this struct will be useful for the callbacks
    
    switch flag
        case 1,
            num = get(gcbo,'UserData');
            setControlCond(s,num);
        case 2,
            num = get(gcbo,'UserData');
            setActiveCond(s,num);
        case 3,
            setSaveNameUI(s);
        case 4,
            view = callComputeContrastMap(s,view,scans);
        otherwise,
            error('Illegal flag entered as third param.')
    end
    
    return
end

cdt = view.curDataType;
dt = cdt; % will change if choosing scan group

%%%%% select scans if needed%%%%%
if ~exist('scans','var')
	[scans, ok] = er_selectScans(view);
	if ~ok  return;  end
elseif scans==0 % flag to use current scan
    scans = getCurScan(view);
elseif scans==-1 % flag to use scan group
    [scans, dt] = er_getScanGroup(view);
    view.curDataType = dt;
end

%%%%% select parfiles for each scan if needed%%%%%
checkParfiles(view,scans);

%%%%% load up the parfiles; find what conditions are present %%%%%
trials = er_concatParfiles(view,scans);
condNums = trials.condNums;
condNames = trials.condNames;
    
% -------------------------------------------------------------------------
% create the interface window
% -------------------------------------------------------------------------
nConds = length(condNums);
winHeight = (30 * nConds) + 180; % do this in pixels, 30 pix per condition row
winWidth = 450;
s.h(1) = figure('Name','er_mkcontrast','Color',[0 0 0.3],'Position',[300 300 winWidth winHeight],...
                           'MenuBar','none');

% add title text fields
tittxt = sprintf('Compute a Contrast Map');
uicontrol('Style','text','String',tittxt,...
          'FontName','Helvetica','FontSize',18,'FontWeight','bold',...
          'HorizontalAlignment','center',...    
          'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 .3],...
          'Units','Normalized','Position',[10/winWidth (winHeight-30)/winHeight 430/winWidth 30/winHeight]);

tittxt2 = sprintf('Scan: %s',num2str(scans));      
uicontrol('Style','text','String',tittxt2,...
          'FontName','Helvetica','FontSize',16,'FontWeight','bold',...
          'HorizontalAlignment','center',...    
          'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 .3],...
          'Units','Normalized','Position',[10/winWidth (winHeight-60)/winHeight 430/winWidth 30/winHeight]);
      
% make a top row of labels
uicontrol('Style','text','String','Cond #',...
          'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 .3],...
          'Units','Normalized','Position',[30/winWidth (winHeight-90)/winHeight 60/winWidth 30/winHeight]);

uicontrol('Style','text','String','Control?',...
          'ForegroundColor',[1 1 1],'BackgroundColor',[1 0 0],...
          'Units','Normalized','Position',[360/winWidth (winHeight-90)/winHeight 60/winWidth 30/winHeight]);

uicontrol('Style','text','String','Condition Name',...
          'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 .3],...
          'Units','Normalized','Position',[210/winWidth (winHeight-90)/winHeight 120/winWidth 30/winHeight]);

uicontrol('Style','text','String','Active?',...
          'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 1],...
          'Units','Normalized','Position',[120/winWidth (winHeight-90)/winHeight 60/winWidth 30/winHeight]);
      

% make labels for each cond num
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.condNumHandles(i) = uicontrol('Style','text','String',num2str(condNums(i)),...
                                                  'FontName','Helvetica','FontSize',14,...
                                                  'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 .3],...
                                                  'Units','Normalized','Position',[30/winWidth ypos 60/winWidth 30/winHeight]);
end

% make control checkboxes for each cond 
cbstr = sprintf('er_mkcontrast(%s,[%s],1);',view.name,num2str(scans));
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.controlHandles(i) = uicontrol('Style','checkbox','Value',0,...
                                              'FontName','Helvetica','FontSize',14,...
                                              'ForegroundColor',[1 1 1],'BackgroundColor',[1 0 0],...
                                              'UserData',i,'Callback',cbstr,...
                                              'Units','Normalized','Position',[360/winWidth ypos 60/winWidth 30/winHeight]);
                                          
    s.editControlHandles(i) = uicontrol('Style','edit','String','',...
                                              'FontName','Arial','FontSize',8,...
                                              'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1],...
                                              'UserData',i,'Callback',cbstr,'Enable','off',...
                                              'Units','Normalized','Position',[(380/winWidth) (ypos + 8/winWidth) 40/winWidth 20/winHeight]);

end

% make edit fields for each cond name
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.condNameHandles(i) = uicontrol('Style','edit','String',condNames{i},...
                                                      'FontName','Helvetica','FontSize',14,...
                                                      'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1],...
                                                      'Units','Normalized','Position',[210/winWidth ypos 120/winWidth 30/winHeight]);
end

% make active checkboxes for each cond
cbstr = sprintf('er_mkcontrast(%s,[%s],2);',view.name,num2str(scans));
for i = 1:nConds
    ypos = (winHeight - 90 -  30*i)/winHeight;
    s.activeHandles(i) = uicontrol('Style','check','Value',0,...
                                          'FontName','Helvetica','FontSize',14,'FontWeight','bold',...
                                          'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 1],...
                                          'UserData',i,'Callback',cbstr,...
                                          'Units','Normalized','Position',[120/winWidth ypos 60/winWidth 30/winHeight]);

    s.editActiveHandles(i) = uicontrol('Style','edit','String','',...
                                              'FontName','Arial','FontSize',8,...
                                              'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1],...
                                              'UserData',i,'Callback',cbstr,'Enable','off',...
                                              'Units','Normalized','Position',[(140/winWidth) (ypos + 8/winWidth) 40/winWidth 20/winHeight]);                     
                                      
end

% make button to set save file path
cbstr = sprintf('er_mkcontrast(%s,[%s],3);',view.name,num2str(scans));
s.setPathHandle = uicontrol('Style','pushbutton','String','Name:',...
                                      'FontName','Helvetica','FontSize',14,...
                                      'ForegroundColor',[1 1 1],'BackgroundColor',[.3 .3 .3],...
                                      'Callback',cbstr,'Enable','off',...
                                      'Units','Normalized','Position',[30/winWidth 20/winHeight 60/winWidth 30/winHeight]);
     
% make field with save filename
s.saveHandle = uicontrol('Style','edit','String','V ',...
                                  'FontName','Helvetica','FontSize',14,'FontWeight','bold',...
                                  'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1],...
                                  'Enable','off',...
                                  'Units','Normalized','Position',[120/winWidth 20/winHeight 210/winWidth 30/winHeight]);

% make 'GO' button
cbstr = sprintf('%s = er_mkcontrast(%s,[%s],4);',view.name,view.name,num2str(scans));
s.goHandle = uicontrol('Style','pushbutton','String','GO',...
                              'FontName','Helvetica','FontSize',24,'FontWeight','bold',...
                              'ForegroundColor',[1 1 1],'BackgroundColor',[0 1 0],...
                              'UserData',condNums,...
                              'Callback',cbstr,'Enable','off',...
                              'Units','Normalized','Position',[360/winWidth 20/winHeight 60/winWidth 60/winHeight]);

% put the s struct, containing important info, in the figure UserData
s.condNames = condNames;
s.condNums = condNums;
set(gcf,'UserData',s);
% -------------------------------------------------------------------------
% end create interface window
% -------------------------------------------------------------------------

% if using scan group, switch back selected data type
if scans==-1    view.curDataType = cdt;     end
                          
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function setControlCond(s,num);
% set the specified num condition as a control condition, 
% highlighting the selected condition number and checking if ready to
% proceed

[active,control] = loadActiveControl(s);

if get(s.controlHandles(num),'Value')==1
	set(s.activeHandles(num),'Value',0);
	set(s.condNameHandles(num),'ForegroundColor',[1 1 1],'BackgroundColor',[1 0 0]);
	set(s.condNumHandles(num),'ForegroundColor',[1 1 1],'BackgroundColor',[1 0 0]);
    set(s.editControlHandles(num),'Enable','On');
    set(s.editActiveHandles(num),'Enable','Off','String','');
    
    if isempty(get(s.editControlHandles(num),'String'))
        if num == 1
            stri = num2str(0);
        else
            indexes = setdiff(find(control{1} == 1),num);
            if isempty(indexes)
                val = -1;
            else
                val = max(control{2}(indexes));
            end
            stri = num2str(val);
        end
            
        set(s.editControlHandles(num),'String',stri);
    end       
    
else
	set(s.condNameHandles(num),'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1]);
	set(s.condNumHandles(num),'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 .3]);
    set(s.editControlHandles(num),'Enable','Off','String','');
    
end
checkifReady(s);
return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function setActiveCond(s,num);
% set the specified num condition as an active condition, 
% highlighting the selected condition number and checking if ready to
% proceed

[active,control] = loadActiveControl(s);

if get(s.activeHandles(num),'Value')==1
	set(s.controlHandles(num),'Value',0);
	set(s.condNameHandles(num),'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 1]);
	set(s.condNumHandles(num),'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 1]);
    set(s.editActiveHandles(num),'Enable','On');
    set(s.editControlHandles(num),'Enable','Off','String','');
    
    if isempty(get(s.editActiveHandles(num),'String'))
        indexes = setdiff(find(active{1} == 1),num);
        if isempty(indexes)
            val = 1;
        else
            val = min(active{2}(indexes));
        end
        set(s.editActiveHandles(num),'String',num2str((num ~= 1)*val));
    end  
    
else
	set(s.condNameHandles(num),'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1]);
	set(s.condNumHandles(num),'ForegroundColor',[1 1 1],'BackgroundColor',[0 0 .3]);
    set(s.editActiveHandles(num),'Enable','Off','String','');
end
checkifReady(s);
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function checkifReady(s);
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

if atLeast1C & atLeast1A
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
function str = rmBlanks(str);
% removes all the blanks from str.
ok = ones(size(str));
loc = findstr(' ',str);
ok(loc) = 0;
str = str(find(ok));
return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function setSaveNameUI(s,num);
[fname,pth] = myUIPutFile('Inplane/Original/','*.mat','Select a save file name / path: ' );
saveName = fullfile(pth,fname);
set(s.saveHandle,'String',saveName);
return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function homogenize(s)

[active,control] = loadActiveControl(s);

if sum(control{2}) ~= 0
    control{2} = control{2}/abs(sum(control{2}));
end
if sum(active{2}) ~= 0 
    active{2} = active{2}/abs(sum(active{2}));
end

for i = 1:length(s.activeHandles)
    if get(s.activeHandles(i),'Value')==1
        set(s.editActiveHandles(i),'String',num2str(active{2}(i)));
    elseif get(s.controlHandles(i),'Value')==1
        set(s.editControlHandles(i),'String',num2str(control{2}(i)));
    end
end
    
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function [active,control] = loadActiveControl(s)

active = cell(1,2);
active{1} = zeros(1,length(s.activeHandles));
active{2} = zeros(1,length(s.activeHandles));
control = cell(1,2);
control{1} = zeros(1,length(s.activeHandles));
control{2} = zeros(1,length(s.controlHandles));
for i = 1:length(s.activeHandles)
    if get(s.activeHandles(i),'Value')==1
        active{1}(i) = 1;
        if ~isempty(get(s.editActiveHandles(i),'String'))
            active{2}(i) = str2num(get(s.editActiveHandles(i),'String'));
        end
    elseif get(s.controlHandles(i),'Value')==1
        control{1}(i) = 1;
        if ~isempty(get(s.editControlHandles(i),'String'))
            control{2}(i) = str2num(get(s.editControlHandles(i),'String'));
        end
    end
end

active{2} = abs(active{2});
control{2} = -abs(control{2});

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function view = callComputeContrastMap(s,view,scans);
% callback for the big 'GO' button; this takes the UI info
% contained in the s struct, and calls the computeContrastMap
% function:
hgui = gcf;
homogenize(s);

% button = questdlg('The values have been normalized. Do you want to proceed?','Normalization','Yes','No','Yes');
% if strcmp(button,'No')
%     return
% end

[active,control] = loadActiveControl(s);

saveName = get(s.saveHandle,'String');
if isempty(findstr(filesep,saveName)) % check that absolute path not specified
%     savePath = fullfile(dataDir(view),['contrastMap_' saveName]);
    savePath = fullfile(dataDir(view),saveName);
else
    savePath = saveName;
end

condNums = get(gcbo,'UserData');
active{1} = condNums(find(active{1} > 0));
control{1} = condNums(find(control{1} > 0));

view = computeContrastMap(view,scans,active{2},control{2},savePath); % ,'-override'
close(hgui);
return
% /---------------------------------------------------------------------/ %

