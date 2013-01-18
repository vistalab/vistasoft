function dummy=generateFlatMapReport(view,scansToPlot,plotWindow)
%
% dummy=generateFlatMapReport(view,scansToPlot)
%
% Author: ARW
%
% Loop over requested scans in the current datatype, calling
% 'publishFigure' for each hemisphere and placing the resulting 
% images into two columns in a multi-part figure
% 
% Example:
%    dummy=generateFlatMapReport(FLAT{1},[1:4]);
%

if(~exist('view','var'))
   view=getSelectedFlat;
   
end
if(~exist('scansToPlot','var'))
    disp('Plotting all scans');
    scansToPlot=1:numScans(view);
end
if(~exist('plotWindow','var'))
    plotWindow=100;

end
totalSubPlots=2*length(scansToPlot);
figure(plotWindow);
thisPlot=1;
plotHeight=0.4; % make the height of each plot 0.4 in normalized coords,
                % leaving room for some titles
plotWidth=1/(length(scansToPlot)+1);
fullPlotWidth=1/(length(scansToPlot));
leftMargin=0.01;
for thisScan=1:length(scansToPlot)
%setCurScan(view,scansToPlot(thisScan));
view=viewset(view,'curscan',scansToPlot(thisScan));

    for thisHemi=1:2
        % Set the current scan and hemisphere in the flat view. 
        % We assume that things like ROIs, rotations, coherence levels,
        % colormaps etc are already done...
        %setCurSlice(view,thisHemi);
        view=viewset(view,'curslice',thisHemi);
        
        [a,i]=publishFigure(view);
        figure(99);
        thisLower=(((2-thisHemi)*0.5))+0.05;
        thisLeft=(thisScan-1)*fullPlotWidth+leftMargin;
        
        subplot('position',[thisLeft,thisLower,plotWidth,0.4]); 
        image(i);
        
        axis off;axis image;
        iStr=sprintf('Scan %d, hemi %d',scansToPlot(thisScan),thisHemi);
        title(iStr);
      
        thisPlot=thisPlot+1;
    end
end
dummy=plotWindow;
