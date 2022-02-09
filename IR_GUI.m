classdef IR_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        LeftPanel                     matlab.ui.container.Panel
        DevelopedbyMohammadAminAlamalhodaLabel  matlab.ui.control.Label
        ImageRegistrationMIAPCoureProjectLabel  matlab.ui.control.Label
        LoadSubjectImageButton        matlab.ui.control.Button
        LoadAtlasImageButton          matlab.ui.control.Button
        PreRegistrationButton         matlab.ui.control.Button
        Status                        matlab.ui.control.EditField
        RegistrationButton            matlab.ui.control.Button
        RegistrationTyoeButtonGroup   matlab.ui.container.ButtonGroup
        CPDButton                     matlab.ui.control.RadioButton
        PolynomialFitButton           matlab.ui.control.RadioButton
        CascadeFeedForwardNetsButton  matlab.ui.control.RadioButton
        RightPanel                    matlab.ui.container.Panel
        UIAxes                        matlab.ui.control.UIAxes
        UIAxes2                       matlab.ui.control.UIAxes
        UIAxes3                       matlab.ui.control.UIAxes
        UIAxes4                       matlab.ui.control.UIAxes
        DiceScoreLabel                matlab.ui.control.Label
        AverageSurfaceDistanceLabel   matlab.ui.control.Label
        HausdorffDistanceLabel_2      matlab.ui.control.Label
        VolumebetweenvertebrasLabel   matlab.ui.control.Label
        NOFnonpositiveelementsofjacobianmatrixofdisplacmentfieldLabel  matlab.ui.control.Label
        ASD                           matlab.ui.control.EditField
        HD                            matlab.ui.control.EditField
        VBV                           matlab.ui.control.EditField
        JOD                           matlab.ui.control.EditField
        DS                            matlab.ui.control.EditField
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end


    
    methods (Access = public)
        
        function buttonsManager(app,mode)
                app.LoadAtlasImageButton.Enable = mode;
                app.LoadSubjectImageButton.Enable = mode;
                app.PreRegistrationButton.Enable = mode;
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadSubjectImageButton
        function LoadSubjectImageButtonPushed(app, event)
            buttonsManager(app,'off')
            
            global ptCloudP;
            global ptCloudA;
            global V_label;
            global VA_label;
            [filename,path] = uigetfile('*.nii');
            loaddata = fullfile(path,filename);
            V_label = niftiread(loaddata);
            ax = app.UIAxes;
            ptCloudP = Pcloudmaker(V_label);
            
            ptCloudP = pcdownsample(ptCloudP,'gridAverage',5);
            
            try 
                MyPcshow(ptCloudP, 'Parent', ax);
            catch
                 close Figure 1
            end
            colormap(ax,"jet")
            
            buttonsManager(app,'on')
        end

        % Button pushed function: LoadAtlasImageButton
        function LoadAtlasImageButtonPushed(app, event)
            buttonsManager(app,'off')
            
            global ptCloudP;
            global ptCloudA;
            global V_label;
            global VA_label;
            [filename,path] = uigetfile('*.nii');
            loaddata = fullfile(path,filename);
            VA_label = niftiread(loaddata);
            ax = app.UIAxes2;
            ptCloudA = Pcloudmaker(VA_label);
            
            ptCloudA = pcdownsample(ptCloudA,'gridAverage',5);

            try 
                MyPcshow(ptCloudA, 'Parent', ax);
            catch
                 close Figure 1
            end
            colormap(ax,"jet")
            
            buttonsManager(app,'on')
        end

        % Button pushed function: PreRegistrationButton
        function PreRegistrationButtonPushed(app, event)
            app.Status.Value = "Please wait, PreRegistering ...";
            buttonsManager(app,'off')
            
            GridStep = 5;
            global ptCloudP;
            global ptCloudA;
            global V_label;
            global VA_label;

            [alpha_1_P, beta_1_P, alpha_2_P] = RotationParams(ptCloudP.Location);
            [alpha_1_A, beta_1_A, alpha_2_A] = RotationParams(ptCloudA.Location);
            ptCloud_P_R = pointCloud(PreRegister(ptCloudP.Location,alpha_1_P, beta_1_P, alpha_2_P));
            ptCloud_A_R = pointCloud(PreRegister(ptCloudA.Location,alpha_1_A, beta_1_A, alpha_2_A));
            
            SeperateVertebras = vertebra_seperator(V_label, alpha_1_P, beta_1_P, alpha_2_P, GridStep);
            SeperateVertebrasA = vertebra_seperator(VA_label, alpha_1_A, beta_1_A, alpha_2_A, GridStep);
            fn1 = fieldnames(SeperateVertebras);
            fn2 = fieldnames(SeperateVertebrasA);
            LocsP = [];
            LocsP_R = [];
            for k = 1:numel(fn1)
                pCloud = SeperateVertebras.(sprintf("Vertebra_%i", SeperateVertebras.(sprintf('%s',fn1{k})).number)).ptCloud;
                LocsP = [LocsP; pCloud.Location];
                fn = fieldnames(SeperateVertebras.(sprintf("Vertebra_%i", SeperateVertebras.(sprintf('%s',fn1{k})).number)));
                if sum(ismember(fn,"movingReg"))
                    movingReg = SeperateVertebras.(sprintf("Vertebra_%i", SeperateVertebras.(sprintf('%s',fn1{k})).number)).movingReg;
                    LocsP_R = [LocsP_R; movingReg.Location];
                else
                    boundaryPointC = SeperateVertebras.(sprintf("Vertebra_%i", SeperateVertebras.(sprintf('%s',fn1{k})).number)).boundaryPointC;
                    LocsP_R = [LocsP_R; boundaryPointC.Location];
                end
            end
            
            LocsA_R = [];
            LocsA = [];
            for k = 1:numel(fn2)
                pCloud = SeperateVertebrasA.(sprintf("Vertebra_%i", SeperateVertebrasA.(sprintf('%s',fn2{k})).number)).ptCloud;
                LocsA = [LocsA; pCloud.Location];
                movingReg = SeperateVertebrasA.(sprintf("Vertebra_%i", SeperateVertebrasA.(sprintf('%s',fn2{k})).number)).sampledPC;
                LocsA_R = [LocsA_R; movingReg.Location]; 
            end
            
            buttonsManager(app,'on')
            
            ax = app.UIAxes3;

            try 
                Mypcshowpair(pointCloud(LocsA_R), pointCloud(LocsP_R), 'Parent', ax);
                legend(ax, {'Atlas','Subject'})
            catch
                 close all
            end
            app.Status.Value = "PreRegistration Completed";
        end

        % Button pushed function: RegistrationButton
        function RegistrationButtonPushed(app, event)
                global V_label;
                global VA_label;
                global SeperateVertebras;
                global SeperateVertebrasA;
                global ptCloud_P_R;
                global ptCloud_A_R;
                global ptCloudAllPoints;
                global ptCloudAllPointsA;
                ptCloud_P = Pcloudmaker(V_label);
                ptCloud_A = Pcloudmaker(VA_label);
                
                
                
                
                
                
            if app.CPDButton.Value == 1
                
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
                DiceScore = DS(SeperateVertebrasF,SeperateVertebrasA);
                % Hausdorff Distance
                
                HausdorffScore = HD(SeperateVertebrasF,SeperateVertebrasA);
                % Average Surface Distance
                
                ASD_Score = ASD(SeperateVertebrasF.PCloud, ptCloud_A_transformed);
                % intersection of vertebras
                
                VertebraIntersectsVolume = VertebraIntersect_calc(SeperateVertebrasF,SeperateVertebrasA);
                % jacobian of displacemnet field
                try
                DisplacemnetField = registered_pointCloud.Location - ptCloud.Location;
                JacobianMatofDisplacemnetField = JacobianMatCalc(DisplacemnetField);
                catch
                    app.Status.Value = "there is a prolem with your python entrepretor. check it using pyenv command";
                    JacobianMatofDisplacemnetField = 'Error';
                end
                ax = app.UIAxes4;
                try 
                Mypcshowpair(pcdownsample(ptCloud_A,'gridAverage',GridStep), movingReg, 'Parent', ax);
                legend(ax, {'Atlas','Subject'})
                catch
                     close all
                end
                
                app.Status.Value = "CPD Registration Completed";
                
                
                
                
                
                
                
                
                
                
            elseif app.PolynomialFitButton.Value == 1
                
                
                GridStep = 5;
                ptCloud_P = Pcloudmaker(V_label);
                ptCloud = ptCloud_P;
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
                DiceScore = DS(SeperateVertebrasF,SeperateVertebrasA);
                % Hausdorff Distance
                
                HausdorffScore = HD(SeperateVertebrasF,SeperateVertebrasA);
                % Average Surface Distance
                
                ASD_Score = ASD(SeperateVertebrasF.PCloud, ptCloud_A_transformed);
                % intersection of vertebras
                
                VertebraIntersectsVolume = VertebraIntersect_calc(SeperateVertebrasF,SeperateVertebrasA);
                % jacobian of displacemnet field
                try
                DisplacemnetField = registered_pointCloud.Location - ptCloud.Location;
                JacobianMatofDisplacemnetField = JacobianMatCalc(DisplacemnetField);
                catch
                    app.Status.Value = "there is a prolem with your python entrepretor. check it using pyenv command";
                    JacobianMatofDisplacemnetField = 'Error';
                end
                
                ax = app.UIAxes4;
                try 
                Mypcshowpair(ptCloud_A_transformed,pcdownsample(registered_pointCloud,'gridAverage',GridStep), 'Parent', ax);
                legend(app.UIAxes4, {'Atlas','Subject'})
                catch
                     close all
                end
                app.Status.Value = "PolyFit Registration Completed";
                
                
                
                
                
                
                
                
                
                
            elseif app.CascadeFeedForwardNetsButton.Value ==1
                
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
                DiceScore = DS(SeperateVertebrasF,SeperateVertebrasA);
                % Hausdorff Distance
                
                HausdorffScore = HD(SeperateVertebrasF,SeperateVertebrasA);
                % Average Surface Distance
                
                ASD_Score = ASD(SeperateVertebrasF.PCloud, ptCloud_A_transformed);
                % intersection of vertebras
                
                VertebraIntersectsVolume = VertebraIntersect_calc(SeperateVertebrasF,SeperateVertebrasA);
                % jacobian of displacemnet field
                try
                DisplacemnetField = registered_pointCloud.Location - ptCloud.Location;
                JacobianMatofDisplacemnetField = JacobianMatCalc(DisplacemnetField);
                catch
                    app.Status.Value = "there is a prolem with your python entrepretor. check it using pyenv command";
                    JacobianMatofDisplacemnetField = 'Error';
                end
                
                ax = app.UIAxes4;
                try 
                Mypcshowpair(ptCloud_A_transformed, pointCloud([F_xR,F_yR,F_zR]), 'Parent', ax);
                legend(app.UIAxes4, {'Atlas','Subject'})
                catch
                     close all
                end
                app.Status.Value = "Network Registration Completed";

            end
            
            app.ASD.Value = num2str(ASD_Score);
            app.DS.Value = num2str(DiceScore);
            app.HD.Value = num2str(HausdorffScore);
            app.VBV.Value = num2str(VertebraIntersectsVolume);
            app.JOD.Value = num2str(JacobianMatofDisplacemnetField);
            
            
            
            

        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {618, 618};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {234, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 838 618];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {234, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create DevelopedbyMohammadAminAlamalhodaLabel
            app.DevelopedbyMohammadAminAlamalhodaLabel = uilabel(app.LeftPanel);
            app.DevelopedbyMohammadAminAlamalhodaLabel.HorizontalAlignment = 'center';
            app.DevelopedbyMohammadAminAlamalhodaLabel.FontSize = 10;
            app.DevelopedbyMohammadAminAlamalhodaLabel.Position = [1 544 232 22];
            app.DevelopedbyMohammadAminAlamalhodaLabel.Text = 'Developed by MohammadAmin Alamalhoda';

            % Create ImageRegistrationMIAPCoureProjectLabel
            app.ImageRegistrationMIAPCoureProjectLabel = uilabel(app.LeftPanel);
            app.ImageRegistrationMIAPCoureProjectLabel.HorizontalAlignment = 'center';
            app.ImageRegistrationMIAPCoureProjectLabel.Position = [61.5 578 112 28];
            app.ImageRegistrationMIAPCoureProjectLabel.Text = {'Image Registration '; 'MIAP Coure Project'};

            % Create LoadSubjectImageButton
            app.LoadSubjectImageButton = uibutton(app.LeftPanel, 'push');
            app.LoadSubjectImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadSubjectImageButtonPushed, true);
            app.LoadSubjectImageButton.Position = [56 486 124 22];
            app.LoadSubjectImageButton.Text = 'Load Subject Image';

            % Create LoadAtlasImageButton
            app.LoadAtlasImageButton = uibutton(app.LeftPanel, 'push');
            app.LoadAtlasImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadAtlasImageButtonPushed, true);
            app.LoadAtlasImageButton.Position = [64 438 109 22];
            app.LoadAtlasImageButton.Text = 'Load Atlas Image';

            % Create PreRegistrationButton
            app.PreRegistrationButton = uibutton(app.LeftPanel, 'push');
            app.PreRegistrationButton.ButtonPushedFcn = createCallbackFcn(app, @PreRegistrationButtonPushed, true);
            app.PreRegistrationButton.Position = [68.5 386 99 22];
            app.PreRegistrationButton.Text = 'PreRegistration';

            % Create Status
            app.Status = uieditfield(app.LeftPanel, 'text');
            app.Status.Editable = 'off';
            app.Status.Position = [5 15 223 109];

            % Create RegistrationButton
            app.RegistrationButton = uibutton(app.LeftPanel, 'push');
            app.RegistrationButton.ButtonPushedFcn = createCallbackFcn(app, @RegistrationButtonPushed, true);
            app.RegistrationButton.Position = [68 140 99 22];
            app.RegistrationButton.Text = 'Registration';

            % Create RegistrationTyoeButtonGroup
            app.RegistrationTyoeButtonGroup = uibuttongroup(app.LeftPanel);
            app.RegistrationTyoeButtonGroup.Title = 'Registration Tyoe';
            app.RegistrationTyoeButtonGroup.Position = [15 202 209 106];

            % Create CPDButton
            app.CPDButton = uiradiobutton(app.RegistrationTyoeButtonGroup);
            app.CPDButton.Text = 'CPD';
            app.CPDButton.Position = [11 60 47 22];
            app.CPDButton.Value = true;

            % Create PolynomialFitButton
            app.PolynomialFitButton = uiradiobutton(app.RegistrationTyoeButtonGroup);
            app.PolynomialFitButton.Text = 'Polynomial Fit';
            app.PolynomialFitButton.Position = [11 38 98 22];

            % Create CascadeFeedForwardNetsButton
            app.CascadeFeedForwardNetsButton = uiradiobutton(app.RegistrationTyoeButtonGroup);
            app.CascadeFeedForwardNetsButton.Text = 'Cascade FeedForward Nets';
            app.CascadeFeedForwardNetsButton.Position = [11 16 172 22];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, 'Subject')
            xlabel(app.UIAxes, '')
            ylabel(app.UIAxes, '')
            app.UIAxes.XTick = [];
            app.UIAxes.XTickLabel = '';
            app.UIAxes.YTick = [];
            app.UIAxes.HandleVisibility = 'off';
            app.UIAxes.Position = [64 413 192 193];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.RightPanel);
            title(app.UIAxes2, 'Atlas')
            xlabel(app.UIAxes2, '')
            ylabel(app.UIAxes2, '')
            app.UIAxes2.XTick = [];
            app.UIAxes2.XTickLabel = '';
            app.UIAxes2.YTick = [];
            app.UIAxes2.HandleVisibility = 'off';
            app.UIAxes2.Position = [312 407 198 199];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.RightPanel);
            title(app.UIAxes3, 'PreRegistred')
            xlabel(app.UIAxes3, '')
            ylabel(app.UIAxes3, '')
            app.UIAxes3.XTick = [];
            app.UIAxes3.XTickLabel = '';
            app.UIAxes3.YTick = [];
            app.UIAxes3.HandleVisibility = 'off';
            app.UIAxes3.Position = [64 154 192 193];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.RightPanel);
            title(app.UIAxes4, 'Registred')
            xlabel(app.UIAxes4, '')
            ylabel(app.UIAxes4, '')
            app.UIAxes4.XTick = [];
            app.UIAxes4.XTickLabel = '';
            app.UIAxes4.YTick = [];
            app.UIAxes4.HandleVisibility = 'off';
            app.UIAxes4.Position = [315 153 192 193];

            % Create DiceScoreLabel
            app.DiceScoreLabel = uilabel(app.RightPanel);
            app.DiceScoreLabel.Position = [55 120 68 23];
            app.DiceScoreLabel.Text = 'Dice Score:';

            % Create AverageSurfaceDistanceLabel
            app.AverageSurfaceDistanceLabel = uilabel(app.RightPanel);
            app.AverageSurfaceDistanceLabel.Position = [312 120 148 23];
            app.AverageSurfaceDistanceLabel.Text = 'Average Surface Distance:';

            % Create HausdorffDistanceLabel_2
            app.HausdorffDistanceLabel_2 = uilabel(app.RightPanel);
            app.HausdorffDistanceLabel_2.Position = [54 72 112 23];
            app.HausdorffDistanceLabel_2.Text = 'Hausdorff Distance:';

            % Create VolumebetweenvertebrasLabel
            app.VolumebetweenvertebrasLabel = uilabel(app.RightPanel);
            app.VolumebetweenvertebrasLabel.Position = [315 71 152 23];
            app.VolumebetweenvertebrasLabel.Text = 'Volume between vertebras:';

            % Create NOFnonpositiveelementsofjacobianmatrixofdisplacmentfieldLabel
            app.NOFnonpositiveelementsofjacobianmatrixofdisplacmentfieldLabel = uilabel(app.RightPanel);
            app.NOFnonpositiveelementsofjacobianmatrixofdisplacmentfieldLabel.Position = [50 3 402 46];
            app.NOFnonpositiveelementsofjacobianmatrixofdisplacmentfieldLabel.Text = {'Ratio of nonpositive elements of jacobian matrix of displacment field'; 'to number of all elements:'};

            % Create DS
            app.DS = uieditfield(app.RightPanel, 'text');
            app.DS.Editable = 'off';
            app.DS.Position = [175 119 100 22];

            % Create ASD
            app.ASD = uieditfield(app.RightPanel, 'text');
            app.ASD.Editable = 'off';
            app.ASD.Position = [474 119 100 22];

            % Create HD
            app.HD = uieditfield(app.RightPanel, 'text');
            app.HD.Editable = 'off';
            app.HD.Position = [175 70 100 22];

            % Create VBV
            app.VBV = uieditfield(app.RightPanel, 'text');
            app.VBV.Editable = 'off';
            app.VBV.Position = [474 70 100 22];

            % Create JOD
            app.JOD = uieditfield(app.RightPanel, 'text');
            app.JOD.Editable = 'off';
            app.JOD.Position = [474 15 100 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = IR_GUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end