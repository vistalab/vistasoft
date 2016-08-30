The vistatest directory contains code to validate functionality of the vistasfoft tools. Currently, the validation depends on an svn repository, though in the near future we hope to end this dependency:

vistadata: http://white.stanford.edu/newlm/index.php/Vistadata <br>

Core functionality of vistatest is based on Matlab's x-unit test suite (http://www.mathworks.com/matlabcentral/fileexchange/22846-matlab-xunit-test-framework). This is not a dependency because the necessary code is included in the repository

There are two simple uses of vistatest. 

(a) Call any of the validation files singly. For example
> test_mrInit

If it runs without error than mrInit has been validated.

(b) Call the script mrvTest to run all validation tests of a particular type. Example calls:

> % test BOLD validation core routines, and write the results in ~/myLogFile.m
> mrvTest('~/myLogFile.m', 'bold');

> % test BOLD validation core and extended routines, and write the results in ~/myLogFile.m> > mrvTest('~/myLogFile.m', 'bold', true);

> % test DIFFUSION validation core routines, and write the results in ~/myLogFile.m
> mrvTest('~/myLogFile.m', 'diffusion');

> % test ANATOMY validation core routines, and write the results in ~/myLogFile.m
> mrvTest('~/myLogFile.m', 'anatomy');


Directory contents:

Directories <br>
anatomy:   test functions for anatomical processing, currently mostly empty <br>
bold:      test functions for functional processing.  <br>
diffusion: test functions for diffusion processing, currently mostly empty <br>
matlab_xunit: external code from Mathworks <br>

Files <br>
.gitignore: Don't include '*.m~' files in repository <br>
README.md: you are here <br>
mrvGetEvironment.m: 	returns information about code and machine <br>
mrvTest.m: script to call all bold test functions and output a validation report <br>
mrvTestRootPath.m: 	path to this repository <br>
test_CleanUpSVN.m: sets vistadata SVN respository to current version <br>

