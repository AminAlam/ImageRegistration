function ax = MyPcshow(varargin)
%   pcshow Plot 3-D point cloud.
%   PCSHOW(ptCloud) displays points with locations and colors or
%   intensities stored in the pointCloud object ptCloud. Use this function
%   to display static point cloud data.
% 
%   PCSHOW(xyzPoints) displays points at the locations that are
%   contained in an M-by-3 or M-by-N-by-3 xyzPoints matrix. The matrix,
%   xyzPoints, contains M or M-by-N [x,y,z] points. The color of each point
%   is determined by its Z value, which is linearly mapped to a color in
%   the current colormap.
%
%   PCSHOW(xyzPoints,colorValue) displays points at the locations that are
%   contained in the xyzPoints matrix with colors specified by colorValue.
%   To specify the same color for all points, colorValue must be a color
%   string or a 1-by-3 RGB vector. To specify a different color for each
%   point, colorValue must be an M-by-3 or M-by-N-by-3 matrix containing
%   RGB values for each point.
%
%   PCSHOW(xyzPoints,colorMapValue) displays points at the locations that
%   are contained in the xyzPoints matrix with colors from the current
%   color map. colorMapValue must be a vector or an M-by-N matrix
%   containing values that are linearly mapped to a color in the current
%   colormap.
%
%   PCSHOW(filename) displays the point cloud stored in the file specified
%   by filename. The file must contain a point cloud that PCREAD can read.
%   PCSHOW calls PCREAD to read the point cloud from the file, but does not
%   store the data in the MATLAB workspace.
%
%   ax = PCSHOW(...) returns the plot's axes.
%
%   pcshow(...,Name,Value) uses additional options specified by one
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
%   'Parent'           Specify an output axes for displaying the
%                      visualization. Note that uiaxes is not supported.
%
%   Notes 
%   ----- 
%   Points with NaN or inf coordinates will not be plotted. 
%
%   A 'MarkerSize' greater than 6 points may reduce rendering performance.
% 
%   cameratoolbar will be automatically turned on in the current figure.
%
%   Class Support 
%   ------------- 
%   ptCloud must be a pointCloud object. xyzPoints must be numeric. C must
%   be a color string or numeric.
% 
%   Example 1: Plot spherical point cloud with color 
%   ------------------------------------------------
%   % Generate a sphere consisting of 600-by-600 faces
%   numFaces = 600;
%   [x,y,z] = sphere(numFaces);
%   ptCloud = pointCloud([x(:),y(:),z(:)]);
%
%   % plot the sphere with the default color map
%   figure
%   pcshow(ptCloud)
%   title('Sphere with the default color map')
%   xlabel('X')
%   ylabel('Y')
%   zlabel('Z')
%
%   % load an image for texture mapping
%   I = imread('visionteam1.jpg');
%
%   % resize and flip the image for mapping the coordinates 
%   J = flipud(imresize(I, size(x)));
%   colorPtCloud = pointCloud([x(:),y(:),z(:)], 'Color', reshape(J, [], 3));
%
%   % plot the sphere with the color texture
%   figure
%   pcshow(colorPtCloud);
%   title('Sphere with the color texture')
%   xlabel('X')
%   ylabel('Y')
%   zlabel('Z')
%
%   Example 2: Plot Lidar point cloud based on its intensity
%   --------------------------------------------------------
%   % Load an organized Lidar point cloud with intensity property
%   ld = load('drivingLidarPoints.mat');
%   
%   % Plot the point cloud, whose intensity is mapped to the 'jet' color map
%   figure
%   pcshow(ld.ptCloud)
%   title('Lidar point cloud with intensity')
%   xlabel('X')
%   ylabel('Y')
%   zlabel('Z')
%   colorbar
%
%   % Change to a different colormap
%   colormap('winter')
%
%   See also pointCloud, pcplayer, reconstructScene, triangulate, plot3, scatter3 

%   Copyright 2013-2019 The MathWorks, Inc.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[X, Y, Z, C, markerSize, vertAxis, vertAxisDir, currentAxes, map, ptCloud] = ...
                            validateAndParseInputs(varargin{:});
                                
[currentAxes, hFigure] = pointclouds.internal.pcui.setupAxesAndFigure(currentAxes);
% Set the colormap
if ~isempty(map)
    colormap(hFigure, map);
end

% Set the colordata for storing
if isempty(C)
    C = Z;
    colorData = [];
else
    if isempty(ptCloud.Color) && isempty(ptCloud.Intensity)
        colorData = C;
    else
        % This means point cloud object holds the color information
        colorData = []; 
    end
end

hObj = scatter3(currentAxes, X, Y, Z, markerSize, C, '.', 'Tag', 'pcviewer');

if ischar(C)
    % This is done to use a numeric value for color data
    colorData = hObj.CData;
end

setappdata(hObj, 'PointCloud', ptCloud);
setappdata(hObj, 'ColorData', colorData);

% Lower and upper limit of auto downsampling.
ptCloudThreshold = [1920*1080, 1e8]; 

% Equal axis is required for cameratoolbar
axis(currentAxes, 'equal');

% Initialize point cloud viewer controls.
pointclouds.internal.pcui.initializePCSceneControl(hFigure, vertAxis,...
    vertAxisDir, ptCloudThreshold);

if nargout > 0
    ax = currentAxes;
    
    % Disable default interactions
    disableDefaultInteractivity(ax);
end

end

%========================================================================== 
function [X, Y, Z, C, markerSize, vertAxis, vertAxisDir, ax, map, ptCloud] = validateAndParseInputs(varargin)
% Validate and parse inputs
narginchk(1, 10);

% the 2nd argument is C only if the number of arguments is even and the
% first argument is not a pointCloud object
if  ~bitget(nargin, 1) && ~isa(varargin{1}, 'pointCloud')
    [X, Y, Z, C, map, ptCloud] = pointclouds.internal.pcui.validateAndParseInputsXYZC(mfilename, varargin{1:2});
    pvpairs = varargin(3:end);
else
    [X, Y, Z, C, map, ptCloud] = pointclouds.internal.pcui.validateAndParseInputsXYZC(mfilename, varargin{1});
    pvpairs = varargin(2:end);
end

parser = pointclouds.internal.pcui.getSharedParamParser(mfilename);

% uiaxes is not supported for pcshow
uiaxesSupportFlag = true;
parser.addParameter('Parent', [], ...
    @(p)vision.internal.inputValidation.validateAxesHandle(p, uiaxesSupportFlag));

parser.parse(pvpairs{:});
    
params = parser.Results;

markerSize  = params.MarkerSize;
ax          = params.Parent;
vertAxis    = params.VerticalAxis;
vertAxisDir = params.VerticalAxisDir;

end

