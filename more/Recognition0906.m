%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   author: reborn
%   date:   2016/8/5
%   descr:  recognize the given USD belonging to which kind with the comparing results.
%			在算法中添加处理黑边的代码，增强鲁棒性：遇到代表黑边的异常数据不进行处理跳过这个位置
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic;
close all;                        %关闭所有窗口
clear all;						  %清空工作区，清空命令区域
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
testcaseCnt = 7;
USDKind = 5;
featureKind = 5;
interval = 100;
USDcouple = USDKind*(USDKind-1)/2;
titleArray = {'能量';'熵值';'对比度';'逆差矩';'相关性'};
dollarArray = {'5';'10';'20';'50';'100'};
%testcaseArray = {'testcase50','testcase100','testcase1','testcase5','testcase2','testcase20','testcase10'};
dataPath = '..\newall\f5d1\ZN';
testcasePath = '../matlabTestcase/';	%待修改
paramPath = 'minLocation_f5d1.txt';
exceptionValue = 100.0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%读取数据%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
allStatistics = importdata(paramPath);
allCouple(1).couple = {allStatistics(1,1),allStatistics(1,2)};
tempCouple = {allStatistics(1,1),allStatistics(1,2)};
allCouple(1).feature(1) = allStatistics(1,3);
allCouple(1).location(1) = allStatistics(1,4);
coupleCnt = 1;
featureCnt = 1;
for l = 2: size(allStatistics,1)
	if(tempCouple{1}==allStatistics(l,1)&&tempCouple{2}==allStatistics(l,2))
		featureCnt = featureCnt+1;
		allCouple(coupleCnt).feature(featureCnt) = allStatistics(l,3);
		allCouple(coupleCnt).location(featureCnt) = allStatistics(l,4);
	else
		coupleCnt = coupleCnt+1;
		featureCnt = 1;
		allCouple(coupleCnt).couple = {allStatistics(l,1),allStatistics(l,2)};
		allCouple(coupleCnt).feature(featureCnt) = allStatistics(l,3);
		allCouple(coupleCnt).location(featureCnt) = allStatistics(l,4);
		tempCouple = {allStatistics(l,1),allStatistics(l,2)};
	end
end

[testcaseFiles,testcasePaths] = dfsFolder(testcasePath);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%开始识别%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fo = fopen('recognizeResult.txt','wt');
fprintf(fo,'%s\t%s\n','识别种类','实际种类');
rightCnt = 0;

