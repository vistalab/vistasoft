function matrix = rmAverageTime(matrix,nrep);
% rmAverageTime - average non-unique epochs in time (1st) dimension
%
%  out = rmAverageTime(in,nrep);
%
% 2006/03 SOD: wrote it.

% sanity check (<1 no averaging needed)
if nrep <= 1,
  return;
else,
  matrixin = matrix;
end;


% get total size input
sz  = size(matrixin);

% get total size output
len      = sz(1)./nrep;
szout    = sz; 
szout(1) = len;

% initiate matrixout
matrix   = matrixin(1:len,:);

% repeat (add) process 
start = len;
for n=1:nrep-1,
    matrix = matrix + matrixin(start+1:start+len,:);
    start     = start + len;
end;

% mean
matrix = matrix ./ nrep;

% reshape if necesary
matrix = reshape(matrix,szout);

return
