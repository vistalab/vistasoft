
/*
  This file has an implementation of the LAPACK routine dsyev
  for C++.  This program solves for the eigenvalues and, if
  desired, the eigenvectors for a square symmetric matrix H.
  It assumes that the upper triangle of H is stored.

    void dsyev(double **H, int n, double *E, double **Evecs)

    H: the n by n symmetric matrix that we are solving, with the
       upper triangle stored
    n: the order of the square matrix H
    E: an n-element array to hold the eigenvalues of H
    Evecs: an n by n matrix to hold the eigenvectors of H

  Source: www-heller.harvard.edu/~shaw/programs/dsyev.h
  Scot Shaw, 30 August 1999
*/

#include <math.h>

void dsyev(double *H, int n, double *E, double *Evecs);
void dsyev_sort(double *E, double *Evecs, int N);

void dsyev_(char *jobz, char *uplo, int *n, double *a,
	       int *lda, double *w, double *work, int *lwork,
	       int *info);

void dsyev(double *H, int n, double *E, double *Evecs)
{
  char jobz = 'V'; /* V/N indicates that eigenvectors should/should not
                 be calculated. */
  char uplo = 'U'; /* U/L indicated that the upper/lower triangle of the
		  symmetric matrix is stored. */
  int lda = n; /* The leading dimension of the matrix to be solved. */
  int lwork = 3*n-1;
  double work[lwork]; /* The work array to be used by dsyev and
                               its size. */

  /* Copy to input array for dsyev */
  int i;
  double a[n*lda];
  for (i=0; i<n*lda; i++) a[i] = H[i];
  
  /* Main function call */
  int info;
  dsyev_(&jobz, &uplo, &n, a, &lda, E, work, &lwork, &info);

  /* Copy output */
  for (i=0; i<n*n; i++) Evecs[i] = a[i];

  dsyev_sort(E, Evecs, n); /* Sort by eigenvalue in decreasing order. */
}

void dsyev_sort(double *E, double *Evecs, int N)
{
  double temp;
  int i, j, k;

  for (j=0; j<N; j++) for (i=0; i<N-1; i++)
    if (fabs(E[i])<fabs(E[i+1])) {
      temp = E[i]; E[i] = E[i+1]; E[i+1] = temp;
      
      for (k=0; k<N; k++) {
	temp = Evecs[k+i*N];
	Evecs[k+i*N] = Evecs[k+(i+1)*N];
	Evecs[k+(i+1)*N] = temp;
      }
    }
}
