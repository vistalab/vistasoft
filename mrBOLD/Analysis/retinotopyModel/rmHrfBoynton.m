function [h]=rmHrfBoynton(t,params)
% Create an HRF based on Boynton et al (1996)
%
% [h]=rmHrfBoynton(t,[params])
%
% % t : a range of latencies
% params(1) : the time constant Tau-'width' (sec)
% params(2) : phase delay (integer)
% params(3) : delay (shift of entire function)
% from Boynton et al, J. Neurosci July 1 1996. 16(13):4207-4221
% they used  T=1.08->1.68, n=3, delay ~2
%
% Example 1 Use defauls.
%   tr = 1.5;
%   t  = tr * (0:50);
%   h = rmHrfBoynton(t);
%   figure; plot(t, h); 
%   xlabel('time (seconds)'); 
%   ylabel('response');
%
% Example 2 Put in your own parameters
%   tr = 1.5;
%   t  = tr * (0:50);
%   params = [2 3 3];
%   h1 = rmHrfBoynton(t);
%   h2 = rmHrfBoynton(t, params);
%   figure; plot(t, h1, 'r', t, h2, 'g'); 
%   xlabel('time (seconds)'); 
%   ylabel('response');
%   legend('Default', 'Subject specfic');
%
% JW: 3/2011: split off from rfConvolveTC.m

if nargin<2 || isempty(params),
    params=[1.68 3 2.05];
end;
if numel(params)>=3,
    % account for the early delay by shifting time:
    t = t-params(3);
end;

% set negative values to zero
t = max(t,0);

% gamma function
h = ( (t./params(1)).^(params(2)-1) ).*exp(-t./params(1));
% decided to skip this last step which basically scales the
% amplitude. This is irrelevant since later on the HRF is
% normalized either to its peak or volume. Now params(2), 'phase
% delay' does not have to be an integer.
%h = h./(params(1)*factorial(round(params(2))-1));


%h=h./sum(h); %  normalize

return;
