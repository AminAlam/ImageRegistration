img1 = imread('test1.png');
img2 = imread('test2.png');
img2 = flip(img2);
DS(img1,img2)

function coeff = DS(img1,img2)

    img1_bw = im2bw(img1);
    img2_bw = im2bw(img2);
    coeff = dice(img1_bw,img2_bw);
    
end