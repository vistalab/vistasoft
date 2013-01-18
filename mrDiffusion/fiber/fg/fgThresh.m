function fg = fgThresh(fg,param,lowerThresh,upperThresh,dt6File)
% 
%  fg = fgThresh(fg,param,[lowerThresh],[upperThresh],[dt6File=mrvSelectFile])
%  
% Remove fibers from a FG that are above and/or below a given threshold
% based on a parameter or statistic attached to the fiber (param). 
% 
% In the case that the user asks for a diffusion parameter the statistics
% are attached to the fiber group using dtiCreateQuenchStats and
% thresholded based on those values. NOTE: to do this you will have to
% provide the path to the dt6File, or you will be prompted for it. You do
% NOT have to have the diffusion stats attached to the fiber before you run
% this function - it will do that for you and save out the FG with those
% stats attached to the resulting FG. 
% 
% 
% INPUTS:
%       fg          - a fiber group structure (e.g., read in with fgRead)
%       param       - the parameter you want to threshold (string). 
%                      SUPPORTED PARAMETER STATISTICS:
%                       * 'length'
%                       * 'FA'
%                       * 'MD'
%                       * 'RD'
%                       * 'AD'
%       lowerThresh - fibers having values less than lowerThresh will be
%                     removed from the fg.
%       lowerThresh - fibers having values above the upperThresh will be
%                     removed from the fg.
%       dt6File     - path to the dt6 file (.mat) * Only required if you
%                     choose a diffuison statistic.
% 
% OUTPUT:
%       fg          - fiber group structure with those fibers removed that
%                     were above and/or below threshold(s).
% 
% WEB RESOURCES:
%       mrvBrowseSVN('fgThresh');
%       
% EXAMPLE USAGE:
%       fg = fgRead('myFiberGroup.pdb');
%       param = 'length';
%       lowerThresh = 20;
%       upperThresh = 100;
%       fg = fgThresh(fg,param,lowerThresh,upperThresh)
% 
% SEE ALSO:
%       fgExtract.m, dtiCreateQuenchStats.m, dtiCreateMap.m, fgGet.m
% 
% 
% (C) Stanford University, VISTA Lab, 2011
% 


%% Check inputs
if notDefined('fg') || isempty(fg) || ~isstruct(fg)
    if exist(fg,'file')
        fg = fgRead(fg);
    else 
        fg = fgRead;
    end
end

if notDefined('param') || isnumeric(param)
    error('You must provide a valid param for thresholding.'); 
end

param = lower(param);

if notDefined('lowerThresh');
    lowerThresh = [];
end

if notDefined('upperThresh');
    upperThresh = [];
end

if notDefined('dt6File') || ~exist(dt6File,'file')
    dt6File = [];
end


%% Length

switch param
    case 'length'
        
    % LOWER THRESH
        if ~isempty(lowerThresh)
            % Use fgGet to return an array of fiber samples
            lengths = fgGet(fg,'nfibersamples');
            % Start a counter to keep track of the place in the array
            n = 0;
            
            % Check that the threshold is within range
            if ~(lowerThresh > min(lengths)) 
                error('lowerThresh is not within range!'); end
            
            % Loop over the lengths array and find the index for each fiber
            % that is below the threshold. 
            for ii = 1:numel(lengths)
                if lengths(ii) < lowerThresh
                    n = n+1;
                    % Store the position of the fiber in inds. 
                    inds(n) = ii;  %#ok<AGROW>
                end
            end
            
            fprintf('%s fibers are below [%s = %s] threshold and will be removed.\n',...
                num2str(numel(inds)),param,num2str(lowerThresh));
            % Remove the fibers (see function at the end of the script)
            fg = fgExtract(fg,inds,'remove');
        end
        
     % UPPER THRESH (Same method as lower thresh)
        if ~isempty(upperThresh)
            lengths = fgGet(fg,'nfibersamples');
            n = 0;
            if ~(lowerThresh > min(lengths)) 
                error('lowerThresh is not within range!'); end
            for ii = 1:numel(lengths)
                if lengths(ii) > upperThresh
                    n = n+1;
                    inds(n) = ii; %#ok<AGROW>
                end
            end
            
            fprintf('%s fibers are above [%s = %s] threshold and will be removed.\n',...
                num2str(numel(inds)),param,num2str(upperThresh));
            
            % Remove the fibers  
            fg = fgExtract(fg,inds,'remove');
        end
end


%% Diffusivity Values - 'fa' ,'md', 'ad','rd'

