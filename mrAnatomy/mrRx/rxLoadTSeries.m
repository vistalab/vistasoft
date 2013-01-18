function rx = rxLoadTSeries(rx,mrView,dt,scans);
%
% rx = rxLoadTSeries([rx,mrView,dt,scans]);
%
% Loads tSeries from the selected view(session), data
% type, and scans and adds to the tSeries field of the
% rx struct. Also ensures (checks and opens if it doesn't
% exist) that a GUI exists to navigate across frames of the
% tSeries. 
%
% The tSeries are loaded as 4D (rows x cols x slices x time)
% uint16 arrays, so this can be fairly memory intensive. 
% 
% ras 03/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('mrView') 
    % initiate a hidden one -- 
    % hope you're not running mrVista
    % in the background
    mrGlobals;
    loadSession;
    HOMEDIR = pwd;
    mrView = initHiddenInplane;
end

if ieNotDefined('dt')
    % put up a dialog
    [dt, ok] = listdlg('PromptString','Load tSeries from which data type?',...
                        'ListSize',[400 600],...
                        'ListString',{dataTYPES.name},...
                        'InitialValue',1 ,...
                        'SelectionMode','single',...
                        'OKString','OK');
                            
    % exit gracefully if canceled                
	if ~ok  return;  end
end

if ieNotDefined('scans')
    % put up a dialog
    scanNames = {dataTYPES(dt).scanParams.annotation};
    for i = 1:length(scanNames)
        scanNames{i} = sprintf('Scan %i: %s',i,scanNames{i});
    end
    [scans, ok] = listdlg('PromptString','Load tSeries from which data type?',...
                        'ListSize',[400 600],...
                        'ListString',scanNames,...
                        'InitialValue',1 ,...
                        'SelectionMode','multiple',...
                        'OKString','OK');
                            
    % exit gracefully if canceled                
	if ~ok  return;  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Part (much tinier than the dressing! :) %
% Load the tSeries, store as uint16 to save    %
% memory:                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rx.tSeries = [];
mrView = selectDataType(mrView,dt);
for s = scans
    rx.tSeries = cat(4,rx.tSeries,uint16(tSeries4D(mrView,s,1)));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check for Frame Navigation Figure            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(rx.ui,'tSeriesFig') | ~ishandle(rx.ui.tSeriesFig)
	% make a tSeries navigation figure
	rx.ui.tSeriesFig = figure('Color','w',...
                              'Units','Normalized',...
                              'Position',[.35 .1 .3 .12],...
                              'Name','Navigate tSeries Frames');
                          
	nFrames = size(rx.tSeries,4);
	
	labelTxt = sprintf('Session %s, Data Type %s \n Scans: %s',...
                        mrSESSION.sessionCode,dataTYPES(dt).name,num2str(scans));
	rx.ui.tSeriesLabel = uicontrol('Style','text','Units','Normalized',...
                                   'Position',[.1 .7 .8 .3],'String',labelTxt,...
                                   'BackgroundColor',get(gcf,'Color'),...
                                   'FontWeight','bold','FontAngle','italic',...
                                   'FontSize',10);
	
	rx.ui.tSeriesVol = rxMakeSlider('Current (target) frame:',[1 nFrames],[.2 .4 .6 .2],1,1);
	
	rx.ui.tSeriesRef = rxMakeSlider('Reference (base) frame:',[1 nFrames],[.2 .1 .6 .2],1,1);                              
	
	%%%%%%%%%%%%%%%%%
	% set callbacks %
	%%%%%%%%%%%%%%%%%
	% Slider callback string (vol)
	cb = 'slider = get(gcbo,''UserData'');';
	cb = sprintf('%s \n val = rxSetSlider(slider);',cb);
	cb = sprintf('%s \n rxSet([],''targetframe'',val);',cb);
	set(rx.ui.tSeriesVol.sliderHandle,'Callback',cb);
	
	% Edit field callback string (vol): 
	cb = ['val = str2num(get(gcbo,''String'')); ' cb];
	set(rx.ui.tSeriesVol.editHandle,'Callback',cb);
	
	% Slider callback string (ref)
	cb = 'slider = get(gcbo,''UserData'');';
	cb = sprintf('%s \n val = rxSetSlider(slider);',cb);
	cb = sprintf('%s \n rxSet([],''baseframe'',val);',cb);
	set(rx.ui.tSeriesRef.sliderHandle,'Callback',cb);
	
	% Edit field callback string (ref): 
	cb = ['val = str2num(get(gcbo,''String'')); ' cb];
	set(rx.ui.tSeriesRef.editHandle,'Callback',cb);
end

rxRefresh(rx);

return