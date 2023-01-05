function dSize = fontChangeSize(fig,dSize)
%Change the font size 
%
%       dSize = fontChangeSize(fig,[changeSize])
%
%  The font sizes of all the text items in the fig is changed.
%
%  The change size (dSize) is limited to -12 and 12.
%  The smallest point size is limited to 6pt on windows and 10pt on
%  linux.
%  There is no upper limit on the max point size.
%
%

% Find the increase or decrease in font size
if ieNotDefined('dSize')
    dSize = ieReadNumber('Enter font size change (-6,6)',2,' %.0f');
    if isempty(dSize), return;
    else
        % Keep the change lower than 6.
        dSize = ieClip(dSize,-6,6);
        % Allow the font differential to be 10 or less
        oldVal = ieSessionGet('deltaFont'); 
        newVal = ieClip(oldVal + dSize,-12,12);
        ieSessionSet('deltaFont',newVal);
    end
end

% Get all the children of the figure.
t = allchild(fig);

% Change the text displays
tHandles = findall(t,'Style','Text');
changeFontSize(tHandles,dSize);

% Change the popupmenu font sizes.
tHandles = findall(t,'Style','popupmenu');
changeFontSize(tHandles,dSize);

% Change the popupmenu font sizes.
tHandles = findall(t,'Style','edit');
changeFontSize(tHandles,dSize);

% Change the radiobutton font sizes.
tHandles = findall(t,'Style','radiobutton');
changeFontSize(tHandles,dSize);

% Change the pushbutton font sizes.
tHandles = findall(t,'Style','pushbutton');
changeFontSize(tHandles,dSize);

return;

%----------------------------------------------
function changeFontSize(tHandles,dSize);
%
% Never let the font size get smaller than 6, but I am not sure why.
minSize = 6;

% Algorithm for changing the font size.
%
% We have a baseSize for each system.  We have a current size for the fonts.
% deltaFont, stored in Matlab preferences.  This delta defined the change from the default baseSize.
%
% We find the difference between the currentSize and the baseSize and we
% adjust the current size so that the change is equal to deltaFont.
% 
if ispc, baseSize = 6;        % Windows
elseif isunix, baseSize = 10; % Linux?
else baseSize = 8;            % Maybe apple?
end

curSize = get(tHandles,'FontSize');
if isempty(curSize), return;
else
    deltaFont = dSize;  % Total change from baseline
    if length(curSize) == 1,
        currentDelta = max(curSize - baseSize,0);
        desiredSize = baseSize + deltaFont;
        set(tHandles,'FontSize',max(desiredSize,baseSize));
    else
       currentDelta = max(curSize{1} - baseSize,0);
        for ii=1:length(curSize) 
            % These are the base sizes of each object
            desiredSize = (curSize{ii} - currentDelta) + deltaFont;
            set(tHandles(ii),'FontSize',max(desiredSize,baseSize)); 
        end
    end
end

return;