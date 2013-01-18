function newCoords = canOri2CurOri(view, coords, ori)
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
    if ismember(view.viewType, {'Volume' 'Gray'})
        ori = getCurSliceOri(view); 
    else
        ori = 1;
    end
end

newCoords = [];
if ~isempty(coords)
    if strcmp(view.viewType,'Volume') | strcmp(view.viewType,'Gray')
        dims = viewSize(view);
        
        % allow for the L/R flip option, which lets you
        % view the anatomy in radiological units (to match the
        % GE software conventions)
        if checkfields(view, 'ui', 'flipLR') & view.ui.flipLR==1
            coords(3,:) = dims(3) - coords(3,:);
        end
        
        switch ori
            case 1, % axial slice
                newCoords = coords([2 3 1],:);
                if isfield(view.ui,'flipLR') & view.ui.flipLR==1
                    newCoords(2,:) = dims(3) - newCoords(2,:);
                end
            case 2, % coronal slice
                newCoords = coords([1 3 2],:);
                if isfield(view.ui,'flipLR') & view.ui.flipLR==1
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
