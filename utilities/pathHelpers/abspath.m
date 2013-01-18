function pth = abspath(pth, makeIfNeeded);
% Return an absolute path specification, parsing any relative
% path specifications.
% 
% pth = abs(pth, [makeIfNeeded]);
%
% If the optional makeIfNeeded flag is set to 1 [default 0], 
% will try to create the directory if it doesn't exist.
%
% ras, 10/2005.
if ~exist('makeIfNeeded', 'var') | isempty(makeIfNeeded)
    makeIfNeeded = 0;
end

callingDir = pwd;

[p f ext] = fileparts(pth);

% try to cd to the parent directory -- that'll make the pwd
% function return an absolute path to the parent:
try 
    cd(p); 
catch 
    % maybe the directory doesn't exist, but we want to make it?
    if makeIfNeeded==1
        fprintf('Couldn''t find directory %s -- \n', pth);
        fprintf('Trying to make it ... ');
        try
            mkdir(p);
            disp('Suceeded.');
        catch
            disp('Failed. '); cd(callingDir); return % don't error though
        end
    else
        % can't disentangle the path, but return anyway
        cd(callingDir); 
        return 
    end       
end

pth = fullfile(pwd, [f ext]);

cd(callingDir);

return


% Older (not sensitive to paths specified as ../../blah/):
% [p f ext] = fileparts(pth);
% if isempty(p), p = pwd; end
% pth = fullfile(p,[f ext]);

    