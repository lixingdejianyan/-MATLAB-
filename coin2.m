%% 多目标物品自动计数与位置标注系统
% 机器视觉大作业-方向2
clear;clc;close all;

%% 1.读取图像
img = imread('coin9.jpeg');  % 替换为你的零件/硬币图片路径
figure('Name','完整处理流程');
subplot(2,3,1);imshow(img);title('原图');

%% 2.灰度化
if size(img,3)==3
    gray = rgb2gray(img);
else
    gray = img;
end
subplot(2,3,2);imshow(gray);title('灰度图');

%% 3.高斯滤波降噪
gray_filter = imgaussfilt(gray,1.2);
subplot(2,3,3);imshow(gray_filter);title('滤波降噪图');

%% 4.自适应二值化（物品偏暗用反向取反~bw）
bw = imbinarize(gray_filter,'adaptive','ForegroundPolarity','dark');
bw = ~bw; % 物品为白色前景，背景黑色
subplot(2,3,4);imshow(bw);title('二值图');

%% 5.形态学运算：去小白噪点、填充孔洞
se_open = strel('disk',2);
se_close = strel('disk',3);
bw_clean = imopen(bw,se_open);  % 开运算去噪
bw_clean = imclose(bw_clean,se_close); % 闭运算填充孔洞
subplot(2,3,5);imshow(bw_clean);title('形态学净化图');

%% 6.连通域分析
[L,total_num] = bwlabel(bw_clean);
stats = regionprops(L,'Area','BoundingBox','Centroid');

%% 7.过滤过小杂点（根据图像调整面积阈值）
area_thresh = 150;  % 小于该像素面积判定为噪声
valid_idx = [];
pos_info = {}; % 存储每个有效目标坐标

for i = 1:total_num
    if stats(i).Area > area_thresh
        valid_idx = [valid_idx,i];
        box = stats(i).BoundingBox;
        cent = stats(i).Centroid;
        pos_info{end+1} = sprintf('目标%d：中心(%.1f,%.1f) 框[x,y,w,h]=[%.1f,%.1f,%.1f,%.1f]',...
            length(valid_idx),cent(1),cent(2),box(1),box(2),box(3),box(4));
    end
end
real_count = length(valid_idx);

%% 8.原图绘制标注框+中心点
subplot(2,3,6);imshow(img);hold on;
color_list = lines(real_count);
for k = 1:real_count
    idx = valid_idx(k);
    bbox = stats(idx).BoundingBox;
    cen = stats(idx).Centroid;
    % 绘制矩形框
    rectangle('Position',bbox,'EdgeColor',color_list(k,:),'LineWidth',2);
    % 绘制中心圆点
    plot(cen(1),cen(2),'o','Color',color_list(k,:),'MarkerSize',6,'MarkerFaceColor',color_list(k,:));
    % 标注编号
    text(cen(1)+6,cen(2),num2str(k),'Color','r','FontSize',12,'FontWeight','bold');
end
title(['目标总数：',num2str(real_count)]);hold off;

%% 9.控制台输出所有目标位置信息
fprintf('====================检测完成====================\n');
fprintf('图像内有效物品总数量：%d\n',real_count);
for s = 1:length(pos_info)
    fprintf('%s\n',pos_info{s});
end
fprintf('================================================\n');