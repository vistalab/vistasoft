function str = pvalText(p,texFlag);
% 
% str = pvalText(p, [texFlag=1]);
%
% Create a string representing a p-value.
%
% Problem: The format to use when reporting a statistical
% p-value depends on what that value is. If the p-value is
% not significant, then you usually want  to specify it exactly 
% -- e.g., 'p = 0.25'. If it's significant, you usually want
% to use scientific notation to describe how significant --
% e.g., 'p < 10e-3'.
%
% Solution: this code takes a numerical value (or array of values) p
% and returns a string (or cell array of strings) str, with each element
% printed out as described above.
%
% If the texFlag is set to 1 [default is 1], will format exponents
% in a way suitable for a TeX renderer (e.g., 'p < 10^{-3}'). If set
% to 0, will render in a more human-readable format (e.g., 'p < 10e-3').
% 
% ras 08/05.
% ras 03/07: deals w/ p values that are at or near 0. We impose a minimum
% p value (set to 10^-30, feel free to change), and any p values lower than
% this are reported as p < 10^-30.
if ~exist('texFlag','var') | isempty(texFlag), texFlag = 1; end

minPval = 10^-30; % minimum value to report

if length(p)>1
    for i = 1:length(p)
        str{i} = pvalText(p(i),texFlag);
    end
    return
end

% p ~= 0 check
if p<=minPval, p = minPval; end

if p < 10^(-2)
    bound = num2str(floor(log10(p))); 
    if texFlag==1
        str = sprintf('p < 10^{%s}',bound);
    else
        str = sprintf('p < 10e%s',bound);
    end
else
    str = sprintf('p = %1.2f',p);
end

return