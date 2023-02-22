function y = fit_model(x,k,v)
y = norm((1 - x(1))*(x(2).^(1:k)') - v)^2;