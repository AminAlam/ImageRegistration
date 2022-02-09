% Created and Developed by Amin Alam - 29th hun 2021
clc
clear
close all
% loading datas

SN = 18;
file_path = "./Project_Stuff/Datas/";
[V, V_label] = NiiLoader(SN,file_path);
tool = imtool3D((V));
setMask(tool,(V_label));
% saveas(gcf,"./report/images/Subject"+num2str(SN)+".png")
% showing point clouds
close all
figure
ptCloud = Pcloudmaker(V_label);
pcshow(ptCloud);
xlabel('X')
ylabel('Y')
zlabel('Z')
view(-46,60)
colormap jet
% saveas(gcf,"./report/images/MainPCSubject"+num2str(SN)+".png")
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Atlas preview
close all
file_path = "./Healthy_sample/";
VA = double(niftiread(file_path+"00"+".nii"));
VA_label = double(niftiread(file_path+"00_mask.nii"));
tool = imtool3D((VA));
setMask(tool,(VA_label));
ptCloud_A = Pcloudmaker(VA_label);
pcshow(ptCloud_A);
xlabel('X')
ylabel('Y')
zlabel('Z')
view(-46,60)
colormap jet


close all
GridStep = 5;
ptCloud_P = Pcloudmaker(V_label);
ptCloud_A = Pcloudmaker(VA_label);
[alpha_1_P, beta_1_P, alpha_2_P] = RotationParams(ptCloud_P.Location);
[alpha_1_A, beta_1_A, alpha_2_A] = RotationParams(ptCloud_A.Location);
ptCloud_P_R = pointCloud(PreRegister(ptCloud_P.Location,alpha_1_P, beta_1_P, alpha_2_P));
ptCloud_A_R = pointCloud(PreRegister(ptCloud_A.Location,alpha_1_A, beta_1_A, alpha_2_A));

SeperateVertebras = vertebra_seperator(V_label, alpha_1_P, beta_1_P, alpha_2_P, GridStep);
SeperateVertebrasA = vertebra_seperator(VA_label, alpha_1_A, beta_1_A, alpha_2_A, GridStep);


fn1 = fieldnames(SeperateVertebras);
fn2 = fieldnames(SeperateVertebrasA);
clc
for i = 15:1:30
    name = "Vertebra_"+num2str(i);
    if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
        moving = SeperateVertebras.(sprintf("Vertebra_%i", i)).sampledPC;
        fixed = SeperateVertebrasA.(sprintf("Vertebra_%i", i)).sampledPC;
        tform = pcregistercpd(moving, fixed);
        SeperateVertebras.(sprintf("Vertebra_%i", i)).tform = tform;
        movingReg = pctransform(moving, tform);
        SeperateVertebras.(sprintf("Vertebra_%i", i)).movingReg = movingReg;

        LocsA_R = fixed.Location;
        LocsP_R = movingReg.Location;
        cp = CommonPoints(LocsA_R, LocsP_R);
        SeperateVertebras.(sprintf("Vertebra_%i", i)).CommonPointsWithAtlas = cp;
    end
end


clc
fn1 = fieldnames(SeperateVertebras);
fn2 = fieldnames(SeperateVertebrasA);
locs_BR = [];
locs_AR = [];

% datas to find curve fit
for i = 15:1:30
    name = "Vertebra_"+num2str(i);
    if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
        beforeReg = SeperateVertebras.(sprintf("Vertebra_%i", i)).sampledPC;
        afterReg = SeperateVertebras.(sprintf("Vertebra_%i", i)).movingReg;
        locs_BR = [locs_BR; beforeReg.Location];
        locs_AR = [locs_AR; afterReg.Location];
    end
end

xP = locs_BR(:,1); yP = locs_BR(:,2); zP = locs_BR(:,3);
xR = locs_AR(:,1); yR = locs_AR(:,2); zR = locs_AR(:,3);

polyOrder = 3;
fitobject_x = polyfit(xP,xR,polyOrder);
fitobject_y = polyfit(yP,yR,polyOrder);
fitobject_z = polyfit(zP,zR,polyOrder);
%
% fit datas using curve fit
ptCloudAllPoints = [];
ptCloudAllPointsA = [];

for i = 15:1:30
    name = "Vertebra_"+num2str(i);
    if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
        PtCloud = SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud_rotated;
        ptCloudAllPoints = [ptCloudAllPoints; PtCloud.Location];
       
        PtCloudA = SeperateVertebrasA.(sprintf("Vertebra_%i", i)).sampledPC;
        ptCloudAllPointsA = [ptCloudAllPointsA; PtCloudA.Location];
    end
end
ptCloudAllPoints = ptCloud_P_R.Location;
xP_all = ptCloudAllPoints(:,1); yP_all = ptCloudAllPoints(:,2); zP_all = ptCloudAllPoints(:,3);
xP_all_R = polyval(fitobject_x,xP_all); yP_all_R = polyval(fitobject_y,yP_all); zP_all_R = polyval(fitobject_z,zP_all);

registered_pointCloud = pointCloud([xP_all_R, yP_all_R, zP_all_R]);
ptCloud_A_transformed = pointCloud(ptCloudAllPointsA);

SeperateVertebrasF = Segmenter([xP_all_R, yP_all_R, zP_all_R],SeperateVertebras,SeperateVertebrasA);

figure
pcshowpair(ptCloud_A_transformed, pointCloud(locs_BR), 'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'Atlas',' patient'},'TextColor','w')
title('Point clouds before registration')

figure
pcshowpair(ptCloud_A_transformed,  pointCloud(locs_AR), 'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'Atlas','patient'},'TextColor','w')
title('Point clouds after mohre to mohre registration')

figure
pcshowpair(ptCloud_A_transformed,  pointCloud(ptCloudAllPoints), 'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'Atlas','patient'},'TextColor','w')
title('Point clouds before polyval transformation')

figure
pcshowpair(ptCloud_A_transformed, registered_pointCloud, 'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'Atlas','patient'},'TextColor','w')
title('Point clouds after polyval transformation')


clc
fn1 = fieldnames(SeperateVertebras);
fn2 = fieldnames(SeperateVertebrasA);
for i = 15:1:30
        name = "Vertebra_"+num2str(i);
        if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
            moving = SeperateVertebrasF.(sprintf("Vertebra_%i", i)).pointCloud;
            fixed = SeperateVertebrasA.(sprintf("Vertebra_%i", i)).ptCloud_rotated;
            LocsA_R = fixed.Location;
            LocsP_R = moving.Location;
            cp = CommonPoints(LocsA_R, LocsP_R);
            SeperateVertebrasF.(sprintf("Vertebra_%i", i)).CommonPointsWithAtlas = cp;
        end
end
% Dice score
clc
DiceScore = DS(SeperateVertebrasF,SeperateVertebrasA)
% Hausdorff Distance

HausdorffScore = HD(SeperateVertebrasF,SeperateVertebrasA)
% Average Surface Distance

ASD_Score = ASD(SeperateVertebrasF.PCloud, ptCloud_A_transformed)
% intersection of vertebras

VertebraIntersectsVolume = VertebraIntersect_calc(SeperateVertebrasF,SeperateVertebrasA)
% jacobian of displacemnet field
try
DisplacemnetField = registered_pointCloud.Location - ptCloud.Location;
JacobianMatofDisplacemnetField = JacobianMatCalc(DisplacemnetField)
catch
    disp('there is a prolem with your python entrepretor. check it using pyenv command')
end