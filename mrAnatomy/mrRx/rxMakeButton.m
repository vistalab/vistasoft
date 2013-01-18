function button = rxMakeButton(name,pos,direc);
%  button = rxMakeButton(name,pos,[direc]);
%
% Make a radio button for mrRx, with
% the specified name and position. 
%
% If a cell of names is specified,
% will make a vertical set of radio
% buttons, one for each entry, filling
% up the box specified by pos.
%
% direc: direction flag--only of relevance
% for multiple buttons. If 0 [default],
% stack buttons vertically; otherwise, place
% horizontally.
% 
% Returns a vector of handles to the buttons.
%
% ras 02/05.
if ieNotDefined('direc')
    direc = 0;
end

if iscell(name)
    % recursively make buttons
    nButtons = length(name);
    for i = 1:nButtons
        subpos = pos;
        if direc==0
            % stack vertically
            subpos(2) = pos(2) + (i-1)*pos(4)/nButtons;
            subpos(4) = pos(4)/nButtons;
        else
            % place horizontally
            subpos(1) = pos(1) + (i-1)*pos(3)/nButtons;
            subpos(3) = pos(3)/nButtons;
        end
        button(i) = rxMakeButton(name{i},subpos,direc);
        
        % new callback:
        cbstr = sprintf('selectButton(get(gcbo,''UserData''),%i);',i);
        cbstr = sprintf('%s \n rxRefresh;',cbstr);
        set(button(i),'Callback',cbstr);
    end
    set(button,'UserData',button,'Style','radiobutton');
    return
end

button = uicontrol('Style','checkbox',...
                   'Units','Normalized',...
                   'Position',pos,...
                   'String',name,...
                   'Min',0,'Max',1,...
                   'Value',0,...
                   'BackgroundColor',get(gcf,'Color'),...
                   'ForegroundColor',[.3 .3 .3],...
                   'Callback','rxRefresh;');
               
return

