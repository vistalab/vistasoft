function ok=checkScans(vw,scanList)
%
% Check that all scans in scanList have the same slices, numFrames, cropSizes
for iscan = 2:length(scanList)
    if find(sliceList(vw,scanList(1)) ~= sliceList(vw,scanList(iscan)))
        mrErrorDlg('Can not average these scans; they have different slices.');
    end
    if (numFrames(vw,scanList(1)) ~= numFrames(vw,scanList(iscan)))
        mrErrorDlg('Can not average these scans; they have different numFrames.');
    end
    if find(viewGet(vw,'slice dims', scanList(1)) ~= viewGet(vw,'slice dims', scanList(iscan)))
        mrErrorDlg('Can not average these scans; they have different cropSizes.');
    end
end

ok = true;

return;