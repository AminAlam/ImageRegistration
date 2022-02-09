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

% %%%%%%%%%%%%%%%%%%%%%%%%%%%% seperating each of vertebras and Pre Regeistration
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

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% caculating transform matrixes
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

% registration using 2 feed forward networks with 10 layer

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

ptCloud_A_transformed = pointCloud(ptCloudAllPointsA);

clc
DownSampled = pcdownsample(pointCloud(ptCloudAllPoints),'gridAverage',7);
ptCloud =  DownSampled;
[n,~] = size(DownSampled.Location);
% interpolating each vertebra
coeef = 0;
xP = []; yP = []; zP = [];
xR = []; yR  = []; zR = [];
for i = 15:1:30
    
    name = "Vertebra_"+num2str(i);
    if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
        coeef = coeef+1;
        beforeReg = SeperateVertebras.(sprintf("Vertebra_%i", i)).sampledPC;
        afterReg = SeperateVertebras.(sprintf("Vertebra_%i", i)).movingReg;
        locs_BR = beforeReg.Location;
        locs_AR = afterReg.Location;
        SampledPC_interpolated = interparc(n,locs_BR(:,1),locs_BR(:,2),locs_BR(:,3),'spline');
        MovingReg_interpolated = interparc(n,locs_AR(:,1),locs_AR(:,2),locs_AR(:,3),'spline');
        SeperateVertebras.(sprintf("Vertebra_%i", i)).sampledPC_interpolated = pointCloud(SampledPC_interpolated);
        SeperateVertebras.(sprintf("Vertebra_%i", i)).movingReg_interpolated = pointCloud(MovingReg_interpolated);
        
        SeperateVertebrasF.(sprintf("Vertebra_%i", i)).pointCloud = pointCloud(MovingReg_interpolated); 
        xP = [xP ; SampledPC_interpolated(:,1)];
        yP = [yP ; SampledPC_interpolated(:,2)];
        zP = [zP ; SampledPC_interpolated(:,3)];
        
        xR = [xR ; MovingReg_interpolated(:,1)];
        yR = [yR ; MovingReg_interpolated(:,2)];
        zR = [zR ; MovingReg_interpolated(:,3)];
    end
    
end

%
xyzP = [xP, yP, zP];
xyzR = [xR, yR, zR];

% pcshowpair(pointCloud([xP,yP,zP]), pointCloud(xyz))
pcshowpair(pointCloud(ptCloudAllPoints), pointCloud(xyzP))
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'main point cloud',' interpolated point cloud'},'TextColor','w')

clc

index = 1;
x = [];
t = [];

for i=1:coeef
x = [x, xyzP(i:coeef:end,index)];
t = [t, xyzR(i:coeef:end,index)];
end
trainFcn = 'trainscg'; 
hiddenLayerSize = 10;
net = fitnet(hiddenLayerSize,trainFcn);

net.divideParam.trainRatio = 100/100;
net.divideParam.valRatio = 0/100;
net.divideParam.testRatio = 0/100;

[net,tr] = train(net,x,t);

F_xR = net(DownSampled.Location(:,index));
%
index = 2;
x = [];
t = [];
for i=1:coeef
x = [x, xyzP(i:coeef:end,index)];
t = [t, xyzR(i:coeef:end,index)];
end

trainFcn = 'trainscg'; 
hiddenLayerSize = 10;
net = fitnet(hiddenLayerSize,trainFcn);

net.divideParam.trainRatio = 100/100;
net.divideParam.valRatio = 0/100;
net.divideParam.testRatio = 0/100;

[net,tr] = train(net,x,t);

F_yR = net(DownSampled.Location(:,index));
%
index = 3;
x = [];
t = [];
for i=1:coeef
x = [x, xyzP(i:coeef:end,index)];
t = [t, xyzR(i:coeef:end,index)];
end

trainFcn = 'trainscg'; 
hiddenLayerSize = 10;
net = fitnet(hiddenLayerSize,trainFcn);

net.divideParam.trainRatio = 100/100;
net.divideParam.valRatio = 0/100;
net.divideParam.testRatio = 0/100;

[net,tr] = train(net,x,t);

F_zR = net(DownSampled.Location(:,index));

SeperateVertebrasF.PCloud = pointCloud([F_xR,F_yR,F_zR]);
registered_pointCloud = SeperateVertebrasF.PCloud;

figure
pcshowpair(ptCloud_A_transformed, pointCloud([xP,yP,zP]))
legend({'before registration','before registration'},'TextColor','w')
figure
pcshowpair(ptCloud_A_transformed, pointCloud([xR,yR,zR]))
legend({'before registration','after mohre to mohre registration'},'TextColor','w')
figure
pcshowpair(ptCloud_A_transformed, pointCloud([F_xR,F_yR,F_zR]), 'MarkerSize',50)
legend({'Atlas','after network registration'},'TextColor','w')

% cacluating common points of each vertebra with atals
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