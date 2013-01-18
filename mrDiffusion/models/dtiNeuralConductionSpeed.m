function [speed,energy] = dtiNeuralConductionSpeed(caliber, g)
%
% [speed,energy] = dtiNeuralConductionSpeed(caliber, g)
%
% Returns neural conduction speed in meters/sec (=mm/msec); caliber is the outer 
% diameter in micrometers. Energy is amol glucose / AP / mm
%
% Equations for conduction speed from Intermediate Physics for Medicine and 
% Biology (RK Hobbie, BJ Roth), pg 160
%
% Wang et. al. work out the metabolic demands vs. radius and the max bit rate:
%   Wang et. al. (2008). Functional Trade-Offs in White Matter Axonal Scaling. J. Neurosci.
%
%   Timing jitter vs. radius: Swadlow (2000). Time and the brain (R. Miller, ed.)
%
%   Myelin thickness vs. radius: Waxman and Bennett (1972). Nature New Biology.
%
% Swadlow & Bennet 1972 show that unmyelinated axons conduct fatster than
% myelinated axons when the fiber diameter is below 0.2um.
%
% 2008.12.01 RFD wrote it.

if(~exist('g','var')||isempty(g))
    if(caliber<0.5)
        g = 1.0;
    else
        g = 0.6;
    end
end
if(islogical(g))
    if(g) g = 0.6;
    else  g = 1.0; end
end

if(g<1)
    if(caliber<0.5), disp('Myelinated fibers are usually >0.5um'); end
    % Myelin thickness usually scales with axon radius:
    %outerRadius = 1.67.*radius./1e6;
    %innerCaliber = g.*caliber;
    % From Hobbie & Roth: speed = 1.8 * sqrt(innerRadius)
    % internode distance is ~200*outerRadius
    % speed = 12 .* outerRadius;
    speed = 5.7 .* caliber;
    %speed = caliber.*g.*sqrt(-log(g));
    energy = 0.056;
else
    if(caliber>0.5), disp('Unmyelinated fibers are usually <0.5um'); end
    % outerRadius in m
    % for unmyelinated fibers, the outer diameter is roughly = diameter, since membrane
    % thickness is negligable (.006um).
    innerRadius = caliber./2 - 0.006;
    % From Hobbie & Roth: speed = 1.8 * sqrt(innerRadius)
    speed = 1.8.*sqrt(innerRadius);
    energy = 1.26 .* caliber; % 12.6*d for cm, 1.26*d for mm 
end
return;

% From Rushton:
% l/D ~ d/D*sqrt(log(D/d));
% g = d/D;
% l/D ~ g*sqrt(log(1/g))
% figure;g=[0.1:0.01:0.9];plot(g,g.*sqrt(log(1./g)));

caliber = 0.2:0.1:10;
[us,ue] = dtiNeuralConductionSpeed(caliber, 1.0);
[ms,me] = dtiNeuralConductionSpeed(caliber, 0.6);
figure;
h=plot(caliber,us,'r-',caliber,ms,'b-');
set(h(1),'LineWidth',2); set(h(2),'LineWidth',2);
ylabel('Speed (mm/msec)');
xlabel('Fiber Caliber (\mum)');
set(gcf,'position',[20 200 280 220]);
grid on;
axis([0 10 0 60]);
%legend({'unmyelinated','myelinated'});
fn = '/tmp/speed';
mrUtilPrintFigure([fn '.eps']);
% pstoimg is in the latex2html package (e.g., apt-get install). It renders
% things much better than matlab.
unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fn '.png ' fn '.eps']);

figure;
plot(caliber,ue,'r-',caliber,me,'b-');
ylabel('Glucose/AP/mm');
xlabel('Fiber Caliber (\mum)');
set(gcf,'position',[20 100 200 160]);
axis([0 5 0 5]);
%legend({'unmyelinated','myelinated'});
fn = '/tmp/energy';
mrUtilPrintFigure([fn '.eps']);
% pstoimg is in the latex2html package (e.g., apt-get install). It renders
% things much better than matlab.
unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fn '.png ' fn '.eps']);

figure;
caliber = [0.2:0.1:3];
length = [1:5:150];
[cg,lg] = meshgrid(caliber,length);
%[delay,umbr] = dtiNeuronBitRate(r,length,7,false);
[delay,mbr,e] = dtiNeuronBitRate(cg,lg,7,true);
surf(cg,lg,delay);
xlabel('Fiber Caliber (\mum)');
ylabel('Fiber length (mm)');
zlabel('Conduction delay (msec)');
set(gcf,'position',[20 100 320 240]);
%[az,el]=view; 
az = 145; el = 38;
view(az,el);
axis([0,3,0,150,0,60]);
fn = '/tmp/delay_surf'; mrUtilPrintFigure([fn '.eps']);
unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fn '.png ' fn '.eps']);

figure
surf(cg,lg,mbr);
xlabel('Fiber Caliber (\mum)');
ylabel('Fiber length (mm)');
zlabel('Bandwidth (bits/sec)');
set(gcf,'position',[20 100 320 240]);
view(az,el);
axis([0,3,0,150,0,15]);
fn = '/tmp/mbr_surf'; mrUtilPrintFigure([fn '.eps']);
unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fn '.png ' fn '.eps']);

figure
surf(cg,lg,e);
xlabel('Fiber Caliber (\mum)');
ylabel('Fiber length (mm)');
zlabel('Energy (amol Glucose/AP)');
set(gcf,'position',[20 100 320 240]);
view(az,el);
axis([0,3,0,150,0,10]);
fn = '/tmp/energy_surf'; mrUtilPrintFigure([fn '.eps']);
unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fn '.png ' fn '.eps']);

