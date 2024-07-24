rm(list=ls())
##差异分析##
library(data.table)
library(limma)
library(dplyr)
library(DESeq2)
library(edgeR)


mycolpal <- c("#e3716e","#7ac7e2","#54beaa","#bdb5e1","#b0d992","#f7df87")
subtype.col.pal <- c("#e3716e","#7ac7e2")
names(subtype.col.pal) <- c("High","Low")

setwd("E:\\流程搭建\\多组学聚类分型\\肺腺癌\\吕亚萍")
dir.create("transcriptome")
cell_type <- c("Lymphocyte","Neutrophil")

for (cell in cell_type){
  diff_gene_expression <- file.path("transcriptome",paste0(cell,"_diff_gene_expression"))
  dir.create(diff_gene_expression)
  
  clust.res <- read.csv(paste0(cell,"_group.csv"),row.names = 1)
  clust.res$group <- factor(clust.res$group,levels = c("High","Low"))
  dim(clust.res)
  head(clust.res)
  
  #设定过滤阈值
  FgCutoff <- 1.5
  qvalueCutoff <- 0.05
  
  #使用limma包利用fpkm进行差异分析
  fpkm <- "E:\\流程搭建\\多组学聚类分型\\肺腺癌\\input\\TCGA-LUAD_transcriptome_profilingonts_mRNA_fpkm_annovar_format.csv"
  rt_fpkm <- data.frame(fread(fpkm,sep=","),row.names = 1)
  rt_fpkm <- t(rt_fpkm)
  rt_fpkm[1:4,1:4]
  data_fpkm=avereps(rt_fpkm)
  data_fpkm=data_fpkm[rowMeans(data_fpkm)>0.1,]
  
  ##去掉正常样本
  group=sapply(strsplit(colnames(data_fpkm),"\\-"),"[",4)
  group=sapply(strsplit(group,""),"[",1)
  group=gsub("2","1",group)
  data_fpkm=data_fpkm[,group==0]
  colnames(data_fpkm) <- substr(colnames(data_fpkm),1,12)
  data_tmp <- as.data.frame(data_fpkm[,row.names(clust.res)] )
  #只纳入入组的样本
  data_tmp[1:4,1:4]
  dim(data_tmp)
  group <- clust.res$group
  
  design <- model.matrix(~factor(group)+0)
  colnames(design) <- c("High","Low")
  
  #算方差
  df.fit <- lmFit(data_tmp,design)
  df.matrix<- makeContrasts(High-Low,levels=design) 
  fit<- contrasts.fit(df.fit,df.matrix)
  #贝叶斯检验
  fit2 <- eBayes(fit)
  #输出基因
  allDEG1 = topTable(fit2,coef=1,n=Inf,adjust="BH") 
  allDEG1 = na.omit(allDEG1)
  allDEG1$group <- rep("High vs Low",nrow(allDEG1))
  allDEG1$genesymbol <- row.names(allDEG1)
  head(allDEG1)
  allDEG1 <- allDEG1 %>% filter(!is.na(logFC)&!is.na(adj.P.Val))
  allDEG1$genesymbol <- row.names(allDEG1)
  write.csv(allDEG1,file.path(diff_gene_expression,"DEG.limma.result.csv"),row.names = TRUE)
  
  
  count <- "E:\\流程搭建\\多组学聚类分型\\肺腺癌\\input\\TCGA-LUAD_transcriptome_profilingonts_mRNA_count_annovar_format.csv"
  rt <- data.frame(fread(count,sep=","),row.names = 1)
  rt <- t(rt)
  rt[1:4,1:4]
  data_count=avereps(rt)
  data_count=data_count[rowMeans(data_count)>0.1,]
  
  ##去掉正常样本
  group=sapply(strsplit(colnames(data_count),"\\-"),"[",4)
  group=sapply(strsplit(group,""),"[",1)
  group=gsub("2","1",group)
  data_count=data_count[,group==0]
  colnames(data_count) <- substr(colnames(data_count),1,12)
  data_count <- as.data.frame(data_count[,row.names(clust.res)] )
  #只纳入入组的样本
  data_count <- data_count[,row.names(clust.res)]
  data_count[1:4,1:4]
  data_tmp <- data_count
  data_tmp[1:4,1:4]
  group <- clust.res$group
  group_dat <- data.frame(condition=group)
  row.names(group_dat) <- row.names(group)
  
  data_tmp
  # 构建DESeq2中的对象
  dds <- DESeqDataSetFromMatrix(countData = data_tmp,colData = group_dat,design = ~ condition)
  # 指定哪一组作为对照组
  dds$condition <- relevel(dds$condition, ref = "Low")
  #计算每个样本的归一化系数
  dds <- estimateSizeFactors(dds)
  #估计基因的离散度
  dds <- estimateDispersions(dds)
  #差异分析
  dds <- nbinomWaldTest(dds)
  dds <- DESeq(dds)
  res <- results(dds)
  des.res <- as.data.frame(res)
  des.res <- des.res[!is.na(des.res$log2FoldChange),]
  des.res$logFC <- log(2^des.res$log2FoldChange)
  des.res$group <- rep("High vs Low",nrow(des.res))
  des.res$genesymbol <- row.names(des.res)
  des.res$adj.P.Val <- des.res$padj
  write.csv(des.res,file.path(diff_gene_expression,"DEG.deseq2.result.csv"),row.names = TRUE)
  
  ##edger分析##
  design <- model.matrix(~group)
  y <- DGEList(counts=data_tmp,group=group)#构建列表
  y <- calcNormFactors(y)#计算样本内标准化因子
  y <- estimateCommonDisp(y)#计算普通的离散
  y <- estimateTagwiseDisp(y)#计算基因范围内的离散
  et <- exactTest(y,pair = c("High","Low"))#进行精确检
  topTags(et)#输出排名靠前的差异miRNA信息
  ordered_tags <- topTags(et, n=100000)#将差异信息存入列
  #剔除FDR值为NA的行
  allDiff=ordered_tags$table
  allDiff=allDiff[is.na(allDiff$FDR)==FALSE,]
  ##原输出的比较组Comparison of groups:  nonclust-clust，进行取反操作 
  allDiff$logFC <- -allDiff$logFC
  allDiff$group <- rep("High vs Low",nrow(allDiff))
  allDiff$genesymbol <- row.names(allDiff)
  allDiff$adj.P.Val <- allDiff$FDR
  write.csv(allDiff,file.path(diff_gene_expression,"DEG.edger.result.csv"),row.names = TRUE)
}



