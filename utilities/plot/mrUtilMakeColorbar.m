function mrUtilMakeColorbar(cmap, labels, desc, fileName, figNum, axisHandle)
% Simple utility to make and save a stand-alone colorbar.
% mrUtilMakeColorbar(cmap, labels, desc, [fileName = no file saved], [figNum=figure], [axisHandle=gca])
%
% labels can be a simple cell-array of stings. You'll get one tick mark per
% label and they will be evenly distributed along the colorbar.
% 
% If you specify a file name, the figure will be 'print'ed to that file.
% Valid file name extensions are '.tif' (300 dpi), '.png' (120 dpi), and
% '.eps'. If you don't provide an extension (eg. just specify
% '/path/to/some/file'), then both a png (good for powerpoint) and an eps
% will be saved.
%
% EXAMPLE:
% mrUtilMakeColorbar(autumn(256),{'0','0.5','1.0'},'Data','DataLegend')
%
% To change the font and line color to white:
% mrUtilMakeColorbar(autumn(256),{'0','0.5','1.0'},'Data')
% set(gcf,'InvertHardCopy','off','color','k');
% set(gca,'ycolor','w','xcolor','w','color', 'k'); 
% set(get(gca,'XLabel'),'color','w'); 
% mrUtilPrintFigure(gcf, 'DataLegend');
%
% HISTORY:
% 2005.08.20 RFD: wrote it.

fontSize = 12;
fontName = 'Helvetica';

if(~exist('desc','var'))
    desc = '';
end
if(~exist('fileName','var'))
  fileName = '';
  figName = desc;
else
  [p,f,e] = fileparts(fileName);
  figName = f;
end
if(~exist('figNum','var')||isempty(figNum))
    figNum = figure;
    set(figNum,'Name',figName);
    figExists = false;
else
    figExists = true;
end
if(~exist('axisHandle','var')||isempty(axisHandle))
    figure(figNum);
    axisHandle = gca;
else
  axes(axisHandle);
end

if(size(labels,1)>size(labels,2))
    vert = true;
else
    vert = false;
end

nColors = size(cmap,1);
nLabels = length(labels);

figure(figNum); axes(axisHandle); cla(axisHandle);
height = ceil(nColors.*0.04);
if(vert)
    image(repmat([1:nColors]', 1, height));
    axis xy;
    set(axisHandle,'ytick',linspace(1,nColors,nLabels),'xtick',[],'FontSize',fontSize,'FontName',fontName);
    set(axisHandle,'yticklabel',labels,'xticklabel',[],'YAxisLocation','right');
    sz = [70 300];
    apos = [-0.2 0.055 0.945 0.88];
else
    image(repmat([1:nColors], height, 1));
    set(axisHandle,'xtick',linspace(1,nColors,nLabels),'ytick',[],'FontSize',fontSize,'FontName',fontName);
    set(axisHandle,'xticklabel',labels,'yticklabel',[]);
    sz = [300 70];
    apos = [0.055 0.35 0.88 0.945];
end
axis equal tight on;

if(~figExists)
   pos = get(gcf,'Position');
   set(figNum,'Position',[pos(1) pos(2) sz], 'PaperPositionMode', 'auto');
   set(axisHandle,'Position',apos);
   colormap(cmap);
end
if(vert)
    ylabel(desc,'FontSize',fontSize,'FontName',fontName);
else
    xlabel(desc,'FontSize',fontSize,'FontName',fontName);
end
if(~isempty(fileName))
    [p,f,e] = fileparts(fileName);
    if(isempty(e))
      print(figNum, '-depsc', '-tiff', '-cmyk', [fileName '.eps']);
      print(figNum, '-dpng', '-r120', [fileName '.png']);
    elseif(strcmp(e,'.eps'))
        print(figNum, '-depsc', '-tiff', '-cmyk', fileName);
    elseif(strcmp(e,'.tif'))
        print(figNum, '-dtiff', '-r300', fileName);
    else
        print(figNum, '-dpng', '-r120', fileName);
    end
end
return;
