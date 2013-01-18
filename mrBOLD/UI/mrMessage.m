function msgHdl = mrMessage(str,HorizontalAlignment,figPos,fontSize)
%
%   msgHdl = mrMessage(str,[HorizontalAlignment],[figPos],[fontSize])
%
% Author: BW
% Purpose:
%   Display an information message to help the user
%   You can set the text alignment ('center' is default).
%   You can set the figure position (normalized coordinates.  Default is
%   upper right of the screen and fairly small: [0.8, 0.8, 0.16, 0.1];
%
% Example:
%
%   msgHndl = mrMessage('Help me','left');
if notDefined('fontSize'), fontSize = 12; end
if notDefined('HorizontalAlignment'), HorizontalAlignment = 'center'; end
if notDefined('figPos'), 
	% try to come up with a logical default figure position, based on the
	% current figure position
	if isempty( get(0, 'CurrentFigure') )  % no figures open
		figPos = [0.8   0.8    0.16    0.1]; 		
	else
		tmpUnits = get(gcf, 'Units');
		set(gcf, 'Units', 'norm');
		parentPos = get(gcf, 'Position');
		set(gcf, 'Units', tmpUnits);
		
		% figure out width, height for this figure
		width  = .16;
		height = .1 * ceil( length(str(:)) / 40 );
		
		% first try putting the message to the right of the figure
		startX = parentPos(1) + parentPos(3);
		startY = parentPos(2) + parentPos(4) - height;
		figPos = [startX, startY, width, height];
		
		% check if this would go past the screen bounds; if so, set it to
		% the left
		if figPos(1) + figPos(3) > 1 | figPos(2) + figPos(4) > 1
			startX = parentPos(1) - width;
			figPos = [startX, startY, width, height];
		end
	end
end

if isa(figPos,'char')
    switch lower(figPos)
        case {'middle','center'}
            figPos = [0.4   0.4    0.16    0.1]; 
        case {'upperright','ur'}
            figPos = [0.8   0.8    0.16    0.1]; 
        case {'upperleft','ul'}
            figPos = [0.8   0.1    0.16    0.1]; 
        case {'uppercenter','uc'}
            figPos = [0.8   0.4    0.16    0.1]; 
    end
end

curFig = gcf;
msgHdl = mrMessageBox;
set(msgHdl,'position',figPos);

guiH = guihandles(msgHdl);
mrMessageBox('setMessage',msgHdl,[],guiH,str);
set(guiH.txtMessage,'HorizontalAlignment',HorizontalAlignment,...
                    'FontSize',fontSize);

figure(curFig);

return;
