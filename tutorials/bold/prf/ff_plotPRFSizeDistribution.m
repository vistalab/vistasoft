%% plots prf size distribution in histogram
% assumes prf sizes are circular
% input rm should contain fields:
%
% sigma1
% 
function fh = ff_plotPRFSizeDistribution(rm)

% turn off text interpreter
set(0, 'DefaultTextInterpreter', 'none'); 


figure()
hist(rm.sigma1);
ht = title(sprintf(['pRF sigmas. ', rm.subject, '\n' rm.name])); 
set(ht, 'FontSize', 24) 
xlabel('pRF radius (vis. ang. deg)', 'FontSize', 18)
ylabel('Number of voxels', 'FontSize', 18)

fh = gcf; 
end
