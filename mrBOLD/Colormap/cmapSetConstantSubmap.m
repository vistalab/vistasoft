function v = cmapSetConstantSubmap(v, newColor, mapIndexRange)
%
% v = cmapSetConstantSubmap(v, [newColor], [mapIndexRange])
%
% newColor defaults to [127 127 127]
% user will be prompted to click on the cmap if mapIndexRange is not specified.
% otherwise, input mapIndexRange as the portion of colorbar within 0-1 (e.g. [0.3 0.7])
% 
% newColor = [127 127 127];
% FLAT{1} = cmapSetConstantSubmap(FLAT{1}, newColor);
% FLAT{1} = cmapSetConstantSubmap(FLAT{1}, newColor, [0,0.1]);

if(ieNotDefined('newColor'))
    newColor = repmat(viewGet(v,'curnumGrays')-1,1,3);
end
if(ieNotDefined('mapIndexRange'))
    h = mrMessage('Click twice on the colorbar to set the range to be blocked out.');
    figure(v.ui.figNum);
    [x,y] = ginput(2);
    mapIndexRange = [min(x) max(x)];
    cmapClip = viewGet(v,'curModeCmapClip');
    mapIndexRange = (mapIndexRange-cmapClip(1)) ./ (cmapClip(2)-cmapClip(1)); % bug fixed
    close(h);
elseif ischar(mapIndexRange); % if mapIndexRange is a character, prompt instead of using mouse
    cmapClip = viewGet(v,'curModeCmapClip');
    ttltxt = sprintf('Enter the start and end of crop-out region ');
    def = {num2str(cmapClip)};
    answer = inputdlg(['within [',num2str(cmapClip),']'],ttltxt,1,def);
    vals = str2num(answer{1});
    if isempty(vals) | (length(vals)==1 & vals(1)==0) 
        disp('You did not set crop region. Cancelled'); return;
    else
        mapIndexRange = vals(1:2);
        mapIndexRange = (mapIndexRange-cmapClip(1)) ./ (cmapClip(2)-cmapClip(1)); % bug fixed
    end
end

mp = viewGet(v, 'curcmap');

lowerBound = round(mapIndexRange(1)*(size(mp,2)-1))+1;
upperBound = round(mapIndexRange(2)*(size(mp,2)-1))+1;
lowerBound = max(1,lowerBound);
upperBound = min(size(mp,2), upperBound);

mp(:,lowerBound:upperBound) = repmat(newColor',1,upperBound-lowerBound+1);

v = viewSet(v, 'curcmap', mp);

return;


