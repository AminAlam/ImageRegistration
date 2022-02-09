function ceoff = HD(SeperateVertebrasF,SeperateVertebrasA)
    fn1 = fieldnames(SeperateVertebrasF);
    fn2 = fieldnames(SeperateVertebrasA);
    dist = [];
    for i = 15:1:30
        name = "Vertebra_"+num2str(i);
        if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
            P = (SeperateVertebrasF.(sprintf("Vertebra_%i", i)).pointCloud.Location);
            A = (SeperateVertebrasA.(sprintf("Vertebra_%i", i)).ptCloud_rotated.Location);
            max_dist = zeros(1,length(P));
            step = 1;
            tic
            for j1 = 1:step:length(P)
                p = P(j1,:);
                A_temp = sqrt((A(:,2)-p(:,2)).^2+(A(:,1)-p(:,1)).^2+(A(:,3)-p(:,3)).^2);
                max_dist(j1) = min(A_temp,[],'all');
            end
            toc
            dist = [dist,max_dist];
        end
    end
ceoff = max(dist,[],'all');