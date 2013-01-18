function mrUtilPrintFigure(fileName, figNum, res, cmykFlag)
% Simple utility to print the current figure to a file.
% 
% mrUtilPrintFigure(fileName, [figNum=gcf], [res=120], [cmykFlag=true])
%
% fileName- relative or absolute path of output file.
%
% If filename ends in '.eps', then an encapsulated postscript file will be
% written. This format is ideal for papers and posters, especially if your
% figure incluses text and/or vector elements (e.g., lines). 
%
% If fileName ends in '.png', then a PNG image will be written. This is a
% nice image format for power-point presentations.
%
% If fileName ends in anything else, then both EPS and PNG formats will be
% written. 
%
% By default, the eps and tiff formats are saved in cmyk colorspace. This
% is good for printing, but it means that your colors are changed from what
% you see on the screen. Set the cmykFlag=false to over-ride this and save
% as rgb.
%
% Matlab's rendering engine isn't great, so for publication-quality figures
% you might try saving and eps and then rendering it with Adobe
% Illustrator. Or, on linux, you can use pstoimg (usuallt distributed as
% part of the latex2html package). E.g.: 
%
%  fn = 'myFig';
%  mrUtilPrintFigure([fn '.eps']);
%  unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fn '.png ' fn '.eps']);
%
% HISTORY:
% 2006.04.19 RFD: wrote it.

if(~exist('fileName','var') || isempty(fileName))
    help(mfilename);
end
if(~exist('figNum','var') || isempty(figNum))
    figNum = gcf;
end
if(~exist('res','var') || isempty(res))
    res = 120;
end
if(~exist('cmykFlag','var') || isempty(cmykFlag))
    cmykFlag = true;
end

[p,f,e] = fileparts(fileName);
    
if(res==0&&strcmpi(e,'.png'))
    % Do a simple screen capture on the current axis
    figure(figNum);
    pause(.5);
    refresh(figNum);
    im = frame2im(getframe(gca));
    % Set background to be transparent
    bg = uint8(round(255.*get(figNum,'color')));
    alpha = (1-double(im(:,:,1)==bg(1)&im(:,:,2)==bg(2)&im(:,:,3)==bg(3)));
    alpha = imfilter(alpha,fspecial('gaussian', [5 5],1.0));
    imwrite(im, fileName, 'Alpha', uint8(round(alpha*255)));
else
    res = ['-r' num2str(res)];
    
    %set(figNum, 'PaperUnits', 'inches','PaperOrientation','portrait');
    set(figNum, 'PaperPositionMode', 'auto');
    %pgPos = get(figNum,'PaperPosition');
    %pgSize = [pgPos(3)-pgPos(1) pgPos(4)-pgPos(2)];
    %set(figNum,'PaperSize',pgSize+0.1);
    %set(figNum,'PaperPosition',[0 0 pgSize]);
    if(isempty(e))
        print(figNum, '-dpng', res, [fileName '.png']);
        if(cmykFlag)
            print(figNum, '-depsc', '-tiff', '-cmyk', '-loose', '-r300', '-painters', [fileName '.eps']);
        else
            print(figNum, '-depsc', '-tiff', '-loose', '-r300', '-painters', [fileName '.eps']);
        end
    elseif(strcmpi(e,'.eps'))
        if(cmykFlag)
            print(figNum, '-depsc', '-tiff', '-cmyk', '-loose', '-r300', '-painters', fileName);
        else
            print(figNum, '-depsc', '-tiff', '-loose', '-r300', '-painters', fileName);
        end
    elseif(strcmpi(e,'.tif')||strcmpi(e,'.tiff'))
        print(figNum, '-dtiff', res, fileName);
    else
        print(figNum, '-dpng', res, fileName);
    end
end

return;
