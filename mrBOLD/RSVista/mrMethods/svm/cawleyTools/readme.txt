MATLAB Support Vector Machine Toolbox
=====================================

(c) Dr Gavin Cawley, September 2000.

This is a (slightly less) beta version of a MATLAB toolbox implementing
Vapnik's support vector machine, as described in [1].  The toolbox currently
supports multi-class pattern recognition, Platt's sequential minimal
optimisation algorithm [2] and an efficient estimate of the leave-oe-out
cross-validation error [3].  The SMO training algorithm is implemented as a
mex file (for speed), and a .mexlx file for Linux machines is supplied.  At
the moment this is the only documentation for the toolbox but the file demo.m
provides a simple demonstration that ought to be enough to get started.  Key
features:

  (a) C++ MEX implementation of the SMO training algorithm, with caching of
      kernel evaluations for efficiency.

  (b) Support for multi-class pattern recognition.

  (c) An efficient criterion for model selection.

  (d) Object oriented design, currently this just means that you can supply
      bespoke kernel functions for particular applications, but will in future
      releases also support a range of training algorithms, model selection
      criteria etc.

LICENSING ARRANGEMENTS
======================

The toolbox is provided free for non-commercial use under the terms of the
GNU GPL licence (see licence.txt in this directory), however, I would be
grateful if: 

   (a) you let me know about any bugs you find,

   (b) you send suggestions of ideas to improve the toolbox (e.g.
       references to other training algorithms),

   (c) reference the toolbox web page in any publication describing research
       performed using the toolbox, or software derived from the toolbox.  A
       suitable BibTeX entry would look something like this: 

@misc{Cawley2000,
   author       = "Cawley, G. C.",
   title        = "{MATLAB} Support Vector Machine Toolbox (v0.50$\beta$) $[$
                  \texttt{http://theoval.sys.uea.ac.uk/\~{}gcc/svm/toolbox}$]$",
   howpublished = "University of East Anglia, School of Information Systems,
                   Norwich, Norfolk, U.K. NR4 7TJ",
   year         = 2000 
}    

TO DO LIST
==========

1. Find time to write a proper list of things to do!

2. Documentation.

3. Support Vector Regression.

4. Automated model selection.

REFERENCES
==========

[1] V.N. Vapnik,
    "The Nature of Statistical Learning Theory",
    Springer-Verlag, New York, ISBN 0-387-94559-8,
    1995.  

[2] J. C. Platt,
    "Fast training of support vector machines using sequential minimal
    optimization", in Advances in Kernel Methods - Support Vector Learning,
    (Eds) B. Scholkopf, C. Burges, and A. J. Smola, MIT Press, Cambridge,
    Massachusetts, chapter 12, pp 185-208, 1999. 

[3] T. Joachims, "Estimating the Generalization Performance of a SVM
    Efficiently", LS-8 Report 25, Universitat Dortmund, Fachbereich
    Informatik, 1999. 