for i = 1: size(testcaseFiles,2)
	firstCouple = allCouple(1);
	ignoreCnt = 1;
	ignoreUSD = zeros(ignoreCnt);
	fileName = char(testcaseFiles(1,i));
	trueKind = '';
	for s = 1:length(fileName)
		if fileName(s) ~='Z'
			trueKind = strcat(trueKind,fileName(s));
		else
			break;
		end
	end
	
	distance1 = 0;
	distance2 = 0;
	for f = 1: featureKind
		ft = fopen(testcasePaths{i},'rt');
		f1 = fopen([dataPath '\newall_' num2str(firstCouple.couple{1}) 'ZN' '.txt'],'rt');
		f2 = fopen([dataPath '\newall_' num2str(firstCouple.couple{2}) 'ZN' '.txt'],'rt');
	
		locationNum = 1;
		while (~feof(ft))&&(~feof(f1))&&(~feof(f2))
			tline = fgetl(ft);
			line1 = fgetl(f1);
			line2 = fgetl(f2);
			if(isempty(tline)&&isempty(line1)&&isempty(line2))
				locationNum = locationNum+1;
			end
			if(locationNum==firstCouple.location(f))
				break;
			end
		end
		for j = 1:f
			tline = fgetl(ft);
			line1 = fgetl(f1);
			line2 = fgetl(f2);
		end
		
		tdata= str2num(tline);
		if(tdata==exceptionValue)
			continue;
		end
		
		line1 = str2num(line1);
		data1 = [];
		data1 = [data1;line1];
		aver1 = mean(data1);
		varia1 = std(data1);
		
		line2 = str2num(line2);
		data2 = [];
		data2 = [data2;line2];
		aver2 = mean(data2);
		varia2 = std(data2);
		
		distance1 = distance1+(abs(aver1-tdata))/varia1;
		distance2 = distance2+(abs(aver2-tdata))/varia2;
		
		fclose(ft);
		fclose(f1);
		fclose(f2);
	end
	if(distance1<=distance2)
		ignoreUSD(ignoreCnt) = firstCouple.couple{2}
	else
		ignoreUSD(ignoreCnt) = firstCouple.couple{1}
	end
	
	%pause();
	%break;
	
	for c = 2:coupleCnt
		flag = 0;
		for g = 1:size(ignoreUSD,2)
			if ((allCouple(c).couple{1}==ignoreUSD(g))||(allCouple(c).couple{2}==ignoreUSD(g)))
				flag = 1;
				break;
			end
		end
		if(flag==1)
			continue;
		end
		
		ignoreCnt = ignoreCnt+1;
		firstCouple = allCouple(c);
		distance1 = 0;
		distance2 = 0;
		for f = 1: featureKind
			ft = fopen(testcasePaths{i},'rt');
			f1 = fopen([dataPath '\newall_' num2str(firstCouple.couple{1}) 'ZN' '.txt'],'rt');
			f2 = fopen([dataPath '\newall_' num2str(firstCouple.couple{2}) 'ZN' '.txt'],'rt');
	
			locationNum = 1;
			while (~feof(ft))&&(~feof(f1))&&(~feof(f2))
				tline = fgetl(ft);
				line1 = fgetl(f1);
				line2 = fgetl(f2);
				if(isempty(tline)&&isempty(line1)&&isempty(line2))
					locationNum = locationNum+1;
				end
				if(locationNum==firstCouple.location(f))
					break;
				end
			end
			
			for j = 1:f
				tline = fgetl(ft);
				line1 = fgetl(f1);
				line2 = fgetl(f2);
			end
			
			tdata = str2num(tline);
			if(tdata==exceptionValue)
				continue;
			end
		
			line1 = str2num(line1);
			data1 = [];
			data1 = [data1;line1];
			aver1 = mean(data1);
			varia1 = std(data1);
		
			line2 = str2num(line2);
			data2 = [];
			data2 = [data2;line2];
			aver2 = mean(data2);
			varia2 = std(data2);
		
			distance1 = distance1+(abs(aver1-tdata))/varia1;
			distance2 = distance2+(abs(aver2-tdata))/varia2;
			% hist1 = histc(data1,min(data1):(max(data1)-min(data1))/interval:max(data1);
			% hist2 = histc(data2,min(data2):(max(data2)-min(data2))/interval:max(data2);
			% distance1 = distance1+(abs(-tdata))/varia1;
			% distance2 = distance2+(abs(aver2-tdata))/varia2;
		
			fclose(ft);
			fclose(f1);
			fclose(f2);
		end
		if(distance1<distance2)
			ignoreUSD(ignoreCnt) = firstCouple.couple{2}
			minUSD = firstCouple.couple{1}
		else
			ignoreUSD(ignoreCnt) = firstCouple.couple{1}
			minUSD = firstCouple.couple{2}
		end
		%pause();
	end
	disp('美金种类为：');
	disp(minUSD);
	disp('实际种类为：');
	disp(trueKind);
	fprintf(fo,'%3.3f\t\t%s\n',minUSD,trueKind);
	
	if(minUSD==str2num(trueKind))
		rightCnt = rightCnt+1;
	end
end

fprintf(fo,'\n','');
accuracyRate = rightCnt/size(testcaseFiles,2);
disp('准确率为：');
disp(accuracyRate);
fprintf(fo,'%s\t','准确率为：');
fprintf(fo,'%3.3f\n',accuracyRate);

fclose(fo);

toc;
	
		
		
		
			
		
		
	
	
