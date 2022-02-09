function cp = CommonPoints(LocsA_R, LocsP_R)
    x = LocsA_R(:,1); y = LocsA_R(:,2); z = LocsA_R(:,3);
    qx = LocsP_R(:,1); qy = LocsP_R(:,2); qz = LocsP_R(:,3);
    shp = alphaShape(x,y,z);
    figure
    plot(shp)
    hold on
    scatter3(qx,qy,qz)
    tf = inShape(shp,qx,qy,qz);
    cp1 = sum(tf);

    
    shp = alphaShape(qx,qy,qz);
    tf = inShape(shp,x,y,z);
    cp2 = sum(tf);
    
    cp = cp1+cp2;
    
   


