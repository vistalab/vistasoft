function newCoords = canOri2CurOri(vw, coords, ori)
%
% newCoords = canOri2CurOri(view, coords, <ori=cur slice orientation>)
%
% swap coords around to "canonical" coordinates, meaning the I|P|R
% coordinate conventions used by mrVista 1.0 vAnatomy.dat files. (see wiki
% for details on this). Swaps around if the current orientation is not a
% sagittal slice.
%
% djh and baw, 7/98
% ras, 04/05, deals w/ radiological conventions
if notDefined('ori'), 
    if ismember(vw.viewType, {'Volume' 'Gray'})
        ori = getCurSliceOri(vw); 
    else
        ori = 1;
    end
end

newCoords = [];
if ~isempty(coords)
    if strcmp(viewGet(vw,'View Type'),'Volume') || strcmp(viewGet(vw,'View Type'),'Gray')
        dims = viewGet(vw,'Size');
        
        % allow for the L/R flip option, which lets you
        % view the anatomy in radiological units (to match the
        % GE software conventions)
        if checkfields(vw, 'ui', 'flipLR') && vw.ui.flipLR==1
            coords(3,:) = dims(3) - coords(3,:);
        end
        
        switch ori
            case 1, % axial slice
                newCoords = coords([2 3 1],:);
                if isfield(vw.ui,'flipLR') && vw.ui.flipLR==1
                    newCoords(2,:) = dims(3) - newCoords(2,:);
                end
            case 2, % coronal slice
                newCoords = coords([1 3 2],:);
                if isfield(vw.ui,'flipLR') && vw.ui.flipLR==1
                    newCoords(2,:) = dims(3) - newCoords(2,:);
                end
            case 3, % sagittal slice
                newCoords = coords;
            otherwise
                myErrorDlg('Invalid slice orientation');
        end
        
    else
        newCoords = coords;
        
    end
end

return
