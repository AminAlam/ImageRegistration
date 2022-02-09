function coeff = DS(img1,img2)

    img1_bw = im2bw(img1);
    img2_bw = im2bw(img2);
    coeff = dice(img1_bw,img2_bw);
