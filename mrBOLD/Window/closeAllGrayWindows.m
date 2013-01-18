function closeAllGrayWindows
%
% function closeAllGrayWindows()
%
% Loop through VOLUME, closing all the gray windows
%
% Called by installSegmentation
%
% djh, 2/14/2001

mrGlobals

disp('Closing gray windows');

for s = 1:length(VOLUME)
    if checkfields(VOLUME{s}, 'ui', 'windowHandle')
        close(VOLUME{s}.ui.windowHandle);
    end
end

return;