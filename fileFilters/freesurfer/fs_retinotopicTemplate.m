function fs_retinotopicTemplate(subject, out_path, subjects_dir)
%
% function fs_retinotopicTemplate(subject, out_path, subjects_dir)
%
% Parameters
% ----------
% subject : str
%    The subject ID in the Freesurfer context
% out_path : str
%    Full path to the location where output files will be generated
% subjects_dir : str (optional)
%    Full path to the Freesurfer SUBJECTS_DIR. Per default this will be set
%    to the environment-defined $SUBJECTS_DIR variable 
%
% Notes 
% ----- 
% Based on the work of Benson et al. (2012). The requirements
% for this to work are: 
% 1. The data should have been processed using the cross-sectional stream
% in FreeSurfer (i.e. recon-all -s subjid -autorecon-all). Preferably using
% Freesurfer version 5.1
% 2. The scripts (surfreg) and atlas (fsaverage_sym), which are not part of
% the standard FreeSurfer 5.1 distribution, should be installed
% 3. surfreg should be installed in $FREESURFER_HOME/bin/
% 4. fsaverage_sym should be copied to the FreeSufer subject data directory
% 
% The 'fsaverage_sym' subject used to be abvailable at:
%
% ftp://surfer.nmr.mgh.harvard.edu/transfer/outgoing/flat/greve/
%
% Until it returns to this location, you can copy it from, or symlink to:
%
% /home/arokem/data/freesurfer_subjects/fsaverage_sym/
%
%
% References
% ----------
% NC Benson, OH Butt, R Datta, PD Radoeva, DH Brainard, GK Aguirre (2012)
% The retinotopic organization of striate cortex is well predicted by
% surface topology. Current Biology 22: 2081-2085.
%
% Greve, Douglas N., Lise Van der Haegen, Qing Cai, Steven Stufflebeam, Mert
% R. Sabuncu, Bruce Fischl, and Marc Bysbaert. "A surface-based analysis of
% language lateralization and cortical asymmetry." (2013). Journal of
% Cognitive Neuroscience. In press.

% To accomodate user set SUBJECTS_DIR system variable:
if notDefined('subjects_dir')
    subjects_dir = getenv('SUBJECTS_DIR');
else
    syscall(sprintf('export SUBJECTS_DIR=%s', subjects_dir));
end


maps = {'ecc', 'pol'};
hemis = {'lh', 'rh'};
for map_idx = 1:length(maps)
    template = fullfile(vistaRootPath, 'fileFilters', 'freesurfer', ...
        sprintf('mh.V1.%stmp.sym.mgh', maps{map_idx}));
    for hemi_idx = 1:length(hemis)
        file_root = fullfile(out_path, sprintf('%s_%s_%s', subject, ...
                             hemis{hemi_idx} , maps{map_idx}));
        % These commands differ slightly for the two hemispheres (xhemi):
        if strcmp(hemis{hemi_idx}, 'lh')
            % If the registration file is not there, we'll have to make it:
            if ~(exist(fullfile(subjects_dir, subject, ...
                    '/surf/lh.fsaverage_sym.sphere.reg'), 'file') == 2)
                fprintf('[%s]: Registering... This might take a while... \n',...
                    mfilename);
                
                cmd_str1 = sprintf('surfreg --s %s --t fsaverage_sym --lh', subject);
            else
                cmd_str1 = '';
            end
            cmd_str2 = ['mri_surf2surf --srcsubject fsaverage_sym --trgsubject ' ...
                sprintf('%s --sval %s --tval ', subject, template) ...
                sprintf('%s.mgh --hemi lh', file_root)];
        else
            if ~(exist(fullfile(subjects_dir, subject, ...
                    'xhemi/surf/lh.fsaverage_sym.sphere.reg'), 'file') == 2)
                fprintf('[%s]: Registering... This might take a while... \n',...
                    mfilename);
                
                % Yep - the following line is with 'lh':
                cmd_str1 = sprintf('surfreg --s %s --t fsaverage_sym --lh --xhemi', subject);
            else
                cmd_str1 = '';
            end
            cmd_str2 = ['mri_surf2surf --srcsubject fsaverage_sym --trgsubject ' ...
                sprintf('%s/xhemi --sval %s --tval ', subject, template) ...
                sprintf('%s.mgh --srcsurfreg sphere.reg --trgsurfreg ', file_root, subject) ...
                'fsaverage_sym.sphere.reg --hemi lh'];
        end
        syscall(cmd_str1);
        syscall(cmd_str2);
        
        
        cmd_str = [sprintf('mri_surf2vol --surfval %s.mgh --projfrac 1 ', file_root) ...
            sprintf('--identity %s --o %s.mgz --hemi %s ', subject, file_root, hemis{hemi_idx}) ...
            sprintf('--template %s/%s/mri/orig.mgz', subjects_dir, subject)];
        syscall(cmd_str);
        
        % Convert to volume:
        outfile = [file_root '.nii']; 
        cmd_str = [sprintf('mri_convert  %s.mgz ', file_root), outfile];
        syscall(cmd_str);
        gzip(outfile);
        delete(outfile);
        
    end
end
end 


% Helper function: throw an error if the system call doesn't work as
% expected:
    function [status, result] = syscall(cmd_str)
        % Allow for noops:
        if strcmp(cmd_str, '')
            return
        end
        fprintf('[%s]: Executing "%s" \n', mfilename, cmd_str);
        [status, result] = system(cmd_str);
        if status~=0
            error(result);
        end
    end

