function status = reserveToolbox(whichToolbox,tryAndWait)
% reserveToolbox - reserve toolbox, if unavailable don't continue or wait.
%
% status = reserveToolbox(mytoolbox,tryAndWait)
%
% Basically, it tries a function of that toolbox. If successful it
% considers that toolbox reserved. If not, it can try a few more times
% (tryAndWait). I believe using a toolbox function will reserve this
% toolbox until you quit that matlab session. 
%
% 2008/02 SOD: wrote it.

if ~exist('whichToolbox','var') || isempty(whichToolbox)
    error('Need toolbox name');
end
if ~iscell(whichToolbox),
    tmp{1} = whichToolbox;
    whichToolbox = tmp;
end
if ~exist('tryAndWait','var') || isempty(tryAndWait)
    tryAndWait = 1;
end

% We would want to try at least one time and it should be an integer.
if tryAndWait<1,
    tryAndWait=1;
else
    tryAndWait = ceil(tryAndWait);
end

% Time to wait before trying again:
waitTime = 60*10; % 10 minutes

% results
status = false(numel(whichToolbox),1);

for n=1:numel(whichToolbox)
    switch lower(whichToolbox{n})
        case {'optim','optimization'}
            % try a few times
            for ii=1:tryAndWait
                try
                    % toolbox' function call (suppress outputs):
                    warning('off','optim:fminunc:SwitchingMethod');
                    options.Display='none';
                    feval(@fminunc,'sin(x)',1,options);
                    warning('on','optim:fminunc:SwitchingMethod');
                    status(n) = true;
                catch
                    % unsuccessfull: wait and try again
                    if ii<tryAndWait,
                        wait(waitTime);
                    end
                end
                % successfull: continue
                if status(n),
                    break;
                end
            end
            
        otherwise
            error('[%s]:Unknown toolbox (or unincorporated): %s',...
                mfilename,whichToolbox{n});
    end
    
    % output
    if ~nargout
        if status(n)
            fprintf(1,'[%s]:%s toolbox reserved.\n', mfilename,whichToolbox{n});
        else
            % Tough, no luck....
            fprintf(1,'[%s]:WARNING:%s toolbox not available.\n',...
                mfilename,whichToolbox{n});
        end
    end
end


return
