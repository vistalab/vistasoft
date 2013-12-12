function pysurfer(subject_id, hemi, surf, subjects_dir, overlay, range, ...
    min, max, background, cortex)
% Show a Freesurfer brain with PySurfer.
%function pysurfer(subject_id, hemi, surf, [subjects_dir], [overlay], [range], ...
%                  [min], [max], [background], [cortex])
%
%
% Parameters
% ----------
%
% subject_id : str
%     The subject id in the Freesurfer context
% hemi : str
%     {'lh' | 'rh'}
% surf: str
%     Which surface to show: {'inflated' | 'pial' | 'white' | ...}
% subjects_dir : str (optional)
%    The full path of the FS SUBJECTS_DIR. Defaults to the system-defined
%    SUBJECTS_DIR
% overlay : str (optional)
%    Full path to a '.mgh' file with data corresponding to the displayed
%    surface
% range : a 1x2 matrix (optional) 
%    Defines a threshold and a maximum for the range of data overlayed
% min : double or int
%    The minimum of the range of the colormap
% max : double or int
%    The maximum of the range of the colormap
% background: str
%    The color of the background. Many different color names work here
% cortex : str
%    The color-scheme used for the display of curvature: 
%    {'classic'|'bone'|'high_contrast'|'low_contrast'}
%    See: http://pysurfer.github.io/documentation/custom_viz.html#changing-the-curvature-color-scheme
% 
% Notes
% -----
% This relies on a call out to Pysurfer. To install pysurfer, refer to the
% website for instructions: http://pysurfer.github.io/
%
% IMPORTANT:
% 
% Examples
% --------
% This gives the mrmesh look and feel 
%    
%      pysurfer('arokem', 'lh', 'inflated', ... 
%               '~/data/freesurfer_subjects', [], [], [], [], 'white','bone')
% 
% This adds an overlay (and sets range/min/max): 
% pysurfer('JMD1-MM-20121025-DWI', 'lh', 'inflated',...
%            '/biac4/wandell/biac2/wandell/data/DWI-Tamagawa-Japan/freesurfer',...
%            '/biac4/wandell/biac2/wandell/data/DWI-Tamagawa-Japan/JMD1-MM-20121025-DWI/fs_Retinotopy2/JMD1-MM-20121025-DWI_lh_ecc.mgh',...
%             [5, 90], 5, 90, 'white','bone')
%


% For reference, these are the arguments to the pysurfer command-line:
% positional arguments:
%   subject_id            subject id as in subjects dir
%   hemi                  hemisphere to load
%   surf                  surface mesh (e.g. 'pial', 'inflated')
%
% optional arguments:
%   -h, --help            show this help message and exit
%   -no-curv              do not display the binarized surface curvature
%   -morphometry MEAS     load morphometry file (e.g. thickness, curvature)
%   -annotation ANNOT     load annotation (by name or filepath)
%   -label LABEL          load label (by name or filepath
%   -borders              only show label/annot borders
%   -overlay FILE         load scalar overlay file
%   -range MIN MAX        overlay threshold and saturation point
%   -min MIN              overlay threshold
%   -max MAX              overlay saturation point
%   -sign {abs,pos,neg}   overlay sign
%   -name NAME            name to use for the overlay
%   -size SIZE            size of the display window (in pixels)
%   -background COLOR     background color for display
%   -cortex COLOR         colormap for binary cortex curvature
%   -title TITLE          title to use for the figure
%   -views [VIEWS [VIEWS ...]]
%                         view list (space-separated) to use

%Matlab does unspeakable things to our environment settings. Undo that:
setenv('LD_LIBRARY_PATH', '/usr/lib')

% Checking for the absolute requirements. There might well be others:
status = system('which pysurfer');

if status ~=0
    error_str = ['To use this visualization function, you need to have pysurfer'...
        ' installed. Refer to http://pysurfer.github.io/ for instructions'];
    error(error_str);
end

status = system('which ipython');

if status ~=0
    error_str = ['To use this visualization function, you need to have ipython'...
        ' installed. Refer to http://ipython.org for instructions'];
    error(error_str);
end


if ~notDefined('subjects_dir')
    setenv('SUBJECTS_DIR', subjects_dir)
end


cmd_str = sprintf('pysurfer %s %s %s', subject_id, hemi, surf);

if ~notDefined('overlay')
    cmd_str = [cmd_str ' -overlay ' overlay];
end

if ~notDefined('threshold')
    cmd_str = [cmd_str sprintf(' -range %s %s', num2str(range(1)),...
                                                num2str(range(2)))];
end

if ~notDefined('min')
    cmd_str = [cmd_str ' -min ' num2str(min)];
end

if ~notDefined('max')
    cmd_str = [cmd_str ' -max ' num2str(max)];
end

if ~notDefined('background') 
    cmd_str = [cmd_str ' -background ' background]; 
end

if ~notDefined('cortex') 
    cmd_str = [cmd_str ' -cortex ' cortex]; 
end
    
warning('STARTING IPYTHON - TYPE "exit" TO RETURN TO YOU MATLAB SESSION')

system(cmd_str);



