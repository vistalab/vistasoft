function newCoords = curOri2CanOri(vw, coords)
%
% newCoords = curOri2CanOri(view, coords);
%
% Convert coordinates into a 'canonical' frame
% of reference -- i.e., the first row of coords
% specifies the row for each point in the view, 
% the second row specifies column, and the third
% specifies slice.
%
% For inplanes, these coords refer to the underlying
% inplane anatomy, rather than the tSeries or maps 
% (e.g., view size rather than data size).
%
% For volume views, this refers to the vAnatomy matrix. 
% The order of points is usually: rows run from superior->inferior,
% columns from anterior->posterior, slices from left->right. So,
% if the coords are specified relative to a sagittal orientation,
% they're unchanged; but if it's an axial or coronal, they're flipped
% around.
%
% For flat views, the coords refer to the y, x, and hemisphere of 
% the unfold.
%
% djh and baw, 7/98
% comments by ras, 09/05
% ras, 02/06 -- added code to parse whether the anatomies are L/R flipped
% (radiological viewing conventions)
newCoords = [];
if ~isempty(coords)
    if strcmp(viewGet(vw,'View Type'),'Volume') || strcmp(viewGet(vw,'View Type'),'Gray')
        curSliceOri = getCurSliceOri(vw);
        switch curSliceOri
            case 1 % axial slice
                newCoords = coords([3 1 2],:);
            case 2 % coronal slice
                newCoords = coords([1 3 2],:);
            case 3 % sagittal slice
                newCoords = coords;
            otherwise
                myErrorDlg('Stupid slice orientation');
        end
        
        % also allow for the L/R flip option, which lets you 
        % view the anatomy in radiological units (to match the
        % GE software conventions)
        if checkfields(vw, 'ui', 'flipLR') && vw.ui.flipLR==1
            dims = viewGet(vw,'Size');
            newCoords(3,:) = dims(3) - newCoords(3,:);
        end
    else
        newCoords = coords;
    end
end

return