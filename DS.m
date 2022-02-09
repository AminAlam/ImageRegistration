% a function for calculating Dice score
function coeff = DS(SeperateVertebrasF,SeperateVertebrasA)
    cp = 0;
    pointP = 0;
    pointA = 0;
    fn1 = fieldnames(SeperateVertebrasF);
    fn2 = fieldnames(SeperateVertebrasA);
    for i = 15:1:30
        name = "Vertebra_"+num2str(i);
        if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
            pointP = pointP + length(SeperateVertebrasF.(sprintf("Vertebra_%i", i)).pointCloud.Location);
            pointA = pointA + length(SeperateVertebrasA.(sprintf("Vertebra_%i", i)).ptCloud_rotated.Location);
            cp = cp + (SeperateVertebrasF.(sprintf("Vertebra_%i", i)).CommonPointsWithAtlas);
%             name
%             disp('number of points P')
%             length(SeperateVertebrasF.(sprintf("Vertebra_%i", i)).pointCloud.Location)
%             disp('number of points A')
%             length(SeperateVertebrasA.(sprintf("Vertebra_%i", i)).ptCloud_rotated.Location)
%             disp('number of points cp')
%             length(SeperateVertebrasF.(sprintf("Vertebra_%i", i)).CommonPointsWithAtlas)
        end
    end
coeff = cp/(pointA+pointP);
    