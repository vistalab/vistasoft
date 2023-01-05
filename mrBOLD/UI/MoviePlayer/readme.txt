Interactive MATLAB Movie Player


Release 2.1
------------------------------------------------------------
- Fixed bug: missing bitmap for export button
- Added capability to export current frame to workspace

Release 2
------------------------------------------------------------
- added forward/backward playback support
- removed an unused input argument syntax

Release 1
------------------------------------------------------------
Q: Ever wish you had better control over the
   playback of a movie you created in MATLAB?

Q: How about the ability to STOP a movie while
   it is running?  Then resume where you left off?

Q: Ever wanted manual frame-by-frame stepping?
   Or programmatic access to playback features?

A: MPLAY is an interactive movie player for MATLAB,
   offering a simple GUI and a command-line API.


It's not terribly fancy, but it works in a majority
of situations.  It uses the TIMER object to control
playback at a specified frame rate.  It provides DVD-like
controls for manual stepping of movie frames.


It will play SEVERAL types of MATLAB movies you might construct:

   1 Standard MATLAB movie structure
     See 'help getframe' for more information on the MATLAB
     movie structure.  Only movies with empty .colormap field
     entries are supported.  This includes most movies you
     have made in R13.
    
   2 Intensity video array
     3-D array organized as MxNxF, where each image is of
     size MxN and there are F image frames.

   3 RGB video array
     4-D array organized as MxNx3xF, where the R, G, and B
     are encoded in the 3rd dimension.  Note that MxNx3 is
     the usual MATLAB format for an RGB image.


Several demonstration movies are available.
Due to size, they are separate a submission file.

Basic utility functions that construct 3-D (intensity) and 4-D
(RGB) movie arrays from your intensity images and movies are
included.  See "mplay_demo" for demonstrations of its use.


