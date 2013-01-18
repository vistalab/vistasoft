function button = mrvButtons(name,pos,parent,cb,direc);
%  button = mrvButtons(name,pos,[parent],[cb],[direc]);
%
% Make a radio button group for mrRx, with
% the specified name and position. 
%
% If only one name is specified, makes a single
% checkbox.
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
% NOTE: There's a new matlab function UIBUTTONGROUP,
% which should probably be a better way to do this;
% but since it looked non-trivial and this code was
% already working well, I just adapted the existing code.
% Anyone who wants to update this is welcome to.
%
% ras 07/05.
if nargin<2, help(mfilename); error('Not enough args.');    end
if ~exist('direc','var') | isempty(direc), direc = 0;       end
if ~exist('parent','var') | isempty(parent), parent = gcf;  end
if ~exist('cb','var') | isempty(cb), cb = '';               end

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
        button(i) = mrvButtons(name{i},subpos,parent,'',direc);
        
        % new callback:
        buttonCb = sprintf('selectButton(get(gcbo,''UserData''),%i);',i);
        if ~isempty(cb)
            buttonCb = sprintf('%s \n %s;',buttonCb,cb);
        end
        set(button(i),'Callback',buttonCb);
    end
    set(button,'UserData',button,'Style','radiobutton');
    return
end

if isprop(parent,'Color')
    color = get(parent,'Color');
else
    color = get(parent,'BackgroundColor');
end

button = uicontrol('Style','checkbox',...
                   'Parent',parent,...
                   'Units','Normalized',...
                   'Position',pos,...
                   'String',name,...
                   'Min',0,'Max',1,...
                   'Value',0,...
                   'FontSize',10,...
                   'BackgroundColor',color,...
                   'ForegroundColor',[.3 .3 .3],...
                   'Callback',cb);
               
return
