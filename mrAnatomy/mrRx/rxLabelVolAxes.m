function rxLabelVolAxes(rx,ori);
%
% Label the anatomical axes on the Rx
% figure, appropriate to the current 
% orientation.
%
% 
% ras 03/05.
if ~exist('rx', 'var') | isempty(rx)
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

switch ori
    case 1, % axial
        title('Left \leftrightarrow Right');
        ylabel('Pos \leftrightarrow Ant');
    case 2, % coronal
        title('Left \leftrightarrow Right');
        ylabel('Inf \leftrightarrow Sup');
    case 3, % sagittal
        title('Ant \leftrightarrow Pos');
        ylabel('Inf \leftrightarrow Sup');
    case 4, % orthogonal
        % ???
end

return
        