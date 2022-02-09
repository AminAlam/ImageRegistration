function SeperateVertebras = vertebra_seperator(V_label,alpha_1, beta_1, alpha_2, GridStep)
    Img = V_label;
    VertebraNumbers = 15:1:30;
    for i = VertebraNumbers
        [x, y, z] = ind2sub(size(Img), find(Img == i));
        xyzPoints = [x, y, z];
        ptCloud = pointCloud(xyzPoints);
        if ~isempty(ptCloud.Location)
            SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud = ptCloud;
            SeperateVertebras.(sprintf("Vertebra_%i", i)).number = i;
            pc = PreRegister(ptCloud.Location,alpha_1, beta_1, alpha_2);
            ptCloud_rotated = pointCloud(pc);
            SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud_rotated = ptCloud_rotated;
            Boundary = boundaryPC(ptCloud_rotated);
            SeperateVertebras.(sprintf("Vertebra_%i", i)).boundaryPointC = Boundary;
            SeperateVertebras.(sprintf("Vertebra_%i", i)).sampledPC = pcdownsample(Boundary,'gridAverage',GridStep);
        end
    end