"""

Use dipy to track from an entire ROI, provided a CSD estimat in .nii format

"""

from Tkinter import Tk
import tkFileDialog

import numpy as np

import nibabel as ni
import nibabel.trackvis as tv

from dipy.tracking.propagation import EuDX
from dipy.utils.spheremakers import sphere_vf_from
from dipy.core import geometry as geo
import dipy.reconst.recspeed as rp

from scipy.special import sph_harm
from scipy.io import loadmat

class CSD(object):
    """
    Constrained Spherical Deconvolution (CSD) [Tournier2007]_ is an ODF
    reconstruction method which relies on the representation of the ODF as a
    linear combination of a selection of spherical harmonics.
    

    [Tournier2007]: Tournier, J. D., Calamante, F., Connelly, A. Robust
    determination of the fibre orientation distribution in diffusion MRI:
    Non-negativity constrained super-resolved spherical
    deconvolution. Neuroimage 2007; 35: 1459-1472.

    Note
    ----
    For now, this class calculates derived measures (qa and ind), used in the
    `dipy` implementation of Euler delta crossing. The estimate of the CSD
    coefficients needs to be calcualted in advance, using `mrtrix`.  
    
    """ 
    def __init__(self,
                 nifti_file,
                 mask=None,
                 odf_sphere='symmetric362',
                 auto=True):
        """
        Initialize your CSD object. For now, this is derived from a
        pre-computed CSD estimate calculated with  
        
        """

        self.data = ni.load(nifti_file).get_data()
        if mask is not None: 
            if isinstance(mask,np.ndarray):
                self.mask=mask
            elif isinstance(mask, str):
                self.mask = ni.load(mask).get_data()
        
        odf_vertices, odf_faces = sphere_vf_from(odf_sphere)
        self.odf_vertices = odf_vertices
        self.odf_faces = odf_faces
        self.n_params = self.data.shape[-1]
        self.L = calculate_L(self.n_params) 
        self.b = self.sph_harm_set(self.L, self.n_params, odf_vertices)

        self.peak_thr=.5
        self.iso_thr=.9        
        
        if auto:
            self.fit()

    def sph_harm_set(self, L, n_params, odf_vertices):
        """
        Calculate the spherical harmonics relevant to the , provided n
        parameters (corresponding to nc = (L+1) * (L+2)/2 with L being the
        maximal harmonic degree

        From the documentation of mrtrix's 'csdeconv': 


          Note that this program makes use of implied symmetries in the
          diffusion profile. First, the fact the signal attenuation profile is
          real implies that it has conjugate symmetry, i.e. Y(l,-m) = Y(l,m)*
          (where * denotes the complex conjugate). Second, the diffusion
          profile should be antipodally symmetric (i.e. S(x) = S(-x)), implying
          that all odd l components should be zero. Therefore, this program
          only computes the even elements.

          Note that the spherical harmonics equations used here differ slightly
          from those conventionally used, in that the (-1)^m factor has been
          omitted. This should be taken into account in all subsequent
          calculations.

          Each volume in the output image corresponds to a different spherical
          harmonic component, according to the following convention: [0]    
          Y(0,0)  [1] Im {Y(2,2)} [2] Im {Y(2,1)} [3]     Y(2,0) [4] Re
          {Y(2,1)} [5] Re {Y(2,2)}  [6] Im {Y(4,4)} [7] Im {Y(4,3)} etc... 

        Note that it seems that sph_harm actually has the order/degree in
        reverse order than the convention used by mrtrix.
        """
    
        # Convert to spherical coordinates:
        r,theta,phi = geo.cart2sphere(odf_vertices[:,0],
                                      odf_vertices[:,1],
                                      odf_vertices[:,2])

        # Preallocate:
        b = np.empty((n_params, theta.shape[0]))
    
        i = 0;
        # Only even order are taken:
        for order in np.arange(0,L,2):
            for degree in np.arange(-order,order+1):
                # In negative degrees, take the imaginary part: 
                if degree < 0:  
                    b[i,:] = np.imag(sph_harm(-1*degree, order, theta, phi));
                else:
                    b[i,:] = np.real(sph_harm(degree, order, theta, phi));
                i = i+1;

        return b
            
    def fit(self): 
        """
        Perform the relatively heavy computations to extract the qa and inds
        properties
        
        1. Given a nifti file with dimensions (x,y,z,n_weights) generate a volume
        with dimensions (x,y,z, odf_n) where each voxel has:

        .. math::

          \sum{w_i, b_i}

        Where $b_i$ are the basis set functions defined from the spherical
        harmonics

        2. Use peak-finding, to calculate an analog of QA, based on
        the CSD estimate of the ODF.
        
        """
        S = self.data
        datashape = self.data.shape
        volshape = datashape[:3]  # Disregarding the params dimension 
        n_vox = np.prod(volshape)
        n_weights = datashape[3]  # This is the params dimension 

        # Reshape it so that we can multiply for all voxels in one fell swoop:
        d = np.reshape(self.data, (n_vox, n_weights))

        # multiply these two matrices together for the odf:  
        odf = np.asarray(np.matrix(d) * np.matrix(self.b))

        # Preallocate: 
        QA = np.zeros((n_vox, 5))
        IN = np.zeros((n_vox, 5))
        
        
        # One norm param for everything, based on the maximum of the maximal ODF.
        glob_norm_param = 0   
        if self.mask is not None:
            # The mask should have dims (x,y,z):
            msk=np.reshape(self.mask, n_vox)

        else:
            # Look everywhere:
            msk = np.ones(n_vox)
            
        for vox in range(n_vox):
            if msk[vox]>0:
                peaks,inds=rp.peak_finding(odf[vox], self.odf_faces)
                glob_norm_param=max(np.max(odf[vox]), glob_norm_param)
                min_odf = np.min(odf[vox])
                
                l=self.reduce_peaks(peaks,min_odf)
                if l==0:
                    QA[vox][0] = peaks[0]-min_odf
                    IN[vox][0] = inds[0]
                if l>0:
                    # Enforce 5 peaks or less: 
                    if l>5:
                        l=5
                    QA[vox][:l] = peaks[:l]-min_odf
                    IN[vox][:l] = inds[:l]

        QA/=glob_norm_param

        qa_shape = volshape + (5,)

        self.QA = np.reshape(QA, qa_shape)
        self.IN = np.reshape(IN, qa_shape)

        # Tuple concatenation: 
        odf_shape =  volshape + (odf.shape[-1],)
        self.odf = np.reshape(odf, odf_shape)
    
    def reduce_peaks(self,peaks,odf_min):
        """
        helping peak_finding when too many peaks are available 
        
        """
        if len(peaks)==0:
            return -1 
        if odf_min<self.iso_thr*peaks[0]:
            #remove small peaks
            ismallp=np.where(peaks<self.peak_thr*peaks[0])
            if len(ismallp[0])>0:
                l=ismallp[0][0]
            else:
                l=len(peaks)
        else:
            return -1
        return l

    def qa(self):
        """
        Quantitative anisotropy
        """
        if hasattr(self, 'QA'):
            return self.QA
        else:
            raise ValueError("QA hasn't been calculated yet. Run .fit()")

    def ind(self):
        """ 
        indices on the sampling sphere
        """
        if hasattr(self, 'IN'):
            return self.IN
        else:
            raise ValueError("ind hasn't been calculated yet. Run .fit()")
    
    
