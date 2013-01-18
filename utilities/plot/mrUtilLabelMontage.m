function mrUtilLabelMontage(labels, colsRowsXY, figNum, axisNum)
%
% mrUtilLabelMontage(labels, colsRowsXY, figNum, axisNum)
%
% Adds a grid of text labels to the specified fig/axis.
%
% labels is a cell-array of stings (length <= prod(colsRows)
% colsRowsXY is a 1x4 specifying the grid as 
% [numAcross numDown pixAcross pixDown]
%
% HISTORY:
% 2007.01.11 RFD: wrote it, pulling code from makeMontage3.

labelNum = 0;
  
numX = colsRowsXY(3)./colsRowsXY(1);
numY = colsRowsXY(4)./colsRowsXY(2);
if(~isempty(labels))
  if(isnumeric(labels)) labels=cellstr(num2str(labels(:),'Z = %0.0f')); end
  for(jj=0:colsRowsXY(2)-1)
    for(ii=0:colsRowsXY(1)-1)    
      labelNum = labelNum+1;
      if(labelNum>length(labels))
	break;
      end
      yoff = 20;
      text(ii*numX+3+1,jj*numY+yoff+1, labels{labelNum}, 'FontName','Helvetica','FontSize',10,'Color',[.3 .3 .3]);
      text(ii*numX+3,jj*numY+yoff, labels{labelNum}, 'FontName','Helvetica','FontSize',10,'Color',[.9 .9 .9]);
    end
  end
end
return;
