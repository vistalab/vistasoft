## Vistasoft

VISTASOFT is the main software repository of the [Vista lab](http://vistalab.stanford.edu) at [Stanford University](http://stanford.edu). It contains Matlab code to perform a variety of analysis on MRI data, including functional MRI and diffusion MRI.

### License

(c) Vista lab, Stanford University.

Unless otherwise noted, all our code is released under the [GPL](http://www.gnu.org/copyleft/gpl.html) 

### Modules
Vistasoft contains the following modules:

- mrAlign : Aligning functional and anatomical data
- mrAnatomy: Handling anatomical MRI data. 
- mrBOLD : analysis of functional MRI data.
- mrDiffusion : Diffusion MRI, including DTI and tractography.
- mrMesh : displaying MR data on rendered 3D surface representations of the brain.
- mrQuant : quantitative MRI (see also [mrQ](https://github.com/vistalab/mrQ))
- mrScripts : a variety of useful scripts

And in addition:
- utilities
- setup
- tutorials 
- external: functions written by others that we use as dependencies (see optional packages).

### External dependencies
Vistasoft depends on the following packages:
- [Matlab](http://mathworks.com)
  - The code has been validated for Matlab 2014b (8.4) - Matlab 2017b (9.3)
- [SPM](http://www.fil.ion.ucl.ac.uk/spm/)

### Optional Packages
 - [Freesurfer](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall)
 - [FSL](http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)
 - [MRTrix](http://www.nitrc.org/projects/mrtrix/)
 - [JSONLab](http://iso2mesh.sourceforge.net/cgi-bin/index.cgi?jsonlab)
 - [RemoteDataToolbox](https://github.com/isetbio/RemoteDataToolbox)

### Documentation
For detailed documentation, please visit the [VISTA lab wiki](http://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/Software).

### Installation

To install Vistasoft:

1. Clone the Vistasoft repository on your local machine; for example:

   ```sh
   > cd ~/matlab
   > git clone https://github.com/vistalab/vistasoft

   ```
   
2. Start Matlab and Add the Vistasoft repository's base directory to your Matlab path:

   ```matlab
   addpath(genpath('~/matlab/vistasoft'));
   ```

   Note that if you have installed additional Matlab packages (such as the RemoteDataToolbox), you will have to ensure that these packages are on your path as well.

For help with the new mrInit intialization method, please see the [Initialization Page](http://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/Software).

