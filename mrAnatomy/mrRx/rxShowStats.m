function rx = rxShowStats(rx,flag);
%
% rx = rxShowStats([rx],flag);
%
% mrRx:
% Show or Hide the text controls
% for the statistics of comparing
% the volume and reference images/vols.
%
% fig: figure to add/remove fields from.
%
% flag: if 1, add fields; if 0, remove.
%
%
% 03/05 ras.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end


if flag==1
    % move the axes over to make room
    set(rx.ui.compareAxes,'Position',[0.05 .25 .9 .7]);
    
    % show/create fields
    if isfield(rx.ui,'compareStats') & ishandle(rx.ui.compareStats.corrcoefVal)

        % show
        fields = fieldnames(rx.ui.compareStats);
        for i = 1:length(fields)
            set(rx.ui.compareStats.(fields{i}),'Visible','on');
        end
    else
        %%%%% create %%%%%
      
        % create text for corr coefficient (R)
        h = uicontrol('Style','text',...
                      'Units','Normalized',...
                      'Position',[0 .16 .25 .05],...
                      'String','Correlation [R]:',...
                      'FontWeight','bold',...
                      'FontAngle','italic',...
                      'HorizontalAlignment','left',...
                      'BackgroundColor',get(gcf,'Color'),...
                      'ForegroundColor',[0 .4 0]);
        rx.ui.compareStats.corrcoefLabel = h;
        h = uicontrol('Style','text',...
                      'Units','Normalized',...
                      'Position',[.25 .16 .2 .05],...
                      'String','(N/A)',...
                      'HorizontalAlignment','left',...
                      'BackgroundColor',get(gcf,'Color'),...
                      'ForegroundColor',[0 0 0]);
        rx.ui.compareStats.corrcoefVal = h;
        
        
        % create text for root mean square error      
        h = uicontrol('Style','text',...
                      'Units','Normalized',...
                      'Position',[0 .1 .25 .05],...
                      'String','R.M.S. Error:',...
                      'FontWeight','bold',...
                      'FontAngle','italic',...
                      'HorizontalAlignment','left',...
                      'BackgroundColor',get(gcf,'Color'),...
                      'ForegroundColor',[.5 0 0]);
        rx.ui.compareStats.rmseLabel = h;
        h = uicontrol('Style','text',...
                      'Units','Normalized',...
                      'Position',[.25 .1 .2 .05],...
                      'String','(N/A)',...
                      'HorizontalAlignment','left',...
                      'BackgroundColor',get(gcf,'Color'),...
                      'ForegroundColor',[0 0 0]);
        rx.ui.compareStats.rmseVal = h;
    end
else
    % hide 'em
    fields = fieldnames(rx.ui.compareStats);
    for i = 1:length(fields)
        set(rx.ui.compareStats.(fields{i}),'Visible','off');
    end
    
    % restore axes to full size
	set(rx.ui.compareAxes,'Position',[0.05 .1 .9 .85]);
end

if ishandle(rx.ui.controlFig)
    set(rx.ui.controlFig,'UserData',rx);
end

rxRefresh(rx);

return