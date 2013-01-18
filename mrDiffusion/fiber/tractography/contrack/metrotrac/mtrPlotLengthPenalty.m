function mtrPlotLengthPenalty(length_absorption)
% 
% mtrPlotLengthPenalty([length_absorption=0.8])
% 

if(~exist('length_absorption','var')|isempty(length_absorption))
    length_absorption = 0.800;
end

FA = [0.88, 0.7664, 0.50, 0.30, 0.15];
cor = {'k', 'g', 'r', 'm', 'c'};
stdev = 1.0978*exp(-1.9567*FA) - 0.1437;
%maxprior = 1/(2*pi)*normpdf(0,0,0.628)/(normcdf(pi,0,0.628)-0.5);
maxprior = normpdf(0,0,0.628)/(normcdf(pi,0,0.628)-0.5);
maxlike = normpdf(0,0,stdev)./(normcdf(pi/2,0,stdev)-0.5);
maxcortexlike = normpdf(0,0,0.15)./(normcdf(pi/2,0,0.15)-0.5);
%length_penalty = pi/5;
length_penalty = 1-length_absorption;

x = [50:2:250];
for i = 1:length(maxlike)
    log_segment_score = log(maxprior * maxlike(i) * length_penalty);
    y = (x-4)/2*log_segment_score + 2*log(0.999)*maxprior*maxcortexlike;
    plot(x,y,cor{i},'LineWidth',2)
    hold on;
end
hold off;

%legend('STT Path','FA = 0.88','FA = 0.77','FA = 0.50','FA = 0.30','FA = 0.15');
legend('FA = 0.88','FA = 0.77','FA = 0.50','FA = 0.30','FA = 0.15');
% Find where stddev will make the function not penalize or reward
stdsearch = [0:0.01:pi/2];
maxlike = normpdf(0,0,stdsearch)./(normcdf(pi/2,0,stdsearch)-0.5);
abs_post = abs(maxprior*maxlike*length_penalty-1);
[junk, mi] = min(abs_post);
stdev_zero = stdsearch(mi);
fa_zero = log((stdev_zero+0.1437)/1.0978)/(-1.9567)