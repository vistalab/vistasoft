function pathStr=rmSave(view,model,params,forceSave,stage)
% rmSave - save/reshape model analysis in output that mrVISTA can read
%
% output = rmSave(view,model,forceSave);
%
% 12/2006 SOD: wrote it.
if notDefined('view'),  error('Need view structure');    end;
if notDefined('model'), error('Need model structure');   end;
if notDefined('params'), error('Need params structure'); end;
if notDefined('forceSave'), forceSave = false;           end;
if notDefined('stage'),     stage = [];                  end;
    
% reshape all params in model struct
dims     = viewGet(view,'datasize');

% if roi get coords
% also compute dimSize, dimSize is the size a parameters has to be
% if we want to reshape it. If it is not this size it is probably
% not defined for each voxel (eg df or description).

% if roi
coords = rmGet(model{1},'roicoords');
coordsInd = rmGet(model{1},'roiIndex');
if ~isempty(coords),
    switch lower(viewGet(view,'viewType')),
        case {'gray'}
            allcoords = viewGet(view,'coords');
        case {'inplane'}
            allcoords = viewGet(view,'coords');
            allcoords = ip2functionalCoords(view, allcoords);
                
    end;
end;

% if param is dimSize we have to reshape if
% we do this for the following parameters
fnames = {'x','y','x02','y02','sigmamajor','sigmaminor','sigmatheta',...
    'sigma2major','sigma2minor','sigma2theta',...
    'b','rss','rss2','rsspos','rssneg','rawrss','rawrss2', 'exponent'};
for m = 1:length(model),
    for f = 1:length(fnames),
        param = rmGet(model{m},fnames{f});
        if numel(param) > 1 && isnumeric(param),

            switch lower(viewGet(view,'viewType')),
                case {'inplane'}
                    try
                        % if beta then all components are stored in 4th dimension
                        switch lower(fnames{f})
                            case 'b',
                                % could do in one step but I'm concerned about the
                                % ordering
                                d = length(size(param));
                                newparam = zeros([dims size(param,d)]);
                                for ii = 1:size(param,d),
                                    switch d
                                        case 4
                                            newparam(:,:,:,ii) = myreshape(param(:,:,:,ii),dims,coordsInd);
                                        case 3
                                            newparam(:,:,:,ii) = myreshape(param(:,:,ii),dims,coordsInd);
                                    end
                                end;
                                param = newparam;
                            otherwise,
                                param = myreshape(param,dims,coordsInd);
                                
                        end
                    catch ME
                        disp('Parameter size error.')
                        disp(fnames{f})
                        rethrow(ME)
                        size(param)
                    end

                case {'gray'}
                    % we only need to do this for rois, whole gray matter is in
                    % correct from.
                    if ~isempty(coords),
                        switch lower(fnames{f})
                            case 'b',
								try
	                                out                = zeros(1,size(allcoords,2),size(param,3));
		                            out(1,coordsInd,:) = param;
			                        param              = out;
                                catch ME
									fprintf(1,'[%s]: failed to get %s.\n',mfilename, fnames{f});
                                    rethrow(ME);
								end
                            otherwise
                                out            = zeros(1,size(allcoords,2));
                                if numel(param)==numel(coordsInd),
                                    out(coordsInd) = param;
                                else
                                    out = param;
                                end
                                param          = out;
                        end;
                    end;

                otherwise
                    error('[%s]:unknown viewType %s',...
                        mfilename,viewGet(view,'viewType'));
            end;
            model{m} = rmSet(model{m},fnames{f},param);
        end;
    end;
end;

% file name
if isempty(params.matFileName),
    % if no filename exists, make one:
    if ~isempty(stage),
        params.matFileName{1} = sprintf('retModel-%s-%s.mat',datestr(now,'yyyymmdd'),stage);
    else
        params.matFileName{1} = ['retModel-',datestr(now,'yyyymmdd'),'.mat'];
    end
else
    % if filename exists use it but add stage flag (if defined)
    if ~isempty(stage),
        if strcmpi(params.matFileName{end}(end-3:end),'.mat')
            matFileName = params.matFileName{end}(1:end-4);
        else
            matFileName = params.matFileName{end};
        end
        params.matFileName{end} = sprintf('%s-%s.mat',matFileName,stage);
    end
end;
pathStr    = fullfile(dataDir(view),params.matFileName{end});

% overwrite?
if exist(pathStr,'file')
    if forceSave == 0,
        [f,p] = uiputfile('*.mat','File exists, please select file?', ...
            pathStr);
        % check
        if(isequal(f,0)||isequal(p,0))
            fprintf(1,'[%s]:Model not saved.\n',mfilename);
            return;
        else
            pathStr = fullfile(p,f);
        end
    else
        % try to make a unique filename that also reflects how many times
        % we have run a certain stage
        while(exist(pathStr,'file'))
            % grow pathStr name
           pathStr = [pathStr(1:end-4) '-' stage '.mat']; 
        end
    end
end

% save
save(pathStr,'model','params');
fprintf(1,'[%s]:Saved %s.\n',mfilename,pathStr);
return;
%------------------------


%------------------------
function mapdata = myreshape(param,dims,coordsInd)

if isequal(dims, size(param))
    
    mapdata = param;
    return
end

if ~isequal(length(coordsInd), prod(dims))
    % otherwise
    mapdata = reshape(param.',dims);
else
    mapdata = zeros(dims);
    mapdata(coordsInd) = param;
end;
return;
%------------------------
