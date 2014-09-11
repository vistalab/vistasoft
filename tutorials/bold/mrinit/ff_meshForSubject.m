function ff_meshForSubject(initials)
close all; 
bookKeeping; 

index = 0; 
% find index corresponding to initials
for ii = 1:length(list_sub)

   if strcmp(initials, list_sub{ii})
       index = ii; 
    end

end

   if index == 0
       error(['mrVista session for this subject does not exist: ' initials])
   end

% cd to session and open mrVista gray
cd(list_sessionPath{index})
vw = mrVista('3');

% % load retinotopic model
% vw = rmSelect(vw, 1, [list_retModFolderPath{index} list_retModName{index}]);
% vw = rmLoadDefault(vw); 

% load right mesh
vw = meshLoad(vw, [list_meshPath{index} list_meshR{index}], 1);

% load left mesh
vw = meshLoad(vw, [list_meshPath{index} list_meshL{index}], 1);

% load contrast map
if (index == 10) || (index == 11) % rl or am
    conMapPath = [list_sessionPath{index} 'Gray/GLMs/WordVScramble.mat']; 
else % andreas' subjects
    conMapPath = [list_sessionPath{index} 'Gray/GLMs/WordVWordScramble.mat']; 
end
vw = loadParameterMap(vw, conMapPath);


% % load an roi
% vw = loadROI(vw, 'LV2d', 'select', [], 0, 1); 
% vw = loadROI(vw, 'left_WvWS_all', 'select', [], 0, 1); 
% vw = loadROI(vw, 'right_WvWS_all', 'select', [], 0, 1); 

% % plot coverage map for checking of x - flippage
% [~, figHandle ,~, ~, ~] = rmPlotCoverage(vw, 'nboot', 10); 

% set to phase for checking of y-flippage
vw = setDisplayMode(vw,'ph'); 
vw = refreshScreen(vw); 

% update all meshes
vw = meshUpdateAll(vw); 

end

