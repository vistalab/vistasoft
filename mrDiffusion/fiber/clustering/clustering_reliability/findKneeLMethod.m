function currentknee=findKneeLMethod(EvaluationMetric, maxNclusters)

%Implemented L-method to define number of clusters within the data
%Coded by ER 09/2008 
%Original method from  Salvador& Chan (2004) "Determining the Number of Clusters/Segments in
%Hierarchical Clustering/Segmentation Algorithms"; DOI  	 10.1109/ICTAI.2004.50

if(~exist('maxNclusters','var')||isempty(maxNclusters))
    maxNclusters=size(EvaluationMetric, 2);
end

%1. Discard everyting to the left of the max EvaluationMetric value
[Y, I]=max(EvaluationMetric);
skipI=I-1;
EvaluationMetricCropped=EvaluationMetric(I:end); 
maxNclustersCropped=maxNclusters-(skipI);
cutoff=maxNclustersCropped
lastknee=maxNclustersCropped+1; currentknee=maxNclustersCropped;

%2. Iterative refinement -- so far replaced by setting maxNclusters to a
%reasonable value
figure; 
subplot(1, 2, 1); plot(EvaluationMetric, 'o-');

[currentknee lastknee]

while currentknee<lastknee
lastknee=currentknee;
currentknee=fitKneeLines(EvaluationMetricCropped, cutoff, skipI);
cutoff=currentknee*2;
%first 2 values of obtained rmse are zero because 
%x=2...c (we are not interested in evaluation metrics for one cluster only)
%rmse can not be estimated for c=2: there is not enough data points to
%estimate the fit. Naturally c beyond 3:(maxNclusters-2) is zero or Inf
hold on;  plot(currentknee, EvaluationMetric(currentknee), 'rs', 'MarkerSize',10,  'MarkerEdgeColor','k', 'MarkerFaceColor','m');
end


subplot(1, 2, 2); plot(EvaluationMetric, 'o-'); hold on; 
plot(currentknee, EvaluationMetric(currentknee), 'rs', 'MarkerSize',10,  'MarkerEdgeColor','k', 'MarkerFaceColor','m');

%%%%%%%%%

function fullc=fitKneeLines(EvaluationMetricCropped, maxNclustersCropped, skipI)
%skipI is the shift factor (number of points skipped at the beginning)
if maxNclustersCropped<20
    maxNclustersCropped=20;
end

for c=3:(maxNclustersCropped-2)
left=regstats(EvaluationMetricCropped(2:c)',2:c,'linear', {'mse', 'yhat'});
right=regstats(EvaluationMetricCropped(c+1:maxNclustersCropped)',c+1:maxNclustersCropped,'linear',  {'mse', 'yhat'});
 hold on; plot(skipI+2:skipI+c, left.yhat, 'r-'); hold on; plot(skipI+c+1:skipI+maxNclustersCropped, right.yhat, 'g-'); 
rmse(c)=((c-1)/(maxNclustersCropped-1))*sqrt(left.mse)+((maxNclustersCropped-c)/(maxNclustersCropped-1))*sqrt(right.mse); 
end
[X, J]=min(rmse(3:maxNclustersCropped-2)); fullc=J+2+skipI;
