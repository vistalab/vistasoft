function outarg = meshAngle(command, name, V);
%
% outarg = meshAngle([command], [name of angle], [Volume View]);
%
% Load/Save camera angles for viewing a mesh from canonical views.
% Angles are stored in the same directory as the mesh, in the file
% 'MeshAngles.mat'. These can be saved/restored for any meshes in that
% directory, so if both right and left hemishpheres are saved, it
% might be good to name it something like 'lateral-right' or 
% 'dorsolateral-left'.
%
% Volume view: view w/ the mesh attached. [defaults to selected gray]
% command: 'load', 'save', or 'list'. [defaults to 'list']
% name: name of the mesh to save.
%
% Returns a different output argument depending on the command:
%   'list': returns a struct containing the saved angles. (If meshAngle is 
%   called as meshAngle(V, 'list', 'quiet'), will only return in the
%   struct and not print to the command window.)
%   'load': returns the cRot value loaded.
%   'save': returns the path of the save file.
%
% Example: meshAngle(getSelectedGray, 'save', 'ventral') saves
% the view under the name 'ventral';
% meshAngle(getSelectedGray, 'load', 'ventral') restores it.
% meshAngle(getSelectedGray, 'list') lists the saved angles for this
% mesh, if any.
%
% ras, 10/2005.
if ieNotDefined('V'), V = getSelectedGray; end
if ieNotDefined('command'), command = 'list'; end

mesh = viewGet(V, 'mesh');

anatPath = getVAnatomyPath;
meshDir = fullfile(fileparts(anatPath), 'Meshes');

switch lower(command)
    case 'load',
        % get angles (and perform file check while we're at it)
        angles = meshAngle('list', 'quiet', V); 
        angleNames = {angles.name};

        % if no name specified, get from dialog
        if ieNotDefined('name')
            dlg.fieldName = 'name';
            dlg.style = 'listbox';
            dlg.string = 'Load which angle?';
            dlg.list = angleNames;
            dlg.value = 1;
            resp = generaldlg2(dlg,'Load Camera Angle...');
            name = resp.name{1};
        end
        
        % check that the named angle has been stored in the file        
        I = cellfind(angleNames, lower(name));
        if isempty(I)
            fprintf('Angle %s not found. Saved angles include:\n',name);
            for i = 1:length(angleNames)
                fprintf('%s \n', angleNames{i});
            end
            error('Selected angle not found');
        else   
            cRot = angles(I).cRot;
            mrmSet(mesh,'camerarotation',cRot);
        end 
        
        outarg = cRot;
        
    case 'save',
        cRot = mrmGet(mesh,'camerarotation');
        
        % if no name specified, get from dialog.
        if ieNotDefined('name')
            name = inputdlg({'Name of Angle to Save:'},...
                    'Save Camera Angle...',1,{'angle1'});
            if isempty(name{1}), return; end  % user canceled
            name = lower(name{1});
        end
        
        % load any angles that may exist.
        pth = fullfile(meshDir, 'MeshAngles.mat');
        if exist(pth,'file'), 
            load(pth,'angles');
            angles(end+1).name = lower(name);
        else
            angles.name = lower(name);
        end
        angles(end).cRot = cRot;
        angles(end).saved = datestr(clock);
        
        % save the angles.
        if exist(pth,'file')
            save(pth,'angles','-append');
        else
            save(pth,'angles')
        end
        fprintf('Saved camera rotation as angles(%i) in %s.\n',...
                length(angles),pth);
        
        outarg = pth;
        
    case 'list',
        % check if the Angles.mat file exists
        pth = fullfile(meshDir, 'MeshAngles.mat');
        if ~exist(pth, 'file')
            msg = sprintf(['No angles have been stored for ' ...
                           'this segmentation: %s.'], mesh.path);
            myWarnDlg(msg);
            angles = [];
            return
        else
            load(pth,'angles');
        end
                
        if ieNotDefined('name') | ~isequal(lower(name),'quiet')
            disp('***********************')
            disp('Angles Saved: ')
            for i = 1:length(angles)
                fprintf('%s \n', angles(i).name);
            end
            disp('***********************')
        end
        
        outarg = angles;
        
    otherwise, help(mfilename); warning('Unknown command'); 
end

return
