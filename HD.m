function ceoff = HD(img1,img2)
    boundaries1 = BoundaryDetector(double(img1));
    boundaries2 = BoundaryDetector(double(img2));
    P = reshape(boundaries1,1,[]);
    Q = reshape(boundaries2,1,[]);
    ceoff = HausdorffDist(P,Q);