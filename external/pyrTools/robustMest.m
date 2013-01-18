function [p, w] = robustMest(A,b,CB,SC);
% ROBUSTMEST - Robust M-estimator
% Solves the problem A*x=b using a robust M-estimator (iterative WLS with Beaton
% and Tukey's weighting function)
%
% Returns the solution (p) and the final weights (w)
%
%  [p,w]=robustMest(A,b);
%

[Ne Ni] = size(A);

MAXITER=100;     % maximum numner of iterations

% default values
if nargin<4
   SC  = 1.4826;
elseif isempty(SC)
   SC  = 1.4826;
end
if nargin<3
   CB=4.685;
elseif isempty(CB)
   CB=4.685;
end

Eant=Inf; Eact=1e20;
w=ones(Ne,1); r=w;
niter=1; 
pact=zeros(Ni,1);

while (Eant>Eact(niter))&(niter<MAXITER)&(Eact(niter)>eps)
   % save previous values     
   niter=niter+1;
   Eant=Eact(niter-1);
   pant=pact;
   want=w;
   
   % recompute weights
   if niter>2
      sigma = SC*median(abs(r-median(r)));
      r=r/sigma;
      w=(1-abs(r/CB).^2) .* (abs(r)<=CB);
   end
   
   % solve WLS with the new weights 
   Aw = A.*repmat(w,[1 Ni]);
   bw=((b-A*pant).*w);
   pact = pant + pinv(Aw)*bw;
   
   % compute residual and total errors
   r = (b - A*pact);
   Eact(niter)=sum((w.*abs(r)).^2)/sum(w.^2);
end

if (Eact(niter)>Eant)
   % take previous values (since actual values made the error to increase)
   p = pant;
   w = want;
else
   p = pact;
   w = w;
end

