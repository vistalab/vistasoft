function r=fisherzinv(z)
% function r=fisherzinv(z)
% transforms z to r (anti fisher z transform):
%
% rmk, 1/14/99

r=(exp(2*z)-1)./(exp(2*z)+1);

