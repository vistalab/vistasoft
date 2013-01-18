function view = adjustMRImage(view);
% view = adjustMRImage(view);
%
% A button-down function for the MR image
% on a view window. This is set to act when
% the user clicks on the image, and does 
% different things depending upon which button
% was pressed. It does the following:
%
% Left click -> 
% Middle click -> Adjust brightness, contrast
% Right click -> 
% Double click -> 
%
% ras 11/04
fig = view.ui.windowHandle;
axs = gcbo;

% figure out which button was pressed
button = get(fig, 'SelectionType');
if strcmp(button,'open')   % double click
   button = 4;
elseif strcmp(button,'normal')  % left 
   button = 1;
elseif strcmp(button,'extend')  % middle / shift-left
   button = 2;
elseif strcmp(button,'alt')     % right / ctrl-left
   button = 3;
else
    % weird selection -- just quit
    return
end

switch button
    case 1,
%         % a test
%         buttonisdown = 1;
%         p1 = get(gca,'CurrentPoint');
%         ax = axis;
%         tic
%         while buttonisdown
%             p2 = get(gca,'CurrentPoint');
%             dx = p2(1,1) - p1(1,1);
%             dy = p2(1,2) - p1(1,2);
%             view = adjBrightness(view,dx/ax(4));
%             tmp = get(gcf,'SelectionType');
%             buttonisdown = (toc<1);
%             p1 = p2;
%         end
    case 2,
        % adjust brightness/contrast of image, while button down
        view = adjBrightness(view,0.1);
    case 3,
        % adjust brightness/contrast of image, while button down
        view = adjBrightness(view,-0.1);
    case 4,
        if isequal(view.viewType,'Flat')
            % set params for thresholding curvature
            
        else
            % a crude manual setting of brightness
            p1 = get(gca,'CurrentPoint');
            ax = axis;
            delta = 2*p1(1,2)/ax(4) - 1;
            view = adjBrightness(view,delta);
        end
end

view = refreshScreen(view);

% reset the call to this functions
cbstr = sprintf('%s = adjustMRImage(%s);',view.name,view.name);
set(gca,'ButtonDownFcn',cbstr);
tmp = get(gca,'Children');
set(tmp,'ButtonDownFcn',cbstr);

return
% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function view = adjBrightness(view,delta);
% alter the brightness of the image
cmap = view.ui.anatMode.cmap;
cmap = brighten(cmap,delta);
numGrays = view.ui.mapMode.numGrays;
view.ui.anatMode.cmap = cmap;
view.ui.ampMode.cmap(1:numGrays,:) = cmap;
view.ui.phMode.cmap(1:numGrays,:) = cmap;
view.ui.coMode.cmap(1:numGrays,:) = cmap;
view.ui.mapMode.cmap(1:numGrays,:) = cmap;
return
% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function adjContrast(delta);
% alter the contrast of the image
return
