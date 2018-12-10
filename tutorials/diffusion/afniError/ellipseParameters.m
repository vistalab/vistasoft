%% Ellipsoid parameters
%
% Silson et al. have a very different set of ellipses, far more oriented
% than anyone else.  This was pointed out by a few of us at Stanford, and
% in discussing with Reynolds (the AFNI guy) it turned out that they solved
% the ellipse using
%
%    ax^2 + bxy + cy^2
%
% That's the wrong equation.  The correction equation is
%
%    ax^2 + 2bxy + cy^2
%
% So when the true value is b, they calculate a value of 2b.  This script
% analyses what we expect to find in terms of the ratios of major and minor
% axes if we solve erroneously, as per the AFNI calculation published by
% Silson et al.
%
% The formulae for the ellipsoid calculations are taken from Wolfram in
%
%   http://mathworld.wolfram.com/Ellipse.html
%
% The calculation shows that in many cases the ratio of the lengths of the
% major and minor axes differs quite significantly when one makes the AFNI
% error.
%
% The significance of this calculation is that Silson et al. deny that
% there is a significant difference.  Hence, there is a dispute based on
% mathematics.  Let's check this code and see who is right.
%
% Wandell, September 24, 2018

%% General quadratic notes
%
%  ax^2 + 2bxy + cy^2 + 2dx + 2fy + g=0
%
% For the centered ellipse we have d = f = 0.
% We set g = -1 for this case so
%
%   ax^2 + 2bxy + cy^2 = 1
%
% J = det([ a b; b c]) > 0 and
% D = det([ a b 0; b c 0; 0 0 1])
% I = a + c
% We require D .n.e. 0, J > 0 and D/I < 0
%

%% Set parameters

% These are the three parameters that can be changed
a = 4;
b = 1; originalB = b;
c = 3;

%{
a = 2;  b = 2; c = 3;  % 3.225 and 1.618
%}
g = -1;  % We fix g to -1 because we can always scale a,b and c to make it so

%%  The formulae for the axis lengths from the Wolfram web-page
%
% a' = sqrt((2(af^2+cd^2+gb^2-2bdf-acg))/((b^2-ac)[sqrt((a-c)^2+4b^2)-(a+c)]))
% b' = sqrt((2(af^2+cd^2+gb^2-2bdf-acg))/((b^2-ac)[-sqrt((a-c)^2+4b^2)-(a+c)])).
%
% The formulae below simplify because d=f=0 and g = -1;

b = originalB;
if ellipseValidate(a,b,c,g)
    
    top    = (2*(g*b^2 - a*c*g));
    bottom = (b^2 - a*c)*(sqrt((a - c)^2 + 4*b^2) - (a + c));
    aLength = sqrt(top / bottom);
    
    top    = (2*(g*b^2 - a*c*g));
    bottom = (b^2 - a*c)*(-1*sqrt((a - c)^2 + 4*b^2) - (a + c));
    bLength = sqrt(top / bottom);
    
    mx = max(aLength, bLength);
    mn = min(aLength, bLength);
    fprintf('Ratio 1: %f (b = %.2f)\n',mx/mn,b);
else
    fprintf('Not an ellipse when b = %f\n',b);
end


%% If we incorrectly solve using b2 = 2b
%
% It doesn't really matter whether we use b2 = 2b or b2 = b/2
% The b values are related by a factor of 2 and one is right and the other
% is wrong.  Reynolds says that this has no impact on the ratio of the
% lengths of the two axes.  That is bogus, as running most cases show, such
% as the ones above

b = originalB/2;
if ellipseValidate(a,b,c,g)
    
    top    = (2*(g*b^2 - a*c*g));
    bottom = (b^2 - a*c)*(sqrt((a - c)^2 + 4*b^2) - (a + c));
    aLength = sqrt(top / bottom);
    
    top    = (2*(g*b^2 - a*c*g));
    bottom = (b^2 - a*c)*(-1*sqrt((a - c)^2 + 4*b^2) - (a + c));
    bLength = sqrt(top / bottom);
    
    mx = max(aLength, bLength);
    mn = min(aLength, bLength);
    fprintf('Ratio 2: %f (b = %.2f)\n',mx/mn,b);
else
    fprintf('Not an ellipse when b = %f\n',b);
end


%%  Or if we divide by 2

b = originalB*2;
if ellipseValidate(a,b,c,g)
    
    top    = (2*(g*b^2 - a*c*g));
    bottom = (b^2 - a*c)*(sqrt((a - c)^2 + 4*b^2) - (a + c));
    aLength = sqrt(top / bottom);
    
    top    = (2*(g*b^2 - a*c*g));
    bottom = (b^2 - a*c)*(-1*sqrt((a - c)^2 + 4*b^2) - (a + c));
    bLength = sqrt(top / bottom);
    
    mx = max(aLength, bLength);
    mn = min(aLength, bLength);
    fprintf('Ratio 3: %f (b = %.2f)\n',mx/mn,b);
else
    fprintf('Not an ellipse when b = %f\n',b);
end


%%

