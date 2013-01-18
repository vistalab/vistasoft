function RV = glm_restrictionVector(nh, nPredictors, active, control, tcWeights)
%
% RV = glm_restrictionVector(nh, nPredictors, active, control, tcWeights)
%
% Creates a restriction vector of dimension 1 X nPredictors*nh
%
% nh - total number of elements in HDIR
% nPredictors - total number of stimulus conditions (including fixation)
% active - list of active conditions
% control - list of control conditions
% tcWeights - list of HDIR components to test (default: all).
%
% Eg: fmri_vrestriction(10, 6, [1 3], [2 5], [3 6:9])
% Generates an RV for testing conditions (1+3)-(2+5) using
% components 3,6,7,8, and 9 in the HDIR.  Conditions 0 and 4 
% are not tested. There are 10 components in the HDIR, and 5 
% stimulus conditions.
%
%
% ras, 02/05, adapted from fs-fast code in fmri_vrestriction for
% internal lab use. We do some things differently, though. 
% E.g., does not assume there are null conditions present and
% remove them.
if ieNotDefined('tcWeights')
    tcWeights = [1:nh];
end

% Check for the correct number of arguments %
if(nargin ~= 4 & nargin ~= 5)
    error('USAGE: glm_restrictionVector(nh, nPredictors, active, control, <tcWeights>');
    return;
end

%% check that the input parameters are correct %%
if(nh < 1)
    error('nh must be greater than 0');
end

if(nPredictors < 1)
    error('Number of conditions must be greater than 0');
end

if any(active<0 | active > nPredictors)
    error('Invalid condition number in active');
end

if any(control<0 | control > nPredictors)
    error('Invalid condition number in control');
end

% Test that the same condition is not in both active and control %
C = [active control];
for n = 1:nPredictors,
    if(length(find(C==n)) > 1)
        error('Same condition is in both active and control');
    end
end

% test that tc weights are in range
if(length(find(tcWeights<1 | tcWeights > nh)))
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
RV = zeros(nPredictors,nh); 
if( ~ isempty(iACnz) )
    RV(active,tcWeights) =  ones(length(active),length(tcWeights)) ./ length(active);
end
if( ~ isempty(iCCnz) )
    RV(control,tcWeights) = -ones(length(control),length(tcWeights)) ./ length(control);
end
RV = reshape(RV', [1 prod(size(RV))]);

return

