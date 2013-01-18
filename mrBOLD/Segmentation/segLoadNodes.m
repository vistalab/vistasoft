function seg = segLoadNodes(seg);
% Ensure that gray node data are loaded in a segmentation.
%
% seg = segLoadNodes(seg);
%
% This function ensures the fields seg.nodes and seg.edges contain
% the loaded gray node / edge information specified in the seg.gray
% file.
%
% ras, 12/2006;
if isempty(seg.nodes) | isempty(seg.edges)
    if exist(seg.gray, 'file')
        [seg.nodes seg.edges] = readGrayGraph(seg.gray);
    else
        % warn, but don't crash
        warning( sprintf('Could not find gray file %s.', seg.gray) );
    end
end

return
