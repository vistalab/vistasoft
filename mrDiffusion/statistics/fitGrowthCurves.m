function [beta, PSI, stats, b, FixedEffectPValues, numObsPerGroup, RMS] =fitGrowthCurves(predictor, predictor_title, predicted, predicted_title, subjectInitials, NUMS,  model, printStatsSummary, variableTitles, method, indCurvesColor)
%Fit and display individual growth curves
%
% [beta, PSI, stats, b] = fitGrowthCurves(predictor, predictor_title, predicted, predicted_title, subjectInitials, [NUMS], [model], [printStatsSummary], [variableTitles], [indCurvesColor])
% 
% Input: Predictor/Predicted: Subjects&Year combos are rows;  
%        predictor: nsubjects_years; predicted: nsubjects_yearsXvariable,
%        NUMS marks entries from the same subject.  
% Note: Models are fitted independently for each predicted variable (e.g.,
%        fiber group)! 
%        Method: 'per subject', 'mle' subjectInitials: a list of
%        strings variableTitles(optional): a list of strings with names for
%        variables, used to put titles to subplots Model: by default 
%        linear model  with mixed (fixed+random) effect on both intercept 
%        and slope
%        indCurvesColor: by default each individual curve will be colored
%        by a color from rainbow. You can also supply a single color for
%        ALL individual curves. 
%
% Output: beta: "group-level" model parameters. b: random coefficients (if
% MLE) or individual fit coefficient (if per subject). To compare side by
% side, add beta to random coefficient.
%
%(1) Generates plots (individual subplot per variable) TODO-- 1.1
%individual data lines + mean-centered individual curves 1.2 individual
%curve fits (including fixed & random effects) TODO -- 1.3 individual data
%lines+ fixed effect (group effect) fit (2)  Prints out stats regarding
%model fit b contains modelParamsXnsubjects random coefficients estimated.
%numObsPerGroup contains nsubjectsXvariable indicating how many
%observations contributed into estimating each random coef. 

