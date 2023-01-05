function y = mean_nan(x)

count = sum(~isnan(x));
x(find(isnan(x)))=0;
y = sum(x)./count;

