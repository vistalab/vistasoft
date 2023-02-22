Acquiring and using Matlab-based mesh tools started with AFQ and accelerated in VISTASOFT December, 2012.  It is an experiment. I think in the future AFQ will remove these files and we will only have a version of them in VISTASOFT.

These mesh related tools were downloaded from the Matlab File Exchange.  We use some parts of them to manage the three-dimensional visualization in coordination with mrMesh.  

Several of these toolboxes include C-code that must be converted into architecture specific mex-files.  See the instructions therein.

Compilation notes so far.  Sigh.

patch_normals

   mex patchnormals_double.c -v --- This is the only one used thus far.

There is a bug in Visual Studio 2010, explained here, for one of the compiles. Basically, an include file is missing from VS 2010 and you need to run these patches to get them.  Pathetic.

  http://connect.microsoft.com/VisualStudio/feedback/details/660584/windows-update-kb2455033-breaks-build-with-missing-ammintrin-h

  
This ran well for smoothpatch

  mex smoothpatch_curvature_double.c -v
  mex smoothpatch_inversedistance_double.c -v
  mex vertex_neighbours_double.c -v

Checking on tricuv_v01 and compute_curvature.  Not sure which is right or best or even the relationship between them.  Sigh.
