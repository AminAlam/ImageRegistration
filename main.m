% Created and Developed by Amin Alam - 29th hun 2021

clc
clear

% loading datas
i = 2;
if i<10
    file_path = "./Project_Stuff/Datas/S0"+num2str(i)+"/";    
else
    file_path = "./Project_Stuff/Datas/S"+num2str(i)+"/";    
end

V1 = double(niftiread(file_path+"pat"+num2str(i)+".nii"));
V1_label = double(niftiread(file_path+"pat"+num2str(i)+"_label.nii"));
tool = imtool3D((V1));
setMask(tool,(V1_label));
%%
