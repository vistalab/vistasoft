function result = mse(A, B)
% MSE: mean-squared-error between two matrices/images.
% 
% result=mse(A,B)
%

result = mean(mean(abs(A-B).^2));

