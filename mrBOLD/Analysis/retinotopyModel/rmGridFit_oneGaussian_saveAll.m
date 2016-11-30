function model = rmGridFit_oneGaussian(model, prediction, data, params, t, varargin)
% rmGridFit_oneGaussian - core of one Gaussian fit
%
% model = rmGridFit_oneGaussian(model,prediction,data,params);
%
% 2008/01 SOD: split of from rmGridFit.
% 2008/12 RAS: split alternate version, which saves the whole RSS matrix.
% Not sure if it's a better design to split into 2 functions, or to add
% sevral flags and conditionals to save or not save all data; I opted to
% keep several independent functions to keep the code from getting too
% messy.

% input check 
if nargin < 4,
    error('Not enough arguments');
end

% some variables we need
rssinf         = inf(size(data(1,:)),'single');
trends         = t.trends;
t_id           = t.dcid+1;

%-----------------------------------
%--- get ready to save all RSS values
%-----------------------------------
% (ras 12/08):
% We want to save, for each voxel, the entire range of RSS values for each
% fit across the parameter grid (x0, y0, sigma in this case). 
% This creates some issues of disk space (cheap, minimal) and memory (not
% as cheap, trickier). 
%
% The ideal format for allRSS would be a matrix of size (voxels x predictions). 
% But this can easily exceed the maximum
% variable size allowed by MATLAB; I checked. (A typical session would have
% ~10^5 voxels, and there are around 10^6 predictions by default. Even
% using smaller-footprint uint8 variables, MATLAB can't store this as a
% matrix.)
%
% To get around this, I break the allRSS data into chunks, named
% allRSS_1 to allRSS_[N], where N is the number of chunks. The chunk size
% depends on the memory availble to the system, and could probably be an
% input argument: I'll hard code it for now. We fill up and save each
% variable separately, never having all the variables in memory or as a
% single file. Ugly, but potentially useful.
stepSize = 1000;
estimatedSteps = ceil( size(prediction, 2) / stepSize )

% set up a save directory for all the allRSS files
% (theoretically, we'd need to have info on the view type here; I'll 
% hard code it to gray for now)
retModelDir = dataDir(getSelectedGray);
[p stem ext] = fileparts(params.matFileName{1});
saveDir = fullfile(retModelDir, ['AllRSS_' stem]);
ensureDirExists(saveDir);

%-----------------------------------
%--- fit different receptive fields profiles
%--- another loop --- and a slow one too
%-----------------------------------
tic; progress = 0;
nFits = size(prediction, 2);
for n=1:nFits
    %-----------------------------------
    % progress monitor (10 dots) and time indicator
    %-----------------------------------
    if floor(n./numel(params.analysis.x0).*10)>progress,
        if progress==0,
            % print out estimated time left
            esttime = toc.*10;
            if floor(esttime./3600)>0,
                fprintf(1,'[%s]:Estimated processing time: %d hours.\t(%s)\n',...
                    mfilename, ceil(esttime./3600), datestr(now));
            else
                fprintf(1, '[%s]:Estimated processing time: %d minutes.\t(%s)\n',...
                    mfilename, ceil(esttime./60), datestr(now));
            end;
            fprintf(1,'[%s]:Grid (x,y,sigma) fit:',mfilename);drawnow;
        end;
        % progress monitor
        fprintf(1,'.');drawnow;
        progress = progress + 1;
    end;

    %-----------------------------------
    %--- now apply glm to fit RF
    %-----------------------------------
    % minimum fRSS fit
    X    = [prediction(:,n) trends];
	
    % This line takes up 30% of the time
    b    = pinv(X)*data;
	
    % reset RSS
    rss  = rssinf;
	
    % Compute RSS only for positive fits. The basic problem is
    % that if you have two complementary locations, you
    % could fit with a postive beta on the one that drives the signal or a
    % negative beta on the portion of the visual field that never sees the
    % stimulus. This would produce the same prediction. We don't like that
    keep   = b(1,:)>0;
	
    % To save time limit the rss computation to those we care about.
    % This line is takes up 60% of the time....
    rss(keep) = sum((data(:,keep)-X*b(:,keep)).^2);
    
    %-----------------------------------
    %--- store data with lower rss
    %-----------------------------------
    minRssIndex = rss < model.rss;
	
    %-----------------------------------
    %--- save the rss values across all voxels for this prediction
    %-----------------------------------
	% see the above comments (~line ) on how we break up the set 
	% of all RSS values into chunks.

	% is it time to initialize a new allRSS variable, for a new subset
	% of the data?
	if mod(n, stepSize)==1 | n==nFits
		% do we have a full subset to save?
		if n > 1
			% these files can be huge: let's store them as uint8 class.
			% this will lose precision (each value will have 256 discrete
			% values, which we scale across the range of values), but save
			% about 75% / file on storage.
			cmd = sprintf('dataRange = mrvMinmax(%s);', varname);
			eval(cmd);
			
			cmd = sprintf('%s = int16( rescale2(%s, dataRange, [-32768 32767]) );', ...
							varname, varname);
			eval(cmd);
			
			savePath = fullfile(saveDir, varname);
			save(savePath, varname, 'dataRange', 'nFits', 'stepSize');
			fprintf('Saved subset %s in %s [%s].\n', varname, savePath, datestr(now)); %temp'

			% clear the variable from memory
			eval( sprintf('clear %s', varname) );
		end

		% initialize the next subset variable
		tic
		iSubset = floor(n / stepSize) + 1;
		varname = sprintf('allRSS_%i', iSubset);
% 		cmd = sprintf('%s = NaN(%i,%i);', varname, size(rss, 1), stepSize);
%         eval(cmd);
% 		fprintf('Initialize new subset step: %s\n', secs2text);
	end

	% assign the current set of RSS values to the current allRSS
	% variable
    cmd = sprintf('%s(:,%i) = rss;', varname, mod(n-1, stepSize)+1);
	eval(cmd);

    % now update
    model.x0(minRssIndex)       = params.analysis.x0(n);
    model.y0(minRssIndex)       = params.analysis.y0(n);
    model.s(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.s_major(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.s_minor(minRssIndex)        = params.analysis.sigmaMajor(n);
    model.s_theta(minRssIndex)        = params.analysis.theta(n);
    model.rss(minRssIndex)      = rss(minRssIndex);
    model.b([1 t_id],minRssIndex) = b(:,minRssIndex);
end;

% end time monitor
et  = toc;
if floor(esttime/3600)>0,
    fprintf(1,'Done[%d hours].\t(%s)\n', ceil(et/3600), datestr(now));
else
    fprintf(1,'Done[%d minutes].\t(%s)\n', ceil(et/60), datestr(now));
end;
drawnow;
return;


