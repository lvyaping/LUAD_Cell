rm(list=ls()) # 清除环境变量
setwd("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图4. 细胞含量在每个患者之间的热图/") # 设置工作目录

#install.packages("pheatmap")
library(pheatmap) # 加载包
library(ggplot2) # 加载包
library(gtable)
library(grid)

data <- read.csv("Hospital_cell.csv", header = TRUE, row.names=1,sep = ",")
data <- data [,1:8]
data  <- t(data)# 转置
dim(data)# 查看变量有多少行多少列
other <- read.csv("Hospital_clinical_111.csv", header = TRUE, row.names=1,sep = ",")
select_data <- other[,c(1:14)]

p <- pheatmap(data, 
              border="white", # 设置边框为白色
              cellwidth = 5,cellheight = 10, # 设置热图方块宽度和高度
              cluster_cols = F, #去掉纵向聚类,横向聚类为cluster_rows
              show_colnames = F, #去掉纵坐标id,横标idshow_rownames
              )

dim(select_data)
#annotation_col <-select_data[,1]

annotation_col = data.frame(Gender = select_data[,1],
                            Age=select_data[,2],
                            Pathologic_stage=select_data[,3],
                            TNM_T=select_data[,4],
                            TNM_N=select_data[,5],
                            TNM_M=select_data[,6],
                            Number_of_lymph_node_metastasis=select_data[,7],
                            EGFR=select_data[,8],
                            ALK=select_data[,9],
                            Her_2=select_data[,10],
                            Ki_67=select_data[,11],
                            TOPIIA=select_data[,12],
                            p170=select_data[,13],
                            p53=select_data[,14]
                            )

rownames(annotation_col) <- colnames(data)




Sexcolor <- c("red","#66CC99") 
names(Sexcolor) <- c("FEMALE","MALE") #类型颜色

#Agecolor <- c("#99CCCC","#016D06",'white')
#names(Agecolor) <- c("low65","up65","None")
Agecolor <- c("#99CCCC","#016D06")
names(Agecolor) <- c("low65","up65")

#Pathologic_stagecolor <- c("#85B22E","#5F80B4","#E29827","#922927",'white') 
#names(Pathologic_stagecolor) <- c("Stage I","Stage II","Stage III","Stage IV","None") #类型颜色
Pathologic_stagecolor <- c("#85B22E","#5F80B4","#E29827","#922927") 
names(Pathologic_stagecolor) <- c("Stage I","Stage II","Stage III","Stage IV") #类型颜色

#TNM_Tcolor<- c("#708090",'#68A180','#F3B1A0', '#D6E7A3','white')
#names(TNM_Tcolor) <- c("T1","T2","T3","T4","None")
TNM_Tcolor<- c("#708090",'#68A180','#F3B1A0', '#D6E7A3')
names(TNM_Tcolor) <- c("T1","T2","T3","T4")

#TNM_Ncolor <- c("#FFF0F5",'#FFB6C1','#FF69B4','#FFFF66','white')
#names(TNM_Ncolor) <- c("N0","N1","N2","N3","None")
TNM_Ncolor <- c("#FFF0F5",'#FFB6C1','#FF69B4')
names(TNM_Ncolor) <- c("N0","N1","N2")

TNM_Mcolor <- c("#BDB76B",'#FFD700', 'white')
names(TNM_Mcolor) <- c("M0","M1","None")

Number_of_lymph_node_metastasiscolor <- c("#D87093",'#FFD899')
names(Number_of_lymph_node_metastasiscolor) <- c("No","Yes")

EGFRcolor <- c("#D87093",'#FFFF66','white')
names(EGFRcolor) <- c("Positive","Negative","None")

ALKcolor <- c("#99CC66",'#CC9999','white')
names(ALKcolor) <- c("Positive","Negative","None")

Her_2color <- c("#990033",'#336633','white')
names(Her_2color) <- c("Positive","Negative","None")

Ki_67color <- c("#CC0033",'#333333','white')
names(Ki_67color) <- c("Positive","Negative","None")

TOPIIAcolor <- c("#333399",'#CCCC00','white')
names(TOPIIAcolor) <- c("Positive","Negative","None")

p170color <- c("#FF6666",'#FFFF00','white')
names(p170color) <- c("Positive","Negative","None")

p53color <- c("#666666",'#CC9966','white')
names(p53color) <- c("Positive","Negative","None")

ann_colors <- list(Gender=Sexcolor, 
                   Age=Agecolor,
                   Pathologic_stage=Pathologic_stagecolor,
                   TNM_T=TNM_Tcolor,
                   TNM_N=TNM_Ncolor,
                   TNM_M=TNM_Mcolor,
                   Number_of_lymph_node_metastasis=Number_of_lymph_node_metastasiscolor,
                   EGFR=EGFRcolor,
                   ALK=ALKcolor,
                   Her_2=Her_2color,
                   Ki_67=Ki_67color,
                   TOPIIA=TOPIIAcolor,
                   p170=p170color,
                   p53=p53color
                   ) #颜色设置



p <- pheatmap(data, 
              scale="row",
              border="#444444", # 设置边框为白色
              cellwidth = 4,cellheight = 10, # 设置热图方块宽度和高度
              cluster_cols = T, #去掉纵向聚类,横向聚类为cluster_rows
              treeheight_row = 10,
              show_colnames = F, #去掉纵坐标id,横标idshow_rownames
              annotation_col = annotation_col,
              annotation_colors = ann_colors,
              fontsize = 8,
              breaks = seq(-1, 1, length.out = 100)
              )



save_pheatmap_pdf <- function(x, filename, width=7, height=7) {
  stopifnot(!missing(x))
  stopifnot(!missing(filename))
  pdf(filename, width=width, height=height)
  grid::grid.newpage()
  grid::grid.draw(x$gtable)
  dev.off()
}

save_pheatmap_pdf(p, "Hospital_heatmap.pdf",20,8)


