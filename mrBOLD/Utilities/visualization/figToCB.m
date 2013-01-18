function figToCB(figNum)
% function figToCB(figNum)
% Copies figure to (Windows) clipboard. Only works under windows.
% Defaults to figNum=4 as this is often the 'publishFigure' window
if (strcmp(computer,'PCWIN'))

    if (~exist('figNum','var'))
        figNum=4;
    end

    global FLAT % make FLAT global in code
    tmpFLAT = FLAT; % pass into temporary variable
    % do the exporting using using 'figure' option
    figNum=['-f',int2str(figNum)];

    print(figNum,'-dmeta')
    % now pass tmpFLAT back into FLAT
    FLAT = tmpFLAT;
else
    disp('Function (figToCB) only works under windows');
end

return