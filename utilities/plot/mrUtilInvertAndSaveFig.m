function mrUtilInvertAndSaveFig(fn,trans)
%
% mrUtilInvertAndSaveFig(fileName,[trans=true])
%
%
%

if(~exist('trans','var')|isempty(trans))
    trans = true;
end

tcol = [1 2 3];
fc = [1 1 1];
if(trans)
    set(gcf,'InvertHardCopy','off','color',tcol/255); 
else
    set(gcf,'InvertHardCopy','off','color',[0 0 0]); 
end
set(gca,'ycolor',fc,'xcolor',fc,'color', fc);
set(get(gca,'XLabel'),'color',fc);
mrUtilPrintFigure([fn '.eps']);
%print2im([fn '.png'], gcf, true, 120);
unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -out ' fn '.png ' fn '.eps']);
if(trans)
    [im,cm] = imread([fn '.png']);
    transInd = cm(:,1)==tcol(1)/255 & cm(:,2)==tcol(2)/255 & cm(:,3)==tcol(3)/255;
    imwrite(im,cm,[fn '.png'],'Transparency',double(~transInd));
end

return