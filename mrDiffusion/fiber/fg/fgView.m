function fgView(dtiH, fg, meshID)
% Display the fiber-group in a mrMesh window controlled by dtiH. 
% 
% fgView(dtiH, fg, meshID)
%
% Parameters
% ----------
% dtiH: A dti Handle from mrDiffusion
% fg: A fiber group
% 
% (c) Stanford VISTASOFT Team, 2012 

% Try figuring out the coordspace of the fiber group
% A lot of fiber groups will not have this defined, in which case, return
% the empty matrix (no additional transformation will be applied).
% try     cspace = fgGet(fg, 'coordspace');
% catch,  cspace = [];
% end

if notDefined('meshID'), meshID = 174; end

fg = dtiXformFiberCoords(fg, dtiGet(dtiH,'img 2 acpc xform'));

% Add your fiber group to the dtiH (this doesn't persist when you leave
% this function...)
dtiH = dtiSet(dtiH,'add fiber group',fg);

% Now show the fg on a mesh:
fgMesh(dtiH, length(dtiH.fiberGroups),meshID);

return
