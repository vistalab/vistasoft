function err = dtiRawTensorErr(x, m, X, sigmaSq, gmmFlag)
%
% err = dtiRawTensorErr(x, m, X, sigmaSq, gmmFlag)
%
% inputs:
%    x: the 7 tensor parameters (b0 and 6 unique elements of the diffusion tensor)
%    m: the nx7 measurements
%    X: -B, where B = the nx7 b-matrix
%    sigmaSq: signal standard deviation squared.
%             E.g., sigmaSq = (1.5267 * stdev(background_noise))^2
%    gmmFlag: if true, a weighted least-squares error is computed using the
%             Geman-McClure M-estimator (GMM)to compute the weights. Note
%             that these weights are based on the residuals from the
%             initial paramaters (x).
%
% Output: SSE
%    
% 2008.09.05 RFD wrote it.

y = exp(X*x);

% compute residuals
r = m - y;
rSq = r.^2;

if(gmmFlag)
    % CSq is the square of the C parameter from Chang et. al.:
    % C = 1.4826*MAD, where MAD=median(|r1-rh|, |r2-rh|, ... |rn-rh|)
    % where rh = median(r1 r2,... rn) and n is the number of data
    % points. The multiplicative constant 1.4826 makes this an
    % approximately unbiased estimate of scale when the error model is
    % Gaussian.
    rh = median(r);
    CSq = 1.4826 * median(abs(r-rh));
    w = 1./(rSq+CSq);
    % Weights should be normalized to the mean weight (pg. 1089):
    w = w/mean(w);
    
else
    w = 1./sigmaSq;
end

err = sum(w.*rSq);

return;
