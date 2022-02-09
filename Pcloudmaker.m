function ptCloud=Pcloudmaker(Img)
[x, y, z] = ind2sub(size(Img), find(Img ~=0));
xyzPoints = [x, y, z];
[row, col] = find(Img ~=0);
ptCloud = pointCloud(xyzPoints);
% pcshow(ptCloud)


