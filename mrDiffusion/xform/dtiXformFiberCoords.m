function fg = dtiXformFiberCoords(fg, xform, coordspace)
%Applies the coordinate xform to all the fiber coordinates 
%
%  fg = dtiXformFiberCoords(fg, xform)
% 
% Typically fibers are stored in ACPC space.  Sometimes we want the fibers
% in image space or MNI space.  This routine efficiently transforms the
% coordinates from the space they are in the new space defined by the
% homogeneous transform (4x4) in xform.
%
% The code is optimized to transform without an expensive loop, unless it
% seems that memory is tight. In that case, it just does a (slow) loop.
%
% Example:
%  xform = dtiGet(dtiH,'acpc2img xform');
%  fgImg = dtiXformFiberCoords(fg,xform,'img');
%
%  xform = dtiGet(dtiH,'img2acpc xform');
%  fgAcpc = dtiXformFiberCoords(fg,xform,'acpc');
%
% HISTORY:
% 2005.01.25 RFD: wrote it.
% 2006.05.17 RFD: added fallback to slow, memory-efficient loop when it
% seems that space is tight.
% 2006.11.21 RFD: now allow just the fibers cell array as input, so that
% this routine is useful even when you don't have a proper 'fg' struct.
% 2009.01.11 RFD: modified to use a hybrid routine that is a good compromise
% between speed and memory usage.
%
% (c) Stanford VISTA Team

% We take either a fibergroup struct or just the 'fibers' field (a cell
% array of fibers).
if(iscell(fg))
    wasCell = true;
    tmp = fg;
    clear fg;
    fg.fibers = tmp;
else
    wasCell = false;
end

% Operate on 1000 fiber coordinates at a time?
stepSize = 1000;
n = numel(fg.fibers);
fiberLen = cellfun('size',fg.fibers,2);
for jj = 1:stepSize:n
    sInd = jj;
    eInd = min(jj+stepSize-1,n);
    
    fc = mrAnatXformCoords(xform, horzcat(fg.fibers{sInd:eInd}),0);
    
    if(~isempty(fc))
        fiberCoord = 1;
        for ii=sInd:eInd
            fg.fibers{ii} = fc(:,(fiberCoord:fiberCoord+fiberLen(ii)-1));
            fiberCoord = fiberCoord + fiberLen(ii);
        end
    end
end

% This was AR's idea, and it was a good one.  But it creates a problem
% because the fg structures have different slots so we can't store them in
% dtiH arrays.  We get an error about unmatched structures.  If the
% dtiH.fiberGroups was a cell array, we would be OK.  But it is an array of
% structs.  Sigh.
if ~notDefined('coordspace')
    fg = fgSet(fg, 'coordspace', coordspace);
else
    fg = fgSet(fg, 'coordspace', []);
end

% Put it back as you found it
if(wasCell)
    fg = fg.fibers; 
end

return;
