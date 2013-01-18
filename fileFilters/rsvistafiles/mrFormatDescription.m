function mrFormatDescription;
% Summary of format for mr Summary of format for mr structs in mrVista 2.0.
% Started by ras (sayres at white stanford edu), 07/2005.
% 
% In an attempt to generalize the handling of MRI data, and
% provide a lot of tools/info at a low level for mrVista 2.0, we've
% created a set of tools to load and save data in many different
% formats, with a standard structure. This is similar in spirit
% to NIFTI format, but with some mrVista-specific extra information
% and more (I think) human-readable fields. NIFTI will likely be
% the default file format for most data in mrVista 2.0, but mr
% objects should be able to load/save in other format as well.
% 
% mr structs have the following fields:
%   data: numeric matrix of data, (2/3/4D)
% 
%   path: the input file path.
% 
%   format: string describing the format of the loaded file.
% 
%   hdr: header-file info for the file(s), in the native format. 
%   e.g., for NIFTI files the header would have the NIFTI-type
%   fields, for DICOM files the header would have DICOM-type fields.
% 
%   info: info about the scanning conditions for the file. Has the
%         following sub-fields:
%           scanner: Name of scanner used
%           subject: Name of subject
%           date:    Date scan was run. Format is the same as
%                    the matlab DATE command, e.g. 22-Jul-2005.
%           startTime: Time of the day the scan was run. [format]
% 
%           If any of this information can't be determined from
%           the file, the field will be left blank.
% 
%   spaces: sub-struct describing how to xform the data to
%           different coordinate systems. Has the following
%           sub-fields:
% 
%           name: name of the space, e.g. 'R|A|S', 'AC/PC', 'Talairach'.
% 
%                 A description of some sample spaces:
%                 'R|A|S': (rows, cols, slices) map to increasing
%                          (right, anterior, superior) locations.
%                          This is the default format for ANALYZE
%                          and NIFTI files, and what is refered to
%                          as the 'canonical' space. In addition,
%                          I (ras) believe GE scanners deal in R|A|S
%                          coords. 
% 
%                          However, matrices stored in this format
%                          don't display very intuitively: the first
%                          slice of a 3-D matrix in R|A|S format
%                          is the lowest axial slice, with the front
%                          of the brain pointing to the left and the 
%                          right hemisphere on the bottom. With this format,
%                          often the 'interesting' areas are buried, and
%                          you need to do some permuting to get a nice
%                          manual view in MATLAB. For this reason, I've
%                          come up with a more display-friendly I|P|R
%                          space below.
% 
%                  'I|P|R': (rows, cols, slices) map to increasing
%                          (inferior, posterior, right) locations. 
%                          This is the convention used in mrLoadRet /
%                          mrVista 1.0 / mrGray. It's not standard, but
%                          it displays nicer, and means I don't have
%                          to build ungainly assumptions into a viewer
%                          (e.g., check for R|A|S and automatically do
%                          a bunch of rotations and flips -- just switch
%                          to I|P|R for a nicer display).
% 
%                         In the mr read/write functions, when it's possible
%                         to find a transformation into R|A|S space, I try
%                         to also add the flips/rotations into I|P|R. When
%                         choosing a format to save as, R|A|S would be 
%                         preferred for consistency's sake. (Though really,
%                         the best format is the one the data were collected
%                         in, as xforming introduces distortions; better just
%                         to save the transformation info and do stuff on the
%                         fly.)
% 
%                 'Scanner': coords as collected in the scanner. For GE
%                         scanners, this would be a form of R|A|S system,
%                         but is probably not a good reference space, since
%                         the subject's head may be positioned differently
%                         in the scanner. But for e.g., comparing different
%                         data files from the same session, this would be
%                         good.
% 
%                 'AC/PC': coordinates relative to the line connecting
%                         the anterior commisure and the posterior 
%                         commisure, using only rigid-body rotations
%                         and translations. [add more info]. I try
%                         to set this to be an I|P|R system, so 
%                         it displays nicely.
% 
% 
%           xform: 4x4 affine transform to convert FROM points
%                   in the mr data's pixel space (where coords go 
%                   (rows, cols, slices) INTO the given space.
%                   xform can be empty or omitted if coords and indices are
%                   entered below.
% 
%           dirLabels: 1x3 cell-of-strings containing labels
%                   for which direction is which in the space, e.g.
%                   {'L <--> R' 'P <--> A' 'I <--> S'}.  % R|A|S space
%                   The first label is for increasing rows, the second for 
%                   columns, the third for slices.
%                   MINOR NOTE: In displaying the dirLabels in MATLAB,
%                   you can take advantage of the TeX interpreter built
%                   in to the renderer (for most text objects), by replacing
%                   the '<-->' string with '\leftrightarrow'. This renders
%                   a nice graphical two-way arrow. (I'll have to remember
%                   to do this in mrViewer.)
% 
%           units: label for the units: e.g. 'mm', 'pixels'.
% 
%           bounds: expected extent of the space, in the space's units.
% 
%           coords: N x 3 or N x 4 matrix directly mapping from indices
%                   in the data to coords in the new space. Usually empty,
%                   but can be non-empty if a highly non-linear mapping
%                   has been computed, e.g., flattening gray matter.
% 
%           indices: indices into the data matrix corresponding to columns
%                   in the coords sub-field. Usually empty,
%                   but can be non-empty if a highly non-linear mapping
%                   has been computed, e.g., flattening gray matter.
% 
%   voxelSize: size of each voxel in the data matrix. Format is
%       [x y z] or [x y z t] for 4D data. x, y, and z correspond to
%       spatial dimensions in milimeters; t is frame period in seconds.
%       Note that x corresponds to different COLUMNS of a matrix while
%       y corresponds to different ROWS.
% 
%   dims: size of the data in voxels.
% 
%   extent: voxelSize * dims, the total extent in spacetime of the MR
%           data.
% 
%   dimUnits: units for each dimension, e.g. {'mm' 'mm' 'mm' 'sec'}.
% 
%   dataUnits: units for the data. [tbd]
% 
%   dataRange: [min max] values of the data.
%
%	phaseFlag: 1 or 0, indicating whether the values for the data are
%	phasic (i.e., circular). An example of a phasic map is a polar angle
%	map is a map of polar angle representation; values "wrap around" from
%	max to min.  This flag is used for certain averaging procedures, making
%	sure a phase average is returned, rather than an arithmetic average.
% 
%   settings: optional field specifying preferred view settings, 
%             such as grayscale levels and labels (used in mrViewer
%             and maybe other UIs)
%   params: parameters of any analyses associated with the data, either
%           used to produce the data, or intended to be applied to the
%           data.
% 
% 
% MORE INFO: 
% We tried to take some cues from the ideas developed for NIFTI format:
% http://nifti.nimh.nih.gov/nifti-1 
% http://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1.h [Techy]
% Although I think what we want to do here is even broader:
% we want to transform to many possible spaces easily (incl. 
% radiological, AC/PC, scanner, Talairach spaces, and even
% flattened gray matter), and have the extensibility to use
% lookup tables for highly-nonlinear remappings. We also 
% try to use more human-readable field names, though the NIFTI
% info is preserved when loading/saving NIFTI format.
% if someone called this as a function, just give them the info:
p = fileparts(mfilename);
web(fullfile(p,'mrFormatDescription.txt'));
return