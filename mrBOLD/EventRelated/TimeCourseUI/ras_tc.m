function [h,data] = ras_tc(view,voxels,scans,series);
%   [h,data] = ras_tc(view,[voxels,scans,series])
%
% ras_tc: display time course data for mrLoadRet, in a somewhat 
% fancy way.
%
% This is written to complement (and eventually, incorporate) the
% functionality of my plotting tools for time courses from
% rapid event-related data. This is more general: it covers
% block-design, long event-related, and other conditions, and
% importantly incorporates information from .par files.
%
% [more -- there's a lot I've added, but I'll make one big update
% on the docs when it's nicely filled out. (ras, 02/18/04)]
%
%
%
%
% 1/3/04 ras: wrote it.
% 1/04: added signal to noise ratios, ability to switch off different cond
% displays, shift onsets, change colors
% 2/04: added ability to read multiple scans / concat parfiles if it uses
% them
% 2/23/04: broke up into several functions, under mrLoadRet sub-section
% View/TimeCourseUI. Also made an offshoot of this, fancyplot2, which
% doesn't use the mrLoadRet view info, for kalanit.
global dataTYPES

if nargin >= 1
    updateFlag = 1;
else
    updateFlag = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1ST DECISION: extract new time course data (w/ corresponding
% axes figure) or just re-render existing data? This is decided by 
% the # args: if 1, update data; otherwise, just render.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if updateFlag
    if ~exist('series','var') | isempty(series)
        series = view.curDataType;
    end
    
    if ~exist('scans','var') | isempty(scans(1))
        scans = getCurScan(view);
    end
    
    if ~exist('voxels','var') | isempty(voxels)
        r = view.selectedROI;
        voxels = view.ROIs(r).coords;
        ROIname = view.ROIs(r).name;
    else
        if ischar(voxels)  % assume name of ROI
            ROIname = voxels;
            view = selectROI(view,ROIname);
            r = view.selectedROI;
            voxels = view.ROIs(r).coords;
        else
            if size(voxels,2)==1
                ROIname = sprintf('Point %i, %i, %i',voxels(1),voxels(2),voxels(3));
            else
                ROIname = '(Multiple selected points)';
            end
        end
    end
    
    h = openTcAxes(view,voxels,scans,series,ROIname);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RENDER TIME COURSE (taking into account prefs as specified in the
% ui)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the data struct -- in the current axes' UserData
tc = get(gcf,'UserData');

% clear previous axes in the figure
old = findobj('Type','axes','Parent',gcf);
delete(old);


% parse the preferences set using the ui
if isequal(get(tc.objHandles(3),'Checked'),'on')
    tc.plotType = 1;
elseif isequal(get(tc.objHandles(4),'Checked'),'on')
    tc.plotType = 2;
else
    tc.plotType = 3;
end

% legend (kind of a hack -- legends are tricky)
if isequal(get(tc.objHandles(end),'Checked'),'on')
    sel = find(selectedConds(tc));
	co = [];
	for i = 1:length(sel)
        leg{i} = tc.condNames{sel(i)};
        leg{i}(findstr(leg{i},'_')) = ' ';
        co = [co; tc.condColors{sel(i)}];
	end
	set(gca,'NextPlot','ReplaceChildren');
	set(gca,'ColorOrder',co);
    plot(rand(2,length(sel)),'LineWidth',4); 
    legend(gca,leg,-1);
end


% stash the updated data struct
set(gcf,'UserData',tc);

% shift parfiles by a specified delta, if it exists 
% (this is useful e.g. if the n discarded frames is incorrectly
% specified, or to compensate for h.r.f. rise time)
if isfield(tc,'onsetDelta')
    tc.onsets = tc.onsets + tc.onsetDelta;
end

% plot, according to prefs
switch tc.plotType
case 1, % whole scans TC
    plotWholeTc(tc);
case 2, % all trials separately
    plotAllTrialsTc(tc);
case 3, % mean trials w/ error bars
    plotMeanTrialsTc(tc);
otherwise
    fprintf('huh?')
    return
end

return




%-------------------------------------------------------------------------
function [h,data] = openTcAxes(view,voxels,scans,series,ROIname);
% opens up the time course figure, plus initializes
% the tc struct, which contains all the information
% necessary for plotting and which resides as the 
% figure's user data. This involves a certain degree
% of parsing what sort of design experiment it was: 
% e.g., is it a cyclical experiment, an ABAB alternating-block
% experiment, or an event-related/unpredictable block experiment where 
% the trial/block order is specified in a parfile? 
%
global dataTYPES mrSESSION;

figName = sprintf('Time Course, scans %s  [ROI %s, session %s]',...
                   num2str(scans(1)),ROIname,mrSESSION.sessionCode);,

figure('Name',figName,'Units','Normalized','Position',[0 0.6 0.8 0.3]);

h(1) = gcf;

%%%%% add menus
h(2) = uimenu('ForegroundColor','b','Label','Time Course','Separator','on','Accelerator','T');

% whole tc option callback:
%   set(gcbo,'Checked','on');
%   h = get(gcbo,'UserData');
%   set(h(1),'Checked','off');
%   set(h(2),'Checked','off');
%   ras_tc;
cbStr=['set(gcbo,''Checked'',''on'');'...
        'h = get(gcbo,''UserData'');'...
        'set(h(1),''Checked'',''off'');'... 
        'set(h(2),''Checked'',''off'');'...     
        'ras_tc;'];
h(3) = uimenu(h(2),'Label','Plot Whole Time Course','Separator','off',...
    'Checked','on','Accelerator','K','CallBack',cbStr);

% all trials option callback:
%   set(gcbo,'Checked','on');
%   h = get(gcbo,'UserData');
%   set(h(1),'Checked','off');
%   set(h(2),'Checked','off');
%   ras_tc;
h(4) = uimenu(h(2),'Label','Plot All Trials','Separator','off',...
    'Accelerator','I','CallBack',cbStr);

% mean trials option callback:
%   set(gcbo,'Checked','on');
%   h = get(gcbo,'UserData');
%   set(h(1),'Checked','off');
%   set(h(2),'Checked','off');
%   ras_tc;
h(5) = uimenu(h(2),'Label','Plot Mean Time Course','Separator','off',...
    'Accelerator','M','CallBack',cbStr);           

set(h(3),'UserData',[h(4) h(5)]);
set(h(4),'UserData',[h(3) h(5)]);
set(h(5),'UserData',[h(3) h(4)]);

% calc SNR (cond 1 V cond 2) callback:
%   tc_calcSNR
h(6) = uimenu(h(2),'Label','Calculate SNR (cond 1 V cond 2)','Separator','on','Callback','tc_calcSNR;');

% calc SNR (choose conds)
cbStr = sprintf('condA = input(''Enter signal condition: '');\n');
cbStr = [cbStr sprintf('condB = input(''Enter baseline condition: '');\n')];
cbStr = [cbStr sprintf('tc_calcSNR(condA,condB);')];
h(7) = uimenu(h(2),'Label','Calculate SNR (choose conds)','Separator','off','Callback',cbStr);

% shift tc callback:
% tc = get(gcf,'UserData');
% tc.onsetDelta = input('Enter # secs to shift onsets relative to time course: ');
% set(gcf,'UserData',tc);
cbStr = sprintf('tc = get(gcf,''UserData'');\n');
cbStr = [cbStr sprintf('tc.onsetDelta = input(')];
cbStr = [cbStr sprintf('''Enter # secs to shift onsets relative to time course: ''')];
cbStr = [cbStr sprintf('); \n set(gcf,''UserData'',tc); \n ras_tc;')];
h(8) = uimenu(h(2),'Label','Shift onsets...','Separator','on','Callback',cbStr);

% align trials callback:
% tc = get(gcf,'UserData');
% tc.alignTrials = input('Enter frames (rel. to trial onset) to align traces (may be multiple, 0 sets align off): ','s');
% tc.alignTrials = str2num(tc.alignTrials);
% set(gcf,'UserData',tc);
% err, figure this out later
cbStr = sprintf('tc = get(gcf,''UserData'');\n');
cbStr = [cbStr sprintf('tc.alignTrials = input(')];
cbStr = [cbStr sprintf('''Enter frames (rel. to trial onset) to align traces (may be multiple, 0 sets align off): ''')];
cbStr = [cbStr sprintf(',''s''); \n tc.alignTrials = str2num(tc.alignTrials);\n')];
cbStr = [cbStr sprintf('set(gcf,''UserData'',tc); \n ras_tc;')];
h(9) = uimenu(h(2),'Label','Align traces','Separator','on','Callback',cbStr);

% legend callback:
% umtoggle(gcbo);
% ras_tc;
cbStr=['umtoggle(gcbo); ras_tc;'];
h(9) = uimenu(h(2),'Label','Show Legend','Separator','on',...
    'Checked','on','Accelerator','L','Callback',cbStr);

% construct tc struct
tc.data = [];
tc.TR = dataTYPES(series).scanParams(scans(1)).framePeriod;
tc.voxels = voxels;
tc.plotType = 1;
tc.legend = 1;
tc.abBlocked = [];
tc.conditions = [];
tc.onsets = [];
tc.condNames = {};
tc.condColors = {};
tc.parfile = [];
tc.onsetDelta = 0;
tc.alignTrials = [];
tc.objHandles = h;

% load the data from scans
if length(scans) > 1
    hwait = mrvWaitbar(0,'Loading tSeries from selected scans...');
	for s = scans
        tc.data = [tc.data; meanTSeries(view,s,voxels)];
        mrvWaitbar(s/length(scans),hwait);
	end
    close(hwait);
else
    tc.data = meanTSeries(view,scans(1),voxels);
end

parCheck = 0;
if isfield(dataTYPES(series).scanParams(scans(1)),'parfile')  
    % if the first has a parfile, I assume they all must have one
   if ~isempty(dataTYPES(series).scanParams(scans(1)).parfile)
       parCheck = 1;
   end
end

if parCheck
    tc.abBlocked = 0; 
else
    choice = menu('No parfile assigned for these scans...','Assign one','ABAB blocked','Cycles');
    if choice==1
        tc.abBlocked = 0;
        ras_assignParfileToScan(view);
        tc.parfile = dataTYPES(series).scanParams(scans(1)).parfile;
    elseif choice==2
        tc.abBlocked = 1;
    else
        tc.abBlocked = 2;
    end
end

% This is an important part, here's where it decides what expt. design
% was used, and sets the tc struct accordingly
if tc.abBlocked==1
    nf = dataTYPES(series).scanParams(scans(1)).nFrames;
    nsecs = nf*tc.TR;
    nc = dataTYPES(series).blockedAnalysisParams(scans(1)).nCycles;
    blockSecs = nsecs/(nc*2);
    tc.conditions = repmat([1 2],1,nc);
    tc.onsets = [0:blockSecs:blockSecs*nc*2] + 1;
    tc.onsets = tc.onsets(1:end-1);
    tc.condNames = {'1st Half-cycle','2nd Half-cycle'};
    tc.condColors = {[0 0 0],[0.5 0.5 0.5]};
    tc.condNums = [1 2];
    tc.parfile = '(ABAB blocked)';    
elseif tc.abBlocked==2 % cyclical, not on/off
    nf = dataTYPES(series).scanParams(scans(1)).nFrames;
    nsecs = nf*tc.TR;
    nc = dataTYPES(series).blockedAnalysisParams(scans(1)).nCycles;
    blockSecs = nsecs/(nc);
    tc.conditions = repmat([1],1,nc);
    tc.onsets = [0:blockSecs:blockSecs*nc] + 1;
    tc.onsets = tc.onsets(1:end-1);
    tc.condNames = {'Cycle Periods'};
    tc.condColors = {[0.1 0 0.66]};
    tc.condNums = [1];
    tc.parfile = '(Cyclical)';    
else
    for s = scans
        tc.parfile = dataTYPES(series).scanParams(s).parfile;
        tc = parseParfile(tc,view,scans); % adds onset,conds
        tc.condNums = unique(tc.conditions);
        nConds = length(unique(tc.conditions));
        colors = tc_colorOrder(nConds);
        for i = 1:nConds
            j = mod(i-1,length(colors))+1;
            tc.condColors{i} = colors{j};
        end
    end
end             

%%%%% add condition menu w/ conditions toggle buttons
% (callback will be as for the legend callback:
% umtoggle(gcbo);
% ras_tc;
hc(1) = uimenu('ForegroundColor','m','Label','Conditions','Separator','on','Accelerator','C');
accelChars = '1234567890-=';
for i = 1:length(tc.condNames)
    if i < length(accelChars)
        accel = accelChars(i);
    else
        accel = '';
    end
    hc(i+1) = uimenu(hc(1),'Label',tc.condNames{i},'Separator','off',...
                     'Checked','on','Accelerator',accel,...
                     'UserData',tc.condColors{i},'Callback',cbStr);
end
tc.condMenuHandles = hc;             

% add also a way to change the assigned colors for each condition
uimenu(hc(1),'Label','Assign Condition Colors...','Separator','on',...
                     'Accelerator','C','Callback','tc_assignColors;');

% add also a way to change the assigned names for each condition
uimenu(hc(1),'Label','Assign Condition Names...','Separator','on',...
                     'Callback','tc_assignNames;');
                 
 % clear axes
cla;

% set tc struct as userdata of axes
set(gcf,'UserData',tc);

return
%-------------------------------------------------------------------------


%-------------------------------------------------------------------------
function plotWholeTc(tc);
% plots the mean time course across the entire selected scans,
% designating different condition periods / half-cylces with different
% colors. Everything's specified in the tc struct.
cla;
plot(tc.data); % just to get axis bounds
AX = axis;
cla;
hold on
condNums = unique(tc.conditions);
tx = [tc.onsets length(tc.data)*tc.TR];
for i = 1:length(tx)-1
    t1 = tx(i);
    t2 = tx(i+1);
    X = [t1 t1 t2 t2];
    Y = [AX(3) AX(4) AX(4) AX(3)];
    cond = tc.conditions(i);
    ind = find(condNums==cond);
    C = tc.condColors{ind};
    patch(X,Y,C,'EdgeAlpha',0);
    if length(tc.condNames)==1
        patch(X,Y,C,'EdgeAlpha',1);
    end    
end
t = [1:length(tc.data)] .* tc.TR;
plot(t,tc.data,'LineWidth',2,'color',[1 1 0.1]); 
ylabel('% Signal');
xlabel('Time, secs');
return
%-------------------------------------------------------------------------


%-------------------------------------------------------------------------
function plotAllTrialsTc(tc);
% plots tc data, superimposing different "trials"
% on top of one another. A "trial" may be an event-related
% trial, a block, or half a cycle (ABAB design).
% The lines for different conditions are color-coded.
cla
condNums = unique(tc.conditions);
prestim = 0;
hold on
tx = [(tc.onsets./tc.TR)+1 length(tc.data)]; % onset frames
intervals = diff(tx);
selected = selectedConds(tc);
for i = 2:length(tx)-1 % for every trial specified by the onset frames
    tstart = round(max([tx(i)-prestim 1]));
    tend = round(min([tx(i+1)-1 length(tc.data)]));
    rng = tstart:tend;
    cond = tc.conditions(i);
    ind = find(condNums==cond);    
    
    if selected(ind)
        col = tc.condColors{ind};
        tw = [0:length(rng)-1 - prestim ] .* tc.TR; % time window
        Y = tc.data(rng);
        % zero time points (for align) if selected
        if ~isempty(tc.alignTrials) & all(tc.alignTrials > 0)
            offset = mean(Y(tc.alignTrials));
            Y = Y - offset;
        end        
        plot(tw,Y,'Color',col);
    end
end
xlabel('Trial time, secs');
ylabel('% Signal');
return
%-------------------------------------------------------------------------



%-------------------------------------------------------------------------
function plotMeanTrialsTc(tc);
% plots mean time courses for each condition, 
% with error bars (SEMs), coded by color.
cla
prestim = 1;
clipToEqual = 0;
condNums = unique(tc.conditions);
tx = round([(tc.onsets./tc.TR)+1 length(tc.data)]);
intervals = diff(tx);
nConds = length(unique(tc.conditions));
hold on
for i = find(selectedConds(tc))
    cond = condNums(i);
    maxInt = max(intervals(tc.conditions==cond)) + prestim;
    trials = find(tc.conditions==cond);
    nTrials = length(trials);
    subData = NaN*ones(maxInt,nTrials);
    for j = 1:nTrials
        rng = tx(trials(j))-prestim:tx(trials(j)+1)-1;
        rng = round(rng);
        rng = rng(rng>0 & rng<length(tc.data)); % clip to fit data
        subData(1:length(rng),j) = tc.data(rng);
    end
    if nTrials > 1
        subData;
        Y = nanmean(subData');
        E = nanstd(subData') ./ sqrt(nTrials-1);
    else
        Y = subData';
        E = zeros(size(Y));
    end
 
    % restrict Y and E to the minimum cond length
    if clipToEqual
        ind = ismember(tc.conditions,condNums(find(selectedConds(tc))));
        minInt = min(intervals(ind));
        Y = Y(1:minInt);
        E = E(1:minInt);
    end
    
    % zero time points (for align) if selected
    if ~isempty(tc.alignTrials) & all(tc.alignTrials > 0)
        offset = mean(Y(tc.alignTrials));
        Y = Y - offset;
    end

    tw = [(1:length(Y)) - prestim + 2] .* tc.TR + tc.onsetDelta; % time window
    ind = find(condNums==cond); 
    col = tc.condColors{ind};
    htmp = errorbar(tw,Y,E);
    set(htmp,'Color',col,'LineWidth',4);
end
xlabel('Trial time, secs');
ylabel('% Signal');
return
%-------------------------------------------------------------------------



%-------------------------------------------------------------------------
function tc = parseParfile(tc,view,scans);
% Reads in a par/prt file, and 
% performs a few (heuristic) checks on
% the onset data from a parfile compared
% to the tSeries data. For instance,
% the par file may specify time points 
% which were later cropped, etc. Also
% concatenates consecutive intervals of
% same condition into one interval.
global HOMEDIR dataTYPES mrSESSION

offset = 0; % used in concatenating onsets from parfiles

for s = scans
    tc.parfile = dataTYPES(view.curDataType).scanParams(s).parfile;

    if isempty(findstr(filesep,tc.parfile))
        parPath = fullfile(HOMEDIR,'stim','parfiles',tc.parfile);
	else
        parPath = tc.parfile;
	end
	if ~exist(parPath,'file')
        error(['Couldn''t find parfile ' parPath '.']);
	end
	[onsets,conds,condNames] = readParFile(parPath);
	
	% check for consecutive intervals
	change = [1 diff(conds)];
	change = (change ~= 0);
% 	change = ones(size(onsets)); % this disables the change check
	
	% find points contained in tc.data
	ok = (onsets < length(tc.data)*tc.TR);
	
   	tc.onsets = [tc.onsets onsets(change & ok)+offset];
	tc.conditions = [tc.conditions conds(change & ok)]; 
    offset = offset + dataTYPES(view.curDataType).scanParams(s).nFrames  * tc.TR; % for next scan
    
	% if condNames are given in parfile, read that too (possible bug for
	% many scans?)
	tc.condNums = unique(tc.conditions);
	nConds = length(tc.condNums);
	for i = 1:nConds
        ind = find(conds==tc.condNums(i));
        if isempty(condNames{ind(1)})
            tc.condNames{i} = sprintf('Condition %i',tc.condNums(i));
        else
            tc.condNames{i} = condNames{ind(1)};
        end
	end    
end

	
% another potentially useful but extraneous feature --
% auto-guess an onset delta based on junk frames for this scan
% (useful, since parfiles can specify the stimulus alone, independent
% of later processing decisions):
tc.onsetDelta = -1*mrSESSION.functionals(scans(1)).junkFirstFrames*tc.TR;

return
%-------------------------------------------------------------------------



function sel = selectedConds(tc);
% goes through the conditions menu on the tc figure,
% parsing which conditions are selected for plotting 
% and which aren't, returning a binary index vector
% of length nConds.
for i = 2:length(tc.condMenuHandles)
    state = get(tc.condMenuHandles(i),'Checked');
    sel(i-1) = isequal(state,'on');
end
return


function co = tc_colorOrder(nConds);
% function to return a set of colors that is
% nice for plotting given the current # of different conditions
co = {};
switch nConds
    case {2,3,4},
        co = {[1 0 0],[0 0 1],[0 0 0]};
    case {5,6},
        co = {[0 0 1],[1 0 0],[0.2 0.5 0.2],...
              [0.5 0 0.5],[0 0.5 0.5],[0.5 0.5 0]};
    case {7,8,9},
        co = {[0 0 0],[0 0 1],[1 0 0],...
              [0 0.8 0],[.7 0 .7],[0 0 .7],... 
              [.7 0 0],[0 .5 0],[.4 0 .4]};
    case{12,13},
%          co = {[0 0 1],[0 0 0.7],[0 0 0.33],[0.33 0 0.33],...
%                [1 0 0],[0.7 0 0],[0.33 0 0],[0.33 0.33 0],...
%                [0.2 0.5 0.2],[0 0.7 0],[0 0.33 0],[0 0.33 0.33]};
        co = {[0 0 0],[0 0 1],[0 0 0.8],[0 0 0.6],[0 0.3 0.8],...
                  [1 0 0],[0.8 0 0],[0.6 0 0],[0.8 0 0.3],...
                  [0 1 0],[0 0.8 0],[0 0.6 0],[0.3 0.8 0]};

    otherwise,
        co = {[0 0 0],[0 0 1],[0 0 0.8],[0 0 0.6],[0 0.3 0.8],...
                  [1 0 0],[0.8 0 0],[0.6 0 0],[0.8 0 0.3],...
                  [0 1 0],[0 0.8 0],[0 0.6 0],[0.3 0.8 0]};
          while length(co) < nConds
              co = [co co]
          end
end
return
            