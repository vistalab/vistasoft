function [t,df,RSS,B]=rmGLM(Y,X,C)
% rmGLM - simple general linear model for retinotopy model
% [t,df,RSS,B]=rmGLM(Y,X[,C]);
%
% Y  : data         (time,voxels)
% X  : design model (time,models)
% C  : contrast in X [default = [1 0 0 ... size(X,2)]]
%                   (different contrasts,size(X,2))
%      example [1 0 0; 1 -1 0]
%      computes t-values of first column in X and difference first
%      and second column in X.
%
% output:
% t  : t-values     (size(C,1),size(Y,2))
% df : degrees of freedom
% RSS: residual sum of squares
% B  : beta of fit
%

% 2006/01 SOD: wrote it.
% 2006/03 SOD: vectorized.

% Programming note:
% This is now the slow part of rmMain and is called lots (at least
% once for every RF) - thus any speed improvements will help. 

% apparently ieNotDefined takes a quarter of the processing time of
% this function so if it is seems that all arguments are there skip
% it.
if nargin ~= 3,
  if ~exist('Y', 'var') || isempty(Y), error('Need Y'); end; 
  if ~exist('X', 'var') || isempty(X), error('Need X'); end; 
  if ~exist('C', 'var') || isempty(C), 
    % use first X predictor
    C    = zeros(1,size(X,2)); 
    C(1) = 1; 
  end;
end;

% degrees of freedom
df = size(Y,1) - rank(X);

% Pseudoinverse of X (save so we only have to do this once)
pinvX = pinv(X);

% beta fit
B = pinvX*Y;

% residual error (this is actually THE slowest process)
RSS  = sum((Y - X*B).^2);
MRSS = RSS./df;

% get t-statistic The contrasts are comparisons between different 
% conditions represented in the columns of X.
% 
% The entries of C are typically C = [1 0 .... -1 .... 0] in each row.
% This produces a contrast between the condition in the first column of X
% and the one in the nth column.

% error
SE  = sqrt(diag(C*(pinvX*pinvX')*C')*MRSS);

% t-values
t   = C*B./SE;


return;

% p 
%p    = 0.5*betainc(df./(df+t.^2),df/2,0.5);
