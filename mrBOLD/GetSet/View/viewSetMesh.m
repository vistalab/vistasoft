function vw = viewSetMesh(vw,param,val,varargin)
%Organize methods for setting view parameters.
%
% This function is wrapped by viewSet. It should not be called by anything
% else other than viewSet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'),  error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

mrGlobals;

switch param
    
    case {'leftclassfile' 'rightclassfile' 'leftgrayfile' 'rightgrayfile'};
        
        % Vol/Gray check
        if ~ismember(vw.viewType, {'Volume' 'Gray'})
            error(['Can only set %s property in ' ...
                'Volume / Gray views.'], param);
        end
        
        % get the field name for this parameter
        switch lower(param)
            case 'leftclassfile'
                fieldName = 'leftClassFile';
            case 'rightclassfile'
                fieldName = 'rightClassFile';
            case 'leftgrayfile'
                fieldName = 'leftPath';
            case 'rightgrayfile'
                fieldName = 'rightPath';
        end
        
        % set field in view
        vw.(fieldName) = val;
        
        % also save this parameter in the coords file, so it remembers.
        %   eval( [fieldName ' = ''' val ''';'] );
        %   coordsFile = fullfile(viewDir(vw), 'coords.mat');
        %   if exist(coordsFile, 'file')
        % 	  save(coordsFile, fieldName, '-append');
        % 	  fprintf('Updated %s with new file information.', coordsFile);
        %   end
        
        % these params interface with the mrMesh functions
    case {'mesh' 'currentmesh' 'allmeshes' 'addmesh' 'meshdata' ...
            'meshn'  'deletemesh'}
        % Vol/Gray check
        if ~ismember(vw.viewType, {'Volume' 'Gray'})
            error(['Can only set %s property in ' ...
                'Volume / Gray views.'], param);
        end
        
        switch lower(param)
            case 'mesh'
                % viewSet(vw,'mesh',val,whichMesh)
                if ~isempty(varargin), whichMesh = varargin{1};
                else whichMesh = viewGet(vw,'currentmeshn');
                end
                
                if isempty(val), vw = viewSet(vw, 'deleteMesh', whichMesh);
                else vw.mesh{whichMesh} = val;
                end
                
            case 'currentmesh'
                whichMesh = viewGet(vw,'currentmeshn');
                vw.mesh{whichMesh} = val;
            case 'allmeshes'
                vw.mesh = val;
            case 'addmesh'
                % viewSet(vw{1},'addmesh',msh,3);
                if ~isempty(varargin), newMeshNum = varargin{1};  % User specified the mesh number
                elseif(isfield(vw,'mesh')), newMeshNum = length(vw.mesh)+1; % add to meshes
                else newMeshNum = 1;                       % or make it the first mesh.
                end
                if ~meshCheck(val),warning('vista:viewError', 'Non-standard mesh being added'); end
                vw.mesh{newMeshNum} = val;
                
                % allow for GUI elements to specify the selected mesh
                if checkfields(vw, 'ui', 'menus', 'meshSelected')
                    h = vw.ui.menus.meshSelected;
                    
                    % index for new menu
                    n = newMeshNum + 1; % 1st entry=top menu
                    
                    % create the menu
                    label = sprintf('%i. %s', val.id, val.name);
                    cb = sprintf('%s = viewSet(%s, ''CurMeshNum'', %i); ', ...
                        vw.name, vw.name, newMeshNum);
                    h(n) = uimenu(h(1), 'Label', label, 'Callback', cb);
                    
                    % update the view handles
                    vw.ui.menus.meshSelected = h;
                    
                    
                    % if we're using the new gray menu, we want to make sure
                    % the mesh-specific options, such as projecting data onto
                    % the mesh or
                    set( allchild(vw.ui.menus.gray), 'Enable', 'on');
                    meshSettingsList(vw.mesh{newMeshNum});
                end
                
                % select the new mesh
                vw = viewSet(vw, 'currentmeshn', newMeshNum);
                
            case 'meshdata'
                curMesh = viewGet(vw,'meshn');
                vw.mesh{curMesh}.data = val;
            case 'meshn'
                vw.meshNum3d = val;
                
                % allow for GUI elements to specify the selected mesh
                if checkfields(vw, 'ui', 'menus', 'meshSelected')
                    try
                        h = vw.ui.menus.meshSelected;
                        set(h, 'Checked', 'off'); % de-select all menus
                        set(h(val+1), 'Checked', 'on'); % select appropriate menu (1st entry=top menu)
                        
                        if checkfields(vw, 'mesh')
                            meshSettingsList(vw.mesh{val});
                        end
                    catch ME
                        warning(ME.identifier, ME.message);
                    end
                end
                
            case 'deletemesh'
                % USAGE: viewSet(vw, 'Delete Mesh', meshNum);
                % allow several meshes to be specified for deletion at once
                if length(val) > 1
                    % we need to go from highest to lowest value: since
                    % removing a mesh reduces the total number of meshes, if we
                    % e.g removed #1 then #2, the second index would point to a
                    % mesh value which no longer exists
                    meshList =  sort(val(:), 'descend');
                    for ii = 1:length(meshList)
                        whichMesh = meshList(ii);
                        vw = viewSet(vw, 'deleteMesh', whichMesh);
                    end
                    return
                end
                
                % if a mesh window is open, close it:
                if vw.mesh{val}.id > 0
                    vw = meshCloseWindow(vw, val);
                end
                
                % remove the mesh entry from the mesh cell array:
                keep = setdiff(1:length(vw.mesh), val);
                vw.mesh = vw.mesh(keep);
                if ~isempty(vw.mesh),
                    vw = viewSet(vw, 'currentmeshn', max(1,min(val)-1));
                end
                
                % Remove any menus specifying this mesh
                if checkfields(vw, 'ui', 'menus', 'meshSelected')
                    try
                        h = vw.ui.menus.meshSelected;
                        delete( h(val+1) ); % +1 because 1st entry is top menu
                        %h = h([1 keep+1]); % this line doesn't seem to do anything
                        vw.ui.menus.meshSelected = h(1:val);
                    catch ME
                        warning(ME.identifier, ME.message);
                        disp('Warning: Couldn''t remove deleted mesh menu.')
                    end
                end
                
                % If there are no meshes left in the array, we clear the mesh
                % array and select mesh 0.
                if isempty(vw.mesh)
                    vw = rmfield(vw, 'mesh');
                    vw = viewSet(vw,'currentmeshn',0);
                end
                
        end
        
    case 'recomputev2gmap'
        msh = viewGet(vw, 'Mesh');
        vertexGrayMap = mrmMapVerticesToGray( ...
            meshGet(msh, 'initialvertices'), ...
            viewGet(vw, 'nodes'), ...
            viewGet(vw, 'mmPerVox'), ...
            viewGet(vw, 'edges'));
        msh = meshSet(msh, 'vertexgraymap', vertexGrayMap);
        vw = viewSet(vw, 'Mesh', msh);
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return