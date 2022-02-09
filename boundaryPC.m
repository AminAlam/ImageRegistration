% this function returns boundary of a point cloud
function PC_P = boundaryPC(pc)
    P = pc.Location;
    tri1 = boundary(P,1);
    h = [P(tri1(:,1),1),P(tri1(:,2),2),P(tri1(:,3),3)];
    PC_P = pointCloud(h);