%Advanced info on models: ----------------------------------------- If you
%think estimates of random effects are too small (to be neglected), use
%{'REParamsSelect', [vectorOfParamsToEstimate=e.g., [2]]}  for nlmefit  and
%zero respective b's for plotting Currently covariance pattern is
%unconstrained, allowing for covariance among the random effects. If you
%think they should not be correlated (therefore the model will have less
%params to estimate, use {'CovPattern', eye(p)} for nlmefit; The default
%model is linear with with mixed (fixed+random) effect on both intercept
%and slope. Other options: model.p=3; model.function =
%@(PHI,t)(PHI(1))./(1+exp(-(t-PHI(2))./PHI(3))); %Exponential growth
%model.p=3; model.function = @(PHI,t)(PHI(1) + PHI(2)*t + PHI(3)*t.^2 );
%%Squared growth 
%
%TODO: Significance of random effects? (can be done?) TODO: how do we go
%about LR symmetric things? TODO: check that there are at least 2 or 3
%points per subject ----------------------------------------

%ER 10/26/2009 wrote it
if ~strmatch(version('-release'), '2008b')
error('This function uses nlmefit which is only avail in Matlab version 2008b');    
end

%Recode NUMS to indices
[temp, temp, c]=unique(NUMS); 
NUMS=c; 

numSubjects=length(unique(NUMS));
 numVariables=size(predicted, 2); 
numObsPerGroup=zeros(numSubjects, numVariables); 

if exist('variableTitles', 'var') && length(variableTitles)~=numVariables
error('wrong length for variableTitles'); 
end
if ~exist('variableTitles', 'var') || isempty( variableTitles)
    indices=1:numVariables; 
    variableTitles=cellstr(int2str(indices')); 
end

if ~exist('model', 'var') || isempty(model)|| ~isstruct(model)
model.p=2; model.function = @(PHI,t)(PHI(1) + PHI(2)*t); %Basic linear(intercept/slope)

end
if ~exist('printStatsSummary', 'var') || isempty( printStatsSummary)
 printStatsSummary=true; 
end





%Quickly plot raw data
%------------------------
%Figure out max number of points
maxYrs=max(hist(NUMS, length(unique(NUMS))));
%figure;
for variable=1:numVariables
    response=predicted(:, variable);
    if numVariables~=1
h=subplot(round(sqrt(numVariables)), ceil(sqrt(numVariables)), variable);
    else
    end
%Pad nonexisting years by zero values);
clear responseR; responseR(1:numSubjects, 1:maxYrs)=NaN; 
clear predictorR; predictorR(1:numSubjects, 1:maxYrs)=NaN; 
for ind=unique(NUMS)
    responseR(ind, :)=response(NUMS==ind); 
    predictorR(ind, :)=predictor(NUMS==ind); 
end
f=plot(predictorR(1:numSubjects, :)',responseR(1:numSubjects, :)','-o','LineWidth',1);
if exist('indCurvesColor', 'var') && ~isempty(indCurvesColor)
set(f, 'Color', indCurvesColor); 
end

xlabel(predictor_title)
ylabel(predicted_title)
title(['\bf' variableTitles{variable}]);
if ~isempty(subjectInitials)
legend(subjectInitials(1:numSubjects), 'Location','NW')
end
grid on
hold on

%Get rid of NaN entries. TODO: check that there are at least 2-3 points per
%subject per FG. 
  predictorNoNaNs=predictor(~isnan(response));     
  NUMSNoNaNs=NUMS(~isnan(response));    
  response(isnan(response))=[]; 
numObsPerGroup(:, variable)=hist(NUMSNoNaNs(:), numSubjects); 
  
beta0 = repmat(-1, [1 model.p]);



switch method
    case 'per subject'
%Fit lines per subject. To account for subject-specific effects, fit the
%model separately to the data for each subject:
phi0 = ones([1 model.p]);
for I = unique(NUMS)
    tI = predictorNoNaNs(NUMSNoNaNs == I);
    cI = response(NUMSNoNaNs == I);
try
    [b(:,I, variable),RES, J, PSI(:, :, variable, I), stats.mse(variable, I)] = nlinfit(tI,cI,model.function,phi0);
catch
    
    b(:,I, variable)=zeros([1 model.p]).*NaN; PSI(:, :, variable, I)=zeros(model.p).*NaN;  stats.mse(variable, I) =NaN;
end
end

%gscatter(predictorNoNaNs,response,NUMSNoNaNs);
xlabel(predictor_title);
ylabel(predicted_title)
ht=title(['\bf' variableTitles{variable}]);
set(ht, 'FontSize', 16); 
hold on
colors = get(f,'Color');
for I = 1:numSubjects
   tplot = predictorNoNaNs(NUMSNoNaNs == I);
  % plot(tplot,model.function(b(:,I, variable),tplot),'Color',colors{I}, 'LineWidth',2);
end
beta(:, variable)=mean(b(:, :, variable),2); 
FixedEffectPValues(:, variable)=NaN.*beta(:, variable); 

    case 'mle'
%Fit a proper simultaneous MLE model
b=zeros(model.p, 1, 1); 
REParamsSelect=[1]; %Note: by setting 'REParamsSelect',[1 3] we allow for random intercept only...

[beta(:, variable),PSI(:, :, variable),stats(variable),b(REParamsSelect, unique(NUMSNoNaNs), variable)] = nlmefit(predictorNoNaNs(:),response(:),NUMSNoNaNs(:),...
     [],model.function,beta0, 'CovPattern', ones(length(REParamsSelect)), 'REParamsSelect',REParamsSelect); %Unconstrained covariance matrix -- by default would be eye
%The covariance pattern is eye(r), corresponding to uncorrelated random effects.
%Here  beta1 is fixed effects and b1 are random effects for the 5 groups; and PSI is cov among the random effects.  Where are the significance values? 


PHI = repmat(beta(:, variable)',numSubjects, 1) + ...          % Fixed effects
      b(:, :, variable)';    % Random effects
tplot = min(predictor(:)):0.1:max(predictor(:));
colors = get(f,'Color');
 
for I = 1:numSubjects
    %fitted_model = @(t)(PHI(I, 1) + PHI(I, 2)*t); 
    fitted_model=model.function(PHI(I, :), tplot');
    subplot(h);
    plot(tplot,fitted_model,'Color',colors{I},'LineWidth',2)
end
FixedEffectPValues(:, variable)=1- chi2cdf(beta(:, variable).^2./(stats(variable).sebeta').^2, 1); %

%To get significance value, use beta2.^2./(stats2.sebeta').^2: this is Wald-type test which, under H0, has asymptotically a chi-square distribution with 1 degree of freedom. 
%Strategy taken from here http://dx.doi.org/10.1016/j.csda.2003.10.005

    otherwise
        error('Can only fit lines per subject or mle'); 
end

predictedY=model.function(beta(:, variable), predictor(:)); 
RMS(variable) = sqrt(mean((predictedY-predicted(:, variable)).^2));
fprintf(1, 'RMS %s\n', RMS(variable));

%ONE OVERALL MODEL FIT GIANT LINE
plot(min(predictor(:)):0.1:max(predictor(:)),model.function(beta(:, variable),min(predictor(:)):0.1:max(predictor(:))), '--*', 'Color', 'black', 'LineWidth',3);

if printStatsSummary & strmatch(method, 'mle')
    format short ;
    fprintf(1, 'Predictor: %s, response variable: %s \n', predictor_title, variableTitles{variable});
    fprintf(1, 'ESTIMATES OF FIXED EFFECTS\n');
    fprintf(1, 'P-values are obtained using Wald-type test \n');  
fprintf(1, '------------------------------------------------------------------\n');
    fprintf(1, '%s \t  %s \t %s \t  %s \n', 'Param', 'Estimate', 'SE', 'p-value');
fprintf(1, '------------------------------------------------------------------\n');
 
    fprintf(1, '%d \t  %04.2d \t %04.2d \t %4.3f \n', [(1:model.p)' beta(:, variable) stats(variable).sebeta' FixedEffectPValues(:, variable)]');
fprintf(1, '\n'); 
    fprintf(1, 'CORRELATION OF RANDOM EFFECTS\n');
 %Highest  ever corr b/w intercept and slope random effects... In this case, those with smaller GM volume have positive growth, whereas those with high initial GM volume have reduction of GM proportion...    
  REC=corrcov(PSI(:, :, variable));
  display(REC);
    fprintf(1, 'GOODNESS OF FIT CRITERIA\n');
  display(stats(variable));

end
end        
return