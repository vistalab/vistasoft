function dtiH = dtiRemoveBackground(dtiH,bgNum)
%Remove a background image from the dti handle
%
%  dtiH = dtiRemoveBackground(dtiH,[bgNum=current])
%
% In addition to removing the background image data (normally to save
% space), related overlays and strings are adjusted.
%
% (c) Stanford VISTA Team, 2011

if notDefined('bgNum'), bgNum = dtiGet(dtiH,'curbgnum'); end

% Remove it
dtiH.bg(bgNum) = [];

% Adjust the overlay
ovNum = dtiGet(dtiH,'cur overlay num');
if(ovNum>=bgNum && ovNum>1) 
    dtiH = dtiSet(dtiH,'curoverlaynum',ovNum-1); 
end

if(bgNum>1), bgNum = bgNum-1; end
dtiH = dtiSet(dtiH,'curbgnum',bgNum);

str = get(dtiH.popupBackground, 'String');
str = str([1:bgNum-1,bgNum+1:length(str)]);
set(dtiH.popupBackground, 'String', str);
set(dtiH.popupOverlay, 'String', str);

return