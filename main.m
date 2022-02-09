% Created and Developed by Amin Alam - 29th hun 2021

clc
clear

% loading datas
path = "./Project_Stuff/Datas/";
i = 2;
[V, V_label] = NiiLoader(i,path);
tool = imtool3D((V));
setMask(tool,(V_label));
%% showing point clouds
ptCloud = Pcloudmaker(V_label);
ax = pcshow(ptCloud);
colormap jet

%% registration
clc
[V1, V1_label] = NiiLoader(i);
i = i + 1;
[V2, V2_label] = NiiLoader(i);
ptCloudMoving = Pcloudmaker(V1_label);
ptCloudFixed = Pcloudmaker(V2_label);
movingDownsampled = pcdownsample(ptCloudMoving,'gridAverage',5);
fixedDownsampled = pcdownsample(ptCloudFixed,'gridAverage',5);
figure
pcshowpair(movingDownsampled,fixedDownsampled,'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
title('Point clouds before registration')
legend({'Moving point cloud','Fixed point cloud'},'TextColor','w')
legend('Location','southoutside')

tform = pcregistercpd(movingDownsampled,fixedDownsampled);
movingReg = pctransform(movingDownsampled,tform);
figure
pcshowpair(movingReg,fixedDownsampled,'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
title('Point clouds after registration')
legend({'Moving point cloud','Fixed point cloud'},'TextColor','w')
legend('Location','southoutside')