switch param
    case {'fa' ,'md', 'ad','rd'}
        
        % [NOTE: This issue has been resolved in fgExtract]. 
        % Clear the existing stats from the fg. If we don't do this here we
        % get some weird display characteristics when we open them in
        % Quench. (They won't display per-point). This seems to only be an
        % issue when loading from .mat groups created with mrD. 
        
        % fg = dtiClearQuenchStats(fg);
        
        % Return a nifti struct with the given param as niMap.data
        niMap = dtiCreateMap(dt6File,param);
        
        % Attach the stats to the fiber group
        fg = dtiCreateQuenchStats(fg,param,param,[],niMap);

        % Check that the fg struct has a 'params' field (where we expect
        % the values to be). 
        if ~isfield(fg,'params') 
            error('Fiber group does not have a params field'); end
        
        % Get the field number (idx) of the fg.params field containing the
        % fiber values.
        idx = 0;
        for ii = 1:numel(fg.params)
            if isfield(fg.params{ii}, 'lname')
                if strcmp(param, fg.params{ii}.lname)
                    idx = ii;
                end
            end
        end
        % If the idx is still zero we error. 
        if idx == 0, error('No fiber values found for %s!',upper(param)); end

      % Lower Thresh
        if ~isempty(lowerThresh)
            % Start a counter to keep track of the place in the array.
            n = 0;
            
            % Get the averaged values (computed by dtiCreateQuenchStats)
            % across each fiber 
            nFibers = fgGet(fg,'n fibers');
            fiberVals = zeros(1,nFibers);
            for ii=1:nFibers
                fiberVals(ii) = fg.params{idx}.stat(ii);
            end
            
            % Check that the threshold is within range
            if ~(lowerThresh > min(fiberVals)) 
                error('lowerThresh is not within range!'); end
            
            % Loop over the fiberVals array and find the index for each fiber
            % that is below the threshold.
            for ii = 1:numel(fiberVals)
                if fiberVals(ii) < lowerThresh
                    n = n+1;
                    % Store the position of the fiber in inds.
                    inds(n) = ii; %#ok<AGROW>
                end
            end
            
            fprintf('%s fibers are below [%s = %s] threshold and will be removed.\n',...
                num2str(numel(inds)),param,num2str(lowerThresh));
            
            % Remove the fibers 
            fg = fgExtract(fg,inds,'remove');
        end
        
      % Upper Thresh (see Lower Thresh for comments)
        if ~isempty(upperThresh)
            n = 0;
            nFibers = fgGet(fg,'n fibers');
            fiberVals = zeros(1,nFibers);
            for ii=1:nFibers
                fiberVals(ii) = fg.params{idx}.stat(ii);
            end
            if ~(upperThresh < max(fiberVals)) 
                error('upperThresh is not within range!'); end
            for ii = 1:numel(fiberVals)
                if fiberVals(ii) > upperThresh
                    n = n+1;
                    inds(n) = ii; %#ok<AGROW>
                end
            end
            
            fprintf('%s fibers are above [%s = %s] threshold and will be removed.\n',...
                num2str(numel(inds)),param,num2str(upperThresh));
            
            % Remove the fibers  
            fg = fgExtract(fg,inds,'remove');
        end
        
end

fprintf('%s fibers passed threshold.\n', num2str(fgGet(fg,'n fibers')));


%% Some other prarameter ???

% Add it here....


%% Amend the fg.name 

% Rename fibers to reflect that these fibers are thresholded based on
% param. This will prevent fibers from being overwritten when thresholded.
fg.name = [fg.name '_' param 'Thresh'];

return






%%  OLD CODE

% This code was modularized and is now in fgExtract.m
% % %%%%%%%%%%%%%% REMOVE FIBERS FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% function fg = f_removeFibers(fg,inds) %,idx)
% % Given a list of inds, remove the specified fibers and their entries in
% % the 'pathwayInfo', 'params', and 'seeds' fields. 
% 
% % % idx will only exist for the 'fa','md','rd','ad' cases
% % if notDefined('idx'), idx = []; end
% 
% % Flip inds so that the fibers with the highest index are removed first.
% % This must be done so that the size of the array does not change before a
% % given entry is removed. 
% % Make sure inds is 1xN
% if ( size(inds,1) > size(inds,2) )
%     inds = inds';
% end
% % Check to see if the inds list needs to be reordered should be included -
% % which means checking to see if the 1st entry is smaller than the last.
% if ( inds(1) < inds(size(inds,2)) )
%     inds = fliplr(inds);
% end
% 
% 
% % Loop over the fiber group and remove those fibers based on the entries in
% % inds
% for ii = 1:numel(inds)
%     % Remove the actual fiber indicies. 
%     fg.fibers(inds(ii)) = [];
%     % All FGs will have a params field at this point, but we check to be
%     % consistent. If we want this to be even more general we have to loop
%     % over it and see which params fields have an entry that's the size of
%     % the fg.fibers field, or at least larger than 1. This could be done by
%     % determining the number of elements in fg.params, then looping over
%     % fg.params{n} and checking to see if that entry has a 'stat' field -
%     % and if so we remove the corresponding entry listed in 'inds'.
%     if isfield(fg,'params') && ~isempty(fg.params)
%         for kk = 1:numel(fg.params)
%             if isfield(fg.params{kk}, 'stat') && size(fg.params{kk}.stat,2) >= inds(ii)
%                 fg.params{kk}.stat(inds(ii)) = [];
%             end
%         end
% %         fg.params{idx}.stat(inds(ii)) = [];
%     end
%     % Some fiber groups will have other fields (pathwayInfo, seeds, Q). The
%     % corresponding entries in tese fields must also be removed. TO DO:
%     % Look into what other fields might have to be altered. (Q).
%     if isfield(fg,'pathwayInfo')  && ~isempty(fg.pathwayInfo);
%         fg.pathwayInfo(inds(ii)) = [];
%     end
%     if isfield(fg,'seeds') && ~isempty(fg.seeds)
%         fg.seeds(inds(ii),:) = [];
%     end
%     if isfield(fg,'Q') && ~isempty(fg.Q)
%         fg.Q(inds(ii)) = [];
%     end
% end
% 
% return
%     
