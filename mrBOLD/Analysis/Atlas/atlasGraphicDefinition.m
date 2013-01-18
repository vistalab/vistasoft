function [locs,roiName,view] = atlasGraphicDefinition(method,view)
%
%  [locs,roiName,view] = atlasGraphicDefinition(method,[view])
%
%Author:  Wandell
%Purpose:
%  Interface routine to graphical methods for specifying the atlas.
%  The different methods return different entries in the locs structure.
%  The calling routine must unpack these.
%
% Example:
%
%    [locs,FLAT{1}] = atlasGraphicDefinition('quadrilateral',FLAT{1});
%    FLAT{1} = refreshView(FLAT{1},0);
%
%    locs = atlasGraphicDefinition('default');
%

switch lower(method)
    case {'default','twolines'}
        w = .5;
        txt = [];
        
        newText = 'Define the central area (usually V1) by drawing two lines.\n';  txt = addText(txt,newText);
        newText = 'to define a peripheral point along one boundary. Repeat\n';     txt = addText(txt,newText);
        newText = 'to define the other boundary (again- fovea first).';            txt = addText(txt,newText);
        msgHndl = mrMessage(txt);
        
        [x1,y1] = getline;
        x1 = x1(1:2); y1 = y1(1:2);
        lineHandle1 = line([x1-w,x1-w,x1+w,x1+w,x1-w],[y1-w,y1+w,y1+w,y1-w,y1-w],'Color','w');
        
        [x2,y2] = getline;
        x2 = x2(1:2); y2 = y2(1:2);
        lineHandle2 = line([x2-w,x2-w,x2+w,x2+w,x2-w],[y2-w,y2+w,y2+w,y2-w,y2-w],'Color','w');
        
        locs.x1 = x1; locs.x2 = x2; locs.y1 = y1; locs.y2 = y2;
        delete(lineHandle1); delete(lineHandle2); delete(msgHndl);
        
    case 'quadrilateral'
        
        found = roiExistName(view,'Quad',0)
        if found == 0, num = 1; else num = length(found)+1; end
        roiName = sprintf('Quad-%.0f',num);
        view = newROI(view,roiName);
        [view, corners] = addROIquadrilateral(view);

        locs.corners = corners;
        
    otherwise
        error('unknown method');
end



return;