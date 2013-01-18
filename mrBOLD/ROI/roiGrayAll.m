function roi = roiGrayAll(seg, mr, roi);
%
% roi = roiGrayAll(seg, [mr], [roi]);
%
% Create an ROI containing all gray matter nodes for a 
% segmentation, or append these nodes to an existing ROI.
%
% seg: segmentation object. See segCreate.
%
% roi: if an ROI structure is passed as a second argument,
%      will append the gray coords to the roi, rather than
%      creating a new one.
%
% ras, 01/2007.
if notDefined('seg'), error('Need a segmentation.'); end
if notDefined('roi'), roi = roiCreate('I|P|R');      end
if notDefined('mr'),  mr = [];                       end

if isempty(seg.nodes)
    [seg.nodes seg.edges] = segGet(seg, 'gray');
end

roi.coords = combineCoords(roi.coords, seg.nodes([2 1 3],:), 'union');
roi.name = sprintf('Gray Matter %s', seg.name);

if ~isempty(mr)
    roi = roiCheckCoords(roi, mr);
end

return
