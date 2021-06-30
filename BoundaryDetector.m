function boundaries = BoundaryDetector(I)
    BW = im2bw(I);
    BW_filled = imfill(BW,'holes');
    boundaries = bwboundaries(BW_filled);

