function [y n] = var_nan(x)

for ii=1:size(x,2)
    tmp = x(:,ii);
    tmp(isnan(tmp))=[];
    y(ii)=var(tmp);
    n(ii)=size(tmp,1);
end
