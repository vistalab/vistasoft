function ok=checkScans(view,scanList)
%
% Check that all scans in scanList have the same slices, numFrames, cropSizes
for iscan = 2:length(scanList)
    if find(sliceList(view,scanList(1)) ~= sliceList(view,scanList(iscan)))
        mrErrorDlg('Can not average these scans; they have different slices.');
    end
    if (numFrames(view,scanList(1)) ~= numFrames(view,scanList(iscan)))
        mrErrorDlg('Can not average these scans; they have different numFrames.');
    end
    if find(sliceDims(view,scanList(1)) ~= sliceDims(view,scanList(iscan)))
        mrErrorDlg('Can not average these scans; they have different cropSizes.');
    end
end
return;