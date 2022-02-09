function ax = Mypcshowpair(ptCloudA, ptCloudB, varargin)
%PCSHOWPAIR Visualize differences between point clouds.
%   PCSHOWPAIR(ptCloudA, ptCloudB) creates a visualization of the
%   differences between point cloud ptCloudA and ptCloudB.
% 
%   ax = PCSHOWPAIR(...) returns the plot's axes.
%
%   PCSHOWPAIR(...,Name,Value) uses additional options specified by one
%   or more Name,Value pair arguments below:
%
%   'MarkerSize'       A positive scalar specifying the approximate
%                      diameter of the point marker in points, a unit
%                      defined by MATLAB graphics.
%
%                      Default: 6
%                       
%   'VerticalAxis'     A string specifying the vertical axis, whose value
%                      is 'X', 'Y' or 'Z'. 
%
%                      Default: 'Z'
%
%   'VerticalAxisDir'  A string specifying the direction of the vertical
%                      axis, whose value is 'Up' or 'Down'.
%
%                      Default: 'Up'
%
%   'BlendFactor'      A scalar between 0 and 1. It specifies the color
%                      blending coefficient, which controls the amount of
%                      magenta in the first point cloud and the amount of
%                      green in the second point cloud.
%
%                      Default: 0.7
%
%   'Parent'           Specify an output axes for displaying the
%                      visualization. Note that uiaxes is not supported.
%
%   Notes 
%   ----- 
%   - Points with NaN or Inf coordinates will not be displayed. 
%
%   - If the point cloud does not contain color information, pure magenta and green are
%     used to render the first and second point cloud, respectively.
%
%   - A 'MarkerSize' greater than 6 points may reduce rendering performance.
%
%   Class Support 
%   ------------- 
%   ptCloudA and ptCloudB must be pointCloud objects.
% 
%   Example: Visualize the difference between two point clouds
%   ----------------------------------------------------------
%   % Load two point clouds captured using Kinect
%   load('livingRoom');
%
%   pc1 = livingRoomData{1};
%   pc2 = livingRoomData{2};
%
%   % Plot and set the viewpoint
%   figure
%   pcshowpair(pc1,pc2,'VerticalAxis','Y','VerticalAxisDir','Down')
%   title('Visualize the difference between two point clouds')
%   xlabel('X(m)')
%   ylabel('Y(m)')
%   zlabel('Z(m)')
%
%   See also pointCloud, pcregistericp, pcshow, pcplayer 

%   Copyright 2015-2019 The MathWorks, Inc.

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

validateattributes(ptCloudA, {'pointCloud'}, {'scalar'}, 'pcshowpair', 'ptCloudA');
validateattributes(ptCloudB, {'pointCloud'}, {'scalar'}, 'pcshowpair', 'ptCloudB');

[markerSize, vertAxis, vertAxisDir, blendFactor, currentAxes] = validateAndParseOptInputs(varargin{:});

[currentAxes, hFigure] = pointclouds.internal.pcui.setupAxesAndFigure(currentAxes);
       
plotPointCloud(currentAxes, ptCloudA, markerSize, blendFactor, 'first');
tf = ishold;
if ~tf
    hold(currentAxes, 'on');
    plotPointCloud(currentAxes, ptCloudB, markerSize, blendFactor, 'second');
    hold(currentAxes, 'off');
else
    plotPointCloud(currentAxes, ptCloudB, markerSize, blendFactor, 'second');
end

% Lower and upper limit of auto downsampling.
ptCloudThreshold = [1920*1080, 1e8]; 

% Equal axis is required for cameratoolbar
axis(currentAxes, 'equal');

% Initialize point cloud viewer controls.
pointclouds.internal.pcui.initializePCSceneControl(hFigure, vertAxis,...
    vertAxisDir, ptCloudThreshold);

if nargout > 0
    ax = currentAxes;
end
end


%========================================================================== 
function plotPointCloud(currentAxes, ptCloud, markerSize, blendFactor, colorAssignment)
if ptCloud.Count > 0
    
    C = getColorValues(ptCloud, blendFactor, colorAssignment);
    
    count = ptCloud.Count;
    X = ptCloud.Location(1:count);
    Y = ptCloud.Location(count+1:count*2);
    Z = ptCloud.Location(count*2+1:end);
    hObj = scatter3(currentAxes, X, Y, Z, markerSize, C, '.', 'Tag', 'pcviewer');
    setappdata(hObj, 'PointCloud', ptCloud);
    setappdata(hObj, 'MagGrColor', C);
end
end

%========================================================================== 
function C = getColorValues(ptCloud, blendFactor, colorAssignment)

    if isempty(ptCloud.Color)
        if strcmpi(colorAssignment, 'first')
            C = [blendFactor, 0, blendFactor];
        else
            C = [0, blendFactor, 0];
        end
    else
        C = im2double(ptCloud.Color);
        if ~ismatrix(C)
            C = reshape(C, [], 3);
        end
        if strcmpi(colorAssignment, 'first')
            C(:, [1,3]) = C(:, [1,3]) * (1 - blendFactor) + blendFactor;
        else
            C(:, 2) = C(:, 2) * (1 - blendFactor) + blendFactor;
        end
    end
    
end

%========================================================================== 
function [markerSize, vertAxis, vertAxisDir, blendFactor, ax] = ...
                                        validateAndParseOptInputs(varargin)

parser = pointclouds.internal.pcui.getSharedParamParser(mfilename);


parser.addParameter('BlendFactor', 0.7, ...
            @(x)validateattributes(x, {'single', 'double'}, ...
                {'real', 'scalar', '>=', 0, '<=', 1}, mfilename, 'BlendFactor'));

% uiaxes is not supported for pcshowpair
uiaxesSupportFlag = true;
parser.addParameter('Parent', [], @(p)vision.internal.inputValidation.validateAxesHandle(p, uiaxesSupportFlag));

parser.parse(varargin{:});
    
params = parser.Results;

markerSize  = params.MarkerSize;
ax          = params.Parent;
blendFactor = params.BlendFactor;
vertAxis    = params.VerticalAxis;
vertAxisDir = params.VerticalAxisDir;

end