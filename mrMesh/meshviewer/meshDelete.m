function vw = meshDelete(vw, meshNum)
% 
%   vw = meshDelete(vw, meshNum);
%
%Author: RFD
%   Deletes specified meshes from the mesh file.  
%   If meshNum = inf, all meshes are deleted.
%
% 2004.01.12 BW  Added viewSet/viewGet, removed old file management
% comments.  Renamed from DeleteMesh.
% 
% Moved most of the function into viewSet.

if ieNotDefined('meshNum')
    meshNames = viewGet(vw,'meshnames');
	
	if length(meshNames) > 1
		[meshNum,ok] = listdlg('PromptString', 'Select meshes to delete:', ...
			'SelectionMode', 'multiple', ...
			'ListString', meshNames);
		if(ok~=1 || isempty(meshNum))
			return;
		end
		
	elseif isempty(meshNames)
		return
		
	elseif length(meshNames)==1
		% only one mesh...
		meshNum = 1;
		
	end
end

if isinf(meshNum),     % Delete them all
    meshNum = 1:viewGet(vw,'numberofmeshes');
end
vw = viewSet(vw,'deleteMesh',meshNum);

return;