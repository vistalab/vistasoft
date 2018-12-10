function fout = mrvWaitbar(x,varargin)
% mrVista wrapper for waitbar
% fout = mrvWaitbar(x, varargin)
%
% The purpose of the wrapper is to check whether VISTA preferences for
% 'verbose' are set to true or false, and if false, then to skip calling
% the waitbar. 
%
% EXAMPLE 1
% setpref('VISTA', 'verbose', true);
% fout = mrvWaitbar(0,'This waitbar is visible')
% pause(1); close(fout)
%
% Example 2
% setpref('VISTA', 'verbose', false);
% fout = mrvWaitbar(0,'There should be no waitbar')
%
% NYU vista team 2017

if ~ispref('VISTA'), setpref('VISTA', 'verbose', false); end
verbose = getpref('VISTA', 'verbose');

% The way we call waitbar depends on whether there are extra input
% arguments (varargin) and whether there is an output argument
varsin  = ~isempty(varargin);
varsout = nargout;

if verbose    
    if varsin  &&  varsout, fout = waitbar(x, varargin{:}); end
    if varsin  && ~varsout,        waitbar(x, varargin{:}); end
    if ~varsin &&  varsout, fout = waitbar(x);              end
    if ~varsin && ~varsout,        waitbar(x);              end               
else
    if varsout, fout = []; end   
end

end