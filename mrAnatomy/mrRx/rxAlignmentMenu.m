function h = rxAlignmentMenu(parent);
%
% h = rxAlignmentMenu(parent);
%
% Make a menu for mrRx file commands,
% attached to parent object.
%
% ras 02/05.
if notDefined('parent'),    parent = gcf;		end

h = uimenu(parent, 'Label', 'Alignment');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Coarse alignment submenu %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hcoarse = uimenu(h, 'Label', 'Coarse', 'Separator', 'on');

% % compute coarse alignment from I-file headers
% uimenu(hcoarse, 'Label', 'From I-file headers', 'Callback', 'rxCoarseIfiles;');

% compute coarse->fine alignment using mrAlignMI method
uimenu(hcoarse, 'Label', 'mrAlignMI (Ifiles + Mutual Inf)', ...
				'Callback', 'rxFineMutualInf(gcf, 0, 1, 1, [8 4 2]);');

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fine alignment submenu   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hfine = uimenu(h, 'Label', 'Fine', 'Separator', 'on');
   
% compute fine alignment from selected points
uimenu(hfine, 'Label', 'From Selected Points', ...
       'Callback', 'rxFinePoints;');
   
% compute fine alignment using mutual information
uimenu(hfine,'Label', 'Using Mutual Information (mrAlignMI)', ...
       'Callback', 'rxFineMutualInf(gcf, 1, 1, 1, [4 2]);');
    
% compute fine alignment using Nestares code
uimenu(hfine, 'Label', 'Nestares code', ...
       'Callback', 'rxFineNestares;');

return