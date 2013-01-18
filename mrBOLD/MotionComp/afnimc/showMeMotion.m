% script showMeMotion:
% 
% If a session of MRI data has been corrected with
% the FSFAST AFNI algorithm, this will seek out the
% information in the 'fmc.mcdat' files that result, and
% plot the net motion, in millimeters, over the course of 
% a session. All motion is plotted relative to the first frame 
% of the first scan in the session.
% 
% This assumes certain things about directory structures, such as
% that the motion-corrected data will be in a directory whose name starts
% with 'bold': it could be 'bold', 'bold_lo', or 'bold-yourmom', but the
% b-shorts and other stuff should be in there. :)
%
% Run in the base directory of the session (e.g., X:\mri\020603dt\)

% 03/20/03 by ras
% 06/17/03 ras: updated to deal with changing rules about how things are
% stashed: normally all files are named 'fmc.mcdat', and have to be in an
% FS-FAST convention named directory -- e.g., /bold/001/fmc.mcdat. Since
% we're trying to implement some things outside of the FS-FAST stream,
% there's an alternate naming: Scan[#].mcdat. So the same file in
% /bold/001/fmc.mcdat might be in /mc/Scan1.mcdat. Right now this code will
% use either criterion, giving preference to the old convention, in
% figuring out the scan #. Doesn't check to see if the numberings
% conflict.
%
% For some reason, the .mcdat files created by my automc code is
% off by a factor of 10. Looking into the problem, but in the
% meantime I'm compensating here by dividing by 10. ras 06/03
w = dir(pwd);

%%%%% init
scansFound = [];
framesPerRun = [];

netMotion = {};
rollRot = {};
pitchRot = {};
yawRot = {};
zTrans = {};
yTrans = {};
xTrans = {};
rmseBefore = {};
rmseAfter = {};
        
rrotAcrossSession = [];
protAcrossSession = [];
yrotAcrossSession = [];
ztransAcrossSession = [];
ytransAcrossSession = [];
xtransAcrossSession = [];
preRMSE = [];
postRMSE = [];
motionAcrossSession = [];


for d = 1:length(w)
    % check .mcdat files matching pattern 'Scan[#].mcdat'
    x = filterdir('.mcdat',w(d).name);
    for s = 1:length(x)
        fullPath = fullfile(pwd,w(d).name,x(s).name);
        if exist(fullPath,'file')
            mcdat = load(fullPath);
            rng = 5:findstr('.',x(s).name);
            scansFound(end+1) = str2num(x(s).name(rng));
            framesPerRun(end+1) =  size(mcdat,1);
            rollRot{end+1} = mcdat(:,2)';
            pitchRot{end+1} = mcdat(:,3)';
            yawRot{end+1} = mcdat(:,4)';
            zTrans{end+1} = mcdat(:,5)';
            yTrans{end+1} = mcdat(:,6)';
            xTrans{end+1} = mcdat(:,7)';
            rmseBefore{end+1} = mcdat(:,8)';
            rmseAfter{end+1} = mcdat(:,9)';
            netMotion{end+1} = mcdat(:,10)';
        end
    end
    
	% check .mcdat files in directories numbered '0##'
    x = filterdir('0',w(d).name);
    for s = 1:length(x)
        fullPath = fullfile(pwd,w(d).name,x(s).name,'fmc.mcdat');
        if exist(fullPath,'file')
            mcdat = load(fullPath);
            scansFound(end+1) = str2num(x(s).name);
            framesPerRun(end+1) =  size(mcdat,1);
            rollRot{end+1} = mcdat(:,2)'; % decided to always divide by 10
            pitchRot{end+1} = mcdat(:,3)';
            yawRot{end+1} = mcdat(:,4)';
            zTrans{end+1} = mcdat(:,5)';
            yTrans{end+1} = mcdat(:,6)';
            xTrans{end+1} = mcdat(:,7)';
            rmseBefore{end+1} = mcdat(:,8)';
            rmseAfter{end+1} = mcdat(:,9)';
            netMotion{end+1} = mcdat(:,10)';
        end
    end
end
[scansFound,I] = sort(scansFound);
framesPerRun = framesPerRun(I);

for s = 1:length(scansFound)
    rrotAcrossSession = [rrotAcrossSession rollRot{I(s)}];
    protAcrossSession = [protAcrossSession pitchRot{I(s)}];
    yrotAcrossSession = [yrotAcrossSession yawRot{I(s)}];
    ztransAcrossSession = [ztransAcrossSession zTrans{I(s)}];
    ytransAcrossSession = [ytransAcrossSession yTrans{I(s)}];
    xtransAcrossSession = [xtransAcrossSession xTrans{I(s)}];
    preRMSE = [preRMSE rmseBefore{I(s)}];
    postRMSE = [postRMSE rmseAfter{I(s)}];
    motionAcrossSession = [motionAcrossSession netMotion{I(s)}];
end

% print out / plot results
fprintf('\n Motion-corrected scans found: ');
for s = 1:length(scansFound)
    fprintf(' %i ',scansFound(s));
end
fprintf('\n Total Frames: %i \n',sum(framesPerRun));

data = [rrotAcrossSession', ...
        protAcrossSession', ...
        yrotAcrossSession', ...
        ztransAcrossSession', ...
        ytransAcrossSession', ...
        xtransAcrossSession', ...
        motionAcrossSession' ...
		];
%             preRMSE', ...
%         postRMSE', ...
leg = {'Roll Rotation (deg)', ...
        'Pitch Rotation (deg)', ...
        'Yaw Rotation (deg)', ...
        'Between-slice translation', ...
        'Up-down within-slice translation', ...
        'Left-right within-slice translation', ...
        'Total, Net motion (mm)' ...
		};    
%         'Root-Mean-Square Error before correction', ...
%         'Root-Mean-Square Error after correction', ...
fancyplot(data,[],'leg',leg);
xlabel('Frames');
ylabel('Net motion, mm or Rotation, deg');
title(['Motion across session: ',pwd],'fontsize',14);

figure, plot(motionAcrossSession);
xlabel('Frames');
ylabel('Net motion, mm');
title(['Motion across session: ',pwd],'fontsize',14);


% add lines indicating breaks between runs
AX = axis;
cumFrames = cumsum(framesPerRun);
for s = 1:length(framesPerRun)
    h = line([cumFrames(s) cumFrames(s)],[AX(3) AX(4)]);
    set(h,'Color',[1 0 0])
end

% add text indicating each run
cumFrames = [0 cumFrames];
for s = 1:length(framesPerRun)
    xPos = cumFrames(s) + framesPerRun(s)/2;
    yPos = AX(3) + 0.9*(AX(4)-AX(3));
    text(xPos,yPos,num2str(s),'fontsize',14,'color',[0 0.5 1]);
end

clear I w x d s h mcdat cumFrames;

return