function rx = rxOpenTSeriesFig(rx);
% rx = rxOpenTSeriesFig(rx);
%
% Open a figure to navigate across 
% the currently-loaded tSeries.
%
% ras 03/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ~isfield(rx,'tSeries')
    msg = 'You must load a tSeries first! See File | Load | mrVista tSeries.';
    myWarnDlg(msg);
    return
end

javaFigs=feature('javafigures');
feature('javafigures', 0);

mrGlobals;
loadSession;

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
    
feature('javafigures',javaFigs);


return