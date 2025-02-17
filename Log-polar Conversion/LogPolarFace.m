close all;
[file, path] = uigetfile({'*.png;*.jpg'}, 'Select an image to convert');
img = im2double(imread(fullfile(path, file)));
height = size(img, 1);
width = size(img, 2);
sampleImg = zeros(height, width);

%% Cortical area (resultant image dimensions)
cortWidth = width; %% width of one hemisphere of brain
cortHeight = floor(height/2);
background = 1; %% 0 (black) - 1 (white) background color where image not drawn

%% toggle whether left and right brain images should be split or stacked
imgSplit = false;
newImg = ones(cortHeight * (1 + ~imgSplit), cortWidth * (1 + imgSplit)) * background;

%% expCoef determines how exponential distance is represented in the cortex
% larger numbers mean greater area on cortex is mapped to the foveal region
expCoef = 100;

%% compression refers to how much an image should be scaled down
% a compression of 2 will mean that a circle with radius of 1800 px
% occupies a cortical pattern with a width of 900 px. Values < 1 will scale up the image
compression = width / cortWidth / 2; % when resize, can match size of original image

%% toggle drawing after every row is generated
stepDraw = false;

for pixel = 1:size(img, 3)
    imgSlice = img(:, :, pixel);
    newImgSlice = ones(cortHeight * (1 + ~imgSplit), cortWidth * (1 + imgSplit)) * background;
    
    for pol = 1: cortHeight
        %% Left side Cortical image
        for dist = 1: cortWidth
            radius = (power(expCoef, 1 - dist/cortWidth) - 1) / (expCoef - 1);
            radius = radius * cortWidth * 2 * compression;
            % Right side of retinal image: 90 to -90 degrees
            angle = (90 - pol / cortHeight * 180) * pi/180;
            [pixVal, inRange, x, y] = pixelValue(radius, angle, imgSlice, width, height);
            if inRange
                newImgSlice(pol, cortWidth - dist + 1) = pixVal;
                sampleImg(floor(y), floor(x)) = 1;
            end
        end

        %% Right side of image = left or bottom side of cortical image
        for dist = cortWidth + 1: 2 * cortWidth
            radius = (power(expCoef, dist/cortWidth - 1) - 1) / (expCoef - 1);
            radius = radius * cortWidth * 2 * compression;
            % Left side of retinal image: 90 to 270 degrees
            angle = (90 + pol / cortHeight * 180) * pi/180;
            [pixVal, inRange, x, y] = pixelValue(radius, angle, imgSlice, width, height);
            if inRange
                if imgSplit; newImgSlice(pol, cortWidth * 3 - dist + 1) = pixVal;
                else; newImgSlice(cortHeight * 2 - pol + 1, dist - cortWidth) = pixVal; end
                sampleImg(floor(y), floor(x)) = 1;
            end
        end

        if stepDraw; imshow(newImgSlice); end
    end
    newImg(:, :, pixel) = newImgSlice;
end
figure('Name', file)
imshow(img);
figure('Name', file + " - Converted");
imshow(newImg);
figure('Name', file + " - Sample Image");
imshow(sampleImg);

function [pixVal, inRange, x, y] = pixelValue(radius, angle, img, width, height)
    inRange = false;
    pixVal = 0;
    x = width/2 + 0.5 + cos(angle) * radius; 
    y = height/2 + 0.5 + sin(angle) * radius;
    if [x, y, -x, -y] > [1, 1, -width, -height]
        inRange = true;
        [x1, x2, y1, y2] = deal(floor(x), ceil(x), floor(y), ceil(y));
        weights = [x-x1, 1-x+x1, y-y1, 1-y+y1];

        % weight gives how close point is to the surrounding pixel
        % Hence, need to multiply pixel by opposite side weight
        topAvg = img(y1,x1) * weights(2) + img(y1,x2) * weights(1);
        bottomAvg = img(y2,x1) * weights(2) + img(y2,x2) * weights(1);
        pixVal = topAvg * weights(4) + bottomAvg * weights(3);

        % Better smoothening may be achieved by using distances to surrounding points as weights
        % instead of having 2 sets of weights (horizontal and vertical distance)
        % Furthermore, to better represent boundaries, a sigmoidal function could also be used
        % instead of a weighted average
    end
end