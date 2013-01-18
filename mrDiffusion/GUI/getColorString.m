function [colorString,colorNum] = getColorString(colorCode)
%
% [colorString,colorNum] = getColorString([colorCode])
% 
% HISTORY:
%   2003.10.02 RFD (bob@white.stanford.edu) wrote it.

colorList = {'yellow','magenta','cyan','red','green','blue','white'};

if(~exist('colorCode','var') | isempty(colorCode))
    colorString = colorList;
    return;
end

if(ischar(colorCode))
    colorNum = find(strncmp(colorList,colorCode,1));
    if(isempty(colorNum))
        colorNum = []; % make it a 0x0 empty matrix.
        colorString = 'unknown';
    else
        colorString = colorList{colorNum(1)};
    end
elseif(isnumeric(colorCode))
    colorString = num2str(colorCode, ' %0.3d');
    colorNum = [];
else
    colorString = 'unknown';
    colorNum = [];
end
return;