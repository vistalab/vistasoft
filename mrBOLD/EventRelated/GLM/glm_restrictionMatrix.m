function RM = glm_restrictionMatrix(test, nh, nc, active, control, tcWeights)
%
% RM = glm_restrictionMatrix(test, nh, nc, active, control, [tcWeights])
%
% For GLM toolbox, creates a restriction matrix, used for testing
% particular predictors against one another in a statistical contrast:
%
% test - String (case insensitive) indicating the test to perform:
%   t  - t-Test, RM will be a row vector
%   tm - t-Test, different p for each delay point (RM same as Fc)
%   Fm - F-Test, different p for each delay point
%   F0 - RM same as t-Test
%   Fd - F-test, different row for each delay, all conditions
%        for each delay on the same row
%   Fc - F-test, different row for each condition, all delays
%        for a condition on the same row
%   Fcd - F-test, different row for each condition for each delay
% nh - total number of elements in HDIR
% nc - total number of stimulus conditions (including fixation)
% active - list of active conditions
% control - list of control conditions
% tcWeights - list of frames in the deconvolved time course to
%             use for the test. [default: all]
%
% Eg: glm_restrictionMatrix('t',10, 6, [1 3], [2 5], [3 6:9])
% Generates an RM for testing conditions (1+3)-(2+5) using
% components 3,6,7,8, and 9 in the HDIR.  Conditions 0 and 4 
% are not tested. There are 10 components in the HDIR, and 5 
% stimulus conditions.
%
% ras 02/05; based on fs-fast code glm_restrictionMatrix.m
if ieNotDefined('tcWeights')
    tcWeights = [1:nh];
end

% Check for the correct number of arguments %
if nargin < 5
    error('USAGE: RM = glm_restrictionMatrix(test, nh, nc, active, control, <tcWeights>)');
end

% Check the Test Type %
if( isempty( strmatch(upper(test),{'T ','TM','FM','F0','FD','FC','FCD','FDC'},'exact')))
    error(sprintf('Unkown test %s',test));
end  

%% check that the input parameters are correct %%
if(nh < 1)
    error('nh must be greater than 0');
end
if(nc < 1)
    error('Number of conditions must be greater than 0');
end
if(length(find(active<0 | active > nc)))
    error('Invalid condition number in active');
end
if(length(find(control<0 | control > nc)))
    error('Invalid condition number in control');
end

% Test that the same condition is not in both active and control %
if ~isempty(intersect(active, control))
    error('Same condition is in both active and control');
end

% Test that specified tc weights are in range
if any(find(tcWeights<1 | tcWeights > nh))
    error('Invalid tcWeights Component');
end

% Strip Condition 0 from active (if there) %
iACnz = find(active ~= 0);
if( ~ isempty(iACnz) )
    active = active(iACnz);
end

% Strip Condition 0 from control (if there) %
iCCnz = find(control ~= 0);
if( ~ isempty(iCCnz) )
    control = control(iCCnz);
end

%% -------- Generate the restriction matrix -------- %%
switch(upper(test))
    case {'T','F0'}, 
        RM = glm_restrictionVector(nh,nc,active,control,tcWeights);
    case {'FD','TM','FM'},     
        for n = 1:length(tcWeights),
            RV = glm_restrictionVector(nh,nc,active,control,tcWeights(n));
            RM(n,:) = reshape(RV', [1 prod(size(RV))]);
        end
    case {'FC'},
        for n = 1:length(iACnz),
            RV = glm_restrictionVector(nh,nc,active(n),0,tcWeights);
            RM(n,:) = reshape(RV', [1 prod(size(RV))]);
        end
        for n = 1:length(iCCnz),
            RV = glm_restrictionVector(nh,nc,0,control(n),tcWeights);
            RM(n+length(active),:) = reshape(RV', [1 prod(size(RV))]);
        end
    case {'FCD','FDC'},
        RM = [];
        for n = 1:length(iACnz),
            RV = glm_restrictionMatrix('Fd',nh,nc,active(n),0,tcWeights);
            RM = [RM; RV;];
        end
        for n = 1:length(iCCnz),
            RV = glm_restrictionMatrix('Fd',nh,nc,0,control(n),tcWeights);
            RM = [RM; RV;];
        end
end

return

