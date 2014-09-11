%% plots prf size distribution in histogram
% assumes prf sizes are circular
% input rm should contain fields:
%
% x0
% y0
% 
function fh = ff_plotPRFThetaDistribution(rm)

% turn off text interpreter
set(0, 'DefaultTextInterpreter', 'none'); 


% calculate theta (returned in radians)
[thetas, ~] = cart2pol(rm.x0,rm.y0); 

% convert radians to degrees
angles = radtodeg(thetas); 
 
    

% plot it!
figure()
hist(angles); 
ht = title(sprintf(['pRF thetas. ', rm.subject, '\n' rm.name])); 
set(ht, 'FontSize', 24) 
xlabel('Degrees from horizontal', 'FontSize', 18)
ylabel('Number of voxels', 'FontSize', 18)

fh = gcf; 
end
