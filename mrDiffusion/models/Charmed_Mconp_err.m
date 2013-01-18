

function err = Charmed_Mconp_err(x,m,Par)

%
%the ftted paramters:
% %initiate hindererd
%              x0(1)=Q0(ii,1);%theta;
%             x0(2)=Q0(ii,2);%phi;
%             x0(3)=l1(ii);%D// lh_par
%             x0(4)=mean([l2(ii) l3(ii)])/l1(ii);%Lh_par/Lh_per  --> Lh_per=x4*x5;
%             
%             if Par.F_h>1
%                 for h=2:Par.F_h,
%                     n=h-1;
%                     x0( 1+4*n:4+4*n)=X0(1:4);
%                 end;
%             end;
%             last_var=Par.F_h*4;
%             if Par.F_R>0
%                 %initiate restricted
%                 n1=last_var+1;
%                 x0(n1)=2; %Dr_par of axon
%                 x0(n1+1)=Q0(ii,1);%theta;
%                 x0(n1+2)=Q0(ii,2);%phi;
%                 last_var=n1+2;
%                 if Par.F_R>1
%                     for r=2:Par.F_R,
%                         
%                         x0(1+last_var:3+last_var) X0(n1:n1+2);
%                         last_var=3+last_var;
%                        
%                     end;
%                 end;
%             end
%             
%             
%             %initiate fractions:
%            num= F_R+Par.F_h+Par.F_R-1;
%            
%            x0(1+last_var:1+last_var+num)=1/(F_R+Par.F_h+Par.F_R);
%            %initiate noise
%            x0(2+last_var+num)=0.03; % this is a case from yaniv data
%                    Q=Par.Q;
R=Par.R;
Delta=Par.Delta;
delta=Par.delta;
tau=Par.tau;
Dr_per=Par.Dr_per;
Q=Par.Q;
%first initiate the fractions
st=Par.F_h*4+3*Par.F_R;
Fh(1:Par.F_h)   =x(1+st:st+Par.F_h);
st=st+Par.F_h;
if Par.F_R>1
Fr(1:Par.F_R-1)   =x(1+st:st+Par.F_R-1);
end;
Fr(Par.F_R)=1-(sum(Fh)+sum(Fr));





% %initiate hindererd
for hf=1:Par.F_h, %run over number of hinderd compartment 
    n=4*(hf-1);
theta_H(hf)= x(1+n);
phi_H(hf) = x(2+n);
Lh_par(hf) = x(3+n);
Lh_per(hf) = x(3+n)*x(4+n);

Qper2_H(:,hf) = Q(:,3).^2.*(1-(sin(Q(:,1)).*sin(theta_H(hf)).*cos(Q(:,2)-phi_H(hf))+cos(Q(:,1)).*cos(theta_H(hf))).^2);%Q_H

Qpar2_H(:,hf) = Q(:,3).^2.*(sin(Q(:,1)).*sin(theta_H(hf)).*cos(Q(:,2)-phi_H(hf))+cos(Q(:,1)).*cos(theta_H(hf))).^2;

E_H(:,hf)=Fh(hf) .* exp( -4*pi^2* ( Delta-(delta/3) ) .* ( Qper2_H(:,hf) .*Lh_per(hf) + Qpar2_H(:,hf).*Lh_par(hf) ) );
end;
last=Par.F_h*4;

for rf=1:Par.F_R,  %run over number of restricted compartment 
    n=last+3*(rf-1);
  
theta_R(rf) = x(1+n); 
phi_R(rf) = x(2+n);
Dr_par(rf) = x(3+n);
 
Qper2_R(:,rf) = Q(:,3).^2.*(1-(sin(Q(:,1)).*sin(theta_R(rf)).*cos(Q(:,2)-phi_R(rf))+cos(Q(:,1)).*cos(theta_R(rf))).^2);%Q_R

Qpar2_R (:,rf)= Q(:,3).^2.*(sin(Q(:,1)).*sin(theta_R(rf)).*cos(Q(:,2)-phi_R(rf))+cos(Q(:,1)).*cos(theta_R(rf))).^2;
 
E_R(:,rf)=  Fr(rf) .* exp  ( -4*pi^2 .*Qpar2_R(:,rf).* ( Delta-(delta/3) ) .* Dr_par(rf)...
     - ( 4*pi^2 *R.^4 .* Qper2_R(:,rf)./( Dr_per*tau ) ) .* ( 7/296 ).*( 2-( 99/112 ).*( R.^2./( Dr_per*tau ) ) ) );

end;

E_D=sum(E_H,2)+sum(E_R,2);

last=Par.F_h*4+Par.F_R*3+Par.F_h+Par.F_R;

N=x(last);



E= sqrt(E_D.^2+N^2);


err=m-E;


