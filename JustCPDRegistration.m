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
ptCloud_P = Pcloudmaker(V_label);
ptCloud_A = Pcloudmaker(VA_label);

% downsampling
GridStep = 5;
moving = pcdownsample(ptCloud_P,'gridAverage',GridStep);
fixed = pcdownsample(ptCloud_A,'gridAverage',GridStep);
tform = pcregistercpd(moving, fixed);
movingReg = pctransform(moving, tform);


% seperating vertebras
Img = V_label;
VertebraNumbers = 15:1:30;
L = 0;
for i = VertebraNumbers
    [x, y, z] = ind2sub(size(Img), find(Img == i));
    xyzPoints = [x, y, z];
    ptCloud = pointCloud(xyzPoints);
    
    if ~isempty(ptCloud.Location)
        SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud = pcdownsample(ptCloud,'gridAverage',GridStep);
        L = L + length(SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud.Location);
        SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud_rotated = SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud;
        SeperateVertebras.(sprintf("Vertebra_%i", i)).number = i;
    end
end

Img = VA_label;
VertebraNumbers = 15:1:30;
for i = VertebraNumbers
    [x, y, z] = ind2sub(size(Img), find(Img == i));
    xyzPoints = [x, y, z];
    ptCloud = pointCloud(xyzPoints);
    
    if ~isempty(ptCloud.Location)
        SeperateVertebrasA.(sprintf("Vertebra_%i", i)).ptCloud_rotated = pcdownsample(ptCloud,'gridAverage',GridStep);;
        SeperateVertebrasA.(sprintf("Vertebra_%i", i)).number = i;
    end
end
registered_pointCloud = movingReg;
Locations = movingReg.Location;
Locations = interparc(L,Locations(:,1),Locations(:,2),Locations(:,3),'spline');
movingReg = pointCloud(Locations);
SeperateVertebrasF = Segmenter(movingReg.Location, SeperateVertebras, SeperateVertebrasA);
ptCloud_A_transformed = pcdownsample(ptCloud_A,'gridAverage',GridStep);
ptCloud = pcdownsample(ptCloud_P,'gridAverage',GridStep);

figure
pcshowpair(fixed, moving, 'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'Atlas','Subject'},'TextColor','w')
view(-46,-10)
% saveas(gcf,"./report/images/Subject"+num2str(SN)+"Original.png")

figure
pcshowpair(fixed, movingReg, 'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
legend({'Atlas','Subject'},'TextColor','w')
view(-46,-10)
% saveas(gcf,"./report/images/Subject"+num2str(SN)+"AfterJustCPD.png")

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