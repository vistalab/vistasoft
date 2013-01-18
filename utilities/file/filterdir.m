function [outdir] = filterdir(pattern,targetdir);
% FILTERDIR: Take 'dir' struct data selectively for entries
% in a directory that match [pattern].
% Usage: [outdir] = filterdir(pattern,[targetdir]);
%
% The output 'outdir' is a struct like the output of a 'dir' command,
% but filtered for entries whose name contains the specified pattern.
%
% 'targetdir' is an optional argument specifying which directory to 
% look in. It defaults to the current directory.
% 
% 4/20/02 by RAS.
%
if nargin < 2
	targetdir = pwd;%[outlist] = filterdir(pattern,targetdir);
end
callingDir = pwd;
w = dir(targetdir);
A = ones(length(w),1);
for i = 1:length(w)
	if isempty(findstr(w(i).name,pattern)) | length(w(i).name) < 3
		A(i) = 0;	% entry does not contain pattern
	end
end

outdir = w(find(A));

return
