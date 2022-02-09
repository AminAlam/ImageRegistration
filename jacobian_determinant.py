import numpy as np
import pystrum.pynd.ndutils as nd
import scipy.io
def jacobian_calc():
    disp = scipy.io.loadmat('DisplacemnetField.mat')
    disp = disp['DisplacemnetField']
    volshape = disp.shape[:-1]
    nb_dims = len(volshape)

    grid_lst = nd.volsize2ndgrid(volshape)
    grid = np.stack(grid_lst, len(volshape))

    J = np.gradient(disp + grid)

    dfdx = J[0]
    dfdy = J[1]

    out = dfdx[..., 0] * dfdy[..., 1] - dfdy[..., 0] * dfdx[..., 1]

    scipy.io.savemat('jacobian_mat.mat',{'jacobian_mat':out})
