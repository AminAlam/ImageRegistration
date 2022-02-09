% this function calculates Average Surface Distance
function coeff = ASD(pCloudP,pCloudA)
    P = boundaryPC(pCloudP).Location;
    A = boundaryPC(pCloudA).Location;
    step = 10;
    dist = zeros(1,length(P));
    
    for j = 1:step:length(P)
        p = P(j,:);
        A_temp = sqrt((A(:,2)-p(:,2)).^2+(A(:,1)-p(:,1)).^2+(A(:,3)-p(:,3)).^2);
        dist(j) = min(A_temp,[],'all');
    end
    
    dist = sum(dist);
    coeff = 2*dist/(length(P)+length(A));
    