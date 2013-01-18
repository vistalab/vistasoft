function view = appendColorMenuCallbacks(view);
% adds an extra call to 'thresholdAnatMap' to each of 
% the color map callbacks, making the antaomies look
% nicer.
% ras, 2003
appendStr = sprintf('%s = resetDisplayModes(%s);',view.name,view.name);
appendStr = sprintf('%s = thresholdAnatMap(%s);',view.name,view.name);
appendStr = sprintf('%s \t view = refreshScreen(%s);',appendStr,view.name);

cmenu = findobj('Parent',view.ui.windowHandle,'Label','Color Map');

submenus = get(cmenu,'Children');

for i = 1:length(submenus)
    if isprop(submenus(i),'Callback') & ~isempty(get(submenus(i),'Callback'))
        cb = get(submenus(i),'Callback');
        
        % test if we've done this before; if so don't do it again:
        if ~isempty( strfind(cb, appendStr) )
            return
        end
        
        cb = [cb appendStr];
        set(submenus(i),'Callback',cb);
    end
    
    for j = allchild(submenus(i))'
        if isprop(j,'Callback') & ~isempty(get(j,'Callback'))
            cb = get(j,'Callback');
            cb = [cb appendStr];
            set(j,'Callback',cb);
        end
    end    
end

return
