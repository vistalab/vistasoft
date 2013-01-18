function tc_saveParfiles(tc);
% tc_saveParfiles(tc);
%
% Time Course UI: save parfiles specified in tc struct.
%
% If an onset shift is specified in the 'onsetDelta' param, this is
% applied to the parfiles before saving.
%
% 07/04 ras.
global HOMEDIR; 

dlgTitle = 'Save parfiles...';
for i = 1:length(tc.params.parfiles)
    prompt{i} = sprintf('Scan %i parfile name:',tc.params.scans(i));
    defaults{i} = tc.params.parfiles{i};
end

answer = inputdlg(prompt,dlgTitle,1,defaults);

scans = tc.params.scans;

for i = 1:length(answer)
    ind = find(tc.trials.run==i);
    par.cond = tc.trials.cond(ind);
    D = tc.params.onsetDelta;
    if i==1
        par.onset = tc.trials.onsetSecs(ind) + D;
    else
        par.onset = tc.trials.onsetSecs(ind) + D - tc.trials.onsetSecs(ind(1));
    end      
    par.label = tc.trials.label(ind);
    par.color = cell(size(par.label));
    
    % use the currently-assigned cond names for the first label
    % for each condition
    for c = unique(par.cond)
        subind = find(par.cond==c);
        par.label{subind(1)} = tc.trials.condNames{find(tc.trials.condNums==c)};
        par.color{subind(1)} = tc.trials.condColors{find(tc.trials.condNums==c)};
    end
    
    parPath = fullfile(parfilesDir(initHiddenInplane), answer{i});    
    writeParfile(par, parPath);
end

% because we applied the onset shift in the parfiles, we can set the
% onsetDelta param back to 0, and save it, so we don't shift twice:
if tc.params.onsetDelta ~= 0
    tc.params.onsetDelta = 0;
    hI = initHiddenInplane(tc.params.dataType, tc.params.scans(1));
    er_setParams(hI, tc.params);
end

return
