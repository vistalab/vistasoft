function p = er_ttest(dof, t, dofApprx)
% Event-related t-test computation
%
%   pSig = er_ttest(dof, t, <dofApprx>)
%
% Compute the p-value corresponding to a selected t value and degrees of
% freedom (dof) in a Student's t distribution. Used in event-related
% analyses.
%
% If dofApprx is not set, tTest() computes the significance level of t
% given dof using the formula:
%
%    z = dof./(dof + t .^ 2);
%    pSig = betainc(z,dof/2,0.5);
%
% When dofApprx is set, an approximation is used
% when dof exceeds dofApprx:
%    p = erfc(abs(t)/sqrt(2.0));
% This can speed the function considerably when
% the dof is large.
%
% Ref: Numerical Rec in C, pg 229.
%
% ras, 04/05: deals w/ NaNs better
% keep track of NaNs in the data, the 
% beta incomplete calculation can't cope:
if nargin < 2, error('Usage: p = tTest(dof, t, <dofApprx>)');  end
if(length(dof) > 1), error('dof must be a scalar');            end

% If dofApprx is unspecified, do not Approx %
if nargin==2, dofApprx = -1;                                   end

% temporarily zero out NaNs
nanInd = find(isnan(t));
t(nanInd) = 0;

if(dof < dofApprx) || (dofApprx < 0)  
    z = dof./(dof + t .^ 2);  
    p = betainc(z,dof/2,0.5);
else  
    p = erfc(abs(t)/sqrt(2.0));
end

% plug back in NaNs where appropriate
p(nanInd) = NaN;

return
