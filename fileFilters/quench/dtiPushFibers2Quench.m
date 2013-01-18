function dtiPushFibers2Quench(fiberGroups, dataDir, dt6File, mrmHost, mrmID)
%
% NOTES:
%   * handles.mrMesh.id = mrmID
%   * handles.mrMesh.host = mrmHost
%   * handles.dataDir = dataDir
%   * handles.dataFile = dt6File
%   * handles.fiberGroups = fiberGroups

% fg has
%  1. params: array of structures, used as statistic header for a pdb of size numstats
%       string name, int uid, int ile, int icpp,int ivs, string agg, 
%       string lname, double *stat[numfibers]
%  
%  2. pathwayInfo: array of structures of size numfibers
%       int algo_type, int seed_point_index, double pathStat[numStats], 
%       double point_stat_array[num points per fiber]
%     
%  3. fibers array of size numfibers
%       double <3x num points per fiber>

% Cases that can arise
% All fibers have proper data
% No fibers have pathwayInfo and params
% 3 fiber cases, 1 means has it 0 means it doesnt
% 1 1 0
% 0 1 1
% 0 0 1
% 0 1 0
% 1 0 0
% 1 0 1
fgm = fiberGroups(1);
if (~quenchCheckServer())
    r = questdlg ('Quench is not running. Would you like to start it?');
    if(~strcmp(r,'Yes'))
        disp('Push canceled.');
        return;
    end;
    quenchStart();
    pause(1);
    p = struct();
    p.datapath = fullfile(dataDir,'bin');
    if ~cinchGenerateData (dt6File, p.datapath)
        disp ('Canceled.');
        return;
    end;
    [id, s, r] = mrMesh([mrmHost, ':4001'], mrmID, 'set_datapath', p);
    % Set the data directory
else
    r = questdlg('Are you sure you want to push fibers? All fibers will be overwritten in Quench!',...
        'Confirm Push', 'Yes','No','Yes');
    if(~strcmp(r,'Yes'))
        disp('Push canceled.');
        return;
    end;
    % CINCH is already running
    p = struct();
    [id, s, r] = mrMesh([mrmHost, ':4001'], mrmID, 'get_datapath', p);
    CINCH_datapath = r.datapath;
    if (~strcmp (CINCH_datapath, [dataDir filesep 'bin']) || strcmp (CINCH_datapath, '[none]'))
        disp ('Refreshing Quench data...');
        p.datapath = [dataDir filesep 'bin'];
        if ~cinchGenerateData (dt6File, p.datapath)
            disp ('Canceled.');
            return;
        end;
        [id, s, r] = mrMesh([mrmHost, ':4001'], mrmID, 'set_datapath', p);
    end;
end;

% fg has
%  1. params: array of structures, used as statistic header for a pdb of size numstats
%       string name, int uid, int ile, int icpp,int ivs, string agg, 
%       string lname, double *stat[numfibers]
%  
%  2. pathwayInfo: array of structures of size numfibers
%       int algo_type, int seed_point_index, double pathStat[numStats], 
%       double point_stat_array[num points per fiber]
%     
%  3. fibers array of size numfibers
%       double <3x num points per fiber>

% This version merges data only if the fibers have matching statistics.
fgm = fiberGroups(1);
fgm.pathwayInfo = addDummyPathwayInfo(fgm, size(fgm.fibers,1),length(fgm.params));    
% append all fibers 
for fgNum = 2:length(fiberGroups)
    fg = fiberGroups(fgNum);
    numFibers = size(fgm.fibers,1);    
    newnumFibers = numFibers + length(fg.fibers);
    % Add the params
    if(size(fgm.params,1)==0 || isfield(fgm,'params')==0)
        fgm.params = fg.params;
    else
        %Make sure that pathwayInfo is not empty, add some dummy data if
        %empty
        fg.pathwayInfo = addDummyPathwayInfo(fg, size(fg.fibers,1),length(fgm.params)); 
        % Expand the pathwayInfo to incorporate the data
        dummy = fgm.pathwayInfo(1);
        dummy.point_stat_array = [];
        fgm.pathwayInfo(numFibers+1:newnumFibers)=dummy;
        % Add the params
        for i = 1: length(fg.params)
            bParamExist = 0;
            for j = 1:length(fgm.params)
                if(fg.params{i}.uid == fgm.params{j}.uid)
                    bParamExist = 1;
                    fgm.params{j}.stat = [fgm.params{j}.stat  fg.params{i}.stat];
                    addMissingParamFields(fgm.params{j});
                    % add the point_stat_vector to the merged place
                    for k = numFibers+1: newnumFibers
                        fgm.pathwayInfo(k).point_stat_array(j,:)=fg.pathwayInfo(k-numFibers).point_stat_array(i,:);
                    end
                    break;
                end
            end
            %If the param did not exist fill it up with zeros
            if bParamExist == 0
                disp('Fibers dont have matching statistics');
                return;
            end
        end

        % Add the params other way around
        for i = 1: length(fgm.params)
            bParamExist = 0;
            for j = 1:length(fg.params)
                if(fg.params{j}.uid == fgm.params{i}.uid)
                    bParamExist = 1;
                    break;
                end
            end
            %If the param did not exist fill it up with zeros
            if bParamExist == 0
                disp('Fibers dont have matching statistics');
                return;
            end
        end

    end
    fgm.fibers = [fgm.fibers ; fg.fibers];
end
str = fiberToStr(fgm);
%myf = fopen('merge.pdb','wb');fwrite(myf,str,'uint8');fclose(myf);
[id, s, r] = mrMesh([mrmHost, ':4001'], mrmID, 'push_paths', str);

pathCount = 0;
for fgNum = 1:length(fiberGroups)
    fg = fiberGroups(fgNum);
    numPaths = length(fiberGroups(fgNum).fibers);
    p = struct();
    p.assignment_min = pathCount;
    p.assignment_max = pathCount+numPaths;
    p.visible = fg.visible;
    p.color = fg.colorRgb';
    p.name = fg.name;
    if (~isfield(fg, 'query_id'))
        fg.query_id = -1;
    end;
    if (fg.query_id ~= -1)
        p.query_id = fg.query_id;
    end;
    [id, s, r] = mrMesh([mrmHost, ':4001'], mrmID, 'push_fg_info', p);
    fiberGroups(fgNum).query_id = r.query_id;
    pathCount = pathCount + numPaths;
end;

return;