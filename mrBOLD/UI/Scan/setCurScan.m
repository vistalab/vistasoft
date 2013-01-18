function view = setCurScan(view,scanNum)
%
% view = setCurScan(view,scanNum)
%
% AUTHOR: Wandell
%    Sets UI parameter of slider to scanNum
%   If the view is hidden, the UI field is absent and nothing is done.  I
%   wonder if we should return an error (or hidden) flag?
%
% ras, 05/05: added a 'curScan' field -- it'd be better to go
% back and add this at view creation, but this should produce a
% workable alternative for hidden views.
view.curScan = scanNum;
% If we have a GUI open, update it as well:
if checkfields(view, 'ui', 'scan'), 
    setSlider(view,view.ui.scan,scanNum,0);
    
%     % Now update: we need to update underlay and overlay
%     % (but not ROIs)
%     switch view.viewType
%         case 'Inplane',
%             view = inplaneUnderlay(view, view.ui.underlayHandle);
%             view = inplaneOverlay(view, view.ui.overlayHandle);
%         case 'Volume'
%             view = volumeUnderlay(view, view.ui.underlayHandle);
%             view = volumeOverlay(view, view.ui.overlayHandle);
%     end
end
return;
