function params = initParamsCheck(params);
%
% params = initParamsCheck(params);
%
% For mrInit2: Check that the parameters provided for 
% initializing a session are all specified and within
% reasonable values.
%
%
%
% ras, 09/2006.
if nargin<1, error('Need a params argument.'); end

if ~checkfields(params, 'sessionDir'), params.sessionDir = pwd; end

if ~checkfields(params, 'sessionCode')
    [p f ext] = fileparts(params.sessionDir);
    params.sessionCode = f;
end

if ~checkfields(params, 'description'), params.description = ''; end

if ~checkfields(params, 'scanOrder'), params.scanOrder = []; end

if ~checkfields(params, 'crop'), params.crop = []; end

if ~checkfields(params, 'annotations'), params.annotations = {}; end

if ~checkfields(params, 'parfile'), params.parfile = {}; end

if ~checkfields(params, 'nCycles'), params.nCycles = []; end


% to be continued...


return
