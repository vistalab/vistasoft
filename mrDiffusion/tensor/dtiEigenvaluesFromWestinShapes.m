function [l1, l2, l3]=dtiEigenvaluesFromWestinShapes(cl, cp, vol, method)
%V is the volume of original tensor
%solution
%Method specifies whether the Westin shapes aligned are computed with
%simple ("new") denominator, l1, or original definition (old) denominator,
%l1+l2+l3
if ~exist('method', 'var')
    method='westinShapes_l1';
end


switch method
    case 'westinShapes_l1'
%westin shapes are new(simplified) versions, NOT the ones computed by dtiComputeWestinShapes: 
%cl=(l1-l2)/l1; 
%cp=(l2-l3)/l1;
%cs=l3/l1;

l1_sol(:, 1)=-((-3/pi).^(1/3).*vol.^(1/3))./(2^(2/3).*((-1+cl).*(-1+cl+cp)).^(1/3)); 
l3_sol(:, 1)=(-1+cl+cp).*l1_sol(:, 1); 
l1_sol(:, 2)=(3/pi)^(1/3)./(2^(2/3).*(((-1+cl).*(-1+cl+cp))./vol).^(1/3));
l3_sol(:, 2)=-(-1+cl+cp).*l1_sol(:, 2); 
l1_sol(:, 3)=-((-1)^(2/3).*(3/pi)^(1/3))./(2^(2/3).*(((-1+cl).*(-1+cl+cp))./vol).^(1/3));
l3_sol(:, 3)=(-1+cl+cp).*l1_sol(:, 3); 

    case 'westinShapes_lsum'
%westin shapes as those computed by dtiComputeWestinShapes: 
%cl=(l1-l2)/(l1+l2+l3); 
%cp=(l2-l3)/(l1+l2+l3);
%cs=l3/(l1+l2+l3);

%I am not sure whether the results produced by this method make sence -- at
%least when protted in barycentric coordinates. If you want to use it,
%check the code.

l1_sol(:, 1)=-((3/pi).^(1/3).*(-(2+4*cl+cp).^2.*vol).^(1/3))./(2*((-2+2*cl-cp).*(-1+cl+cp)).^(1/3));
l3_sol(:, 1)=-2*l1_sol(1).*(-1+cl+cp)./(2+4*cl+cp);
l1_sol(:, 2)=((3/pi).^(1/3))./(2*(((-2+2*cl-cp).*(-1+cl+cp))./((2+4*cl+cp).^2.*vol)).^(1/3));
l3_sol(:, 2)=-2*l1_sol(2).*(-1+cl+cp)./(2+4*cl+cp);
l1_sol(:, 3)=((-1).^(2/3).*(3/pi).^(1/3))./(2*(((-2+2*cl-cp).*(-1+cl+cp))./((2+4*cl+cp).^2.*vol)).^(1/3));
l3_sol(:, 3)=-2*l1_sol(3).*(-1+cl+cp)./(2+4*cl+cp);

    otherwise
        fprintf('Enter either "westinShapes_lsum" or "westinShapes_l1" for method'); return;
end

%The three solutions are only different in that some of them are not real! The second one is usually good enough. 
solN=1;

while(~isreal(l1_sol(:, solN)) || ~isreal(l3_sol(:, solN)))
solN=solN+1;
end
l1=l1_sol(:, solN); 
l3=l3_sol(:, solN); 
l2=vol./(l1.*l3.*4.*pi./3);
l2(isnan(l2))=0;

end


