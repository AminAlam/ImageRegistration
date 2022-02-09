% this function segments final point clouds according to preregisterd
function SeperateVertebrasF = Segmenter(Locations, SeperateVertebras, SeperateVertebrasA)
    fn1 = fieldnames(SeperateVertebras);
    fn2 = fieldnames(SeperateVertebrasA);
    totalLocs = [];
    L1 = 0;
    for i = 15:1:30
        name = "Vertebra_"+num2str(i);
        if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
            pc_PreFR = SeperateVertebras.(sprintf("Vertebra_%i", i)).ptCloud_rotated;
            L2 = length(pc_PreFR.Location);
            vertebra = Locations(L1+1:L1+L2,:);
%               indexes = SeperateVertebras.(sprintf("Vertebra_%i", i)).indexes;
%               vertebra = Locations(indexes,:);
            L1 = L1 + L2;
            SeperateVertebrasF.(sprintf("Vertebra_%i", i)).pointCloud = pointCloud(vertebra);
            totalLocs = [totalLocs; vertebra];
        end
    end
    SeperateVertebrasF.PCloud = pointCloud(totalLocs);

