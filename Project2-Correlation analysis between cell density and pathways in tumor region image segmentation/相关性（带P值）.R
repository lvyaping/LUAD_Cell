
library(psych) #相关性检验
library(pheatmap) #热图绘制
diffmicro<-read.csv("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图2. 肿瘤区域图像分割的细胞密度和通路之间的相关性分析/通路匹配结果_217.csv",row.names = 1)
immunecell<-read.csv("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图2. 肿瘤区域图像分割的细胞密度和通路之间的相关性分析/细胞含量_217.csv",row.names = 1)

corr <- corr.test(diffmicro,immunecell,method="spearman",adjust = "BH")
r <- corr$r #相关系数矩阵
p <- corr$p #p值矩阵
getSig <- function(dc) {
  sc <- ''
  if (dc < 0.001) sc <- '***'
  else if (dc < 0.01) sc <- '**'
  else if (dc < 0.05) sc <- '*'
  sc
}
#为p值矩阵应用函数，生成显著性标记矩阵
sig_mat<- matrix(sapply(p, getSig), nrow=nrow(p))
#生成带显著性标记的热图

pic_origin <- pheatmap(r,cluster_cols = F,cluster_rows = T,cellheight = 7,cellwidth = 17,show_rownames = T,
                       show_colnames = T,border_color = "#D3D3D3", fontsize_number = 8,
                       display_numbers=sig_mat,color = c(colorRampPalette(colors = c("#1a908c","white","#d17133"))(100)),
                       filename = "E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图2. 肿瘤区域图像分割的细胞密度和通路之间的相关性分析/ner.pdf")

