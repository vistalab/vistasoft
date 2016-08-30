function vw = makeAnnotationString(vw)
%
% function vw = makeAnnotationString(vw)
%
% djh, 3/2001
% ras, 11/2004: made it a uicontrol.
pos = [.15 .95 .5 .04];

bgcolor = get(gcf,'Color');

h = uicontrol('Style','text',...
              'Units','Normalized',...
              'Position',pos,...
              'FontName','Helvetica',...
              'FontSize',10,...
              'FontWeight','bold',...
              'BackgroundColor',bgcolor,...
              'ForegroundColor',[.1 0 0],...
              'HorizontalAlignment','center',...
              'String','');

vw.ui.annotationHandle = h;

return

% OLD:
% 
% set(INPLANE{1}.ui.annotationHandle,'string','mumble');% 
% set(VOLUME{1}.ui.annotationHandle,'string','mumble');% 
% set(FLAT{1}.ui.annotationHandle,'string','mumble');
% annotationPos = [0.5 0.95 0.4 0.04];
% annotationAxis = subplot('position',annotationPos);
% axis off;
% text(0,0,'','FontSize',12,'HorizontalAlignment','center',...
%      'FontWeight','bold');
% annotationHandle = get(annotationAxis,'Children');
% vw.ui.annotationHandle = annotationHandle;
% 
% % Return the current axes to the main image
% set(gcf,'CurrentAxes',vw.ui.mainAxisHandle);
