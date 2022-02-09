% a function for calculating colume of intersection between vertebras
function IntersetinVomume = VertebraIntersect_calc(SeperateVertebrasF,SeperateVertebrasA)
    IntersetinVomume = 0;
    fn1 = fieldnames(SeperateVertebrasF);
    fn2 = fieldnames(SeperateVertebrasA);
    for i = 15:1:30
            name = "Vertebra_"+num2str(i);
            if sum(ismember(fn1,name)) && sum(ismember(fn2,name))
                pointP = SeperateVertebrasF.(sprintf("Vertebra_%i", i)).pointCloud.Location;
                pointA = SeperateVertebrasF.(sprintf("Vertebra_%i", i+1)).pointCloud.Location;
                xP = pointP(:,1);
                yP = pointP(:,2);
                zP = pointP(:,3); 

                xA = pointA(:,1);
                yA = pointA(:,2);
                zA = pointA(:,3); 

                shpP = alphaShape(xP,yP,zP);
                shpA = alphaShape(xA,yA,zA);

                idP2A = inShape(shpA,xP,yP,zP);
                idA2P = inShape(shpP,xA,yA,zA);

                shp = alphaShape([xP(idP2A); xA(idA2P)], [yP(idP2A); yA(idA2P)], [zP(idP2A); zA(idA2P)]);
                IntersetinVomume = IntersetinVomume + volume(shp); 
                if sum(ismember(fn1,"Vertebra_"+num2str(i+2))) ==0
                    break
                end
            end 
    end


