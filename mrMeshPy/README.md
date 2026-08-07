# mrMeshPy
A Python, VTK6 and Qt5 dependent viewer to replace mrMesh (Stanford).

Instruction video can be see at https://youtu.be/NH_wEimGxVQ

This Readme should be read in conjunction with the License.md file in this directory.

This program is reliant on the following packages:
  - Python VTK 6 
  - Python Qt 5
  - numpy
  - scipy
  
HEALTH WARNING -- Current caveats for users familiar with mrMesh

As you can imagine, this program is very much a work in progress. You should be aware of the following current limitations of the program as it stands (and how it differs from mrMesh):

- - Support for VOLUME{1} only – mrMeshPy does not currently support loading of multiple VOLUME views and will always try to reference VOLUME{1} in the matlab workspace.

- - Crash = restart – if for some reason either matlab or mrMeshPy crash, please restart both matlab and mrMeshPy or things might get horribly out of synch – we are working on this :)

- - The menu bar (top) in the viewer is incomplete, but the ROIs submenu works

- -  Other functions are slowly being added – see/edit TODO.txt for info.

