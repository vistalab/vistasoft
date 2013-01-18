# Compiles build_mesh, smooth_mesh, curvature
# renobowen@gmail.com [2011]

basedir="`pwd`"
logfile=$basedir/buildlog

gcc_branch="origin/gcc-4_2-branch"
gcc_dir=$basedir/gcc
gcc_build=$gcc_dir/build
gcc_bin=$gcc_build/bin/gcc
gxx_bin=$gcc_build/bin/g++

cmake_dir=$basedir/cmake
cmake_build=$cmake_dir/build
cmake_bin=$cmake_build/bin/cmake

vtk_branch="v5.0.4"
vtk_dir=$basedir/vtk
vtk_build=$vtk_dir/build

matlab_version="r2009b"
matlab_options="-nodesktop -nosplash -nojvm -r"
matlab_mexopts=/white/scr1/matlab/$matlab_version/bin/mexopts.sh

# GCC / G++
function get_gcc {
	mkdir $gcc_dir $gcc_build 

	echo "Retrieving GCC..."
	cd $gcc_dir
	git clone git://gcc.gnu.org/git/gcc.git source 

	# I've specified version 4.2, but if you'd like to view other branches: 
	# git branch -a | grep gcc-
	cd source 
	git checkout $gcc_branch

	echo "Building GCC..."
	cd $gcc_build
	../source/configure --prefix=$gcc_build --disable-multilib &> $logfile

	make -j 4 &> $logfile
	make install &> $logfile
}

# CMake
function get_cmake {
	mkdir $cmake_dir $cmake_build

	echo "Retrieving CMake..."
	cd $cmake_dir
	git clone git://cmake.org/cmake.git source 

	cd source
	git checkout quiet release 

	echo "Building CMake..."
	cd $cmake_build
	../source/configure --prefix=$cmake_build &> $logfile

	make -j 4 &> $logfile
	make install &> $logfile
}

# VTK
function get_vtk {
	mkdir $vtk_dir $vtk_build

	echo "Retrieving VTK..."
	cd $vtk_dir
	git clone git://vtk.org/VTK.git source 

	cd source
	git checkout $vtk_branch 

	echo "Building VTK..."
	$cmake_bin \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DBUILD_EXAMPLES:BOOL=OFF \
		-DVTK_USE_ANSI_STDLIB:BOOL=ON \
		-DBUILD_TESTING:BOOL=OFF \
		-DCMAKE_BUILD_TYPE:STRING=Release \
		-DVTK_USE_HYBRID:BOOL=ON \
		-DVTK_USE_PARALLEL:BOOL=ON \
		-DVTK_USE_RENDERING:BOOL=ON \
		-DVTK_USE_PATENTED:BOOL=ON \
		-DCMAKE_INSTALL_PREFIX:STRING=$vtk_build \
		-DCMAKE_CXX_FLAGS_RELEASE:STRING="-fPIC" \
		-DCMAKE_C_FLAGS_RELEASE:STRING="-fPIC" \
		-DCMAKE_C_COMPILER:STRING=$gcc_bin \
		-DCMAKE_CXX_COMPILER:STRING=$gxx_bin \
		&> $logfile

	make -j 4 &> $logfile
	make install &> $logfile
}

# MEX Files
function build_mexfiles {
	cp $matlab_mexopts $basedir/mexopts.sh 

	sed -i -e "s:CC='gcc':CC='$gcc_bin':" $basedir/mexopts.sh
	sed -i -e "s:CXX='g++':CXX='$gxx_bin':" $basedir/mexopts.sh
	sed -i -e "s:CFLAGS='-ansi -D_GNU_SOURCE':CFLAGS='-ansi -D_GNU_SOURCE -Wno-deprecated':" $basedir/mexopts.sh
	sed -i -e "s:CXXFLAGS='-ansi -D_GNU_SOURCE':CXXFLAGS='-ansi -D_GNU_SOURCE -Wno-deprecated':" $basedir/mexopts.sh

	echo "Building mex files..."
	matlab$matlab_version $matlab_options "cd(fileparts(which('build_mesh.cpp'))); mex -f '$basedir/mexopts.sh'	build_mesh.cpp -I$vtk_build/include/vtk-5.0 -L$vtk_build/lib -lvtkFiltering -lvtkCommon -lvtkGraphics -lvtkFiltering -lpthread -ldl; mex -f '$basedir/mexopts.sh' curvature.cpp -I$vtk_build/include/vtk-5.0 -L$vtk_build/lib -lvtkFiltering -lvtkCommon -lvtkGraphics -lvtkFiltering -lpthread -ldl; mex -f '$basedir/mexopts.sh' smooth_mesh.cpp -I$vtk_build/include/vtk-5.0 -L$vtk_build/lib -lvtkFiltering -lvtkCommon -lvtkGraphics -lvtkFiltering -lpthread -ldl; exit;"
}

get_gcc
get_cmake
get_vtk
build_mexfiles

echo "Finished."
