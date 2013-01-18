function fiber_torsion_vals=dtiFiberTorsion(fiber)

%Compute fiber torsion (at every segment long the fiber)
%For 3xn fiber as defined here
%http://en.wikipedia.org/wiki/Torsion_of_curves

%
%ER 12/2007
xprime=gradient(fiber(1, :)); 
yprime=gradient(fiber(2, :)); 
zprime=gradient(fiber(3, :)); 

xpp=gradient(xprime); 
ypp=gradient(yprime); 
zpp=gradient(zprime); 

fiber_torsion_vals=(gradient(zpp).*(xprime.*ypp-yprime.*xpp)+zpp.*(gradient(xpp).*yprime-xprime.*gradient(ypp))+zprime.*(xpp.*gradient(ypp)-gradient(xpp).*ypp))./((xprime.^2+yprime.^2+zprime.^2).*(xpp.^2+ypp.^2+zpp.^2))