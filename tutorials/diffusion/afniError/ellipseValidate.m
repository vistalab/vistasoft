function bool = ellipseValidate(a,b,c,g)
%
% Check that the four parameters satisfy the ellipse requirement
%
% Wandell, September 2018
%
% See also ellipseParametes

q = [a b; b c];
D = det([ a b 0; b c 0; 0 0 g]);
J = det(q);
I = a+c;

bool = false;
if J <= 0,   fprintf('J fails to be non-negative\n'); return; end
if D == 0,   fprintf('Singular\n'); return; end
if D/I >= 0, fprintf('Final D/I requirement\n'); return; end

% Made it to here, so it must be OK
bool = true;

end