def calculate_L(n):
    """ 
    Calculate the maximal harmonic order (L), given that you know the number of
    parameters that were estimated. This proceeds according to the following
    logic:

    .. math:: 

       n = \frac{1}{2} (L+1) (L+2)

       \rarrow 2n = L^2 + 3L + 2
       \rarrow L^2 + 3L + 2 - 2n = 0
       \rarrow L^2 + 3L + 2(1-n) = 0

       \rarrow L_{1,2} = \frac{-3 \pm \sqrt{9 - 8 (1-n)}}{2}

       \rarrow L{1,2} = \frac{-3 \pm \sqrt{1 + 8n}}{2}


    Finally, the positive value is chosen between the two options. 

    """


    L1 = (-3 + np.sqrt(1+ 8 *n))/2
    L2 = (-3 - np.sqrt(1+ 8 *n))/2

    return max([L1,L2])

def get_roi_from_mat(roi_mat_file, affine=None):
    """

    Get the ROI coordinates from an mrDiffusion mat-file format and transform
    using an affine, if provided. 
    
    """

    coords = loadmat(roi_mat_file, squeeze_me=True)['roi'].coords

    if affine is not None: 
        coords = np.array(align_to_acpc(coords.T,
                                         affine,
                                         round_it=True)).T.astype(int)

    return coords[:,0]-1,coords[:,1]-1,coords[:,2]-1
    
def align_to_acpc(xyz_orig, qform, round_it=False):
    """
    Transform a set of coordinates, xyz by an affine qform. If requested, make
    sure that the answer is rounded.  
    """ 


    xyz_orig = np.asarray(xyz_orig)

    # If this is a single point: 
    if len(xyz_orig.shape) == 1:
        xyz_orig1 = np.vstack([np.array([xyz_orig]).T,1])
    else:
        xyz_orig1 = np.vstack([xyz_orig,np.ones(xyz_orig.shape[-1])])

    if round:
        xyz1 = np.round(np.matrix(qform).getI() * xyz_orig1)
    else: 
        xyz1 = np.matrix(qform).getI() * xyz_orig1

    x, y, z = (np.array(xyz1[0]).squeeze(),
               np.array(xyz1[1]).squeeze(),
               np.array(xyz1[2]).squeeze())        

    return x,y,z
    
if __name__=="__main__":
 
    # Use a TK dialog to get user input (which files to use): 
    master = Tk()
    master.withdraw() #hiding tkinter window
    
    csd_file = tkFileDialog.askopenfilename(title="CSD file",
            filetypes=[("nifti",".nii"),("gzipped nifti", "nii.gz"),
                        ("All files",".*")])

    if csd_file == "":
        raise ValueError("No file chosen")

    mask_file = tkFileDialog.askopenfilename(title="Mask file",
            filetypes=[("nifti",".nii"),("gzipped nifti", "nii.gz"),
                        ("All files",".*")])
    if mask_file == "":
        print("No mask was chosen")

    roi_file = tkFileDialog.askopenfilename(title="mrDiffusion ROI file",
            filetypes=[("mat file",".mat"),("All files",".*")])
    
    # Once that's settled, you can kill the tkinter window:
    master.quit()


    # And move on to processing
    C = CSD(csd_file, mask_file)

    affine = ni.load(csd_file).get_affine()
    roi_coords = np.array(get_roi_from_mat(roi_file, affine)).T
    
    eu = EuDX(a=C.qa(), ind=C.ind(), seeds=roi_coords, a_low=.03)

    # Following: http://web.archiveorange.com/archive/v/AW2a1JYHnD5DycIdS5NW
    # This is the format expected by trackvis.write: 
    streamlines = [[track, None, None] for track in eu] 
    # Need to get the affine. Get it from the mask, because it has the right
    # shape:
    
    img = ni.load(mask_file)
    aff = img.get_affine()
    # And provide it to the trackvis 
    hdr = tv.empty_header()
    tv.aff_to_hdr(aff, hdr)
    hdr['dim'] = img.shape

    f='tracks.trk'
    tv.write(f,streamlines,hdr, points_space='voxel')
