function vw = makeROIfromIndices(vw,ind,name,select,color,comments)
% makeROIfromIndices - make ROI from indices
%
% vw = makeROIfromIndices(vw,ind)
%
% 2010 SD & WZ: wrote it.

if notDefined('vw'),        error('Need view struct');   end
if notDefined('ind'),       error('Need indices');       end
if notDefined('name'),      name    = [];           end
if notDefined('select'),    select  = true;         end
if notDefined('color'),     color   = [];           end
if notDefined('comments'),  comments= [];           end

% define coordinates from indices
coords = viewGet(vw,'coords');
coords = coords(:,logical(ind));

% make new ROI
vw = newROI(vw,name,select,color,coords, comments);

return