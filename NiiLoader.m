function [V, V_label] = NiiLoader(i)
if i<10
    file_path = "./Project_Stuff/Datas/S0"+num2str(i)+"/";    
else
    file_path = "./Project_Stuff/Datas/S"+num2str(i)+"/";    
end

V = double(niftiread(file_path+"pat"+num2str(i)+".nii"));
V_label = double(niftiread(file_path+"pat"+num2str(i)+"_label.nii"));

