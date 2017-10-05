function k = dtiDirConcFun(s)

% k = dtiDirConcFun(s)
%
% Computes the inverse concentration function k = A^(-1)(1-s) from the Watson
% distribution. If s is the dispersion of a Watson sample, then the MLE of k
% solves A(k) = 1-s.
% If s is a vector, k describes the inverse curve. Interpolate this curve
% to find particular values (see dtiDirConcentration.m)
%
% HISTORY:
%   2004.10.20 ASH (armins@stanford.edu) wrote it.

%h = mrvWaitbar(0, 'Inverting concentration function');
for j = 1:length(s),
    g = 1 - s(j);
    [k(j), fval, exitflag] = Asolve(g);
    if (exitflag==0), fprintf('No convergence at s = %f\n', num2str(s(j))); end
    %mrvWaitbar(j/length(s),h)
end
%close (h)

return

%-------------------------------------------------------
function [k,A,exitflag] = Asolve(g)
    tol = 0.0001;
    err = 1;
    k = 1;
    exitflag = 1;
    while (abs(err)>tol),
        I = Ifun(k);
        A = (1/I - 1)/(2*k);
        if abs(A-g) > abs(err), exitflag = 0; break, end
        err = A - g;
        dA = A + (1-3*A)/(2*k) - A^2;
        k = k - err/dA;
    end
return

function I = Ifun(k)
    t = [1-logspace(0,-6,1000), 1];
	I = trapz(t,exp(k*(t.^2-1)));
return
