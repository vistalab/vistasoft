
function err = Charmed_err(x,m,Par)

%
%the ftted paramters:
 %the ftted paramters:
        %         theta_H=x(1);  %the  orientation of the hindererd component  from the qradients pitch from z axis
        %         phi_H=x(2);      %the  orientation of the hindererd
        %                           component  from the qradients
        %                       rotation in x-y plane see Assaf et al MRM 2004 p 977-8
        %         f_h=x(3);     the hidered component
        %         Lh_par=x(4);  the parallel Diffusion coefficient in the hindererd component
        %         Lh_per=x(5);  the ratio of the perpendicular ADC to the parallel ADC
        %                       in the hindered component to that of the x(5)=Lh_par/Lh_per;
        %         Dr_par=x(6);  the parallel Diffusion coefficient in the restricted component
        %         N=x(7);       %the noise floor
        %         theta_R=x(8);    %the cylinder orientation in it the diff is
        %                        restricted:pitch from z axis
        %         phi_R=x(9);     %the cylinder orientation in it the diff is restricted:
        %                       rotation in x-y plane see Assaf et al MRM 2004 p 977-8
        Q=Par.Q;
R=Par.R;
Delta=Par.Delta;
delta=Par.delta;
tau=Par.tau;
Dr_per=Par.Dr_per;


theta_H = x(1); 
phi_H = x(2);
f_h = x(3);
Lh_par = x(4);
Lh_per = x(4)*x(5);
Dr_par = x(6);
N = x(7); %noise floor
theta_R = x(8); 
phi_R = x(9);

f_r = 1-f_h;

% f_r =0;
% h_r=1;


 Qper2_H = Q(:,3).^2.*(1-(sin(Q(:,1)).*sin(theta_H).*cos(Q(:,2)-phi_H)+cos(Q(:,1)).*cos(theta_H)).^2);%Q_H

 Qpar2_H = Q(:,3).^2.*(sin(Q(:,1)).*sin(theta_H).*cos(Q(:,2)-phi_H)+cos(Q(:,1)).*cos(theta_H)).^2;

 Qper2_R = Q(:,3).^2.*(1-(sin(Q(:,1)).*sin(theta_R).*cos(Q(:,2)-phi_R)+cos(Q(:,1)).*cos(theta_R)).^2);%Q_R

 Qpar2_R = Q(:,3).^2.*(sin(Q(:,1)).*sin(theta_R).*cos(Q(:,2)-phi_R)+cos(Q(:,1)).*cos(theta_R)).^2;




E_D = f_h .* exp( -4*pi^2* ( Delta-(delta/3) ) .* ( Qper2_H.*Lh_per + Qpar2_H.*Lh_par ) )...
      + f_r .* exp  ( -4*pi^2 .*Qpar2_R.* ( Delta-(delta/3) ) .* Dr_par...
      - ( 4*pi^2 *R.^4 .* Qper2_R./( Dr_per*tau ) ) .* ( 7/296 ).*( 2-( 99/112 ).*( R.^2./( Dr_per*tau ) ) ) );


E= sqrt(E_D.^2+N^2);


err=m-E;

