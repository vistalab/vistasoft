function status = tc_parfilesCheck(view,scans);
% status = tc_parfilesCheck(view,scans): 
%
% For time course UI, check that the selected scans
% have parfiles. If not, but if they're cyclic in design,
% offer to make them.
%
% If the code returns with parfiles having been assigned for 
% each scan, returns a status of 1; otherwise, returns 0.
%
% 07/04 ras.
status = 0;

global dataTYPES;

if ieNotDefined('scans')
    scans = er_getScanGroup(view);
end

dt = viewGet(view,'curdt');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check whether a parfile is assigned for the scans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parCheck = zeros(size(scans));

for i = 1:length(scans)
	if isfield(dataTYPES(dt).scanParams(scans(i)),'parfile')  
        % if the first has a parfile, I assume they all must have one
       if ~isempty(dataTYPES(dt).scanParams(scans(1)).parfile)
           parCheck(i) = 1;
       end
	end
end

notAssigned = scans(find(parCheck==0));

% if all are assigned, great, we can return...
if isempty(notAssigned)
    status = 1;
    return;
end

% ... otherwise, proceed to check if they can be readily
% generated from the information in dataTYPES:
isCyclic = zeros(size(notAssigned));
for i = 1:length(notAssigned)
    s = notAssigned(i);
    if dataTYPES(dt).blockedAnalysisParams(s).blockedAnalysis==1
        isCyclic(i) = 1;
    end
end
    
% if we reached this point, that means we can offer to construct the
% parfiles for the non-assigned scans:
msg = ['There are some scans without parfiles assigned ... but we can '...
       'try to build them if the scans are cyclic or rapid '...
       'event-related. What do you want to do?'];
button = questdlg(msg, mfilename, 'Build Parfile(s)', ...
                  'Assign Parfile(s)', 'Cancel', 'Cancel');

% exit gracefully if user cancels
if ~ismember(button, {'Build Parfile(s)' 'Assign Parfile(s)'}), return; end
              
if isequal(button, 'Build Parfile(s)')
    % build and save the parfiles
    rapider = questdlg('Are the scans rapid event-related?');
    if isequal(rapider,'Yes')               % rapid event-related
        msg = 'How many non-null Conditions?';
        def = num2str(dataTYPES(dt).blockedAnalysisParams(scans(1)).nCycles);
        answer = inputdlg(msg,'Rapid Event-Related',1,{def});
        nConds = str2num(answer{1});
        
        dlgTitle = 'Enter condition params';
        defcolors = tc_colorOrder(nConds);
        for i = 1:nConds
            prompt{2*i-1} = sprintf('Enter Condition %i name:',i);
            prompt{2*i} = sprintf('Enter Condition %i color:',i);
            defaults{2*i-1} = sprintf('Cond %i',i);
            defaults{2*i} = num2str(defcolors{i});
        end
        prompt{end+1} = 'Enter parfile prefix (will add scan # afterwards):';
        defaults{end+1} = 'scan';
        answer = inputdlg(prompt,dlgTitle,1,defaults);

        % construct par struct containing onset, condition, cond name info        
        scan = notAssigned(1);
        nf = dataTYPES(dt).scanParams(scan).nFrames;
        TR = dataTYPES(dt).scanParams(scan).framePeriod;
        ncyc = 1;
        nsecs = round(nf * TR);
        blockSecs = nsecs/(ncyc*nConds);
        par.cond = repmat(1:nConds,1,ncyc);
        par.onset = [0:blockSecs:blockSecs*ncyc*nConds] + 1;
        par.onset = round(par.onset(1:end-1));
        for i = 1:nConds
            labels{i} = answer{2*i-1}; % condition names
            colors{i} = answer{2*i};  % condition colors
        end
        labels = [{'blank'} labels];
        colors = [{[0 0 0]} colors];
        par.label = labels(par.cond+1);
        par.color = colors(par.cond+1);
        
    elseif isequal(rapider,'No')            % cyclic
        dlgTitle = 'How many conditions in each cycle?';
        prompt = {'(E.g. 1 for traveling-wave, 2 for ABAB blocked...'};
        answer = inputdlg(prompt,dlgTitle,1,{'2'});
        nConds = str2num(answer{1});
        
        dlgTitle = 'Enter condition params';
        defcolors = tc_colorOrder(nConds);
        for i = 1:nConds
            prompt{2*i-1} = sprintf('Enter Condition %i name:',i);
            prompt{2*i} = sprintf('Enter Condition %i color:',i);
            defaults{2*i-1} = sprintf('Cond %i',i);
            defaults{2*i} = num2str(defcolors{i});
        end
        prompt{end+1} = 'Enter parfile prefix (will add scan # afterwards):';
        defaults{end+1} = 'scan';
        answer = inputdlg(prompt,dlgTitle,1,defaults);
        
        msg = 'Will assume that each scan has the same structure. Hope this is correct...\n';
        fprintf(msg);

        % construct par struct containing, onset, condition, cond name info
        scan = notAssigned(1);
        nf = dataTYPES(dt).scanParams(scan).nFrames;
        TR = dataTYPES(dt).scanParams(scan).framePeriod;
        ncyc = dataTYPES(dt).blockedAnalysisParams(scan).nCycles;
        nsecs = nf * TR;
        blockSecs = nsecs/(ncyc*nConds);
        par.cond = repmat(1:nConds,1,ncyc);
        par.onset = [0:blockSecs:blockSecs*ncyc*nConds] + 1;
        par.onset = par.onset(1:end-1);
        par.label = {}; par.color = {};
        for i = 1:nConds
            par.label{i} = answer{2*i-1}; % condition names
            par.color{i} = answer{2*i};  % condition colors
        end
                        
    else                            % user pressed 'Cancel' or closed dlg
        return;
    end

    global HOMEDIR;
    for i = 1:length(notAssigned)
        scan = notAssigned(i);
        parFileName = [answer{end} num2str(scan) '.par'];
        parPath = fullfile(parfilesDir(view) ,parFileName);
        writeParfile(par,parPath);
        dataTYPES(dt).scanParams(scan).parfile = parFileName;
    end
    
    save(fullfile(HOMEDIR,'mrSESSION.mat'),'dataTYPES','-append');
    
elseif isequal(button, 'Assign Parfile(s)') 
    % assign the parfiles to the scans
    er_assignParfilesToScans(view, scans);
end

status = 1;

return
