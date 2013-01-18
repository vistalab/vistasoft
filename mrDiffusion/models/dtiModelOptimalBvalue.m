
% For our 150 dir, b=2.5 data, the noise level is 67 and the 
% signal in the white matter is 1166.
% Also, in the callosum, the AD is 1.1 and RD is 0.23.
% In the gray matter, the diffusivity is 0.9 isotropic.
snr = 17;

%b = [0.0 0.25 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 5.0];
b = [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
[x,y,z] = sph2cart(linspace(0,pi,100),0,ones(1,100));
q = [x; y; z]';

% See dtiModelPowderAverage
v_r = 0.0;     % Volume fraction of the restricted component
f_dir = diag([1 -1 1]);
d_a = 1.1; 
d_r = 0.23;
% Now compose the expected diffusion tensor for this fiber:
Dh = f_dir*diag([d_a d_r d_r])*f_dir';
[val,vec] = eig(Dh);
pdd = val(:,3);
d_ar = 1.1; 
d_rr = 0.1;
Dr = f_dir*diag([d_ar d_rr d_rr])*f_dir';

Dgm = diag(0.9);

for(ii=1:size(q,1))
    deviationAngle(ii) = acos(dot(q(ii,:),pdd))./pi.*180;
    for(jj=1:numel(b))
        hindered = exp(-b(jj).*q(ii,:)*Dh*q(ii,:)');
        restricted = exp(-b(jj).*q(ii,:)*Dr*q(ii,:)');
        sa(ii,jj) = (1-v_r).*hindered + v_r.*restricted;
    end
end
% Compute the expected signal attenuation in gray matter
for(jj=1:numel(b))
    sgm(jj) = exp(-b(jj).*Dgm);
end

cm = autumn(numel(b)+2);
clear lh lt;
figure(2); clf;
hold on;
figure(3); clf;
hold on;
for(ii=1:numel(b))
    y = sa(:,ii).*snr;
    figure(2); plot(deviationAngle',y,'k-');
    plot(deviationAngle(2), sgm(ii).*snr, 'k*');
    figure(3); 
    lh(ii) = plot(deviationAngle',diff([y(1);y]),'-','Color',cm(ii,:),'LineWidth',2);
    lt{ii} = sprintf('b=%0.2f',b(ii));
end
figure(2); 
set(gca,'xtick',[0 45 90 135 180]);
xlabel('Fiber/gradient angle (deg)');
ylabel('SNR');
mrUtilResizeFigure(gcf, 280, 180);
figure(3); 
set(gca,'xtick',[0 45 90 135 180]);
xlabel('Fiber/gradient angle (deg)');
ylabel('dS/dq (arb)');
legend(lh,lt);
%mrUtilResizeFigure(gcf, 280, 180);
sgm.*snr

fn = sprintf('effect_of_b_rd%03d_ad%03d',round(d_r*100),round(d_a*100));
%mrUtilPrintFigure([fn '.eps']);
%unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fn '.png ' fn '.eps']);

