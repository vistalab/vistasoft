# Compiles mrMeshSrv and builds vtk and wxwidgets.
# lmperry@stanford.edu [June 17, 2011]

# README: Move this file into a folder where you would like the build to take place.
#         Make sure it's executable and run it. Stay close, you will need to enter
#         your sudo password a couple of times. If you'd like to increase the speed
#	  find and replace -j2 with -jn where n = the number of cores to be used (ex -j8).

# Checkout the MrMesh Source Code.
echo "Downloading mrMesh Source Code."
svn co https://white.stanford.edu/repos/vistasrc/mrMesh_legacy
mv mrMesh_legacy mrMesh
cd mrMesh

basedir="`pwd`"
local_dir=$basedir/local

wx_branch="WX_2_8_11"
wx_dir="wx"

vtk_dir="name"
vtk_branch="v5.6.1"
vtk_dir=$basedir/vtk
vtk_build=$vtk_dir/build

mesh_dir=$basedir/server

# wxWidgets
function build_wx {
	echo "Checking out wxwidgets..."
	svn checkout http://svn.wxwidgets.org/svn/wx/wxWidgets/tags/$wx_branch $wx_dir
	cd $wx_dir	

	echo "Configuring..."
	./configure --prefix=$local_dir --enable-monolithic --with-gtk --with-opengl --disable-shared --disable-unicode LIBS=-lX11 

	echo "Running make..."
	make -j2 
	sudo make install 
	sudo ldconfig
}

# VTK
function build_vtk {
	cd $basedir
	mkdir $vtk_dir $vtk_build	
	cd $vtk_dir
	
	# Get VTK
	echo "Retrieving VTK..."
	git clone git://vtk.org/VTK.git source 

	cd source
	git checkout $vtk_branch 
	
	# Configure the make
	cmake \
          -DBUILD_SHARED_LIBS:BOOL=OFF \
          -DBUILD_EXAMPLES:BOOL=OFF \
          -DBUILD_TESTING:BOOL=OFF \
          -DCMAKE_BUILD_TYPE:STRING=Release \
          -DVTK_USE_HYBRID:BOOL=ON \
          -DVTK_USE_ANSI_STDLIB:BOOL=ON \
          -DVTK_USE_PARALLEL:BOOL=ON \
          -DVTK_USE_RENDERING:BOOL=ON \
          -DVTK_USE_PATENTED:BOOL=ON \
          -DCMAKE_CXX_FLAGS_RELEASE:STRING="-O3 -DNDEBUG" \
          -DCMAKE_INSTALL_PREFIX:PATH=$local_dir \
          .
	&> $logfile
   echo "Building VTK..."
   make -j2 
   sudo make install 
}

# Call the functions
build_wx
build_vtk

# mrMeshSrv 
cd $mesh_dir
echo "Building mrMeshSrv..."
# Execute the Makefile in mrMesh/server
make -j2 

echo "DONE!"


	
